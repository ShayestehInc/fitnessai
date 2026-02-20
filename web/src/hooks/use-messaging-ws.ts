"use client";

import { useEffect, useRef, useCallback, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { API_URLS } from "@/lib/constants";
import {
  getAccessToken,
  isAccessTokenExpired,
  refreshAccessToken,
} from "@/lib/token-manager";
import type { Message, Conversation } from "@/types/messaging";

// ---------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------

export type WsConnectionState =
  | "connecting"
  | "connected"
  | "disconnected"
  | "failed";

interface WsNewMessageEvent {
  type: "new_message";
  message: Message;
}

interface WsTypingIndicatorEvent {
  type: "typing_indicator";
  user_id: number;
  is_typing: boolean;
}

interface WsReadReceiptEvent {
  type: "read_receipt";
  reader_id: number;
  read_at: string;
}

interface WsPongEvent {
  type: "pong";
}

type WsEvent =
  | WsNewMessageEvent
  | WsTypingIndicatorEvent
  | WsReadReceiptEvent
  | WsPongEvent;

// ---------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------

const HEARTBEAT_INTERVAL_MS = 30_000;
const HEARTBEAT_TIMEOUT_MS = 5_000;
const MAX_RECONNECT_ATTEMPTS = 5;
const BASE_RECONNECT_DELAY_MS = 1_000;
const MAX_RECONNECT_DELAY_MS = 16_000;
const TYPING_DEBOUNCE_MS = 3_000;
const TYPING_DISPLAY_TIMEOUT_MS = 4_000;

// Close codes from the backend consumer
const CLOSE_CODE_AUTH_FAILED = 4001;

// ---------------------------------------------------------------------
// Hook
// ---------------------------------------------------------------------

interface UseMessagingWebSocketOptions {
  conversationId: number;
  enabled?: boolean;
  /** Called when a new message arrives. Consumer should handle scroll logic. */
  onNewMessage?: (message: Message) => void;
}

interface UseMessagingWebSocketReturn {
  connectionState: WsConnectionState;
  typingUser: { userId: number; name: string } | null;
  sendTyping: (isTyping: boolean) => void;
}

export function useMessagingWebSocket({
  conversationId,
  enabled = true,
  onNewMessage,
}: UseMessagingWebSocketOptions): UseMessagingWebSocketReturn {
  const queryClient = useQueryClient();

  const [connectionState, setConnectionState] =
    useState<WsConnectionState>("disconnected");
  const [typingUser, setTypingUser] = useState<{
    userId: number;
    name: string;
  } | null>(null);

  // Refs for mutable state that shouldn't trigger re-renders
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const pongTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const typingDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const typingDisplayTimerRef = useRef<ReturnType<typeof setTimeout> | null>(
    null,
  );
  const lastTypingSentRef = useRef(false);
  const intentionalCloseRef = useRef(false);
  const onNewMessageRef = useRef(onNewMessage);
  onNewMessageRef.current = onNewMessage;

  // ------------------------------------------------------------------
  // Cleanup helpers
  // ------------------------------------------------------------------

  const clearTimers = useCallback(() => {
    if (reconnectTimerRef.current) {
      clearTimeout(reconnectTimerRef.current);
      reconnectTimerRef.current = null;
    }
    if (heartbeatTimerRef.current) {
      clearInterval(heartbeatTimerRef.current);
      heartbeatTimerRef.current = null;
    }
    if (pongTimerRef.current) {
      clearTimeout(pongTimerRef.current);
      pongTimerRef.current = null;
    }
    if (typingDebounceRef.current) {
      clearTimeout(typingDebounceRef.current);
      typingDebounceRef.current = null;
    }
    if (typingDisplayTimerRef.current) {
      clearTimeout(typingDisplayTimerRef.current);
      typingDisplayTimerRef.current = null;
    }
  }, []);

  // ------------------------------------------------------------------
  // React Query cache helpers
  // ------------------------------------------------------------------

  const appendMessageToCache = useCallback(
    (message: Message) => {
      // Update the messages cache for page 1 of this conversation
      queryClient.setQueryData(
        ["messaging", "messages", conversationId, 1],
        (old: { count: number; next: string | null; previous: string | null; results: Message[] } | undefined) => {
          if (!old) return old;
          // Dedup by ID
          if (old.results.some((m) => m.id === message.id)) return old;
          return {
            ...old,
            count: old.count + 1,
            results: [...old.results, message],
          };
        },
      );
    },
    [queryClient, conversationId],
  );

  const updateConversationPreview = useCallback(
    (message: Message) => {
      queryClient.setQueryData(
        ["messaging", "conversations"],
        (old: Conversation[] | undefined) => {
          if (!old) return old;
          return old.map((conv) => {
            if (conv.id !== conversationId) return conv;
            return {
              ...conv,
              last_message_at: message.created_at,
              last_message_preview:
                message.content || (message.image ? "Sent a photo" : ""),
            };
          });
        },
      );
    },
    [queryClient, conversationId],
  );

  const updateReadReceipts = useCallback(
    (readAt: string) => {
      // Mark all own messages as read in the cache
      queryClient.setQueryData(
        ["messaging", "messages", conversationId, 1],
        (old: { count: number; next: string | null; previous: string | null; results: Message[] } | undefined) => {
          if (!old) return old;
          return {
            ...old,
            results: old.results.map((m) =>
              !m.is_read ? { ...m, is_read: true, read_at: readAt } : m,
            ),
          };
        },
      );
    },
    [queryClient, conversationId],
  );

  // ------------------------------------------------------------------
  // WebSocket connect
  // ------------------------------------------------------------------

  const connect = useCallback(async () => {
    // Close existing connection if any
    if (wsRef.current) {
      intentionalCloseRef.current = true;
      wsRef.current.close(1000);
      wsRef.current = null;
    }

    setConnectionState("connecting");

    // Ensure we have a valid token
    if (isAccessTokenExpired()) {
      const refreshed = await refreshAccessToken();
      if (!refreshed) {
        setConnectionState("failed");
        return;
      }
    }

    const token = getAccessToken();
    if (!token) {
      setConnectionState("failed");
      return;
    }

    const wsUrl = `${API_URLS.wsMessaging(conversationId)}?token=${encodeURIComponent(token)}`;

    let ws: WebSocket;
    try {
      ws = new WebSocket(wsUrl);
    } catch {
      setConnectionState("failed");
      return;
    }

    wsRef.current = ws;
    intentionalCloseRef.current = false;

    ws.onopen = () => {
      setConnectionState("connected");
      reconnectAttemptsRef.current = 0;

      // Start heartbeat
      heartbeatTimerRef.current = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: "ping" }));

          // Set pong timeout
          pongTimerRef.current = setTimeout(() => {
            // No pong received — close and trigger reconnect
            ws.close(4000, "Heartbeat timeout");
          }, HEARTBEAT_TIMEOUT_MS);
        }
      }, HEARTBEAT_INTERVAL_MS);
    };

    ws.onmessage = (event: MessageEvent) => {
      let data: WsEvent;
      try {
        data = JSON.parse(event.data as string) as WsEvent;
      } catch {
        // Malformed message — silently ignore
        return;
      }

      switch (data.type) {
        case "pong":
          // Clear pong timeout
          if (pongTimerRef.current) {
            clearTimeout(pongTimerRef.current);
            pongTimerRef.current = null;
          }
          break;

        case "new_message":
          appendMessageToCache(data.message);
          updateConversationPreview(data.message);
          onNewMessageRef.current?.(data.message);
          // Clear typing indicator — if user just sent a message, they stopped typing
          setTypingUser(null);
          if (typingDisplayTimerRef.current) {
            clearTimeout(typingDisplayTimerRef.current);
            typingDisplayTimerRef.current = null;
          }
          break;

        case "typing_indicator":
          if (data.is_typing) {
            // We don't have the name from the WS event — use a placeholder.
            // The chat-view will resolve the name from conversation data.
            setTypingUser({ userId: data.user_id, name: "" });

            // Reset display timeout
            if (typingDisplayTimerRef.current) {
              clearTimeout(typingDisplayTimerRef.current);
            }
            typingDisplayTimerRef.current = setTimeout(() => {
              setTypingUser(null);
            }, TYPING_DISPLAY_TIMEOUT_MS);
          } else {
            setTypingUser(null);
            if (typingDisplayTimerRef.current) {
              clearTimeout(typingDisplayTimerRef.current);
              typingDisplayTimerRef.current = null;
            }
          }
          break;

        case "read_receipt":
          updateReadReceipts(data.read_at);
          break;

        default:
          // Unknown event type — silently ignore
          break;
      }
    };

    ws.onclose = (event: CloseEvent) => {
      clearTimers();
      wsRef.current = null;

      if (intentionalCloseRef.current) {
        setConnectionState("disconnected");
        return;
      }

      // Auth failure — try to refresh token and reconnect
      if (event.code === CLOSE_CODE_AUTH_FAILED) {
        refreshAccessToken().then((refreshed) => {
          if (refreshed && reconnectAttemptsRef.current < MAX_RECONNECT_ATTEMPTS) {
            reconnectAttemptsRef.current += 1;
            connect();
          } else {
            setConnectionState("failed");
          }
        });
        return;
      }

      // Unexpected close — reconnect with backoff
      if (reconnectAttemptsRef.current < MAX_RECONNECT_ATTEMPTS) {
        setConnectionState("disconnected");
        const delay = Math.min(
          BASE_RECONNECT_DELAY_MS * Math.pow(2, reconnectAttemptsRef.current),
          MAX_RECONNECT_DELAY_MS,
        );
        reconnectAttemptsRef.current += 1;

        reconnectTimerRef.current = setTimeout(() => {
          connect();
        }, delay);
      } else {
        setConnectionState("failed");
      }
    };

    ws.onerror = () => {
      // The onclose handler will fire after onerror — let it handle reconnection
    };
  }, [
    conversationId,
    clearTimers,
    appendMessageToCache,
    updateConversationPreview,
    updateReadReceipts,
  ]);

  // ------------------------------------------------------------------
  // Send typing indicator
  // ------------------------------------------------------------------

  const sendTyping = useCallback(
    (isTyping: boolean) => {
      const ws = wsRef.current;
      if (!ws || ws.readyState !== WebSocket.OPEN) return;

      if (isTyping) {
        // Debounce: don't send more than once per TYPING_DEBOUNCE_MS
        if (lastTypingSentRef.current) return;

        ws.send(JSON.stringify({ type: "typing", is_typing: true }));
        lastTypingSentRef.current = true;

        if (typingDebounceRef.current) {
          clearTimeout(typingDebounceRef.current);
        }
        typingDebounceRef.current = setTimeout(() => {
          lastTypingSentRef.current = false;
          // Send stop-typing after debounce (idle timeout)
          if (wsRef.current?.readyState === WebSocket.OPEN) {
            wsRef.current.send(
              JSON.stringify({ type: "typing", is_typing: false }),
            );
          }
        }, TYPING_DEBOUNCE_MS);
      } else {
        // Explicit stop-typing
        lastTypingSentRef.current = false;
        if (typingDebounceRef.current) {
          clearTimeout(typingDebounceRef.current);
          typingDebounceRef.current = null;
        }
        ws.send(JSON.stringify({ type: "typing", is_typing: false }));
      }
    },
    [],
  );

  // ------------------------------------------------------------------
  // Lifecycle: connect/disconnect on conversation change
  // ------------------------------------------------------------------

  useEffect(() => {
    if (!enabled || conversationId <= 0) return;

    connect();

    return () => {
      intentionalCloseRef.current = true;
      clearTimers();
      if (wsRef.current) {
        wsRef.current.close(1000);
        wsRef.current = null;
      }
      setConnectionState("disconnected");
      setTypingUser(null);
      reconnectAttemptsRef.current = 0;
    };
  }, [conversationId, enabled, connect, clearTimers]);

  // ------------------------------------------------------------------
  // Reconnect on tab visibility change
  // ------------------------------------------------------------------

  useEffect(() => {
    if (!enabled) return;

    const handleVisibilityChange = () => {
      if (document.visibilityState === "visible" && !wsRef.current) {
        reconnectAttemptsRef.current = 0;
        connect();
      }
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    };
  }, [enabled, connect]);

  return { connectionState, typingUser, sendTyping };
}

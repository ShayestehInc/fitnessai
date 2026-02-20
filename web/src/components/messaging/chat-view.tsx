"use client";

import { useEffect, useRef, useCallback, useState } from "react";
import { ArrowDown, User, Loader2 } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { getInitials } from "@/lib/format-utils";
import { useMessages, useSendMessage, useMarkConversationRead } from "@/hooks/use-messaging";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { MessageBubble } from "./message-bubble";
import { ChatInput } from "./chat-input";
import type { Conversation, Message } from "@/types/messaging";

interface ChatViewProps {
  conversation: Conversation;
}

export function ChatView({ conversation }: ChatViewProps) {
  const { user } = useAuth();
  const [page, setPage] = useState(1);
  const [allMessages, setAllMessages] = useState<Message[]>([]);
  const [showScrollDown, setShowScrollDown] = useState(false);

  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const { data, isLoading, isError, refetch } = useMessages(conversation.id, page);
  const sendMessage = useSendMessage(conversation.id);
  const markRead = useMarkConversationRead(conversation.id);

  // Show the other party's info in the header
  const otherParty =
    user?.id === conversation.trainer.id
      ? conversation.trainee
      : conversation.trainer;
  const displayName =
    `${otherParty.first_name} ${otherParty.last_name}`.trim() || otherParty.email;
  const initials = getInitials(otherParty.first_name, otherParty.last_name);

  // Reset state when conversation changes
  useEffect(() => {
    setPage(1);
    setAllMessages([]);
  }, [conversation.id]);

  // Merge fetched messages into state
  useEffect(() => {
    if (data?.results) {
      setAllMessages((prev) => {
        if (page === 1) {
          return data.results;
        }
        // Prepend older messages, dedup by id
        const existingIds = new Set(prev.map((m) => m.id));
        const newMessages = data.results.filter((m) => !existingIds.has(m.id));
        return [...newMessages, ...prev];
      });
    }
  }, [data, page]);

  // Mark conversation as read on open (only once per conversation switch)
  const markReadCalledRef = useRef<number | null>(null);
  useEffect(() => {
    if (
      conversation.unread_count > 0 &&
      markReadCalledRef.current !== conversation.id
    ) {
      markReadCalledRef.current = conversation.id;
      markRead.mutate();
    }
  }, [conversation.id, conversation.unread_count, markRead]);

  const scrollToBottom = useCallback(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, []);

  // Auto-scroll to bottom on initial load and when sending a message
  useEffect(() => {
    if (page === 1 && allMessages.length > 0) {
      scrollToBottom();
    }
  }, [allMessages.length, page, scrollToBottom]);

  // Refetch messages every 5 seconds for near-real-time feel
  useEffect(() => {
    if (page !== 1) return;
    const interval = setInterval(() => {
      refetch();
    }, 5_000);
    return () => clearInterval(interval);
  }, [page, refetch]);

  const handleScroll = useCallback(() => {
    const el = scrollAreaRef.current;
    if (!el) return;

    // Show scroll-down button if not near bottom
    const distanceFromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
    setShowScrollDown(distanceFromBottom > 100);

    // Load more when scrolled to top
    if (el.scrollTop < 50 && data?.next && !isLoading) {
      setPage((p) => p + 1);
    }
  }, [data?.next, isLoading]);

  const handleSend = useCallback(
    (content: string, image?: File) => {
      sendMessage.mutate(
        { content, image },
        {
          onSuccess: () => {
            // Refetch page 1 to show latest message
            setPage(1);
            refetch();
            scrollToBottom();
          },
        },
      );
    },
    [sendMessage, refetch, scrollToBottom],
  );

  // Group messages by date for date separators
  const groupedMessages = groupMessagesByDate(allMessages);

  return (
    <div className="flex h-full flex-col">
      {/* Chat header */}
      <div className="flex items-center gap-3 border-b px-4 py-3">
        <Avatar size="default">
          {otherParty.profile_image ? (
            <AvatarImage src={otherParty.profile_image} alt={displayName} />
          ) : null}
          <AvatarFallback>
            {initials || <User className="h-4 w-4" aria-hidden="true" />}
          </AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-sm font-semibold">{displayName}</h2>
          <p className="truncate text-xs text-muted-foreground">
            {otherParty.email}
          </p>
        </div>
      </div>

      {/* Messages area */}
      <div
        ref={scrollAreaRef}
        onScroll={handleScroll}
        className="relative flex-1 overflow-y-auto px-4 py-4"
        role="log"
        aria-label="Message history"
        aria-live="polite"
      >
        {isLoading && page === 1 ? (
          <div className="flex items-center justify-center py-12" role="status">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            <span className="sr-only">Loading messages...</span>
          </div>
        ) : isError ? (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <p className="mb-2 text-sm text-destructive">
              Failed to load messages
            </p>
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Try again
            </Button>
          </div>
        ) : allMessages.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <p className="text-sm text-muted-foreground">
              No messages yet. Send a message to start the conversation.
            </p>
          </div>
        ) : (
          <div className="space-y-1">
            {isLoading && page > 1 && (
              <div className="flex justify-center py-2" role="status">
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                <span className="sr-only">Loading older messages...</span>
              </div>
            )}
            {groupedMessages.map((group) => (
              <div key={group.date}>
                <div className="my-4 flex items-center gap-3">
                  <div className="h-px flex-1 bg-border" />
                  <span className="text-[11px] font-medium text-muted-foreground">
                    {group.date}
                  </span>
                  <div className="h-px flex-1 bg-border" />
                </div>
                <div className="space-y-1.5">
                  {group.messages.map((message) => (
                    <MessageBubble
                      key={message.id}
                      message={message}
                      isOwnMessage={message.sender.id === user?.id}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
        <div ref={bottomRef} />

        {/* Scroll to bottom button */}
        {showScrollDown && (
          <Button
            size="icon"
            variant="secondary"
            className="absolute bottom-4 right-4 h-8 w-8 rounded-full shadow-md"
            onClick={scrollToBottom}
            aria-label="Scroll to latest messages"
          >
            <ArrowDown className="h-4 w-4" />
          </Button>
        )}
      </div>

      {/* Typing indicator: v1 limitation — web uses HTTP polling, not WebSocket.
         Typing indicators require real-time bidirectional communication which is
         only available on mobile via WebSocket. The TypingIndicator component exists
         at ./typing-indicator.tsx for use when web WebSocket support is added. */}

      {/* Chat input */}
      <ChatInput onSend={handleSend} isSending={sendMessage.isPending} />
    </div>
  );
}

interface MessageGroup {
  date: string;
  messages: Message[];
}

function groupMessagesByDate(messages: Message[]): MessageGroup[] {
  const groups: MessageGroup[] = [];
  let currentDate = "";

  for (const message of messages) {
    const date = new Date(message.created_at);
    const dateStr = formatDateSeparator(date);

    if (dateStr !== currentDate) {
      currentDate = dateStr;
      groups.push({ date: dateStr, messages: [] });
    }
    groups[groups.length - 1].messages.push(message);
  }

  return groups;
}

function formatDateSeparator(date: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const messageDay = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
  );

  const diffDays = Math.floor(
    (today.getTime() - messageDay.getTime()) / 86_400_000,
  );

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) {
    return date.toLocaleDateString(undefined, { weekday: "long" });
  }
  return date.toLocaleDateString(undefined, {
    month: "long",
    day: "numeric",
    year:
      date.getFullYear() !== now.getFullYear() ? "numeric" : undefined,
  });
}

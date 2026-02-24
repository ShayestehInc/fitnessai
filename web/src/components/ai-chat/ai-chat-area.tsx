"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { BrainCircuit, Loader2, Send, Sparkles, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ChatMessage } from "./chat-message";
import { SuggestionChips } from "./suggestion-chips";
import { TraineeSelector } from "./trainee-selector";
import type { AiChatThreadDetail } from "@/types/ai-chat";

interface AiChatAreaProps {
  thread: AiChatThreadDetail | undefined;
  isLoadingThread: boolean;
  isSending: boolean;
  pendingMessage: string | null;
  sendError: string | null;
  suggestedFollowup: string;
  onSend: (content: string, traineeId?: number) => void;
  onDismissError: () => void;
}

export function AiChatArea({
  thread,
  isLoadingThread,
  isSending,
  pendingMessage,
  sendError,
  suggestedFollowup,
  onSend,
  onDismissError,
}: AiChatAreaProps) {
  const [input, setInput] = useState("");
  const [traineeId, setTraineeId] = useState<number | undefined>();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Auto-scroll when messages change, pending message appears, or sending state changes
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [thread?.messages, pendingMessage, isSending]);

  const handleSend = useCallback(() => {
    if (!input.trim() || isSending) return;
    const text = input.trim();
    setInput("");
    onSend(text, traineeId);
  }, [input, traineeId, isSending, onSend]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSend();
        return;
      }
      // Tab to accept AI suggestion
      if (e.key === "Tab" && suggestedFollowup && !input) {
        e.preventDefault();
        setInput(suggestedFollowup);
      }
    },
    [handleSend, suggestedFollowup, input],
  );

  const handleSuggestion = useCallback(
    (s: string) => {
      onSend(s, traineeId);
    },
    [onSend, traineeId],
  );

  // No thread selected — show empty state
  if (!thread && !isLoadingThread) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-4 text-center">
        <div className="rounded-full bg-muted p-4">
          <BrainCircuit className="h-8 w-8 text-muted-foreground" aria-hidden="true" />
        </div>
        <h3 className="text-lg font-semibold">Select a thread</h3>
        <p className="max-w-sm text-sm text-muted-foreground">
          Choose a thread from the sidebar or create a new one to start chatting
          with your AI assistant.
        </p>
      </div>
    );
  }

  // Loading thread detail
  if (isLoadingThread) {
    return (
      <div className="flex h-full items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  const serverMessages = thread?.messages ?? [];
  const hasMessages = serverMessages.length > 0 || pendingMessage !== null;
  const showGhost = !isSending && !input && suggestedFollowup;

  return (
    <div className="flex h-full flex-col">
      {/* Top bar */}
      <div className="flex items-center justify-between border-b px-4 py-2">
        <div className="min-w-0 flex-1">
          <h3 className="truncate text-sm font-medium">{thread?.title}</h3>
          {thread?.trainee_context_name && (
            <p className="text-xs text-muted-foreground">
              Context: {thread.trainee_context_name}
            </p>
          )}
        </div>
        <TraineeSelector value={traineeId} onChange={setTraineeId} />
      </div>

      {/* Error banner */}
      {sendError && (
        <div className="flex items-center justify-between bg-destructive/10 px-4 py-2 text-sm text-destructive">
          <span>{sendError}</span>
          <Button variant="ghost" size="icon-xs" onClick={onDismissError}>
            <X className="h-3 w-3" />
          </Button>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        {!hasMessages ? (
          <div className="flex h-full flex-col items-center justify-center gap-6">
            <div className="rounded-full bg-muted p-4">
              <BrainCircuit className="h-12 w-12 text-muted-foreground" />
            </div>
            <div className="text-center">
              <h3 className="mb-1 text-lg font-semibold">AI Assistant</h3>
              <p className="max-w-md text-sm text-muted-foreground">
                Ask questions about your trainees, get insights, or generate
                summaries. Select a trainee for context-specific answers.
              </p>
            </div>
            <SuggestionChips onSelect={handleSuggestion} />
          </div>
        ) : (
          <div className="space-y-4">
            {serverMessages.map((msg) => (
              <ChatMessage
                key={msg.id}
                message={{
                  role: msg.role,
                  content: msg.content,
                  timestamp: msg.created_at,
                }}
              />
            ))}

            {/* Optimistic user message + thinking indicator */}
            {pendingMessage !== null && (
              <>
                <ChatMessage
                  message={{
                    role: "user",
                    content: pendingMessage,
                    timestamp: new Date().toISOString(),
                  }}
                />
                <div className="flex items-center gap-2 rounded-lg bg-muted px-4 py-3 text-sm text-muted-foreground">
                  <Sparkles className="h-4 w-4 animate-pulse" />
                  <span>AI is crafting your answer...</span>
                </div>
              </>
            )}

            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input with ghost AI suggestion */}
      <div className="flex gap-2 border-t px-4 py-3">
        <div className="relative flex-1">
          {/* Ghost text layer — AI-generated follow-up shown behind the real input */}
          {showGhost && (
            <div
              className="pointer-events-none absolute inset-0 flex items-center px-3 text-sm text-muted-foreground/40"
              aria-hidden="true"
            >
              <span className="truncate">{suggestedFollowup}</span>
              <span className="ml-2 shrink-0 rounded border border-muted-foreground/20 px-1 py-0.5 text-[10px] leading-none text-muted-foreground/40">
                Tab
              </span>
            </div>
          )}
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={showGhost ? "" : "Ask your AI assistant..."}
            disabled={isSending}
            className="h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs transition-colors focus-visible:border-ring focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50"
          />
        </div>
        <Button
          onClick={handleSend}
          disabled={!input.trim() || isSending}
          size="icon"
          aria-label="Send message"
        >
          {isSending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Send className="h-4 w-4" />
          )}
        </Button>
      </div>
    </div>
  );
}

"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { BrainCircuit, Loader2, Send, Trash2, X, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAiChat, useAiProviders } from "@/hooks/use-ai-chat";
import { ChatMessage } from "./chat-message";
import { SuggestionChips } from "./suggestion-chips";
import { TraineeSelector } from "./trainee-selector";

export function ChatContainer() {
  const { messages, isSending, error, sendMessage, clearMessages, dismissError } =
    useAiChat();
  const providers = useAiProviders();
  const [input, setInput] = useState("");
  const [traineeId, setTraineeId] = useState<number | undefined>();
  const [clearDialogOpen, setClearDialogOpen] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const isConfigured =
    providers.data && providers.data.some((p) => p.is_configured);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = useCallback(() => {
    if (!input.trim()) return;
    const text = input;
    setInput("");
    sendMessage(text, traineeId);
  }, [input, traineeId, sendMessage]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  const handleSuggestion = useCallback((s: string) => {
    setInput(s);
  }, []);

  if (providers.isLoading) {
    return (
      <div className="flex h-[calc(100vh-12rem)] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (providers.data && !isConfigured) {
    return (
      <div className="flex h-[calc(100vh-12rem)] flex-col items-center justify-center gap-4">
        <div className="rounded-full bg-amber-100 p-4 dark:bg-amber-900/20">
          <AlertTriangle className="h-8 w-8 text-amber-500" />
        </div>
        <p className="text-lg font-semibold">AI is not configured</p>
        <p className="text-sm text-muted-foreground">
          Contact your admin to set up AI providers.
        </p>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-12rem)] flex-col">
      {/* Top bar */}
      <div className="flex items-center justify-between border-b pb-3">
        <TraineeSelector value={traineeId} onChange={setTraineeId} />
        {messages.length > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setClearDialogOpen(true)}
          >
            <Trash2 className="mr-1 h-4 w-4" />
            Clear
          </Button>
        )}
      </div>

      {/* Error banner */}
      {error && (
        <div className="flex items-center justify-between rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          <span>{error}</span>
          <Button variant="ghost" size="icon-xs" onClick={dismissError}>
            <X className="h-3 w-3" />
          </Button>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto py-4">
        {messages.length === 0 ? (
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
          <div className="space-y-4 px-1">
            {messages.map((msg, i) => (
              <ChatMessage key={i} message={msg} />
            ))}
            {isSending && (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Loader2 className="h-4 w-4 animate-spin" />
                <span>Thinking...</span>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input */}
      <div className="flex gap-2 border-t pt-3">
        <Input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask your AI assistant..."
          disabled={isSending}
          className="flex-1"
        />
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

      {/* Clear confirmation dialog */}
      <Dialog open={clearDialogOpen} onOpenChange={setClearDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Clear conversation</DialogTitle>
            <DialogDescription>
              Are you sure you want to clear all messages? This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setClearDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={() => {
                clearMessages();
                setClearDialogOpen(false);
              }}
            >
              Clear all messages
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

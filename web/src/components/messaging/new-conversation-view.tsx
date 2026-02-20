"use client";

import { useState } from "react";
import { MessageSquare, Loader2 } from "lucide-react";
import { useStartConversation } from "@/hooks/use-messaging";
import { ChatInput } from "./chat-input";

interface NewConversationViewProps {
  traineeId: number;
  onConversationCreated: (conversationId: number) => void;
}

export function NewConversationView({
  traineeId,
  onConversationCreated,
}: NewConversationViewProps) {
  const startConversation = useStartConversation();
  const [error, setError] = useState<string | null>(null);

  const handleSend = (content: string, image?: File) => {
    setError(null);
    startConversation.mutate(
      { trainee_id: traineeId, content, image },
      {
        onSuccess: (data) => {
          onConversationCreated(data.conversation_id);
        },
        onError: () => {
          setError("Failed to send message. The trainee may not be assigned to you.");
        },
      },
    );
  };

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-3 border-b px-4 py-3">
        <h2 className="text-sm font-semibold">New Message</h2>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center px-4 text-center">
        <div className="mb-4 rounded-full bg-muted p-4">
          <MessageSquare
            className="h-8 w-8 text-muted-foreground"
            aria-hidden="true"
          />
        </div>
        <p className="mb-2 max-w-sm text-sm text-muted-foreground">
          Send your first message to start the conversation.
        </p>
        {error && (
          <p className="mb-2 text-sm text-destructive" role="alert">
            {error}
          </p>
        )}
        {startConversation.isPending && (
          <div className="mb-4 flex items-center gap-2 text-sm text-muted-foreground" role="status">
            <Loader2 className="h-4 w-4 animate-spin" />
            Sending...
          </div>
        )}
      </div>

      <ChatInput
        onSend={handleSend}
        isSending={startConversation.isPending}
        placeholder="Type your first message..."
      />
    </div>
  );
}

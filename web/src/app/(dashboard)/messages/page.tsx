"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import { MessageSquare } from "lucide-react";
import { useConversations } from "@/hooks/use-messaging";
import { PageHeader } from "@/components/shared/page-header";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { ConversationList } from "@/components/messaging/conversation-list";
import { ChatView } from "@/components/messaging/chat-view";
import type { Conversation } from "@/types/messaging";

export default function MessagesPage() {
  const searchParams = useSearchParams();
  const conversationIdParam = searchParams.get("conversation");

  const {
    data: conversations,
    isLoading,
    isError,
    refetch,
  } = useConversations();
  const [selectedConversation, setSelectedConversation] =
    useState<Conversation | null>(null);

  // Auto-select conversation from URL param or first in list
  useEffect(() => {
    if (!conversations || conversations.length === 0) {
      setSelectedConversation(null);
      return;
    }

    if (conversationIdParam) {
      const targetId = parseInt(conversationIdParam, 10);
      const found = conversations.find((c) => c.id === targetId);
      if (found) {
        setSelectedConversation(found);
        return;
      }
    }

    // If nothing selected yet, select the first conversation
    if (!selectedConversation) {
      setSelectedConversation(conversations[0]);
    } else {
      // Update selected conversation data if it exists in refreshed list
      const updated = conversations.find(
        (c) => c.id === selectedConversation.id,
      );
      if (updated) {
        setSelectedConversation(updated);
      } else {
        setSelectedConversation(conversations[0]);
      }
    }
  }, [conversations, conversationIdParam]); // eslint-disable-line react-hooks/exhaustive-deps

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Messages"
          description="Direct messages with your trainees"
        />
        <LoadingSpinner label="Loading conversations..." />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Messages"
          description="Direct messages with your trainees"
        />
        <ErrorState
          message="Failed to load conversations. Please try again."
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] flex-col gap-4">
      <PageHeader
        title="Messages"
        description="Direct messages with your trainees"
      />

      <div className="flex flex-1 overflow-hidden rounded-lg border bg-card">
        {/* Conversation list sidebar */}
        <div className="w-80 shrink-0 overflow-y-auto border-r">
          <ConversationList
            conversations={conversations ?? []}
            selectedId={selectedConversation?.id ?? null}
            onSelect={setSelectedConversation}
          />
        </div>

        {/* Chat area */}
        <div className="flex-1">
          {selectedConversation ? (
            <ChatView conversation={selectedConversation} />
          ) : (
            <div className="flex h-full flex-col items-center justify-center text-center">
              <div className="mb-4 rounded-full bg-muted p-4">
                <MessageSquare
                  className="h-8 w-8 text-muted-foreground"
                  aria-hidden="true"
                />
              </div>
              <h3 className="mb-1 text-lg font-semibold">
                Select a conversation
              </h3>
              <p className="max-w-sm text-sm text-muted-foreground">
                Choose a conversation from the left to start messaging, or
                open a trainee&apos;s profile to start a new conversation.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

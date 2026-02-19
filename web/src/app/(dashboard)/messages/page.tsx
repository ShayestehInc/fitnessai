"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, MessageSquare } from "lucide-react";
import { useConversations } from "@/hooks/use-messaging";
import { PageHeader } from "@/components/shared/page-header";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { ConversationList } from "@/components/messaging/conversation-list";
import { ChatView } from "@/components/messaging/chat-view";
import { Button } from "@/components/ui/button";
import type { Conversation } from "@/types/messaging";

export default function MessagesPage() {
  const searchParams = useSearchParams();
  const conversationIdParam = searchParams.get("conversation");
  const traineeIdParam = searchParams.get("trainee");

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

    // Select by conversation ID
    if (conversationIdParam) {
      const targetId = parseInt(conversationIdParam, 10);
      const found = conversations.find((c) => c.id === targetId);
      if (found) {
        setSelectedConversation(found);
        return;
      }
    }

    // Select by trainee ID (from trainee detail "Message" button)
    if (traineeIdParam) {
      const targetTraineeId = parseInt(traineeIdParam, 10);
      const found = conversations.find(
        (c) => c.trainee.id === targetTraineeId,
      );
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
  }, [conversations, conversationIdParam, traineeIdParam]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleSelectConversation = (conversation: Conversation) => {
    setSelectedConversation(conversation);
  };

  const handleBackToList = () => {
    setSelectedConversation(null);
  };

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
    <div className="flex min-h-0 flex-1 flex-col gap-4">
      <PageHeader
        title="Messages"
        description="Direct messages with your trainees"
      />

      <div className="flex flex-1 overflow-hidden rounded-lg border bg-card">
        {/* Conversation list sidebar — hidden on small screens when a conversation is selected */}
        <div
          className={`w-full shrink-0 overflow-y-auto border-r md:w-80 ${
            selectedConversation ? "hidden md:block" : "block"
          }`}
        >
          <ConversationList
            conversations={conversations ?? []}
            selectedId={selectedConversation?.id ?? null}
            onSelect={handleSelectConversation}
          />
        </div>

        {/* Chat area — hidden on small screens when no conversation is selected */}
        <div
          className={`min-w-0 flex-1 ${
            selectedConversation ? "block" : "hidden md:block"
          }`}
        >
          {selectedConversation ? (
            <div className="flex h-full flex-col">
              {/* Back button visible only on small screens */}
              <div className="flex items-center border-b px-2 py-1.5 md:hidden">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleBackToList}
                  aria-label="Back to conversations"
                >
                  <ArrowLeft className="mr-1 h-4 w-4" />
                  Back
                </Button>
              </div>
              <ChatView conversation={selectedConversation} />
            </div>
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

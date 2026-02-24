"use client";

import { Suspense, useState, useEffect, useMemo, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowLeft, MessageSquare, Search } from "lucide-react";
import { useConversations } from "@/hooks/use-messaging";
import { PageHeader } from "@/components/shared/page-header";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { ConversationList } from "@/components/messaging/conversation-list";
import { ChatView } from "@/components/messaging/chat-view";
import { NewConversationView } from "@/components/messaging/new-conversation-view";
import { MessageSearch } from "@/components/messaging/message-search";
import { Button } from "@/components/ui/button";
import type { Conversation } from "@/types/messaging";
import type { SearchMessageResult } from "@/types/messaging";

function MessagesContent() {
  const router = useRouter();
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
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [highlightMessageId, setHighlightMessageId] = useState<number | null>(
    null,
  );

  // Determine if we need to show the new-conversation view:
  // trainee param is present but no matching conversation exists yet.
  const showNewConversation = useMemo(() => {
    if (!traineeIdParam || !conversations) return false;
    const targetTraineeId = parseInt(traineeIdParam, 10);
    if (isNaN(targetTraineeId)) return false;
    return !conversations.some((c) => c.trainee.id === targetTraineeId);
  }, [traineeIdParam, conversations]);

  const parsedTraineeId = traineeIdParam ? parseInt(traineeIdParam, 10) : 0;
  const newConversationTraineeId = isNaN(parsedTraineeId) ? 0 : parsedTraineeId;

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
      // If we're showing new conversation view, don't auto-select anything
      if (showNewConversation) return;
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
  }, [conversations, conversationIdParam, traineeIdParam, showNewConversation]); // eslint-disable-line react-hooks/exhaustive-deps

  // Cmd/Ctrl+K keyboard shortcut for search
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setIsSearchOpen((prev) => !prev);
      }
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleSelectConversation = (conversation: Conversation) => {
    setSelectedConversation(conversation);
    setHighlightMessageId(null);
    setIsSearchOpen(false);
  };

  const handleBackToList = () => {
    setSelectedConversation(null);
  };

  const handleNewConversationCreated = (conversationId: number) => {
    // Refetch conversations so the new one appears, then navigate to it
    refetch().then(() => {
      router.replace(`/messages?conversation=${conversationId}`);
    });
  };

  const handleSearchResultClick = useCallback(
    (result: SearchMessageResult) => {
      setIsSearchOpen(false);
      setHighlightMessageId(result.message_id);

      // Find the conversation in the already-loaded list
      if (conversations) {
        const found = conversations.find(
          (c) => c.id === result.conversation_id,
        );
        if (found) {
          setSelectedConversation(found);
          router.replace(`/messages?conversation=${result.conversation_id}`);
          return;
        }
      }

      // Conversation not in the current list (e.g. paginated beyond page 1).
      // Refetch to ensure it appears, then navigate via URL param which
      // the useEffect will pick up.
      router.replace(`/messages?conversation=${result.conversation_id}`);
      refetch();
    },
    [conversations, router, refetch],
  );

  const handleCloseSearch = useCallback(() => {
    setIsSearchOpen(false);
  }, []);

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

  // Decide what to show in the chat area
  const showNewConvView = showNewConversation && !selectedConversation;

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-4">
      <div className="flex items-center justify-between">
        <PageHeader
          title="Messages"
          description="Direct messages with your trainees"
        />
        <Button
          variant="outline"
          size="sm"
          onClick={() => setIsSearchOpen(true)}
          className="gap-2"
          aria-label="Search messages"
        >
          <Search className="h-4 w-4" />
          <span className="hidden sm:inline">Search</span>
          <kbd className="pointer-events-none hidden h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium text-muted-foreground sm:inline-flex">
            {typeof navigator !== "undefined" &&
            /mac/i.test(navigator.userAgent)
              ? "\u2318"
              : "Ctrl"}
            K
          </kbd>
        </Button>
      </div>

      <div className="flex h-[calc(100dvh-12rem)] overflow-hidden rounded-lg border bg-card">
        {/* Sidebar: either search results or conversation list */}
        <div
          className={`w-full shrink-0 overflow-y-auto border-r md:w-80 ${
            selectedConversation || showNewConvView ? "hidden md:block" : "block"
          }`}
        >
          {isSearchOpen ? (
            <MessageSearch
              onResultClick={handleSearchResultClick}
              onClose={handleCloseSearch}
            />
          ) : (
            <ConversationList
              conversations={conversations ?? []}
              selectedId={selectedConversation?.id ?? null}
              onSelect={handleSelectConversation}
            />
          )}
        </div>

        {/* Chat area -- hidden on small screens when no conversation is selected */}
        <div
          className={`min-w-0 flex-1 ${
            selectedConversation || showNewConvView ? "block" : "hidden md:block"
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
              <ChatView
                conversation={selectedConversation}
                highlightMessageId={highlightMessageId}
                onHighlightShown={() => setHighlightMessageId(null)}
              />
            </div>
          ) : showNewConvView ? (
            <div className="flex h-full flex-col">
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
              <NewConversationView
                traineeId={newConversationTraineeId}
                onConversationCreated={handleNewConversationCreated}
              />
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

export default function MessagesPage() {
  return (
    <Suspense
      fallback={
        <div className="space-y-6">
          <PageHeader
            title="Messages"
            description="Direct messages with your trainees"
          />
          <LoadingSpinner label="Loading messages..." />
        </div>
      }
    >
      <MessagesContent />
    </Suspense>
  );
}

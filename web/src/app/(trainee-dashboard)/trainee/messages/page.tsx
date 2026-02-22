"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowLeft, MessageSquare, Search } from "lucide-react";
import { useConversations } from "@/hooks/use-messaging";
import { PageHeader } from "@/components/shared/page-header";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { ConversationList } from "@/components/messaging/conversation-list";
import { ChatView } from "@/components/messaging/chat-view";
import { MessageSearch } from "@/components/messaging/message-search";
import { Button } from "@/components/ui/button";
import type { Conversation, SearchMessageResult } from "@/types/messaging";

export default function TraineeMessagesPage() {
  const router = useRouter();
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
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [highlightMessageId, setHighlightMessageId] = useState<number | null>(
    null,
  );

  // Auto-select conversation (trainee typically has only one)
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

    // Auto-select first (and usually only) conversation
    if (!selectedConversation) {
      setSelectedConversation(conversations[0]);
    } else {
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

  const handleSearchResultClick = useCallback(
    (result: SearchMessageResult) => {
      setIsSearchOpen(false);
      setHighlightMessageId(result.message_id);

      if (conversations) {
        const found = conversations.find(
          (c) => c.id === result.conversation_id,
        );
        if (found) {
          setSelectedConversation(found);
          router.replace(`/trainee/messages?conversation=${result.conversation_id}`);
          return;
        }
      }

      router.replace(`/trainee/messages?conversation=${result.conversation_id}`);
      refetch();
    },
    [conversations, router, refetch],
  );

  const handleCloseSearch = useCallback(() => {
    setIsSearchOpen(false);
  }, []);

  // Memoize hasConversations to avoid recalculation
  const hasConversations = useMemo(
    () => (conversations?.length ?? 0) > 0,
    [conversations],
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Messages"
          description="Chat with your trainer"
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
          description="Chat with your trainer"
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
      <div className="flex items-center justify-between">
        <PageHeader
          title="Messages"
          description="Chat with your trainer"
        />
        {hasConversations && (
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
        )}
      </div>

      <div className="flex flex-1 overflow-hidden rounded-lg border bg-card">
        {/* Sidebar: conversation list or search */}
        <div
          className={`w-full shrink-0 overflow-y-auto border-r md:w-80 ${
            selectedConversation ? "hidden md:block" : "block"
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

        {/* Chat area */}
        <div
          className={`min-w-0 flex-1 ${
            selectedConversation ? "block" : "hidden md:block"
          }`}
        >
          {selectedConversation ? (
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
              <ChatView
                conversation={selectedConversation}
                highlightMessageId={highlightMessageId}
                onHighlightShown={() => setHighlightMessageId(null)}
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
                {hasConversations
                  ? "Select a conversation"
                  : "No messages yet"}
              </h3>
              <p className="max-w-sm text-sm text-muted-foreground">
                {hasConversations
                  ? "Choose a conversation from the left to start messaging."
                  : "Your trainer will start a conversation with you."}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

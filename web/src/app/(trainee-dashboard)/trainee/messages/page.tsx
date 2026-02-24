"use client";

import { Suspense, useState, useEffect, useMemo, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowLeft, MessageSquare, Search } from "lucide-react";
import { useConversations } from "@/hooks/use-messaging";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { ConversationList } from "@/components/messaging/conversation-list";
import { ChatView } from "@/components/messaging/chat-view";
import { MessageSearch } from "@/components/messaging/message-search";
import { Button } from "@/components/ui/button";
import type { Conversation, SearchMessageResult } from "@/types/messaging";

function TraineeMessagesContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const conversationIdParam = searchParams.get("conversation");

  const {
    data: conversations,
    isLoading,
    isError,
    refetch,
  } = useConversations();

  // Store the selected conversation ID rather than the object itself.
  // "auto" means "auto-select the best default".
  const [selectedId, setSelectedId] = useState<number | "auto">("auto");
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [highlightMessageId, setHighlightMessageId] = useState<number | null>(
    null,
  );

  // Derive the selected conversation from conversations + selectedId.
  // This avoids calling setState inside an effect to sync with conversation data.
  const selectedConversation: Conversation | null = useMemo(() => {
    if (!conversations || conversations.length === 0) return null;

    // If a specific conversation ID is selected, find it
    if (selectedId !== "auto") {
      const found = conversations.find((c) => c.id === selectedId);
      if (found) return found;
      // Fallback: the selected ID no longer exists, auto-select
    }

    // If URL param specifies a conversation, use that
    if (conversationIdParam) {
      const targetId = parseInt(conversationIdParam, 10);
      const found = conversations.find((c) => c.id === targetId);
      if (found) return found;
    }

    // Auto-select first (trainee typically has only one)
    return conversations[0] ?? null;
  }, [conversations, selectedId, conversationIdParam]);

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

  const handleSelectConversation = useCallback((conversation: Conversation) => {
    setSelectedId(conversation.id);
    setHighlightMessageId(null);
    setIsSearchOpen(false);
  }, []);

  const handleBackToList = useCallback(() => {
    setSelectedId("auto");
  }, []);

  const handleSearchResultClick = useCallback(
    (result: SearchMessageResult) => {
      setIsSearchOpen(false);
      setHighlightMessageId(result.message_id);
      setSelectedId(result.conversation_id);
      router.replace(`/trainee/messages?conversation=${result.conversation_id}`);

      // If the conversation isn't loaded yet, refetch
      if (!conversations?.find((c) => c.id === result.conversation_id)) {
        refetch();
      }
    },
    [conversations, router, refetch],
  );

  const handleCloseSearch = useCallback(() => {
    setIsSearchOpen(false);
  }, []);

  const hasConversations = useMemo(
    () => (conversations?.length ?? 0) > 0,
    [conversations],
  );

  const isMac = useMemo(
    () =>
      typeof navigator !== "undefined" && /mac/i.test(navigator.userAgent),
    [],
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
    <PageTransition>
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
                {isMac ? "\u2318" : "Ctrl"}K
              </kbd>
            </Button>
          )}
        </div>

        <div className="flex flex-1 overflow-hidden rounded-lg border bg-card" style={{ maxHeight: "calc(100dvh - 10rem)" }}>
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
    </PageTransition>
  );
}

export default function TraineeMessagesPage() {
  return (
    <Suspense
      fallback={
        <div className="space-y-6">
          <PageHeader
            title="Messages"
            description="Chat with your trainer"
          />
          <LoadingSpinner label="Loading messages..." />
        </div>
      }
    >
      <TraineeMessagesContent />
    </Suspense>
  );
}

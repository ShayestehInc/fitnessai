"use client";

import { useState, useCallback, useEffect } from "react";
import { ArrowLeft, AlertTriangle, BrainCircuit } from "lucide-react";
import { toast } from "sonner";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { Button } from "@/components/ui/button";
import { ChatSkeleton } from "@/components/ai-chat/chat-skeleton";
import { AiThreadSidebar } from "@/components/ai-chat/ai-thread-sidebar";
import { AiChatArea } from "@/components/ai-chat/ai-chat-area";
import {
  useAiThreads,
  useAiThread,
  useCreateAiThread,
  useSendAiMessage,
  useRenameAiThread,
  useDeleteAiThread,
  useAiProviders,
} from "@/hooks/use-ai-chat";
import type { AiChatThread } from "@/types/ai-chat";

export default function AiChatPage() {
  const [selectedThreadId, setSelectedThreadId] = useState<number | null>(null);
  const [sendError, setSendError] = useState<string | null>(null);

  const providers = useAiProviders();
  const threads = useAiThreads();
  const threadDetail = useAiThread(selectedThreadId);
  const createThread = useCreateAiThread();
  const sendMessage = useSendAiMessage(selectedThreadId);
  const renameThread = useRenameAiThread();
  const deleteThread = useDeleteAiThread();

  const isConfigured = providers.data?.providers?.some((p) => p.configured);

  // Auto-select first thread when threads load and nothing is selected
  useEffect(() => {
    if (selectedThreadId === null && threads.data && threads.data.length > 0) {
      setSelectedThreadId(threads.data[0].id);
    }
  }, [threads.data, selectedThreadId]);

  const handleSelectThread = useCallback((thread: AiChatThread) => {
    setSelectedThreadId(thread.id);
    setSendError(null);
  }, []);

  const handleNewThread = useCallback(() => {
    createThread.mutate(
      {},
      {
        onSuccess: (data) => {
          setSelectedThreadId(data.id);
          setSendError(null);
        },
        onError: () => {
          toast.error("Failed to create thread");
        },
      },
    );
  }, [createThread]);

  const handleSend = useCallback(
    (content: string, traineeId?: number) => {
      if (!selectedThreadId) return;
      setSendError(null);

      sendMessage.mutate(
        { message: content, trainee_id: traineeId },
        {
          onError: (err) => {
            setSendError(err.message || "Failed to send message");
          },
        },
      );
    },
    [selectedThreadId, sendMessage],
  );

  const handleRename = useCallback(
    (threadId: number, title: string) => {
      renameThread.mutate(
        { threadId, title },
        {
          onError: () => {
            toast.error("Failed to rename thread");
          },
        },
      );
    },
    [renameThread],
  );

  const handleDelete = useCallback(
    (threadId: number) => {
      deleteThread.mutate(threadId, {
        onSuccess: () => {
          if (selectedThreadId === threadId) {
            setSelectedThreadId(null);
          }
        },
        onError: () => {
          toast.error("Failed to delete thread");
        },
      });
    },
    [deleteThread, selectedThreadId],
  );

  const handleBackToList = useCallback(() => {
    setSelectedThreadId(null);
  }, []);

  const handleDismissError = useCallback(() => {
    setSendError(null);
  }, []);

  if (providers.isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title="AI Chat"
            description="Your AI assistant for trainee insights and management"
          />
          <ChatSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (providers.data && !isConfigured) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader
            title="AI Chat"
            description="Your AI assistant for trainee insights and management"
          />
          <div className="flex h-[calc(100vh-12rem)] flex-col items-center justify-center gap-4">
            <div className="rounded-full bg-amber-100 p-4 dark:bg-amber-900/20">
              <AlertTriangle className="h-8 w-8 text-amber-500" />
            </div>
            <p className="text-lg font-semibold">AI is not configured</p>
            <p className="text-sm text-muted-foreground">
              Contact your admin to set up AI providers.
            </p>
          </div>
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="flex min-h-0 flex-1 flex-col gap-4">
        <PageHeader
          title="AI Chat"
          description="Your AI assistant for trainee insights and management"
        />

        <div className="flex h-[calc(100vh-12rem)] overflow-hidden rounded-lg border bg-card">
          {/* Sidebar */}
          <div
            className={`w-full shrink-0 overflow-y-auto border-r md:w-80 ${
              selectedThreadId !== null ? "hidden md:block" : "block"
            }`}
          >
            <AiThreadSidebar
              threads={threads.data ?? []}
              selectedId={selectedThreadId}
              isLoading={threads.isLoading}
              onSelect={handleSelectThread}
              onNewThread={handleNewThread}
              onRename={handleRename}
              onDelete={handleDelete}
              isCreating={createThread.isPending}
            />
          </div>

          {/* Chat area */}
          <div
            className={`min-w-0 flex-1 ${
              selectedThreadId !== null ? "block" : "hidden md:block"
            }`}
          >
            {selectedThreadId !== null && (
              <div className="flex items-center border-b px-2 py-1.5 md:hidden">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleBackToList}
                  aria-label="Back to threads"
                >
                  <ArrowLeft className="mr-1 h-4 w-4" />
                  Back
                </Button>
              </div>
            )}
            <AiChatArea
              thread={threadDetail.data}
              isLoadingThread={threadDetail.isLoading}
              isSending={sendMessage.isPending}
              sendError={sendError}
              onSend={handleSend}
              onDismissError={handleDismissError}
            />
          </div>
        </div>
      </div>
    </PageTransition>
  );
}

"use client";

import { useCallback, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { ChatMessage, AiChatResponse, AiProvider } from "@/types/ai-chat";

export function useAiChat() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sendMessage = useCallback(
    async (content: string, traineeId?: number) => {
      if (!content.trim() || isSending) return;

      setError(null);
      setIsSending(true);

      const userMessage: ChatMessage = {
        role: "user",
        content: content.trim(),
        timestamp: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, userMessage]);

      try {
        const response = await apiClient.post<AiChatResponse>(
          API_URLS.AI_CHAT,
          {
            message: content.trim(),
            ...(traineeId ? { trainee_id: traineeId } : {}),
          },
        );

        const assistantMessage: ChatMessage = {
          role: "assistant",
          content: response.response,
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, assistantMessage]);
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Failed to send message";
        setError(message);
        // Remove the user message on error so they can retry
        setMessages((prev) => prev.slice(0, -1));
      } finally {
        setIsSending(false);
      }
    },
    [isSending],
  );

  const clearMessages = useCallback(() => {
    setMessages([]);
    setError(null);
  }, []);

  const dismissError = useCallback(() => {
    setError(null);
  }, []);

  return { messages, isSending, error, sendMessage, clearMessages, dismissError };
}

export function useAiProviders() {
  return useQuery<AiProvider[]>({
    queryKey: ["ai-providers"],
    queryFn: () => apiClient.get<AiProvider[]>(API_URLS.AI_PROVIDERS),
    staleTime: 10 * 60 * 1000,
  });
}

"use client";

import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ChatContainer } from "@/components/ai-chat/chat-container";

export default function AiChatPage() {
  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="AI Chat"
          description="Your AI assistant for trainee insights and management"
        />
        <ChatContainer />
      </div>
    </PageTransition>
  );
}

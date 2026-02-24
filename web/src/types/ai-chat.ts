export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
  timestamp: string;
}

export interface AiChatRequest {
  message: string;
  trainee_id?: number;
}

export interface AiChatResponse {
  response: string;
}

export interface AiProvider {
  provider: string;
  model: string;
  configured: boolean;
}

export interface AiProvidersResponse {
  providers: AiProvider[];
  current: {
    provider: string;
    model: string;
  };
}

// --- Persistent thread types ---

export interface AiChatThreadMessage {
  id: number;
  role: "user" | "assistant";
  content: string;
  provider: string;
  model_name: string;
  created_at: string;
}

export interface AiChatThread {
  id: number;
  title: string;
  trainee_context_id: number | null;
  trainee_context_name: string | null;
  last_message_at: string | null;
  message_count: number;
  created_at: string;
}

export interface AiChatThreadDetail {
  id: number;
  title: string;
  trainee_context_id: number | null;
  trainee_context_name: string | null;
  last_message_at: string | null;
  created_at: string;
  messages: AiChatThreadMessage[];
}

export interface SendAiMessageResponse {
  user_message: AiChatThreadMessage;
  assistant_message: AiChatThreadMessage;
  thread_title: string;
  suggested_followup: string;
}

export interface CreateThreadRequest {
  title?: string;
  trainee_context_id?: number | null;
}

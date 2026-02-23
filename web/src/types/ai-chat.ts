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

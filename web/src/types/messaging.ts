export interface MessageSender {
  id: number;
  first_name: string;
  last_name: string;
  profile_image: string | null;
}

export interface ConversationParticipant {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  profile_image: string | null;
}

export interface Conversation {
  id: number;
  trainer: ConversationParticipant;
  trainee: ConversationParticipant;
  last_message_at: string | null;
  last_message_preview: string | null;
  unread_count: number;
  is_archived: boolean;
  created_at: string;
}

export interface Message {
  id: number;
  conversation_id: number;
  sender: MessageSender;
  content: string;
  is_read: boolean;
  read_at: string | null;
  created_at: string;
}

export interface MessagesResponse {
  count: number;
  next: string | null;
  previous: string | null;
  results: Message[];
}

export interface StartConversationResponse {
  conversation_id: number;
  message: Message;
}

export interface UnreadMessageCount {
  unread_count: number;
}

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
  image: string | null;
  is_read: boolean;
  read_at: string | null;
  edited_at: string | null;
  is_deleted: boolean;
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
  is_new_conversation: boolean;
}

export interface ConversationsResponse {
  count: number;
  next: string | null;
  previous: string | null;
  results: Conversation[];
}

export interface UnreadMessageCount {
  unread_count: number;
}

export interface SearchMessageResult {
  message_id: number;
  conversation_id: number;
  sender_id: number;
  sender_first_name: string;
  sender_last_name: string;
  content: string;
  image_url: string | null;
  created_at: string;
  other_participant_id: number;
  other_participant_first_name: string;
  other_participant_last_name: string;
}

export interface SearchMessagesResponse {
  count: number;
  num_pages: number;
  page: number;
  has_next: boolean;
  has_previous: boolean;
  results: SearchMessageResult[];
}

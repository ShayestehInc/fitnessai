import {
  LayoutDashboard,
  Users,
  Dumbbell,
  Mail,
  MessageSquare,
  BarChart3,
  Bell,
  Settings,
  BrainCircuit,
  Megaphone,
  CreditCard,
  CalendarDays,
  Lightbulb,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface NavLink {
  label: string;
  href: string;
  icon: LucideIcon;
}

export const navLinks: NavLink[] = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Trainees", href: "/trainees", icon: Users },
  { label: "Messages", href: "/messages", icon: MessageSquare },
  { label: "Programs", href: "/programs", icon: Dumbbell },
  { label: "AI Chat", href: "/ai-chat", icon: BrainCircuit },
  { label: "Exercises", href: "/exercises", icon: Dumbbell },
  { label: "Invitations", href: "/invitations", icon: Mail },
  { label: "Analytics", href: "/analytics", icon: BarChart3 },
  { label: "Announcements", href: "/announcements", icon: Megaphone },
  { label: "Notifications", href: "/notifications", icon: Bell },
  { label: "Feature Requests", href: "/feature-requests", icon: Lightbulb },
  { label: "Subscription", href: "/subscription", icon: CreditCard },
  { label: "Calendar", href: "/calendar", icon: CalendarDays },
  { label: "Settings", href: "/settings", icon: Settings },
];

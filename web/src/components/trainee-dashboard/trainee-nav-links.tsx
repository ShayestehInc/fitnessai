import {
  LayoutDashboard,
  Dumbbell,
  History,
  TrendingUp,
  Apple,
  MessageSquare,
  Megaphone,
  Trophy,
  Settings,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface TraineeNavLink {
  label: string;
  href: string;
  icon: LucideIcon;
  badgeKey?: "messages" | "announcements";
}

export const traineeNavLinks: TraineeNavLink[] = [
  { label: "nav.dashboard", href: "/trainee/dashboard", icon: LayoutDashboard },
  { label: "nav.myProgram", href: "/trainee/program", icon: Dumbbell },
  { label: "nav.history", href: "/trainee/history", icon: History },
  { label: "nav.progress", href: "/trainee/progress", icon: TrendingUp },
  { label: "nav.nutrition", href: "/trainee/nutrition", icon: Apple },
  { label: "nav.messages", href: "/trainee/messages", icon: MessageSquare, badgeKey: "messages" },
  { label: "nav.announcements", href: "/trainee/announcements", icon: Megaphone, badgeKey: "announcements" },
  { label: "nav.achievements", href: "/trainee/achievements", icon: Trophy },
  { label: "nav.settings", href: "/trainee/settings", icon: Settings },
];

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
  { label: "Dashboard", href: "/trainee/dashboard", icon: LayoutDashboard },
  { label: "My Program", href: "/trainee/program", icon: Dumbbell },
  { label: "History", href: "/trainee/history", icon: History },
  { label: "Progress", href: "/trainee/progress", icon: TrendingUp },
  { label: "Nutrition", href: "/trainee/nutrition", icon: Apple },
  { label: "Messages", href: "/trainee/messages", icon: MessageSquare, badgeKey: "messages" },
  { label: "Announcements", href: "/trainee/announcements", icon: Megaphone, badgeKey: "announcements" },
  { label: "Achievements", href: "/trainee/achievements", icon: Trophy },
  { label: "Settings", href: "/trainee/settings", icon: Settings },
];

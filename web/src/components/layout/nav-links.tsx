import {
  LayoutDashboard,
  Users,
  Dumbbell,
  Library,
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

export interface NavGroup {
  label?: string;
  links: NavLink[];
}

export const navGroups: NavGroup[] = [
  {
    links: [
      { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
      { label: "Trainees", href: "/trainees", icon: Users },
      { label: "Messages", href: "/messages", icon: MessageSquare },
      { label: "Programs", href: "/programs", icon: Dumbbell },
    ],
  },
  {
    label: "Tools",
    links: [
      { label: "AI Chat", href: "/ai-chat", icon: BrainCircuit },
      { label: "Exercises", href: "/exercises", icon: Library },
      { label: "Analytics", href: "/analytics", icon: BarChart3 },
    ],
  },
  {
    label: "Communication",
    links: [
      { label: "Invitations", href: "/invitations", icon: Mail },
      { label: "Announcements", href: "/announcements", icon: Megaphone },
      { label: "Notifications", href: "/notifications", icon: Bell },
      { label: "Feature Requests", href: "/feature-requests", icon: Lightbulb },
    ],
  },
  {
    label: "Account",
    links: [
      { label: "Subscription", href: "/subscription", icon: CreditCard },
      { label: "Calendar", href: "/calendar", icon: CalendarDays },
      { label: "Settings", href: "/settings", icon: Settings },
    ],
  },
];

// Flat array for backward compatibility (admin-nav-links imports NavLink type)
export const navLinks: NavLink[] = navGroups.flatMap((g) => g.links);

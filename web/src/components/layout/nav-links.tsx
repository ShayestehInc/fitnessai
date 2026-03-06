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
      { label: "nav.dashboard", href: "/dashboard", icon: LayoutDashboard },
      { label: "nav.trainees", href: "/trainees", icon: Users },
      { label: "nav.messages", href: "/messages", icon: MessageSquare },
      { label: "nav.programs", href: "/programs", icon: Dumbbell },
    ],
  },
  {
    label: "nav.tools",
    links: [
      { label: "nav.aiChat", href: "/ai-chat", icon: BrainCircuit },
      { label: "nav.exercises", href: "/exercises", icon: Library },
      { label: "nav.analytics", href: "/analytics", icon: BarChart3 },
    ],
  },
  {
    label: "nav.communication",
    links: [
      { label: "nav.invitations", href: "/invitations", icon: Mail },
      { label: "nav.announcements", href: "/announcements", icon: Megaphone },
      { label: "nav.notifications", href: "/notifications", icon: Bell },
      { label: "nav.featureRequests", href: "/feature-requests", icon: Lightbulb },
    ],
  },
  {
    label: "nav.account",
    links: [
      { label: "nav.subscription", href: "/subscription", icon: CreditCard },
      { label: "nav.calendar", href: "/calendar", icon: CalendarDays },
      { label: "nav.settings", href: "/settings", icon: Settings },
    ],
  },
];

// Flat array for backward compatibility (admin-nav-links imports NavLink type)
export const navLinks: NavLink[] = navGroups.flatMap((g) => g.links);

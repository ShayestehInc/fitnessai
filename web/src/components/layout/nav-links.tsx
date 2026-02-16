import {
  LayoutDashboard,
  Users,
  Dumbbell,
  Mail,
  BarChart3,
  Bell,
  Settings,
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
  { label: "Programs", href: "/programs", icon: Dumbbell },
  { label: "Invitations", href: "/invitations", icon: Mail },
  { label: "Analytics", href: "/analytics", icon: BarChart3 },
  { label: "Notifications", href: "/notifications", icon: Bell },
  { label: "Settings", href: "/settings", icon: Settings },
];

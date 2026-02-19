import {
  LayoutDashboard,
  Users,
  CreditCard,
  Layers,
  Ticket,
  UserCog,
  Settings,
  Handshake,
  CalendarClock,
  AlertTriangle,
} from "lucide-react";
import type { NavLink } from "./nav-links";

export const adminNavLinks: NavLink[] = [
  { label: "Dashboard", href: "/admin/dashboard", icon: LayoutDashboard },
  { label: "Trainers", href: "/admin/trainers", icon: Users },
  { label: "Subscriptions", href: "/admin/subscriptions", icon: CreditCard },
  { label: "Tiers", href: "/admin/tiers", icon: Layers },
  { label: "Coupons", href: "/admin/coupons", icon: Ticket },
  { label: "Users", href: "/admin/users", icon: UserCog },
  { label: "Ambassadors", href: "/admin/ambassadors", icon: Handshake },
  { label: "Upcoming Payments", href: "/admin/upcoming-payments", icon: CalendarClock },
  { label: "Past Due", href: "/admin/past-due", icon: AlertTriangle },
  { label: "Settings", href: "/admin/settings", icon: Settings },
];

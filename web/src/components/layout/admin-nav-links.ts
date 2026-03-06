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
  { label: "nav.dashboard", href: "/admin/dashboard", icon: LayoutDashboard },
  { label: "admin.trainers", href: "/admin/trainers", icon: Users },
  { label: "admin.subscriptions", href: "/admin/subscriptions", icon: CreditCard },
  { label: "admin.tiers", href: "/admin/tiers", icon: Layers },
  { label: "admin.coupons", href: "/admin/coupons", icon: Ticket },
  { label: "admin.users", href: "/admin/users", icon: UserCog },
  { label: "admin.ambassadors", href: "/admin/ambassadors", icon: Handshake },
  { label: "admin.upcomingPayments", href: "/admin/upcoming-payments", icon: CalendarClock },
  { label: "admin.pastDue", href: "/admin/past-due", icon: AlertTriangle },
  { label: "nav.settings", href: "/admin/settings", icon: Settings },
];

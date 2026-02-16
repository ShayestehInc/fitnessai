import {
  LayoutDashboard,
  Users,
  CreditCard,
  Layers,
  Ticket,
  UserCog,
  Settings,
} from "lucide-react";
import type { NavLink } from "./nav-links";

export const adminNavLinks: NavLink[] = [
  { label: "Dashboard", href: "/admin/dashboard", icon: LayoutDashboard },
  { label: "Trainers", href: "/admin/trainers", icon: Users },
  { label: "Subscriptions", href: "/admin/subscriptions", icon: CreditCard },
  { label: "Tiers", href: "/admin/tiers", icon: Layers },
  { label: "Coupons", href: "/admin/coupons", icon: Ticket },
  { label: "Users", href: "/admin/users", icon: UserCog },
  { label: "Settings", href: "/admin/settings", icon: Settings },
];

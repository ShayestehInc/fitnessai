import {
  LayoutDashboard,
  Users,
  DollarSign,
  Settings,
  Shield,
  CreditCard,
  Layers,
  Ticket,
} from "lucide-react";
import type { NavLink } from "./nav-links";

export const ambassadorNavLinks: NavLink[] = [
  { label: "Dashboard", href: "/ambassador/dashboard", icon: LayoutDashboard },
  { label: "Referrals", href: "/ambassador/referrals", icon: Users },
  { label: "Payouts", href: "/ambassador/payouts", icon: DollarSign },
  { label: "Settings", href: "/ambassador/settings", icon: Settings },
];

export const ambassadorManageLinks: NavLink[] = [
  { label: "Manage", href: "/ambassador/manage", icon: Shield },
  { label: "My Trainers", href: "/ambassador/manage/trainers", icon: Users },
  { label: "Subscriptions", href: "/ambassador/manage/subscriptions", icon: CreditCard },
  { label: "Tiers", href: "/ambassador/manage/tiers", icon: Layers },
  { label: "Coupons", href: "/ambassador/manage/coupons", icon: Ticket },
];

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
  { label: "nav.dashboard", href: "/ambassador/dashboard", icon: LayoutDashboard },
  { label: "ambassador.referrals", href: "/ambassador/referrals", icon: Users },
  { label: "ambassador.payouts", href: "/ambassador/payouts", icon: DollarSign },
  { label: "nav.settings", href: "/ambassador/settings", icon: Settings },
];

export const ambassadorManageLinks: NavLink[] = [
  { label: "ambassador.manage", href: "/ambassador/manage", icon: Shield },
  { label: "ambassador.trainers", href: "/ambassador/manage/trainers", icon: Users },
  { label: "ambassador.subscriptions", href: "/ambassador/manage/subscriptions", icon: CreditCard },
  { label: "admin.tiers", href: "/ambassador/manage/tiers", icon: Layers },
  { label: "ambassador.coupons", href: "/ambassador/manage/coupons", icon: Ticket },
];

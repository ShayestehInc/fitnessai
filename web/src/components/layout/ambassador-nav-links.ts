import {
  LayoutDashboard,
  Users,
  DollarSign,
  Settings,
} from "lucide-react";
import type { NavLink } from "./nav-links";

export const ambassadorNavLinks: NavLink[] = [
  { label: "Dashboard", href: "/ambassador/dashboard", icon: LayoutDashboard },
  { label: "Referrals", href: "/ambassador/referrals", icon: Users },
  { label: "Payouts", href: "/ambassador/payouts", icon: DollarSign },
  { label: "Settings", href: "/ambassador/settings", icon: Settings },
];

import {
  LayoutDashboard,
  Users,
  DollarSign,
  Settings,
  type LucideIcon,
} from "lucide-react";

export interface NavLink {
  label: string;
  href: string;
  icon: LucideIcon;
}

export const ambassadorNavLinks: NavLink[] = [
  { label: "Dashboard", href: "/ambassador/dashboard", icon: LayoutDashboard },
  { label: "Referrals", href: "/ambassador/referrals", icon: Users },
  { label: "Payouts", href: "/ambassador/payouts", icon: DollarSign },
  { label: "Settings", href: "/ambassador/settings", icon: Settings },
];

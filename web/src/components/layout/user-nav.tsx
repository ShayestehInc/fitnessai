"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/use-auth";
import { UserRole } from "@/types/user";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { LogOut, Settings } from "lucide-react";

const ROLE_LABELS: Record<string, string> = {
  [UserRole.TRAINER]: "Trainer",
  [UserRole.ADMIN]: "Admin",
  [UserRole.AMBASSADOR]: "Ambassador",
  [UserRole.TRAINEE]: "Trainee",
};

export function UserNav() {
  const { user, logout } = useAuth();

  const initials = user
    ? `${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase() ||
      user.email.charAt(0).toUpperCase()
    : "?";

  const displayName = user
    ? `${user.first_name} ${user.last_name}`.trim() || user.email
    : "";

  const roleLabel = user ? ROLE_LABELS[user.role] ?? "" : "";

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          className="flex items-center gap-2.5 rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring lg:rounded-lg lg:border lg:border-border lg:px-3 lg:py-1.5 lg:hover:bg-accent"
          aria-label={`User menu for ${displayName}`}
        >
          <Avatar className="h-8 w-8">
            {user?.profile_image && (
              <AvatarImage src={user.profile_image} alt="Profile" />
            )}
            <AvatarFallback className="text-xs">{initials}</AvatarFallback>
          </Avatar>
          <div className="hidden text-left lg:block">
            <p className="max-w-[140px] truncate text-sm font-medium leading-tight">
              {displayName}
            </p>
            {roleLabel && (
              <p className="text-xs leading-tight text-muted-foreground">
                {roleLabel}
              </p>
            )}
          </div>
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel>
          <div className="flex flex-col space-y-1">
            <p className="truncate text-sm font-medium">{displayName}</p>
            <p className="truncate text-xs text-muted-foreground">{user?.email}</p>
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem asChild>
          <Link
            href={
              user?.role === UserRole.ADMIN
                ? "/admin/settings"
                : user?.role === UserRole.AMBASSADOR
                  ? "/ambassador/settings"
                  : user?.role === UserRole.TRAINEE
                    ? "/trainee/settings"
                    : "/settings"
            }
            className="cursor-pointer"
          >
            <Settings className="mr-2 h-4 w-4" />
            Settings
          </Link>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={logout} className="cursor-pointer">
          <LogOut className="mr-2 h-4 w-4" />
          Log out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

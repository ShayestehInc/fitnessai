"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/use-auth";
import { UserRole } from "@/types/user";
import { Sidebar } from "@/components/layout/sidebar";
import { SidebarMobile } from "@/components/layout/sidebar-mobile";
import { Header } from "@/components/layout/header";
import { Loader2 } from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { isLoading, isAuthenticated, user } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.replace("/login");
    }
  }, [isLoading, isAuthenticated, router]);

  // Redirect non-trainer users to their appropriate dashboard
  useEffect(() => {
    if (!isLoading && isAuthenticated && user?.role === UserRole.ADMIN) {
      router.replace("/admin/dashboard");
    } else if (!isLoading && isAuthenticated && user?.role === UserRole.AMBASSADOR) {
      router.replace("/ambassador/dashboard");
    } else if (!isLoading && isAuthenticated && user?.role === UserRole.TRAINEE) {
      router.replace("/trainee/dashboard");
    }
  }, [isLoading, isAuthenticated, user, router]);

  if (isLoading || !isAuthenticated) {
    return (
      <div className="flex min-h-screen items-center justify-center" role="status" aria-label="Loading dashboard">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-hidden="true" />
        <span className="sr-only">Loading dashboard...</span>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-primary-foreground focus:shadow-lg"
      >
        Skip to main content
      </a>
      <Sidebar />
      <SidebarMobile open={mobileOpen} onOpenChange={setMobileOpen} />
      <div className="flex flex-1 flex-col">
        <Header onMenuClick={() => setMobileOpen(true)} />
        <main className="flex-1 overflow-auto p-4 lg:p-6" id="main-content">{children}</main>
      </div>
    </div>
  );
}

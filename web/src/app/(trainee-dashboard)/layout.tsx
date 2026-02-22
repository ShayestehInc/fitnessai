"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/use-auth";
import { UserRole } from "@/types/user";
import { TraineeSidebar } from "@/components/trainee-dashboard/trainee-sidebar";
import { TraineeSidebarMobile } from "@/components/trainee-dashboard/trainee-sidebar-mobile";
import { TraineeHeader } from "@/components/trainee-dashboard/trainee-header";
import { Loader2 } from "lucide-react";

export default function TraineeDashboardLayout({
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

  // Redirect non-trainee users to their appropriate dashboard
  useEffect(() => {
    if (!isLoading && isAuthenticated && user) {
      if (user.role === UserRole.ADMIN) {
        router.replace("/admin/dashboard");
      } else if (user.role === UserRole.AMBASSADOR) {
        router.replace("/ambassador/dashboard");
      } else if (user.role === UserRole.TRAINER) {
        router.replace("/dashboard");
      }
    }
  }, [isLoading, isAuthenticated, user, router]);

  if (isLoading || !isAuthenticated) {
    return (
      <div
        className="flex min-h-screen items-center justify-center"
        role="status"
        aria-label="Loading dashboard"
      >
        <Loader2
          className="h-8 w-8 animate-spin text-muted-foreground"
          aria-hidden="true"
        />
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
      <TraineeSidebar />
      <TraineeSidebarMobile open={mobileOpen} onOpenChange={setMobileOpen} />
      <div className="flex flex-1 flex-col">
        <TraineeHeader onMenuClick={() => setMobileOpen(true)} />
        <main className="flex-1 overflow-auto p-4 lg:p-6" id="main-content">
          {children}
        </main>
      </div>
    </div>
  );
}

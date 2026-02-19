"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/use-auth";
import { UserRole } from "@/types/user";
import { AmbassadorSidebar } from "@/components/layout/ambassador-sidebar";
import { AmbassadorSidebarMobile } from "@/components/layout/ambassador-sidebar-mobile";
import { Header } from "@/components/layout/header";
import { Skeleton } from "@/components/ui/skeleton";

export default function AmbassadorDashboardLayout({
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

  // Redirect non-ambassador users to their appropriate dashboard
  useEffect(() => {
    if (!isLoading && isAuthenticated && user) {
      if (user.role === UserRole.ADMIN) {
        router.replace("/admin/dashboard");
      } else if (user.role === UserRole.TRAINER) {
        router.replace("/dashboard");
      } else if (user.role !== UserRole.AMBASSADOR) {
        router.replace("/login");
      }
    }
  }, [isLoading, isAuthenticated, user, router]);

  if (
    isLoading ||
    !isAuthenticated ||
    !user ||
    user.role !== UserRole.AMBASSADOR
  ) {
    return (
      <div className="flex min-h-screen" role="status" aria-label="Loading ambassador dashboard">
        {/* Sidebar skeleton */}
        <div className="hidden w-64 border-r bg-background p-4 lg:block">
          <Skeleton className="mb-6 h-8 w-32" />
          <div className="space-y-3">
            {[1, 2, 3, 4].map((i) => (
              <Skeleton key={i} className="h-8 w-full" />
            ))}
          </div>
        </div>
        {/* Main content skeleton */}
        <div className="flex flex-1 flex-col">
          <div className="h-14 border-b px-4">
            <Skeleton className="mt-3 h-8 w-48" />
          </div>
          <div className="flex-1 p-6">
            <Skeleton className="mb-4 h-8 w-64" />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {[1, 2, 3, 4].map((i) => (
                <Skeleton key={i} className="h-28 w-full" />
              ))}
            </div>
          </div>
        </div>
        <span className="sr-only">Loading ambassador dashboard...</span>
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
      <AmbassadorSidebar />
      <AmbassadorSidebarMobile
        open={mobileOpen}
        onOpenChange={setMobileOpen}
      />
      <div className="flex flex-1 flex-col">
        <Header onMenuClick={() => setMobileOpen(true)} />
        <main className="flex-1 overflow-auto p-4 lg:p-6" id="main-content">
          {children}
        </main>
      </div>
    </div>
  );
}

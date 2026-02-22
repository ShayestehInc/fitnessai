import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { SESSION_COOKIE, ROLE_COOKIE } from "@/lib/constants";

const PUBLIC_PATHS = ["/login"];

function getDashboardPath(role: string | undefined): string {
  if (role === "ADMIN") return "/admin/dashboard";
  if (role === "AMBASSADOR") return "/ambassador/dashboard";
  if (role === "TRAINEE") return "/trainee/dashboard";
  return "/dashboard";
}

function isAdminPath(pathname: string): boolean {
  return pathname.startsWith("/admin");
}

function isAmbassadorPath(pathname: string): boolean {
  return pathname.startsWith("/ambassador");
}

function isTraineeViewPath(pathname: string): boolean {
  return pathname.startsWith("/trainee-view");
}

function isTraineeDashboardPath(pathname: string): boolean {
  return pathname.startsWith("/trainee/") || pathname === "/trainee";
}

function isTrainerDashboardPath(pathname: string): boolean {
  return (
    !isAdminPath(pathname) &&
    !isAmbassadorPath(pathname) &&
    !isTraineeViewPath(pathname) &&
    !isTraineeDashboardPath(pathname) &&
    !PUBLIC_PATHS.includes(pathname) &&
    pathname !== "/"
  );
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasSession = request.cookies.get(SESSION_COOKIE)?.value === "1";
  const userRole = request.cookies.get(ROLE_COOKIE)?.value;

  // Authenticated users visiting login -> redirect to appropriate dashboard
  // AC-22: TRAINEE role users accessing /login are redirected to /trainee-view
  if (PUBLIC_PATHS.includes(pathname) && hasSession) {
    return NextResponse.redirect(
      new URL(getDashboardPath(userRole), request.url),
    );
  }

  // Unauthenticated users visiting protected routes -> redirect to login
  if (!PUBLIC_PATHS.includes(pathname) && !hasSession && pathname !== "/") {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // Non-admin users attempting to access admin routes -> redirect to their dashboard
  // NOTE: The role cookie is client-writable, so this is a convenience guard only.
  // True authorization is enforced server-side by the API (HTTP 403) and by the
  // layout component which verifies the role from the authenticated user object.
  if (isAdminPath(pathname) && hasSession && userRole !== "ADMIN") {
    return NextResponse.redirect(
      new URL(getDashboardPath(userRole), request.url),
    );
  }

  // Non-ambassador users attempting to access ambassador routes -> redirect to their dashboard
  if (isAmbassadorPath(pathname) && hasSession && userRole !== "AMBASSADOR") {
    return NextResponse.redirect(
      new URL(getDashboardPath(userRole), request.url),
    );
  }

  // Non-trainee users attempting to access trainee dashboard routes -> redirect to their dashboard
  if (isTraineeDashboardPath(pathname) && hasSession && userRole !== "TRAINEE") {
    return NextResponse.redirect(
      new URL(getDashboardPath(userRole), request.url),
    );
  }

  // TRAINEE role users trying to access trainer/admin/ambassador paths -> redirect to trainee dashboard
  if (
    isTrainerDashboardPath(pathname) &&
    hasSession &&
    userRole === "TRAINEE"
  ) {
    return NextResponse.redirect(new URL("/trainee/dashboard", request.url));
  }

  // Ambassador users attempting to access trainer dashboard routes -> redirect to ambassador dashboard
  if (
    isTrainerDashboardPath(pathname) &&
    hasSession &&
    userRole === "AMBASSADOR"
  ) {
    return NextResponse.redirect(
      new URL("/ambassador/dashboard", request.url),
    );
  }

  // Root path -> redirect based on session and role
  if (pathname === "/") {
    if (hasSession) {
      return NextResponse.redirect(
        new URL(getDashboardPath(userRole), request.url),
      );
    }
    return NextResponse.redirect(new URL("/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization)
     * - favicon.ico
     * - public assets
     */
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};

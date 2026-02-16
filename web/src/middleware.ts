import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { SESSION_COOKIE, ROLE_COOKIE } from "@/lib/constants";

const PUBLIC_PATHS = ["/login"];

function getDashboardPath(role: string | undefined): string {
  return role === "ADMIN" ? "/admin/dashboard" : "/dashboard";
}

function isAdminPath(pathname: string): boolean {
  return pathname.startsWith("/admin");
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasSession = request.cookies.get(SESSION_COOKIE)?.value === "1";
  const userRole = request.cookies.get(ROLE_COOKIE)?.value;

  // Authenticated users visiting login -> redirect to appropriate dashboard
  if (PUBLIC_PATHS.includes(pathname) && hasSession) {
    return NextResponse.redirect(
      new URL(getDashboardPath(userRole), request.url),
    );
  }

  // Unauthenticated users visiting protected routes -> redirect to login
  if (!PUBLIC_PATHS.includes(pathname) && !hasSession && pathname !== "/") {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // Non-admin users attempting to access admin routes -> redirect to trainer dashboard
  // NOTE: The role cookie is client-writable, so this is a convenience guard only.
  // True authorization is enforced server-side by the API (HTTP 403) and by the
  // admin layout component which verifies the role from the authenticated user object.
  if (isAdminPath(pathname) && hasSession && userRole !== "ADMIN") {
    return NextResponse.redirect(new URL("/dashboard", request.url));
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

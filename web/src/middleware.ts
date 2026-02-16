import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { SESSION_COOKIE } from "@/lib/constants";

const PUBLIC_PATHS = ["/login"];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasSession = request.cookies.get(SESSION_COOKIE)?.value === "1";

  // Authenticated users visiting login -> redirect to dashboard
  // (Role-aware redirect happens client-side in AuthProvider/layout)
  if (PUBLIC_PATHS.includes(pathname) && hasSession) {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }

  // Unauthenticated users visiting protected routes -> redirect to login
  if (!PUBLIC_PATHS.includes(pathname) && !hasSession && pathname !== "/") {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // Root path -> redirect based on session
  if (pathname === "/") {
    if (hasSession) {
      return NextResponse.redirect(new URL("/dashboard", request.url));
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

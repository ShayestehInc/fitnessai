"use client";

import {
  createContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";
import type { ReactNode } from "react";
import { User, UserRole } from "@/types/user";
import { API_URLS } from "@/lib/constants";
import {
  clearTokens,
  hasValidSession,
  isAccessTokenExpired,
  refreshAccessToken,
  setTokens,
  setRoleCookie,
} from "@/lib/token-manager";
import { apiClient } from "@/lib/api-client";

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<User>;
  logout: () => void;
  refreshUser: () => Promise<User>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchUser = useCallback(async (): Promise<User> => {
    try {
      const userData = await apiClient.get<User>(API_URLS.CURRENT_USER);
      if (
        userData.role !== UserRole.TRAINER &&
        userData.role !== UserRole.ADMIN &&
        userData.role !== UserRole.AMBASSADOR
      ) {
        clearTokens();
        setUser(null);
        throw new Error(
          "Only trainer, admin, and ambassador accounts can access this dashboard",
        );
      }
      setUser(userData);
      setRoleCookie(userData.role);
      return userData;
    } catch (error) {
      clearTokens();
      setUser(null);
      // Re-throw role errors so the login page can display them
      if (
        error instanceof Error &&
        error.message.includes("accounts can access")
      ) {
        throw error;
      }
      throw error;
    }
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function initAuth() {
      if (!hasValidSession()) {
        if (!cancelled) setIsLoading(false);
        return;
      }

      if (isAccessTokenExpired()) {
        const refreshed = await refreshAccessToken();
        if (!refreshed) {
          if (!cancelled) setIsLoading(false);
          return;
        }
      }

      await fetchUser();
      if (!cancelled) setIsLoading(false);
    }

    const authPromise = initAuth();
    const timeoutPromise = new Promise<void>((_, reject) =>
      setTimeout(() => reject(new Error("Auth timeout")), 10_000),
    );

    Promise.race([authPromise, timeoutPromise]).catch(() => {
      if (!cancelled) {
        clearTokens();
        setUser(null);
        setIsLoading(false);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [fetchUser]);

  const login = useCallback(
    async (email: string, password: string): Promise<User> => {
      const response = await fetch(API_URLS.LOGIN, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const body = await response.json().catch(() => null);
        const message =
          body?.detail ?? body?.non_field_errors?.[0] ?? "Login failed";
        throw new Error(message);
      }

      const data = await response.json();
      setTokens(data.access, data.refresh);
      return fetchUser();
    },
    [fetchUser],
  );

  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
    window.location.href = "/login";
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isLoading,
      isAuthenticated: user !== null,
      login,
      logout,
      refreshUser: fetchUser,
    }),
    [user, isLoading, login, logout, fetchUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

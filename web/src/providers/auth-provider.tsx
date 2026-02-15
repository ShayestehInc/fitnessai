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
} from "@/lib/token-manager";
import { apiClient } from "@/lib/api-client";

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchUser = useCallback(async () => {
    try {
      const userData = await apiClient.get<User>(API_URLS.CURRENT_USER);
      if (userData.role !== UserRole.TRAINER) {
        clearTokens();
        setUser(null);
        throw new Error("Only trainer accounts can access this dashboard");
      }
      setUser(userData);
    } catch {
      clearTokens();
      setUser(null);
    }
  }, []);

  useEffect(() => {
    async function initAuth() {
      if (!hasValidSession()) {
        setIsLoading(false);
        return;
      }

      if (isAccessTokenExpired()) {
        const refreshed = await refreshAccessToken();
        if (!refreshed) {
          setIsLoading(false);
          return;
        }
      }

      await fetchUser();
      setIsLoading(false);
    }

    initAuth();
  }, [fetchUser]);

  const login = useCallback(
    async (email: string, password: string) => {
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
      await fetchUser();
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
    }),
    [user, isLoading, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

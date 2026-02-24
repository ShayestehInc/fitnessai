"use client";

import { useState, useEffect, useCallback } from "react";

const STORAGE_KEY = "fitnessai_sidebar_collapsed";

function readInitialValue(): boolean {
  if (typeof window === "undefined") return false;
  try {
    return localStorage.getItem(STORAGE_KEY) === "true";
  } catch {
    return false;
  }
}

export function useSidebarCollapse(): {
  collapsed: boolean;
  toggleCollapsed: () => void;
} {
  const [collapsed, setCollapsed] = useState(readInitialValue);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, String(collapsed));
    } catch {
      // Storage unavailable — silently ignore
    }
  }, [collapsed]);

  const toggleCollapsed = useCallback(() => {
    setCollapsed((prev) => !prev);
  }, []);

  return { collapsed, toggleCollapsed };
}

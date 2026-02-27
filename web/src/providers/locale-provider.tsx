"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import enMessages from "@/messages/en.json";
import esMessages from "@/messages/es.json";
import ptBRMessages from "@/messages/pt-BR.json";

export type Locale = "en" | "es" | "pt-br";

type Messages = typeof enMessages;

const messagesMap: Record<Locale, Messages> = {
  en: enMessages,
  es: esMessages,
  "pt-br": ptBRMessages,
};

const LOCALE_COOKIE = "NEXT_LOCALE";

function getCookie(name: string): string | undefined {
  if (typeof document === "undefined") return undefined;
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match?.[1];
}

function setCookie(name: string, value: string, days: number = 365): void {
  if (typeof document === "undefined") return;
  const expires = new Date(Date.now() + days * 864e5).toUTCString();
  document.cookie = `${name}=${value};expires=${expires};path=/;SameSite=Lax`;
}

interface LocaleContextValue {
  locale: Locale;
  messages: Messages;
  setLocale: (locale: Locale) => void;
  t: (key: string) => string;
}

const LocaleContext = createContext<LocaleContextValue | null>(null);

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>("en");

  useEffect(() => {
    const saved = getCookie(LOCALE_COOKIE) as Locale | undefined;
    if (saved && saved in messagesMap) {
      setLocaleState(saved);
    }
  }, []);

  const setLocale = useCallback((newLocale: Locale) => {
    setLocaleState(newLocale);
    setCookie(LOCALE_COOKIE, newLocale);
    // Update html lang attribute
    if (typeof document !== "undefined") {
      document.documentElement.lang = newLocale === "pt-br" ? "pt-BR" : newLocale;
    }
  }, []);

  const messages = messagesMap[locale];

  const t = useCallback(
    (key: string): string => {
      const parts = key.split(".");
      let current: unknown = messages;
      for (const part of parts) {
        if (current && typeof current === "object" && part in current) {
          current = (current as Record<string, unknown>)[part];
        } else {
          return key; // Fallback to key if translation not found
        }
      }
      return typeof current === "string" ? current : key;
    },
    [messages],
  );

  return (
    <LocaleContext.Provider value={{ locale, messages, setLocale, t }}>
      {children}
    </LocaleContext.Provider>
  );
}

export function useLocale(): LocaleContextValue {
  const context = useContext(LocaleContext);
  if (!context) {
    throw new Error("useLocale must be used within a LocaleProvider");
  }
  return context;
}

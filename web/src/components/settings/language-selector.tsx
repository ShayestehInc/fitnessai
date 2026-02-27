"use client";

import { useCallback } from "react";
import { Globe } from "lucide-react";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { useLocale, type Locale } from "@/providers/locale-provider";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";

const languages = [
  { code: "en" as Locale, nativeName: "English", backendCode: "en" },
  { code: "es" as Locale, nativeName: "Español", backendCode: "es" },
  { code: "pt-br" as Locale, nativeName: "Português (Brasil)", backendCode: "pt-br" },
] as const;

export function LanguageSelector() {
  const { locale, setLocale, t } = useLocale();

  const handleSelect = useCallback(
    async (lang: (typeof languages)[number]) => {
      if (lang.code === locale) return;

      setLocale(lang.code);

      // Persist to backend
      try {
        await apiClient.patch(API_URLS.USER_PROFILES, {
          preferred_language: lang.backendCode,
        });
      } catch {
        // Locale is already saved locally via cookie
      }

      toast.success(t("language.changed"));
    },
    [locale, setLocale, t],
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t("settings.language")}</CardTitle>
        <CardDescription>{t("settings.languageDesc")}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex gap-3" role="radiogroup" aria-label="Language selection">
          {languages.map((lang) => {
            const isSelected = locale === lang.code;
            return (
              <button
                key={lang.code}
                role="radio"
                aria-checked={isSelected}
                tabIndex={isSelected ? 0 : -1}
                onClick={() => handleSelect(lang)}
                className={cn(
                  "flex flex-1 flex-col items-center gap-2 rounded-lg border-2 p-4 transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                  isSelected
                    ? "border-primary bg-accent"
                    : "border-transparent",
                )}
              >
                <Globe
                  className="h-5 w-5 text-muted-foreground"
                  aria-hidden="true"
                />
                <span className="text-sm font-medium">{lang.nativeName}</span>
              </button>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

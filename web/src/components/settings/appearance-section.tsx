"use client";

import { useTheme } from "next-themes";
import { Monitor, Moon, Sun } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { cn } from "@/lib/utils";

const themes = [
  { value: "light", label: "Light", icon: Sun },
  { value: "dark", label: "Dark", icon: Moon },
  { value: "system", label: "System", icon: Monitor },
] as const;

export function AppearanceSection() {
  const { theme, setTheme } = useTheme();

  return (
    <Card>
      <CardHeader>
        <CardTitle>Appearance</CardTitle>
        <CardDescription>
          Choose how the dashboard looks to you
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div
          className="flex gap-3"
          role="radiogroup"
          aria-label="Theme selection"
        >
          {themes.map(({ value, label, icon: Icon }) => (
            <button
              key={value}
              role="radio"
              aria-checked={theme === value}
              onClick={() => setTheme(value)}
              className={cn(
                "flex flex-1 flex-col items-center gap-2 rounded-lg border-2 p-4 transition-colors hover:bg-accent",
                theme === value
                  ? "border-primary bg-accent"
                  : "border-transparent",
              )}
            >
              <Icon
                className="h-5 w-5 text-muted-foreground"
                aria-hidden="true"
              />
              <span className="text-sm font-medium">{label}</span>
            </button>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

"use client";

import * as React from "react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetFooter,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";

const WIDTH_CLASSES = {
  sm: "sm:max-w-sm", // 384px
  md: "sm:max-w-md", // 480px (28rem → ~448, but md = 28rem)
  lg: "sm:max-w-lg", // 640px (32rem → 512, lg = 32rem)
  xl: "sm:max-w-xl", // 800px (36rem → 576, xl = 36rem)
} as const;

interface SlideOverPanelProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: string;
  width?: keyof typeof WIDTH_CLASSES;
  children: React.ReactNode;
  footer?: React.ReactNode;
}

export function SlideOverPanel({
  open,
  onOpenChange,
  title,
  description,
  width = "md",
  children,
  footer,
}: SlideOverPanelProps) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="right"
        className={cn(
          "flex h-full flex-col gap-0 p-0",
          WIDTH_CLASSES[width],
        )}
      >
        <SheetHeader className="border-b px-6 py-4">
          <SheetTitle>{title}</SheetTitle>
          {description && (
            <SheetDescription>{description}</SheetDescription>
          )}
        </SheetHeader>
        <div className="flex-1 overflow-y-auto px-6 py-4">{children}</div>
        {footer && (
          <SheetFooter className="border-t px-6 py-4">{footer}</SheetFooter>
        )}
      </SheetContent>
    </Sheet>
  );
}

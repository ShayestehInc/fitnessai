"use client";

import { useState } from "react";
import Image from "next/image";
import { Dumbbell } from "lucide-react";
import { cn } from "@/lib/utils";

interface BrandLogoProps {
  logoUrl: string | null;
  altText?: string;
  size?: string;
}

/**
 * Renders the trainer's branded logo, or falls back to the default
 * Dumbbell icon when the logo URL is missing or fails to load.
 */
export function BrandLogo({
  logoUrl,
  altText = "",
  size = "h-6 w-6",
}: BrandLogoProps) {
  const [imgError, setImgError] = useState(false);

  if (!logoUrl || imgError) {
    return (
      <Dumbbell
        className={cn(size, "shrink-0 text-sidebar-primary")}
        aria-hidden="true"
      />
    );
  }

  return (
    <Image
      src={logoUrl}
      alt={altText}
      width={24}
      height={24}
      className={cn(size, "shrink-0 rounded object-contain")}
      onError={() => setImgError(true)}
      unoptimized
    />
  );
}

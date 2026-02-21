"use client";

import { useState, useCallback } from "react";
import { Download, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  getAccessToken,
  isAccessTokenExpired,
  refreshAccessToken,
  clearTokens,
} from "@/lib/token-manager";

interface ExportButtonProps {
  url: string;
  filename: string;
  label?: string;
  "aria-label"?: string;
}

async function getValidToken(): Promise<string | null> {
  if (isAccessTokenExpired()) {
    const refreshed = await refreshAccessToken();
    if (!refreshed) {
      clearTokens();
      window.location.href = "/login";
      return null;
    }
  }
  return getAccessToken();
}

export function ExportButton({
  url,
  filename,
  label = "Export CSV",
  "aria-label": ariaLabel,
}: ExportButtonProps) {
  const [isDownloading, setIsDownloading] = useState(false);

  const handleDownload = useCallback(async () => {
    setIsDownloading(true);
    try {
      const token = await getValidToken();
      if (!token) return;

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.status === 401) {
        // Token expired between check and request — try one refresh
        const refreshed = await refreshAccessToken();
        if (refreshed) {
          const retryToken = getAccessToken();
          if (!retryToken) {
            window.location.href = "/login";
            return;
          }
          const retryResponse = await fetch(url, {
            headers: { Authorization: `Bearer ${retryToken}` },
          });
          if (!retryResponse.ok) {
            toast.error("Failed to download CSV. Please try again.");
            return;
          }
          const blob = await retryResponse.blob();
          triggerDownload(blob, filename);
          return;
        }
        clearTokens();
        window.location.href = "/login";
        return;
      }

      if (response.status === 403) {
        toast.error("You don't have permission to export this data.");
        return;
      }

      if (!response.ok) {
        toast.error("Failed to download CSV. Please try again.");
        return;
      }

      const blob = await response.blob();
      triggerDownload(blob, filename);
    } catch {
      toast.error("Failed to download CSV. Please try again.");
    } finally {
      setIsDownloading(false);
    }
  }, [url, filename]);

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={handleDownload}
      disabled={isDownloading}
      aria-label={ariaLabel ?? label}
    >
      {isDownloading ? (
        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
      ) : (
        <Download className="mr-2 h-4 w-4" />
      )}
      {label}
    </Button>
  );
}

function triggerDownload(blob: Blob, filename: string): void {
  const objectUrl = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = objectUrl;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  // Delay revocation for Safari compatibility
  setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
}

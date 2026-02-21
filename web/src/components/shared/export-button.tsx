"use client";

import { useState, useCallback, useRef } from "react";
import { Download, Loader2, CheckCircle } from "lucide-react";
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
  disabled?: boolean;
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

type ButtonStatus = "idle" | "downloading" | "success";

export function ExportButton({
  url,
  filename,
  label = "Export CSV",
  "aria-label": ariaLabel,
  disabled = false,
}: ExportButtonProps) {
  const [status, setStatus] = useState<ButtonStatus>("idle");
  const abortRef = useRef<AbortController | null>(null);

  const handleDownload = useCallback(async () => {
    // Abort any in-flight download before starting a new one
    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setStatus("downloading");

    function onSuccess(): void {
      if (controller.signal.aborted) return;
      toast.success(`${filename} downloaded`);
      setStatus("success");
      setTimeout(() => {
        if (!controller.signal.aborted) setStatus("idle");
      }, 2000);
    }

    try {
      const token = await getValidToken();
      if (!token) return;

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
        signal: controller.signal,
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
            signal: controller.signal,
          });
          if (!retryResponse.ok) {
            toast.error("Failed to download CSV. Please try again.");
            return;
          }
          const blob = await retryResponse.blob();
          triggerDownload(blob, filename);
          onSuccess();
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
      onSuccess();
    } catch (error: unknown) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      toast.error("Failed to download CSV. Please try again.");
    } finally {
      setStatus((prev) => (prev === "success" ? "success" : "idle"));
    }
  }, [url, filename]);

  const isDownloading = status === "downloading";
  const isSuccess = status === "success";

  return (
    <>
      <div className="sr-only" role="status" aria-live="polite">
        {isDownloading ? "Downloading CSV file..." : ""}
        {isSuccess ? `${filename} downloaded successfully` : ""}
      </div>
      <Button
        type="button"
        variant="outline"
        size="sm"
        onClick={handleDownload}
        disabled={disabled || isDownloading}
        aria-label={ariaLabel ?? label}
      >
        {isDownloading ? (
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
        ) : isSuccess ? (
          <CheckCircle className="mr-2 h-4 w-4 text-green-600" />
        ) : (
          <Download className="mr-2 h-4 w-4" />
        )}
        {isDownloading ? "Downloading..." : label}
      </Button>
    </>
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

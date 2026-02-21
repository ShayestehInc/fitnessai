"use client";

import { useState, useCallback } from "react";
import { Download, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { getAccessToken } from "@/lib/token-manager";

interface ExportButtonProps {
  url: string;
  filename: string;
  label?: string;
  "aria-label"?: string;
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
      const token = getAccessToken();
      if (!token) {
        toast.error("Session expired. Please log in again.");
        return;
      }

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        if (response.status === 403) {
          toast.error("You don't have permission to export this data.");
        } else {
          toast.error("Failed to download CSV. Please try again.");
        }
        return;
      }

      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = objectUrl;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(objectUrl);
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

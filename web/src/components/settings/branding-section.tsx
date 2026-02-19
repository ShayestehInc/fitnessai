"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, Upload, X } from "lucide-react";
import { toast } from "sonner";
import { useBranding, useUpdateBranding, useUploadLogo, useRemoveLogo } from "@/hooks/use-branding";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { getErrorMessage } from "@/lib/error-utils";

const PRESET_COLORS = [
  "#4f46e5", "#3b82f6", "#10b981", "#14b8a6", "#8b5cf6", "#ec4899",
  "#ef4444", "#f97316", "#f59e0b", "#64748b", "#71717a", "#059669",
];

const HEX_REGEX = /^#[0-9a-fA-F]{6}$/;

export function BrandingSection() {
  const { data: branding, isLoading } = useBranding();
  const updateMutation = useUpdateBranding();
  const uploadLogoMutation = useUploadLogo();
  const removeLogoMutation = useRemoveLogo();

  const [appName, setAppName] = useState("");
  const [primaryColor, setPrimaryColor] = useState("#4f46e5");
  const [secondaryColor, setSecondaryColor] = useState("#3b82f6");
  const [hasChanges, setHasChanges] = useState(false);

  useEffect(() => {
    if (branding) {
      setAppName(branding.app_name ?? "");
      setPrimaryColor(branding.primary_color ?? "#4f46e5");
      setSecondaryColor(branding.secondary_color ?? "#3b82f6");
      setHasChanges(false);
    }
  }, [branding]);

  const handleSave = useCallback(() => {
    updateMutation.mutate(
      {
        app_name: appName,
        primary_color: primaryColor,
        secondary_color: secondaryColor,
      },
      {
        onSuccess: () => {
          toast.success("Branding updated");
          setHasChanges(false);
        },
        onError: (err) => toast.error(getErrorMessage(err)),
      },
    );
  }, [appName, primaryColor, secondaryColor, updateMutation]);

  const handleLogoUpload = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      if (file.size > 5 * 1024 * 1024) {
        toast.error("File must be under 5MB");
        return;
      }

      const validTypes = ["image/jpeg", "image/png", "image/webp"];
      if (!validTypes.includes(file.type)) {
        toast.error("Only JPEG, PNG, and WebP images are accepted");
        return;
      }

      uploadLogoMutation.mutate(file, {
        onSuccess: () => toast.success("Logo uploaded"),
        onError: (err) => toast.error(getErrorMessage(err)),
      });
    },
    [uploadLogoMutation],
  );

  const handleRemoveLogo = useCallback(() => {
    removeLogoMutation.mutate(undefined, {
      onSuccess: () => toast.success("Logo removed"),
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }, [removeLogoMutation]);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-24" />
          <Skeleton className="h-4 w-48" />
        </CardHeader>
        <CardContent className="space-y-4">
          <Skeleton className="h-10 w-full" />
          <Skeleton className="h-10 w-full" />
          <Skeleton className="h-10 w-full" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Branding</CardTitle>
        <CardDescription>Customize your white-label branding</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* App Name */}
        <div className="space-y-2">
          <div className="flex justify-between">
            <Label htmlFor="app-name">App Name</Label>
            <span className="text-xs text-muted-foreground">{appName.length}/50</span>
          </div>
          <Input
            id="app-name"
            value={appName}
            onChange={(e) => {
              setAppName(e.target.value);
              setHasChanges(true);
            }}
            maxLength={50}
            placeholder="FitnessAI"
          />
        </div>

        {/* Primary Color */}
        <div className="space-y-2">
          <Label>Primary Color</Label>
          <div className="flex flex-wrap gap-2">
            {PRESET_COLORS.map((color) => (
              <button
                key={color}
                onClick={() => {
                  setPrimaryColor(color);
                  setHasChanges(true);
                }}
                className={cn(
                  "h-8 w-8 rounded-full border-2 transition-transform hover:scale-110",
                  primaryColor === color ? "border-foreground scale-110" : "border-transparent",
                )}
                style={{ backgroundColor: color }}
                aria-label={`Select color ${color}`}
              />
            ))}
          </div>
          <Input
            value={primaryColor}
            onChange={(e) => {
              setPrimaryColor(e.target.value);
              setHasChanges(true);
            }}
            placeholder="#4f46e5"
            maxLength={7}
          />
          {primaryColor && !HEX_REGEX.test(primaryColor) && (
            <p className="text-sm text-destructive">Enter a valid hex color</p>
          )}
        </div>

        {/* Secondary Color */}
        <div className="space-y-2">
          <Label>Secondary Color</Label>
          <div className="flex flex-wrap gap-2">
            {PRESET_COLORS.map((color) => (
              <button
                key={color}
                onClick={() => {
                  setSecondaryColor(color);
                  setHasChanges(true);
                }}
                className={cn(
                  "h-8 w-8 rounded-full border-2 transition-transform hover:scale-110",
                  secondaryColor === color ? "border-foreground scale-110" : "border-transparent",
                )}
                style={{ backgroundColor: color }}
                aria-label={`Select secondary color ${color}`}
              />
            ))}
          </div>
          <Input
            value={secondaryColor}
            onChange={(e) => {
              setSecondaryColor(e.target.value);
              setHasChanges(true);
            }}
            placeholder="#3b82f6"
            maxLength={7}
          />
        </div>

        {/* Logo */}
        <div className="space-y-2">
          <Label>Logo</Label>
          {branding?.logo ? (
            <div className="flex items-center gap-3">
              <img
                src={branding.logo}
                alt="Current logo"
                className="h-12 w-12 rounded object-cover"
              />
              <Button
                variant="outline"
                size="sm"
                onClick={handleRemoveLogo}
                disabled={removeLogoMutation.isPending}
              >
                <X className="mr-1 h-3 w-3" />
                Remove
              </Button>
            </div>
          ) : (
            <label className="flex cursor-pointer items-center gap-2 rounded-md border-2 border-dashed p-4 transition-colors hover:border-primary/50">
              <Upload className="h-5 w-5 text-muted-foreground" />
              <span className="text-sm text-muted-foreground">
                Drop or click to upload (JPEG, PNG, WebP, max 5MB)
              </span>
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handleLogoUpload}
                className="hidden"
              />
            </label>
          )}
        </div>

        {/* Live Preview */}
        <div className="space-y-2">
          <Label>Preview</Label>
          <div className="rounded-lg border p-4">
            <div
              className="flex items-center gap-2 rounded-md p-3"
              style={{ backgroundColor: primaryColor }}
            >
              <span className="text-sm font-semibold text-white">
                {appName || "FitnessAI"}
              </span>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-2">
          <Button onClick={handleSave} disabled={!hasChanges || updateMutation.isPending}>
            {updateMutation.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            Save Changes
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              if (branding) {
                setAppName(branding.app_name ?? "");
                setPrimaryColor(branding.primary_color ?? "#4f46e5");
                setSecondaryColor(branding.secondary_color ?? "#3b82f6");
                setHasChanges(false);
              }
            }}
            disabled={!hasChanges}
          >
            Reset
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

"use client";

import { useCallback, useRef, useState } from "react";
import { Upload, X, Link, Loader2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

interface FileUploadFieldProps {
  label: string;
  accept: string;
  maxSizeMB: number;
  currentUrl: string;
  onFileSelect: (file: File | null) => void;
  onUrlChange: (url: string) => void;
  uploading: boolean;
  selectedFile: File | null;
}

export function FileUploadField({
  label,
  accept,
  maxSizeMB,
  currentUrl,
  onFileSelect,
  onUrlChange,
  uploading,
  selectedFile,
}: FileUploadFieldProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);
  const [sizeError, setSizeError] = useState("");

  const validateAndSelect = useCallback(
    (file: File) => {
      setSizeError("");
      const maxBytes = maxSizeMB * 1024 * 1024;
      if (file.size > maxBytes) {
        setSizeError(`File too large. Maximum size is ${maxSizeMB}MB.`);
        return;
      }
      onFileSelect(file);
    },
    [maxSizeMB, onFileSelect],
  );

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setDragOver(false);
      const file = e.dataTransfer.files[0];
      if (file) validateAndSelect(file);
    },
    [validateAndSelect],
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setDragOver(false);
  }, []);

  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (file) validateAndSelect(file);
    },
    [validateAndSelect],
  );

  const clearFile = useCallback(() => {
    onFileSelect(null);
    setSizeError("");
    if (fileInputRef.current) fileInputRef.current.value = "";
  }, [onFileSelect]);

  const previewUrl = selectedFile ? URL.createObjectURL(selectedFile) : null;
  const isImage = accept.startsWith("image/");

  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      <Tabs defaultValue="upload" className="w-full">
        <TabsList className="w-full">
          <TabsTrigger value="upload" className="flex-1 gap-1.5">
            <Upload className="h-3.5 w-3.5" />
            Upload
          </TabsTrigger>
          <TabsTrigger value="url" className="flex-1 gap-1.5">
            <Link className="h-3.5 w-3.5" />
            URL
          </TabsTrigger>
        </TabsList>

        <TabsContent value="upload">
          {selectedFile ? (
            <div className="relative mt-2 rounded-md border p-3">
              <div className="flex items-center gap-3">
                {isImage && previewUrl ? (
                  <img
                    src={previewUrl}
                    alt="Preview"
                    className="h-12 w-12 rounded object-cover"
                  />
                ) : (
                  <div className="flex h-12 w-12 items-center justify-center rounded bg-muted text-xs text-muted-foreground">
                    {selectedFile.name.split(".").pop()?.toUpperCase()}
                  </div>
                )}
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">
                    {selectedFile.name}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {(selectedFile.size / (1024 * 1024)).toFixed(1)} MB
                  </p>
                </div>
                {uploading ? (
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                ) : (
                  <button
                    type="button"
                    onClick={clearFile}
                    className="rounded-full p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                    aria-label="Remove file"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>
          ) : (
            <div
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => fileInputRef.current?.click()}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  fileInputRef.current?.click();
                }
              }}
              className={`mt-2 flex cursor-pointer flex-col items-center justify-center rounded-md border-2 border-dashed px-4 py-6 transition-colors ${
                dragOver
                  ? "border-primary bg-primary/5"
                  : "border-muted-foreground/25 hover:border-muted-foreground/50"
              }`}
            >
              <Upload className="mb-2 h-6 w-6 text-muted-foreground" />
              <p className="text-sm text-muted-foreground">
                Drop a file here or click to browse
              </p>
              <p className="mt-1 text-xs text-muted-foreground/70">
                Max {maxSizeMB}MB
              </p>
              <input
                ref={fileInputRef}
                type="file"
                accept={accept}
                onChange={handleFileChange}
                className="hidden"
                aria-label={`Upload ${label.toLowerCase()}`}
              />
            </div>
          )}
          {sizeError && (
            <p className="mt-1 text-sm text-destructive">{sizeError}</p>
          )}
        </TabsContent>

        <TabsContent value="url">
          <Input
            className="mt-2"
            value={currentUrl}
            onChange={(e) => onUrlChange(e.target.value)}
            placeholder={
              isImage
                ? "https://example.com/image.jpg"
                : "https://youtube.com/watch?v=..."
            }
          />
          {currentUrl && isImage && (
            <img
              src={currentUrl}
              alt="Preview"
              className="mt-2 h-20 w-20 rounded object-cover"
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = "none";
              }}
            />
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}

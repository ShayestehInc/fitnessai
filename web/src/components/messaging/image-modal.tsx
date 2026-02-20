"use client";

import { X } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

interface ImageModalProps {
  imageUrl: string;
  open: boolean;
  onClose: () => void;
}

export function ImageModal({ imageUrl, open, onClose }: ImageModalProps) {
  return (
    <Dialog open={open} onOpenChange={(isOpen) => !isOpen && onClose()}>
      <DialogContent className="max-w-[90vw] max-h-[90vh] p-0 overflow-hidden border-none bg-black/95">
        <DialogTitle className="sr-only">Image preview</DialogTitle>
        <div className="relative flex items-center justify-center">
          <Button
            variant="ghost"
            size="icon"
            className="absolute right-2 top-2 z-10 rounded-full bg-black/50 text-white hover:bg-black/70"
            onClick={onClose}
            aria-label="Close image"
          >
            <X className="h-5 w-5" />
          </Button>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={imageUrl}
            alt="Full size message attachment"
            className="max-h-[85vh] max-w-full object-contain"
          />
        </div>
      </DialogContent>
    </Dialog>
  );
}

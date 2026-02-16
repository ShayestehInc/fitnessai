"use client";

import { useState } from "react";
import { Loader2, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { useDeleteProgram } from "@/hooks/use-programs";
import { getErrorMessage } from "@/lib/error-utils";
import type { ProgramTemplate } from "@/types/program";

interface DeleteProgramDialogProps {
  program: ProgramTemplate;
  trigger: React.ReactNode;
}

export function DeleteProgramDialog({
  program,
  trigger,
}: DeleteProgramDialogProps) {
  const [open, setOpen] = useState(false);
  const deleteMutation = useDeleteProgram();

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(program.id);
      toast.success(`"${program.name}" has been deleted`);
      setOpen(false);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  };

  const handleOpenChange = (nextOpen: boolean) => {
    // Prevent closing while delete is in progress
    if (!nextOpen && deleteMutation.isPending) return;
    setOpen(nextOpen);
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Delete Program Template</DialogTitle>
          <DialogDescription asChild>
            <div>
              <span>Are you sure you want to delete &ldquo;</span>
              <span className="inline break-all font-medium">
                {program.name}
              </span>
              <span>&rdquo;? This action cannot be undone.</span>
              {program.times_used > 0 && (
                <span className="mt-1 block text-amber-600 dark:text-amber-400">
                  This template has been used {program.times_used} time
                  {program.times_used !== 1 ? "s" : ""}. Assigned programs will
                  not be affected.
                </span>
              )}
            </div>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => setOpen(false)}
            disabled={deleteMutation.isPending}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={handleDelete}
            disabled={deleteMutation.isPending}
          >
            {deleteMutation.isPending ? (
              <>
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
                Deleting...
              </>
            ) : (
              <>
                <Trash2 className="mr-2 h-4 w-4" aria-hidden="true" />
                Delete
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

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
      toast.success("Program deleted");
      setOpen(false);
    } catch {
      toast.error("Failed to delete program");
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Delete Program Template</DialogTitle>
          <DialogDescription>
            Are you sure you want to delete &ldquo;{program.name}&rdquo;?
            {program.times_used > 0 && (
              <span className="mt-1 block text-amber-600 dark:text-amber-400">
                This template has been used {program.times_used} time
                {program.times_used !== 1 ? "s" : ""}. Assigned programs will
                not be affected.
              </span>
            )}
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

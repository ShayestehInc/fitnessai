"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Pin, Pencil, Trash2, Plus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { AnnouncementFormDialog } from "./announcement-form-dialog";
import { AnnouncementDeleteDialog } from "./announcement-delete-dialog";
import { useCreateAnnouncement, useUpdateAnnouncement, useDeleteAnnouncement } from "@/hooks/use-announcements";
import { getErrorMessage } from "@/lib/error-utils";
import { Megaphone } from "lucide-react";
import type { Announcement } from "@/types/announcement";

interface AnnouncementListProps {
  announcements: Announcement[];
}

export function AnnouncementList({ announcements }: AnnouncementListProps) {
  const [formOpen, setFormOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedAnnouncement, setSelectedAnnouncement] =
    useState<Announcement | null>(null);

  const createMutation = useCreateAnnouncement();
  const deleteMutation = useDeleteAnnouncement();

  const sorted = [...announcements].sort((a, b) => {
    if (a.is_pinned && !b.is_pinned) return -1;
    if (!a.is_pinned && b.is_pinned) return 1;
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
  });

  function handleCreate() {
    setSelectedAnnouncement(null);
    setFormOpen(true);
  }

  function handleEdit(announcement: Announcement) {
    setSelectedAnnouncement(announcement);
    setFormOpen(true);
  }

  function handleDeleteClick(announcement: Announcement) {
    setSelectedAnnouncement(announcement);
    setDeleteOpen(true);
  }

  if (announcements.length === 0) {
    return (
      <EmptyState
        icon={Megaphone}
        title="No announcements yet"
        description="Create your first announcement to broadcast to all trainees."
        action={
          <Button onClick={handleCreate}>
            <Plus className="mr-2 h-4 w-4" />
            Create Announcement
          </Button>
        }
      />
    );
  }

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Announcements</CardTitle>
          <Button size="sm" onClick={handleCreate}>
            <Plus className="mr-2 h-4 w-4" />
            Create
          </Button>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-8" />
                  <TableHead>Title</TableHead>
                  <TableHead>Preview</TableHead>
                  <TableHead>Format</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead className="w-24">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sorted.map((a) => (
                  <TableRow key={a.id}>
                    <TableCell>
                      {a.is_pinned && (
                        <Pin
                          className="h-4 w-4 text-amber-500"
                          aria-label="Pinned"
                        />
                      )}
                    </TableCell>
                    <TableCell>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <span className="block max-w-[200px] truncate font-medium">
                            {a.title}
                          </span>
                        </TooltipTrigger>
                        <TooltipContent>{a.title}</TooltipContent>
                      </Tooltip>
                    </TableCell>
                    <TableCell className="max-w-[300px] truncate text-sm text-muted-foreground">
                      {a.body.slice(0, 100)}
                      {a.body.length > 100 ? "..." : ""}
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">{a.content_format}</Badge>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {format(new Date(a.created_at), "MMM d, yyyy")}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          variant="ghost"
                          size="icon-xs"
                          onClick={() => handleEdit(a)}
                          aria-label={`Edit ${a.title}`}
                        >
                          <Pencil className="h-3 w-3" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon-xs"
                          onClick={() => handleDeleteClick(a)}
                          aria-label={`Delete ${a.title}`}
                        >
                          <Trash2 className="h-3 w-3 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <AnnouncementFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        announcement={selectedAnnouncement}
        isPending={createMutation.isPending}
        onSubmit={(data) => {
          if (selectedAnnouncement) {
            // Update handled within EditWrapper
          } else {
            createMutation.mutate(data, {
              onSuccess: () => {
                toast.success("Announcement created");
                setFormOpen(false);
              },
              onError: (err) => toast.error(getErrorMessage(err)),
            });
          }
        }}
      />

      {selectedAnnouncement && (
        <>
          <EditAnnouncementWrapper
            open={formOpen && Boolean(selectedAnnouncement)}
            onOpenChange={setFormOpen}
            announcement={selectedAnnouncement}
          />
          <AnnouncementDeleteDialog
            open={deleteOpen}
            onOpenChange={setDeleteOpen}
            title={selectedAnnouncement.title}
            isPending={deleteMutation.isPending}
            onConfirm={() => {
              deleteMutation.mutate(selectedAnnouncement.id, {
                onSuccess: () => {
                  toast.success("Announcement deleted");
                  setDeleteOpen(false);
                  setSelectedAnnouncement(null);
                },
                onError: (err) => toast.error(getErrorMessage(err)),
              });
            }}
          />
        </>
      )}
    </>
  );
}

function EditAnnouncementWrapper({
  open,
  onOpenChange,
  announcement,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  announcement: Announcement;
}) {
  const updateMutation = useUpdateAnnouncement(announcement.id);

  return (
    <AnnouncementFormDialog
      open={open}
      onOpenChange={onOpenChange}
      announcement={announcement}
      isPending={updateMutation.isPending}
      onSubmit={(data) => {
        updateMutation.mutate(data, {
          onSuccess: () => {
            toast.success("Announcement updated");
            onOpenChange(false);
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        });
      }}
    />
  );
}

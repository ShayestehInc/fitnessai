"use client";

import { useState, useMemo, useCallback } from "react";
import { Users, Plus, Loader2 } from "lucide-react";
import {
  useAmbassadorAdminTrainers,
  useAmbassadorAdminCreateTrainer,
  useAmbassadorAdminImpersonateTrainer,
} from "@/hooks/use-ambassador-admin-trainers";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import {
  setImpersonationState,
} from "@/components/layout/impersonation-banner";
import { setTokens, getAccessToken, getRefreshToken, setRoleCookie } from "@/lib/token-manager";

export default function AmbassadorTrainersPage() {
  const [searchInput, setSearchInput] = useState("");
  const [createOpen, setCreateOpen] = useState(false);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    first_name: "",
    last_name: "",
  });
  const [formError, setFormError] = useState<string | null>(null);

  const debouncedSearch = useDebounce(searchInput, 300);
  const filters = useMemo(
    () => ({ search: debouncedSearch || undefined }),
    [debouncedSearch],
  );

  const trainers = useAmbassadorAdminTrainers(filters);
  const createTrainer = useAmbassadorAdminCreateTrainer();
  const impersonate = useAmbassadorAdminImpersonateTrainer();

  const handleCreate = useCallback(async () => {
    setFormError(null);
    if (!formData.email || !formData.password) {
      setFormError("Email and password are required.");
      return;
    }
    if (formData.password.length < 8) {
      setFormError("Password must be at least 8 characters.");
      return;
    }
    try {
      await createTrainer.mutateAsync(formData);
      toast.success("Trainer created successfully");
      setCreateOpen(false);
      setFormData({ email: "", password: "", first_name: "", last_name: "" });
    } catch (error) {
      setFormError(getErrorMessage(error));
    }
  }, [formData, createTrainer]);

  const handleImpersonate = useCallback(
    async (trainerId: number) => {
      try {
        const result = await impersonate.mutateAsync(trainerId);
        setImpersonationState({
          adminAccessToken: getAccessToken() ?? "",
          adminRefreshToken: getRefreshToken() ?? "",
          trainerEmail: result.trainer.email,
        });
        setTokens(result.access, result.refresh);
        setRoleCookie("TRAINER");
        window.location.href = "/dashboard";
      } catch (error) {
        toast.error(getErrorMessage(error));
      }
    },
    [impersonate],
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Trainers"
        description="Manage trainers you've referred or created"
        actions={
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
            Create Trainer
          </Button>
        }
      />

      <Input
        placeholder="Search by name or email..."
        value={searchInput}
        onChange={(e) => setSearchInput(e.target.value)}
        className="max-w-sm"
        aria-label="Search trainers"
      />

      {trainers.isLoading && (
        <div className="space-y-2" role="status" aria-label="Loading trainers">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
          <span className="sr-only">Loading trainers...</span>
        </div>
      )}

      {trainers.isError && (
        <ErrorState
          message="Failed to load trainers"
          onRetry={() => trainers.refetch()}
        />
      )}

      {trainers.data && trainers.data.length === 0 && (
        <EmptyState
          icon={Users}
          title="No trainers found"
          description={
            debouncedSearch
              ? "No trainers match your search."
              : "You haven't created or referred any trainers yet."
          }
          action={
            !debouncedSearch ? (
              <Button onClick={() => setCreateOpen(true)}>
                Create Your First Trainer
              </Button>
            ) : undefined
          }
        />
      )}

      {trainers.data && trainers.data.length > 0 && (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Tier</TableHead>
                <TableHead className="text-right">Trainees</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {trainers.data.map((trainer) => (
                <TableRow key={trainer.id}>
                  <TableCell className="font-medium">
                    {trainer.first_name} {trainer.last_name}
                  </TableCell>
                  <TableCell>{trainer.email}</TableCell>
                  <TableCell>
                    <Badge
                      variant={trainer.is_active ? "default" : "secondary"}
                    >
                      {trainer.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {trainer.subscription?.tier ?? "FREE"}
                  </TableCell>
                  <TableCell className="text-right">
                    {trainer.trainee_count}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleImpersonate(trainer.id)}
                      disabled={impersonate.isPending}
                    >
                      View As
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Create Trainer Dialog */}
      <Dialog
        open={createOpen}
        onOpenChange={(open) => {
          setCreateOpen(open);
          if (!open) {
            setFormError(null);
            setFormData({
              email: "",
              password: "",
              first_name: "",
              last_name: "",
            });
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Trainer</DialogTitle>
            <DialogDescription>
              Create a new trainer account linked to your ambassador profile.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="create-email">Email</Label>
              <Input
                id="create-email"
                type="email"
                value={formData.email}
                onChange={(e) =>
                  setFormData((d) => ({ ...d, email: e.target.value }))
                }
                placeholder="trainer@example.com"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="create-first">First Name</Label>
                <Input
                  id="create-first"
                  value={formData.first_name}
                  onChange={(e) =>
                    setFormData((d) => ({ ...d, first_name: e.target.value }))
                  }
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="create-last">Last Name</Label>
                <Input
                  id="create-last"
                  value={formData.last_name}
                  onChange={(e) =>
                    setFormData((d) => ({ ...d, last_name: e.target.value }))
                  }
                />
              </div>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="create-password">Password</Label>
              <Input
                id="create-password"
                type="password"
                value={formData.password}
                onChange={(e) =>
                  setFormData((d) => ({ ...d, password: e.target.value }))
                }
                placeholder="Min. 8 characters"
              />
            </div>
            {formError && (
              <div
                className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
                role="alert"
              >
                {formError}
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleCreate}
              disabled={createTrainer.isPending}
            >
              {createTrainer.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Create
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

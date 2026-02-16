"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import {
  useCreateAdminUser,
  useUpdateAdminUser,
  useDeleteAdminUser,
} from "@/hooks/use-admin-users";
import type { AdminUser } from "@/types/admin";

interface CreateUserDialogProps {
  user: AdminUser | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const ROLES = [
  { value: "ADMIN", label: "Admin" },
  { value: "TRAINER", label: "Trainer" },
];

function getPasswordStrength(password: string): {
  label: string;
  color: string;
} {
  if (password.length === 0) return { label: "", color: "" };
  if (password.length < 8)
    return { label: "Too short", color: "text-destructive" };
  let score = 0;
  if (/[a-z]/.test(password)) score++;
  if (/[A-Z]/.test(password)) score++;
  if (/[0-9]/.test(password)) score++;
  if (/[^a-zA-Z0-9]/.test(password)) score++;
  if (score <= 1) return { label: "Weak", color: "text-destructive" };
  if (score === 2) return { label: "Fair", color: "text-amber-500" };
  if (score === 3) return { label: "Good", color: "text-blue-500" };
  return { label: "Strong", color: "text-green-500" };
}

export function CreateUserDialog({
  user,
  open,
  onOpenChange,
}: CreateUserDialogProps) {
  const isEdit = user !== null;
  const createUser = useCreateAdminUser();
  const updateUser = useUpdateAdminUser();
  const deleteUser = useDeleteAdminUser();

  const [email, setEmail] = useState(user?.email ?? "");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState(user?.role ?? "TRAINER");
  const [firstName, setFirstName] = useState(user?.first_name ?? "");
  const [lastName, setLastName] = useState(user?.last_name ?? "");
  const [isActive, setIsActive] = useState(user?.is_active ?? true);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  function validate(): boolean {
    const newErrors: Record<string, string> = {};
    if (!isEdit) {
      if (!email.trim()) newErrors.email = "Email is required";
      if (!password) newErrors.password = "Password is required";
      else if (password.length < 8)
        newErrors.password = "Password must be at least 8 characters";
    } else {
      if (password && password.length < 8)
        newErrors.password = "Password must be at least 8 characters";
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;

    try {
      if (isEdit && user) {
        const payload: Record<string, unknown> = {
          first_name: firstName.trim(),
          last_name: lastName.trim(),
          is_active: isActive,
          role,
        };
        if (password) payload.password = password;
        await updateUser.mutateAsync({ id: user.id, data: payload });
        toast.success("User updated");
      } else {
        await createUser.mutateAsync({
          email: email.trim().toLowerCase(),
          password,
          role,
          first_name: firstName.trim(),
          last_name: lastName.trim(),
        });
        toast.success("User created");
      }
      onOpenChange(false);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleDelete() {
    if (!user) return;
    setDeleteError(null);
    try {
      await deleteUser.mutateAsync(user.id);
      toast.success(`User ${user.email} deleted`);
      onOpenChange(false);
    } catch (error) {
      setDeleteError(getErrorMessage(error));
    }
  }

  const isPending =
    createUser.isPending || updateUser.isPending || deleteUser.isPending;
  const passwordStrength = getPasswordStrength(password);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit User" : "Create User"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? `Editing ${user?.email}`
              : "Create a new admin or trainer account"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isEdit && (
            <div className="space-y-1">
              <Label htmlFor="user-email">Email</Label>
              <Input
                id="user-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="user@example.com"
                aria-invalid={!!errors.email}
                aria-describedby={
                  errors.email ? "user-email-error" : undefined
                }
              />
              {errors.email && (
                <p id="user-email-error" className="text-xs text-destructive">
                  {errors.email}
                </p>
              )}
            </div>
          )}

          <div className="space-y-1">
            <Label htmlFor="user-password">
              {isEdit ? "New Password (leave blank to keep)" : "Password"}
            </Label>
            <Input
              id="user-password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={isEdit ? "Leave blank to keep current" : ""}
              autoComplete="new-password"
              aria-invalid={!!errors.password}
              aria-describedby={
                errors.password ? "user-password-error" : undefined
              }
            />
            {errors.password && (
              <p
                id="user-password-error"
                className="text-xs text-destructive"
              >
                {errors.password}
              </p>
            )}
            {passwordStrength.label && (
              <p className={`text-xs ${passwordStrength.color}`}>
                Password strength: {passwordStrength.label}
              </p>
            )}
          </div>

          <div className="space-y-1">
            <Label htmlFor="user-role">Role</Label>
            <select
              id="user-role"
              value={role}
              onChange={(e) => setRole(e.target.value)}
              className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            >
              {ROLES.map((r) => (
                <option key={r.value} value={r.value}>
                  {r.label}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <Label htmlFor="user-first-name">First Name</Label>
              <Input
                id="user-first-name"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                placeholder="John"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="user-last-name">Last Name</Label>
              <Input
                id="user-last-name"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                placeholder="Doe"
              />
            </div>
          </div>

          {isEdit && (
            <div className="flex items-center gap-2">
              <input
                id="user-active"
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="h-4 w-4 rounded border-input"
              />
              <Label htmlFor="user-active" className="cursor-pointer">
                Active
              </Label>
            </div>
          )}

          {isEdit && !showDeleteConfirm && (
            <Button
              type="button"
              variant="destructive"
              size="sm"
              onClick={() => setShowDeleteConfirm(true)}
              className="w-full"
            >
              Delete User
            </Button>
          )}

          {showDeleteConfirm && (
            <div className="rounded-md border border-destructive/20 bg-destructive/5 p-3">
              <p className="mb-2 text-sm text-destructive">
                Are you sure you want to delete {user?.email}?
              </p>
              {deleteError && (
                <p className="mb-2 text-sm text-destructive" role="alert">
                  {deleteError}
                </p>
              )}
              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="destructive"
                  size="sm"
                  onClick={handleDelete}
                  disabled={deleteUser.isPending}
                >
                  {deleteUser.isPending && (
                    <Loader2
                      className="mr-1 h-3 w-3 animate-spin"
                      aria-hidden="true"
                    />
                  )}
                  Confirm Delete
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setShowDeleteConfirm(false);
                    setDeleteError(null);
                  }}
                >
                  Cancel
                </Button>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {(createUser.isPending || updateUser.isPending) && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              {isEdit ? "Update User" : "Create User"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

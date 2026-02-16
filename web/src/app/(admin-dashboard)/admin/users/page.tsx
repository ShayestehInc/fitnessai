"use client";

import { useState, useMemo } from "react";
import { UserCog, Plus } from "lucide-react";
import { useAdminUsers } from "@/hooks/use-admin-users";
import { useDebounce } from "@/hooks/use-debounce";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { UserList } from "@/components/admin/user-list";
import { CreateUserDialog } from "@/components/admin/create-user-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import type { AdminUser } from "@/types/admin";

const ROLE_OPTIONS = [
  { value: "", label: "All Roles" },
  { value: "ADMIN", label: "Admin" },
  { value: "TRAINER", label: "Trainer" },
];

export default function AdminUsersPage() {
  const [searchInput, setSearchInput] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [formKey, setFormKey] = useState(0);

  const debouncedSearch = useDebounce(searchInput, 300);

  const filters = useMemo(
    () => ({
      search: debouncedSearch || undefined,
      role: roleFilter || undefined,
    }),
    [debouncedSearch, roleFilter],
  );

  const users = useAdminUsers(filters);

  function handleCreate() {
    setSelectedUser(null);
    setFormKey((k) => k + 1);
    setDialogOpen(true);
  }

  function handleRowClick(user: AdminUser) {
    setSelectedUser(user);
    setDialogOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users"
        description="Manage admin and trainer accounts"
        actions={
          <Button onClick={handleCreate}>
            <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
            Create User
          </Button>
        }
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder="Search by name or email..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="max-w-sm"
          aria-label="Search users"
        />
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="flex h-9 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          aria-label="Filter by role"
        >
          {ROLE_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {users.isLoading && (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </div>
      )}

      {users.isError && (
        <ErrorState
          message="Failed to load users"
          onRetry={() => users.refetch()}
        />
      )}

      {users.data && users.data.length === 0 && (
        <EmptyState
          icon={UserCog}
          title="No users found"
          description={
            debouncedSearch || roleFilter
              ? "No users match your search criteria."
              : "No admin or trainer users exist yet."
          }
          action={
            !debouncedSearch && !roleFilter ? (
              <Button onClick={handleCreate}>Create User</Button>
            ) : undefined
          }
        />
      )}

      {users.data && users.data.length > 0 && (
        <UserList users={users.data} onRowClick={handleRowClick} />
      )}

      <CreateUserDialog
        key={selectedUser?.id ?? `new-${formKey}`}
        user={selectedUser}
        open={dialogOpen}
        onOpenChange={setDialogOpen}
      />
    </div>
  );
}

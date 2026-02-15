"use client";

import { useCallback, useState } from "react";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";
import { useChangePassword } from "@/hooks/use-settings";
import { ApiError } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function SecuritySection() {
  const changePassword = useChangePassword();

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (!currentPassword) {
      newErrors.current_password = "Current password is required";
    }
    if (newPassword.length < 8) {
      newErrors.new_password = "Password must be at least 8 characters";
    }
    if (newPassword !== confirmPassword) {
      newErrors.confirm_password = "Passwords do not match";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [currentPassword, newPassword, confirmPassword]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!validate()) return;

      changePassword.mutate(
        {
          current_password: currentPassword,
          new_password: newPassword,
        },
        {
          onSuccess: () => {
            toast.success("Password changed successfully");
            setCurrentPassword("");
            setNewPassword("");
            setConfirmPassword("");
            setErrors({});
          },
          onError: (error) => {
            if (error instanceof ApiError && error.body) {
              const body = error.body as Record<string, string[]>;
              const newErrors: Record<string, string> = {};

              if (body.current_password) {
                newErrors.current_password = body.current_password[0];
              }
              if (body.new_password) {
                newErrors.new_password = body.new_password[0];
              }
              if (body.non_field_errors) {
                newErrors.new_password = body.non_field_errors[0];
              }

              if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors);
              } else {
                toast.error("Failed to change password");
              }
            } else {
              toast.error("Failed to change password");
            }
          },
        },
      );
    },
    [currentPassword, newPassword, validate, changePassword],
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>Security</CardTitle>
        <CardDescription>Update your password</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="currentPassword">Current password</Label>
            <Input
              id="currentPassword"
              type="password"
              value={currentPassword}
              onChange={(e) => {
                setCurrentPassword(e.target.value);
                setErrors((prev) => ({ ...prev, current_password: "" }));
              }}
              maxLength={128}
              autoComplete="current-password"
            />
            {errors.current_password && (
              <p className="text-sm text-destructive" role="alert">
                {errors.current_password}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="newPassword">New password</Label>
            <Input
              id="newPassword"
              type="password"
              value={newPassword}
              onChange={(e) => {
                setNewPassword(e.target.value);
                setErrors((prev) => ({ ...prev, new_password: "" }));
              }}
              maxLength={128}
              autoComplete="new-password"
            />
            {errors.new_password && (
              <p className="text-sm text-destructive" role="alert">
                {errors.new_password}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="confirmPassword">Confirm new password</Label>
            <Input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => {
                setConfirmPassword(e.target.value);
                setErrors((prev) => ({ ...prev, confirm_password: "" }));
              }}
              maxLength={128}
              autoComplete="new-password"
            />
            {errors.confirm_password && (
              <p className="text-sm text-destructive" role="alert">
                {errors.confirm_password}
              </p>
            )}
          </div>

          <Button
            type="submit"
            disabled={changePassword.isPending}
          >
            {changePassword.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
            )}
            Change password
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

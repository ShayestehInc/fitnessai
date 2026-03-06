"use client";

import { useState } from "react";
import { z } from "zod";
import { toast } from "sonner";
import { useCreateInvitation } from "@/hooks/use-invitations";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SlideOverPanel } from "@/components/ui/slide-over-panel";
import { Loader2, Plus } from "lucide-react";
import { ApiError } from "@/lib/api-client";

const invitationSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  message: z.string().optional(),
  expires_days: z.coerce
    .number()
    .int()
    .min(1, "Must be at least 1 day")
    .max(30, "Must be at most 30 days")
    .optional(),
});

interface CreateInvitationPanelProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateInvitationPanel({
  open,
  onOpenChange,
}: CreateInvitationPanelProps) {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [expiresInDays, setExpiresInDays] = useState("7");
  const [error, setError] = useState<string | null>(null);
  const createInvitation = useCreateInvitation();

  function resetForm() {
    setEmail("");
    setMessage("");
    setExpiresInDays("7");
    setError(null);
  }

  function handleOpenChange(v: boolean) {
    onOpenChange(v);
    if (!v) resetForm();
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (createInvitation.isPending) return;
    setError(null);

    const result = invitationSchema.safeParse({
      email,
      message: message || undefined,
      expires_days: expiresInDays ? Number(expiresInDays) : undefined,
    });

    if (!result.success) {
      setError(result.error.issues[0].message);
      return;
    }

    try {
      await createInvitation.mutateAsync(result.data);
      toast.success("Invitation sent", {
        description: `Invitation sent to ${email}`,
      });
      resetForm();
      onOpenChange(false);
    } catch (err) {
      if (err instanceof ApiError && err.body && typeof err.body === "object") {
        const body = err.body as Record<string, string[]>;
        const firstError = Object.values(body).flat()[0];
        setError(firstError ?? "Failed to send invitation");
      } else {
        setError("Failed to send invitation");
      }
    }
  }

  return (
    <SlideOverPanel
      open={open}
      onOpenChange={handleOpenChange}
      title="Invite a Trainee"
      description="Send an invitation to a new trainee. They'll receive a code to sign up."
      width="sm"
      footer={
        <>
          <Button
            type="button"
            variant="outline"
            onClick={() => handleOpenChange(false)}
            disabled={createInvitation.isPending}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="invitation-form"
            disabled={createInvitation.isPending}
          >
            {createInvitation.isPending ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Sending...
              </>
            ) : (
              "Send Invitation"
            )}
          </Button>
        </>
      }
    >
      <form id="invitation-form" onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div
            className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
            role="alert"
            aria-live="assertive"
          >
            {error}
          </div>
        )}
        <div className="space-y-2">
          <Label htmlFor="invite-email">Email</Label>
          <Input
            id="invite-email"
            type="email"
            placeholder="trainee@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            maxLength={254}
            disabled={createInvitation.isPending}
            required
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="invite-message">Message (optional)</Label>
          <Input
            id="invite-message"
            placeholder="Welcome to my training program!"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            maxLength={500}
            disabled={createInvitation.isPending}
          />
          {message.length > 0 && (
            <p className="text-xs text-muted-foreground">
              {message.length}/500
            </p>
          )}
        </div>
        <div className="space-y-2">
          <Label htmlFor="invite-expires">Expires in (days)</Label>
          <Input
            id="invite-expires"
            type="number"
            min={1}
            max={30}
            step={1}
            value={expiresInDays}
            onChange={(e) => setExpiresInDays(e.target.value)}
            disabled={createInvitation.isPending}
          />
        </div>
      </form>
    </SlideOverPanel>
  );
}

/** Convenience trigger button for use in page headers. */
export function CreateInvitationTrigger({
  onClick,
}: {
  onClick: () => void;
}) {
  return (
    <Button onClick={onClick}>
      <Plus className="mr-2 h-4 w-4" />
      New Invitation
    </Button>
  );
}

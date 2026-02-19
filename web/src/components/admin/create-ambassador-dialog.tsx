"use client";

import { useCallback, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useCreateAmbassador } from "@/hooks/use-admin-ambassadors";
import { getErrorMessage } from "@/lib/error-utils";

interface CreateAmbassadorDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateAmbassadorDialog({
  open,
  onOpenChange,
}: CreateAmbassadorDialogProps) {
  const [email, setEmail] = useState("");
  const [commissionRate, setCommissionRate] = useState("10");
  const [referralCode, setReferralCode] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateAmbassador();

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (!email.trim() || !email.includes("@")) {
        newErrors.email = "Valid email is required";
      }

      const rate = Number(commissionRate);
      if (isNaN(rate) || rate < 1 || rate > 50) {
        newErrors.commission = "Commission rate must be between 1% and 50%";
      }

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      createMutation.mutate(
        {
          email: email.trim(),
          commission_rate: rate,
          referral_code: referralCode.trim() || undefined,
        },
        {
          onSuccess: () => {
            toast.success("Ambassador created");
            onOpenChange(false);
            setEmail("");
            setCommissionRate("10");
            setReferralCode("");
            setErrors({});
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [email, commissionRate, referralCode, createMutation, onOpenChange],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Add Ambassador</DialogTitle>
          <DialogDescription>
            Create a new ambassador account with referral capabilities.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="amb-email">Email</Label>
            <Input
              id="amb-email"
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setErrors((prev) => ({ ...prev, email: "" }));
              }}
              placeholder="ambassador@example.com"
              aria-invalid={Boolean(errors.email)}
            />
            {errors.email && (
              <p className="text-sm text-destructive">{errors.email}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="amb-commission">Commission Rate (%)</Label>
            <Input
              id="amb-commission"
              type="number"
              value={commissionRate}
              onChange={(e) => {
                setCommissionRate(e.target.value);
                setErrors((prev) => ({ ...prev, commission: "" }));
              }}
              min={1}
              max={50}
              step={1}
              aria-invalid={Boolean(errors.commission)}
            />
            {errors.commission && (
              <p className="text-sm text-destructive">{errors.commission}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="amb-code">
              Referral Code (optional, auto-generated if empty)
            </Label>
            <Input
              id="amb-code"
              value={referralCode}
              onChange={(e) =>
                setReferralCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, ""))
              }
              placeholder="AMBASSADOR10"
              maxLength={20}
            />
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={createMutation.isPending}>
              {createMutation.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Create
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

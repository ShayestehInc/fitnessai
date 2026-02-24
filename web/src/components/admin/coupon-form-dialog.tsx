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
import { useCreateCoupon, useUpdateCoupon } from "@/hooks/use-admin-coupons";
import { SELECT_CLASSES_FULL_WIDTH } from "@/lib/admin-constants";
import type {
  AdminCoupon,
  CreateCouponPayload,
  UpdateCouponPayload,
} from "@/types/admin";

interface CouponFormDialogProps {
  coupon: AdminCoupon | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const COUPON_TYPES = [
  { value: "percent", label: "Percentage (%)" },
  { value: "fixed", label: "Fixed Amount ($)" },
  { value: "free_trial", label: "Free Trial (days)" },
];

const APPLIES_TO_OPTIONS = [
  { value: "trainer", label: "Trainer Subscription" },
  { value: "trainee", label: "Trainee Coaching" },
  { value: "both", label: "Both" },
];

const AVAILABLE_TIERS = ["FREE", "STARTER", "PRO", "ENTERPRISE"];

export function CouponFormDialog({
  coupon,
  open,
  onOpenChange,
}: CouponFormDialogProps) {
  const isEdit = coupon !== null;
  const createCoupon = useCreateCoupon();
  const updateCoupon = useUpdateCoupon();

  const [code, setCode] = useState(coupon?.code ?? "");
  const [description, setDescription] = useState(coupon?.description ?? "");
  const [couponType, setCouponType] = useState(coupon?.coupon_type ?? "percent");
  const [discountValue, setDiscountValue] = useState(
    coupon?.discount_value ?? "",
  );
  const [appliesTo, setAppliesTo] = useState(coupon?.applies_to ?? "both");
  const [maxUses, setMaxUses] = useState(
    coupon ? String(coupon.max_uses) : "0",
  );
  const [maxUsesPerUser, setMaxUsesPerUser] = useState(
    coupon ? String(coupon.max_uses_per_user) : "1",
  );
  const [applicableTiers, setApplicableTiers] = useState<string[]>(
    coupon?.applicable_tiers ?? [],
  );
  const [validUntil, setValidUntil] = useState(
    coupon?.valid_until ? coupon.valid_until.slice(0, 16) : "",
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  function handleTierToggle(tier: string) {
    setApplicableTiers((prev) =>
      prev.includes(tier) ? prev.filter((t) => t !== tier) : [...prev, tier],
    );
  }

  function validate(): boolean {
    const newErrors: Record<string, string> = {};

    if (!isEdit) {
      const cleanCode = code.toUpperCase().replace(/\s/g, "");
      if (!cleanCode) newErrors.code = "Code is required";
      else if (!/^[A-Z0-9]+$/.test(cleanCode))
        newErrors.code = "Code must be alphanumeric";
    }

    const value = parseFloat(discountValue);
    if (isNaN(value) || value <= 0)
      newErrors.discount_value = "Discount value must be positive";
    if (couponType === "percent" && value > 100)
      newErrors.discount_value = "Percentage discount cannot exceed 100%";

    const maxUsesNum = parseInt(maxUses, 10);
    if (isNaN(maxUsesNum) || maxUsesNum < 0)
      newErrors.max_uses = "Must be 0 or greater";

    const maxPerUserNum = parseInt(maxUsesPerUser, 10);
    if (isNaN(maxPerUserNum) || maxPerUserNum < 1)
      newErrors.max_uses_per_user = "Must be 1 or greater";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;

    try {
      if (isEdit && coupon) {
        const payload: UpdateCouponPayload = {
          description: description.trim(),
          discount_value: parseFloat(discountValue).toFixed(2),
          applicable_tiers: applicableTiers,
          max_uses: parseInt(maxUses, 10),
          max_uses_per_user: parseInt(maxUsesPerUser, 10),
          valid_until: validUntil ? new Date(validUntil).toISOString() : null,
        };
        await updateCoupon.mutateAsync({ id: coupon.id, data: payload });
        toast.success(`Coupon "${coupon.code}" updated`);
      } else {
        const payload: CreateCouponPayload = {
          code: code.toUpperCase().replace(/\s/g, ""),
          description: description.trim(),
          coupon_type: couponType,
          discount_value: parseFloat(discountValue).toFixed(2),
          applies_to: appliesTo,
          applicable_tiers: applicableTiers,
          max_uses: parseInt(maxUses, 10),
          max_uses_per_user: parseInt(maxUsesPerUser, 10),
          valid_from: new Date().toISOString(),
          valid_until: validUntil
            ? new Date(validUntil).toISOString()
            : null,
        };
        await createCoupon.mutateAsync(payload);
        toast.success(`Coupon "${payload.code}" created`);
      }
      onOpenChange(false);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  const isPending = createCoupon.isPending || updateCoupon.isPending;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] max-w-lg overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Edit Coupon" : "Create Coupon"}
          </DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update coupon details"
              : "Create a new discount coupon"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isEdit && (
            <div className="space-y-1">
              <Label htmlFor="coupon-code">Code</Label>
              <Input
                id="coupon-code"
                value={code}
                onChange={(e) =>
                  setCode(e.target.value.toUpperCase().replace(/\s/g, ""))
                }
                placeholder="SUMMER2026"
                maxLength={50}
                aria-invalid={!!errors.code}
                aria-describedby={
                  errors.code ? "coupon-code-error" : undefined
                }
              />
              {errors.code && (
                <p id="coupon-code-error" className="text-xs text-destructive">
                  {errors.code}
                </p>
              )}
            </div>
          )}

          <div className="space-y-1">
            <Label htmlFor="coupon-description">Description</Label>
            <Input
              id="coupon-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Summer promotional discount"
            />
          </div>

          {!isEdit && (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div className="space-y-1">
                <Label htmlFor="coupon-type">Type</Label>
                <select
                  id="coupon-type"
                  value={couponType}
                  onChange={(e) => setCouponType(e.target.value)}
                  className={SELECT_CLASSES_FULL_WIDTH}
                >
                  {COUPON_TYPES.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-1">
                <Label htmlFor="coupon-applies-to">Applies To</Label>
                <select
                  id="coupon-applies-to"
                  value={appliesTo}
                  onChange={(e) => setAppliesTo(e.target.value)}
                  className={SELECT_CLASSES_FULL_WIDTH}
                >
                  {APPLIES_TO_OPTIONS.map((o) => (
                    <option key={o.value} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          )}

          <div className="space-y-1">
            <Label htmlFor="coupon-discount">Discount Value</Label>
            <Input
              id="coupon-discount"
              type="number"
              min="0.01"
              step="0.01"
              value={discountValue}
              onChange={(e) => setDiscountValue(e.target.value)}
              placeholder={
                couponType === "percent"
                  ? "25"
                  : couponType === "free_trial"
                    ? "14"
                    : "10.00"
              }
              aria-invalid={!!errors.discount_value}
              aria-describedby={
                errors.discount_value ? "coupon-discount-error" : undefined
              }
            />
            {errors.discount_value && (
              <p
                id="coupon-discount-error"
                className="text-xs text-destructive"
              >
                {errors.discount_value}
              </p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <Label htmlFor="coupon-max-uses">
                Max Uses (0 = unlimited)
              </Label>
              <Input
                id="coupon-max-uses"
                type="number"
                min="0"
                value={maxUses}
                onChange={(e) => setMaxUses(e.target.value)}
                aria-invalid={!!errors.max_uses}
                aria-describedby={
                  errors.max_uses ? "coupon-max-uses-error" : undefined
                }
              />
              {errors.max_uses && (
                <p
                  id="coupon-max-uses-error"
                  className="text-xs text-destructive"
                >
                  {errors.max_uses}
                </p>
              )}
            </div>
            <div className="space-y-1">
              <Label htmlFor="coupon-max-per-user">Max Uses Per User</Label>
              <Input
                id="coupon-max-per-user"
                type="number"
                min="1"
                value={maxUsesPerUser}
                onChange={(e) => setMaxUsesPerUser(e.target.value)}
                aria-invalid={!!errors.max_uses_per_user}
                aria-describedby={
                  errors.max_uses_per_user
                    ? "coupon-max-per-user-error"
                    : undefined
                }
              />
              {errors.max_uses_per_user && (
                <p
                  id="coupon-max-per-user-error"
                  className="text-xs text-destructive"
                >
                  {errors.max_uses_per_user}
                </p>
              )}
            </div>
          </div>

          <div className="space-y-2">
            <Label>Applicable Tiers (leave empty for all tiers)</Label>
            <div className="flex flex-wrap gap-3">
              {AVAILABLE_TIERS.map((tier) => (
                <label
                  key={tier}
                  className="flex items-center gap-1.5 text-sm cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={applicableTiers.includes(tier)}
                    onChange={() => handleTierToggle(tier)}
                    className="h-4 w-4 rounded border-input accent-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                  />
                  {tier}
                </label>
              ))}
            </div>
            <p className="text-xs text-muted-foreground">
              Select specific tiers this coupon applies to, or leave all
              unchecked to apply to all tiers.
            </p>
          </div>

          <div className="space-y-1">
            <Label htmlFor="coupon-valid-until">
              Valid Until (optional)
            </Label>
            <Input
              id="coupon-valid-until"
              type="datetime-local"
              value={validUntil}
              onChange={(e) => setValidUntil(e.target.value)}
            />
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              {isEdit ? "Update Coupon" : "Create Coupon"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

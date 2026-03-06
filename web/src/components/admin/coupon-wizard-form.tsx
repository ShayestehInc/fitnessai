"use client";

import { useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { StepWizard, type WizardStep } from "@/components/ui/step-wizard";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { getErrorMessage } from "@/lib/error-utils";
import { useCreateCoupon, useUpdateCoupon } from "@/hooks/use-admin-coupons";
import { SELECT_CLASSES_FULL_WIDTH } from "@/lib/admin-constants";
import type {
  AdminCoupon,
  CreateCouponPayload,
  UpdateCouponPayload,
} from "@/types/admin";

interface CouponWizardFormProps {
  coupon?: AdminCoupon | null;
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

export function CouponWizardForm({ coupon }: CouponWizardFormProps) {
  const router = useRouter();
  const isEdit = coupon != null;
  const createCoupon = useCreateCoupon();
  const updateCoupon = useUpdateCoupon();

  // Step 1: Type & Code
  const [code, setCode] = useState(coupon?.code ?? "");
  const [couponType, setCouponType] = useState(coupon?.coupon_type ?? "percent");
  const [appliesTo, setAppliesTo] = useState(coupon?.applies_to ?? "both");
  const [description, setDescription] = useState(coupon?.description ?? "");

  // Step 2: Value & Limits
  const [discountValue, setDiscountValue] = useState(
    coupon?.discount_value ?? "",
  );
  const [maxUses, setMaxUses] = useState(
    coupon ? String(coupon.max_uses) : "0",
  );
  const [maxUsesPerUser, setMaxUsesPerUser] = useState(
    coupon ? String(coupon.max_uses_per_user) : "1",
  );

  // Step 3: Scope & Duration
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

  const validateTypeAndCode = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    if (!isEdit) {
      const cleanCode = code.toUpperCase().replace(/\s/g, "");
      if (!cleanCode) newErrors.code = "Code is required";
      else if (!/^[A-Z0-9]+$/.test(cleanCode))
        newErrors.code = "Code must be alphanumeric";
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [code, isEdit]);

  const validateValueAndLimits = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
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
  }, [discountValue, couponType, maxUses, maxUsesPerUser]);

  const isPending = createCoupon.isPending || updateCoupon.isPending;

  const handleComplete = useCallback(async () => {
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
          valid_until: validUntil ? new Date(validUntil).toISOString() : null,
        };
        await createCoupon.mutateAsync(payload);
        toast.success(`Coupon "${payload.code}" created`);
      }
      router.push("/admin/coupons");
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }, [
    isEdit, coupon, code, description, couponType, discountValue,
    appliesTo, applicableTiers, maxUses, maxUsesPerUser, validUntil,
    createCoupon, updateCoupon, router,
  ]);

  const typeLabel =
    COUPON_TYPES.find((t) => t.value === couponType)?.label ?? couponType;
  const appliesToLabel =
    APPLIES_TO_OPTIONS.find((o) => o.value === appliesTo)?.label ?? appliesTo;

  const steps: WizardStep[] = useMemo(
    () => [
      {
        label: "Type & Code",
        description: "Set the coupon code and type.",
        validate: validateTypeAndCode,
        content: (
          <div className="space-y-4">
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
            {isEdit && (
              <div className="space-y-1">
                <Label>Code</Label>
                <p className="font-mono font-medium">{coupon?.code}</p>
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
          </div>
        ),
      },
      {
        label: "Value & Limits",
        description: "Set the discount value and usage limits.",
        validate: validateValueAndLimits,
        content: (
          <div className="space-y-4">
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
                <p id="coupon-discount-error" className="text-xs text-destructive">
                  {errors.discount_value}
                </p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <Label htmlFor="coupon-max-uses">Max Uses (0 = unlimited)</Label>
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
                  <p id="coupon-max-uses-error" className="text-xs text-destructive">
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
                  <p id="coupon-max-per-user-error" className="text-xs text-destructive">
                    {errors.max_uses_per_user}
                  </p>
                )}
              </div>
            </div>
          </div>
        ),
      },
      {
        label: "Scope & Duration",
        description: "Choose applicable tiers and expiration.",
        content: (
          <div className="space-y-4">
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
              <Label htmlFor="coupon-valid-until">Valid Until (optional)</Label>
              <Input
                id="coupon-valid-until"
                type="datetime-local"
                value={validUntil}
                onChange={(e) => setValidUntil(e.target.value)}
              />
            </div>
          </div>
        ),
      },
      {
        label: "Review",
        description: "Review your coupon details before saving.",
        content: (
          <div className="space-y-4">
            <div className="rounded-lg border p-4 space-y-3">
              <div className="flex items-center gap-2">
                <h3 className="font-mono font-semibold text-lg">
                  {isEdit ? coupon?.code : code.toUpperCase() || "—"}
                </h3>
                <Badge variant="outline">{typeLabel}</Badge>
              </div>
              {description && (
                <p className="text-sm text-muted-foreground">{description}</p>
              )}
              <Separator />
              <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
                <div>
                  <p className="text-muted-foreground">Discount</p>
                  <p className="font-medium">
                    {couponType === "percent"
                      ? `${discountValue}%`
                      : couponType === "free_trial"
                        ? `${discountValue} days`
                        : `$${discountValue}`}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Applies To</p>
                  <p className="font-medium">{appliesToLabel}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Max Uses</p>
                  <p className="font-medium">
                    {parseInt(maxUses, 10) === 0 ? "Unlimited" : maxUses}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Max Per User</p>
                  <p className="font-medium">{maxUsesPerUser}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Expires</p>
                  <p className="font-medium">
                    {validUntil
                      ? new Date(validUntil).toLocaleDateString()
                      : "Never"}
                  </p>
                </div>
              </div>
              {applicableTiers.length > 0 && (
                <>
                  <Separator />
                  <div>
                    <p className="mb-2 text-sm text-muted-foreground">
                      Applicable Tiers
                    </p>
                    <div className="flex flex-wrap gap-1">
                      {applicableTiers.map((t) => (
                        <Badge key={t} variant="secondary">
                          {t}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        ),
      },
    ],
    [
      code, description, couponType, appliesTo, isEdit, coupon, errors,
      discountValue, maxUses, maxUsesPerUser,
      applicableTiers, validUntil,
      typeLabel, appliesToLabel,
      validateTypeAndCode, validateValueAndLimits,
    ],
  );

  return (
    <StepWizard
      title={isEdit ? "Edit Coupon" : "Create Coupon"}
      steps={steps}
      onComplete={handleComplete}
      onCancel={() => router.push("/admin/coupons")}
      submitLabel={isEdit ? "Update Coupon" : "Create Coupon"}
      isSubmitting={isPending}
    />
  );
}

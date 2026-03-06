"use client";

import { useState, useCallback, useMemo } from "react";
import { Plus, X, Check, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { StepWizard, type WizardStep } from "@/components/ui/step-wizard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { getErrorMessage } from "@/lib/error-utils";
import { useCreateTier, useUpdateTier } from "@/hooks/use-admin-tiers";
import type { AdminSubscriptionTier, CreateTierPayload } from "@/types/admin";
import { useLocale } from "@/providers/locale-provider";

interface TierWizardFormProps {
  tier?: AdminSubscriptionTier | null;
}

export function TierWizardForm({ tier }: TierWizardFormProps) {
  const { t } = useLocale();
  const router = useRouter();
  const isEdit = tier != null;
  const createTier = useCreateTier();
  const updateTier = useUpdateTier();

  // Step 1: Basic Info
  const [name, setName] = useState(tier?.name ?? "");
  const [displayName, setDisplayName] = useState(tier?.display_name ?? "");
  const [description, setDescription] = useState(tier?.description ?? "");
  const [isActive, setIsActive] = useState(tier?.is_active ?? true);
  const [sortOrder, setSortOrder] = useState(
    tier ? String(tier.sort_order) : "0",
  );

  // Step 2: Pricing
  const [price, setPrice] = useState(tier?.price ?? "");
  const [traineeLimit, setTraineeLimit] = useState(
    tier ? String(tier.trainee_limit) : "0",
  );
  const [stripePriceId, setStripePriceId] = useState(
    tier?.stripe_price_id ?? "",
  );

  // Step 3: Features
  const [features, setFeatures] = useState<string[]>(tier?.features ?? []);
  const [featureInput, setFeatureInput] = useState("");

  // Validation
  const [errors, setErrors] = useState<Record<string, string>>({});

  function addFeature() {
    const trimmed = featureInput.trim();
    if (trimmed && !features.includes(trimmed)) {
      setFeatures([...features, trimmed]);
    }
    setFeatureInput("");
  }

  function removeFeature(index: number) {
    setFeatures(features.filter((_, i) => i !== index));
  }

  const validateBasicInfo = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    if (!name.trim()) newErrors.name = "Name is required";
    if (!displayName.trim()) newErrors.display_name = "Display name is required";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [name, displayName]);

  const validatePricing = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    const priceNum = parseFloat(price);
    if (isNaN(priceNum) || priceNum < 0)
      newErrors.price = "Price must be a non-negative number";
    const limitNum = parseInt(traineeLimit, 10);
    if (isNaN(limitNum) || limitNum < 0)
      newErrors.trainee_limit = "Trainee limit must be 0 or greater";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [price, traineeLimit]);

  const isPending = createTier.isPending || updateTier.isPending;

  const handleComplete = useCallback(async () => {
    const payload: CreateTierPayload = {
      name: name.toUpperCase().trim(),
      display_name: displayName.trim(),
      description: description.trim(),
      price: parseFloat(price).toFixed(2),
      trainee_limit: parseInt(traineeLimit, 10),
      features,
      stripe_price_id: stripePriceId.trim(),
      is_active: isActive,
      sort_order: parseInt(sortOrder, 10) || 0,
    };

    try {
      if (isEdit && tier) {
        await updateTier.mutateAsync({ id: tier.id, data: payload });
        toast.success(`Tier "${displayName}" updated`);
      } else {
        await createTier.mutateAsync(payload);
        toast.success(`Tier "${displayName}" created`);
      }
      router.push("/admin/tiers");
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }, [
    name, displayName, description, price, traineeLimit,
    features, stripePriceId, isActive, sortOrder,
    isEdit, tier, createTier, updateTier, router,
  ]);

  const steps: WizardStep[] = useMemo(
    () => [
      {
        label: "Basic Info",
        description: "Set the tier name and description.",
        validate: validateBasicInfo,
        content: (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <Label htmlFor="tier-name">{t("common.name")}</Label>
                <Input
                  id="tier-name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="PRO"
                  disabled={isEdit}
                  aria-invalid={!!errors.name}
                  aria-describedby={errors.name ? "tier-name-error" : undefined}
                />
                {errors.name && (
                  <p id="tier-name-error" className="text-xs text-destructive">
                    {errors.name}
                  </p>
                )}
              </div>
              <div className="space-y-1">
                <Label htmlFor="tier-display-name">{t("admin.displayName")}</Label>
                <Input
                  id="tier-display-name"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Pro"
                  aria-invalid={!!errors.display_name}
                  aria-describedby={
                    errors.display_name ? "tier-display-name-error" : undefined
                  }
                />
                {errors.display_name && (
                  <p id="tier-display-name-error" className="text-xs text-destructive">
                    {errors.display_name}
                  </p>
                )}
              </div>
            </div>

            <div className="space-y-1">
              <Label htmlFor="tier-description">{t("common.description")}</Label>
              <Input
                id="tier-description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="For professional trainers"
              />
            </div>

            <div className="space-y-1">
              <Label htmlFor="tier-sort">{t("admin.sortOrder")}</Label>
              <Input
                id="tier-sort"
                type="number"
                min="0"
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value)}
                className="w-24"
              />
            </div>

            <div className="flex items-center gap-2">
              <input
                id="tier-active"
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="h-4 w-4 rounded border-input accent-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              />
              <Label htmlFor="tier-active" className="cursor-pointer">
                Active
              </Label>
            </div>
          </div>
        ),
      },
      {
        label: "Pricing",
        description: "Configure pricing and limits.",
        validate: validatePricing,
        content: (
          <div className="space-y-4">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div className="space-y-1">
                <Label htmlFor="tier-price">Price ($/mo)</Label>
                <Input
                  id="tier-price"
                  type="number"
                  min="0"
                  step="0.01"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="79.00"
                  aria-invalid={!!errors.price}
                  aria-describedby={errors.price ? "tier-price-error" : undefined}
                />
                {errors.price && (
                  <p id="tier-price-error" className="text-xs text-destructive">
                    {errors.price}
                  </p>
                )}
              </div>
              <div className="space-y-1">
                <Label htmlFor="tier-limit">{t("admin.traineeLimit")}</Label>
                <Input
                  id="tier-limit"
                  type="number"
                  min="0"
                  value={traineeLimit}
                  onChange={(e) => setTraineeLimit(e.target.value)}
                  placeholder="0 = unlimited"
                  aria-invalid={!!errors.trainee_limit}
                  aria-describedby={
                    errors.trainee_limit ? "tier-limit-error" : undefined
                  }
                />
                {errors.trainee_limit && (
                  <p id="tier-limit-error" className="text-xs text-destructive">
                    {errors.trainee_limit}
                  </p>
                )}
              </div>
            </div>

            <div className="space-y-1">
              <Label htmlFor="tier-stripe-price">Stripe Price ID (optional)</Label>
              <Input
                id="tier-stripe-price"
                value={stripePriceId}
                onChange={(e) => setStripePriceId(e.target.value)}
                placeholder="price_..."
              />
            </div>
          </div>
        ),
      },
      {
        label: "Features",
        description: "Add features included in this tier.",
        content: (
          <div className="space-y-4">
            <div className="flex gap-2">
              <Input
                value={featureInput}
                onChange={(e) => setFeatureInput(e.target.value)}
                placeholder={t("featureRequests.addFeature")}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    addFeature();
                  }
                }}
                aria-label="New feature"
              />
              <Button
                type="button"
                variant="outline"
                size="icon"
                onClick={addFeature}
                aria-label="Add feature"
              >
                <Plus className="h-4 w-4" />
              </Button>
            </div>
            {features.length > 0 ? (
              <div className="flex flex-wrap gap-1">
                {features.map((feature, i) => (
                  <span
                    key={i}
                    className="inline-flex items-center gap-1 rounded-md bg-muted px-2 py-1 text-xs"
                  >
                    {feature}
                    <button
                      type="button"
                      onClick={() => removeFeature(i)}
                      className="hover:text-destructive"
                      aria-label={`Remove feature: ${feature}`}
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                No features added yet. Type a feature and press Enter or click +.
              </p>
            )}
          </div>
        ),
      },
      {
        label: "Review",
        description: "Review your tier details before saving.",
        content: (
          <div className="space-y-4">
            <div className="rounded-lg border p-4 space-y-3">
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-lg">{displayName || "Untitled"}</h3>
                <Badge variant={isActive ? "default" : "secondary"}>
                  {isActive ? "Active" : "Inactive"}
                </Badge>
              </div>
              {description && (
                <p className="text-sm text-muted-foreground">{description}</p>
              )}
              <Separator />
              <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
                <div>
                  <p className="text-muted-foreground">{t("common.name")}</p>
                  <p className="font-medium">{name.toUpperCase() || "—"}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">{t("admin.price")}</p>
                  <p className="font-medium">
                    {price ? `$${parseFloat(price).toFixed(2)}/mo` : "—"}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">{t("admin.traineeLimit")}</p>
                  <p className="font-medium">
                    {parseInt(traineeLimit, 10) === 0
                      ? "Unlimited"
                      : traineeLimit}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">{t("admin.sortOrder")}</p>
                  <p className="font-medium">{sortOrder}</p>
                </div>
                {stripePriceId && (
                  <div className="col-span-2">
                    <p className="text-muted-foreground">Stripe Price ID</p>
                    <p className="font-medium font-mono text-xs">{stripePriceId}</p>
                  </div>
                )}
              </div>
              {features.length > 0 && (
                <>
                  <Separator />
                  <div>
                    <p className="mb-2 text-sm text-muted-foreground">{t("admin.features")}</p>
                    <div className="flex flex-wrap gap-1">
                      {features.map((f, i) => (
                        <span
                          key={i}
                          className="inline-flex items-center gap-1 rounded-md bg-muted px-2 py-1 text-xs"
                        >
                          <Check className="h-3 w-3 text-green-600" aria-hidden="true" />
                          {f}
                        </span>
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
      name, displayName, description, isActive, sortOrder, errors,
      price, traineeLimit, stripePriceId,
      features, featureInput, isEdit,
      validateBasicInfo, validatePricing,
    ],
  );

  return (
    <StepWizard
      title={isEdit ? "Edit Tier" : "Create Tier"}
      steps={steps}
      onComplete={handleComplete}
      onCancel={() => router.push("/admin/tiers")}
      submitLabel={isEdit ? "Update Tier" : "Create Tier"}
      isSubmitting={isPending}
    />
  );
}

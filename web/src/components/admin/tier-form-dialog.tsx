"use client";

import { useState } from "react";
import { Loader2, Plus, X } from "lucide-react";
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
import { useCreateTier, useUpdateTier } from "@/hooks/use-admin-tiers";
import type { AdminSubscriptionTier, CreateTierPayload } from "@/types/admin";

interface TierFormDialogProps {
  tier: AdminSubscriptionTier | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function TierFormDialog({
  tier,
  open,
  onOpenChange,
}: TierFormDialogProps) {
  const isEdit = tier !== null;
  const createTier = useCreateTier();
  const updateTier = useUpdateTier();

  const [name, setName] = useState(tier?.name ?? "");
  const [displayName, setDisplayName] = useState(tier?.display_name ?? "");
  const [description, setDescription] = useState(tier?.description ?? "");
  const [price, setPrice] = useState(tier?.price ?? "");
  const [traineeLimit, setTraineeLimit] = useState(
    tier ? String(tier.trainee_limit) : "0",
  );
  const [features, setFeatures] = useState<string[]>(tier?.features ?? []);
  const [featureInput, setFeatureInput] = useState("");
  const [stripePriceId, setStripePriceId] = useState(
    tier?.stripe_price_id ?? "",
  );
  const [isActive, setIsActive] = useState(tier?.is_active ?? true);
  const [sortOrder, setSortOrder] = useState(
    tier ? String(tier.sort_order) : "0",
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate(): boolean {
    const newErrors: Record<string, string> = {};
    if (!name.trim()) newErrors.name = "Name is required";
    if (!displayName.trim()) newErrors.display_name = "Display name is required";
    const priceNum = parseFloat(price);
    if (isNaN(priceNum) || priceNum < 0)
      newErrors.price = "Price must be a non-negative number";
    const limitNum = parseInt(traineeLimit, 10);
    if (isNaN(limitNum) || limitNum < 0)
      newErrors.trainee_limit = "Trainee limit must be 0 or greater";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

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

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;

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
      onOpenChange(false);
    } catch (error) {
      const message = getErrorMessage(error);
      toast.error(message);
    }
  }

  const isPending = createTier.isPending || updateTier.isPending;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] max-w-lg overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Tier" : "Create Tier"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update subscription tier details"
              : "Create a new subscription tier"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <Label htmlFor="tier-name">Name</Label>
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
              <Label htmlFor="tier-display-name">Display Name</Label>
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
                <p
                  id="tier-display-name-error"
                  className="text-xs text-destructive"
                >
                  {errors.display_name}
                </p>
              )}
            </div>
          </div>

          <div className="space-y-1">
            <Label htmlFor="tier-description">Description</Label>
            <Input
              id="tier-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="For professional trainers"
            />
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
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
              <Label htmlFor="tier-limit">Trainee Limit</Label>
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
                <p
                  id="tier-limit-error"
                  className="text-xs text-destructive"
                >
                  {errors.trainee_limit}
                </p>
              )}
            </div>
            <div className="space-y-1">
              <Label htmlFor="tier-sort">Sort Order</Label>
              <Input
                id="tier-sort"
                type="number"
                min="0"
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value)}
              />
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

          <div className="space-y-2">
            <Label>Features</Label>
            <div className="flex gap-2">
              <Input
                value={featureInput}
                onChange={(e) => setFeatureInput(e.target.value)}
                placeholder="Add a feature..."
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
            {features.length > 0 && (
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
            )}
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
              {isEdit ? "Update Tier" : "Create Tier"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

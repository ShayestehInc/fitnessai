"use client";

import { useCallback, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { SlideOverPanel } from "@/components/ui/slide-over-panel";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useCreateAmbassador } from "@/hooks/use-admin-ambassadors";
import { getErrorMessage } from "@/lib/error-utils";
import { useLocale } from "@/providers/locale-provider";

interface CreateAmbassadorPanelProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateAmbassadorPanel({
  open,
  onOpenChange,
}: CreateAmbassadorPanelProps) {
  const { t } = useLocale();
  const [email, setEmail] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [password, setPassword] = useState("");
  const [commissionRate, setCommissionRate] = useState("20");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const createMutation = useCreateAmbassador();

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (!email.trim() || !email.includes("@")) {
        newErrors.email = "Valid email is required";
      }
      if (!firstName.trim()) {
        newErrors.firstName = "First name is required";
      }
      if (!lastName.trim()) {
        newErrors.lastName = "Last name is required";
      }
      if (!password || password.length < 8) {
        newErrors.password = "Password must be at least 8 characters";
      } else if (/^\d+$/.test(password)) {
        newErrors.password = "Password cannot be entirely numeric";
      }

      const rate = Number(commissionRate);
      if (isNaN(rate) || rate < 0 || rate > 100) {
        newErrors.commission = "Commission rate must be between 0% and 100%";
      }

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      createMutation.mutate(
        {
          email: email.trim(),
          first_name: firstName.trim(),
          last_name: lastName.trim(),
          password,
          commission_rate: rate,
        },
        {
          onSuccess: () => {
            toast.success(t("admin.ambassadorCreated"));
            onOpenChange(false);
            setEmail("");
            setFirstName("");
            setLastName("");
            setPassword("");
            setCommissionRate("20");
            setErrors({});
          },
          onError: (err) => toast.error(getErrorMessage(err)),
        },
      );
    },
    [email, firstName, lastName, password, commissionRate, createMutation, onOpenChange],
  );

  return (
    <SlideOverPanel
      open={open}
      onOpenChange={onOpenChange}
      title={t("admin.addAmbassador")}
      description={t("admin.createAmbassadorDesc")}
      width="md"
      footer={
        <div className="flex w-full justify-end gap-2">
          <Button
            variant="outline"
            type="button"
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="create-ambassador-form"
            disabled={createMutation.isPending}
          >
            {createMutation.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
            )}
            Create
          </Button>
        </div>
      }
    >
      <form id="create-ambassador-form" onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="amb-email">{t("settings.email")}</Label>
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

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-2">
            <Label htmlFor="amb-first-name">{t("settings.firstName")}</Label>
            <Input
              id="amb-first-name"
              value={firstName}
              onChange={(e) => {
                setFirstName(e.target.value);
                setErrors((prev) => ({ ...prev, firstName: "" }));
              }}
              placeholder="Jane"
              aria-invalid={Boolean(errors.firstName)}
            />
            {errors.firstName && (
              <p className="text-sm text-destructive">{errors.firstName}</p>
            )}
          </div>
          <div className="space-y-2">
            <Label htmlFor="amb-last-name">{t("settings.lastName")}</Label>
            <Input
              id="amb-last-name"
              value={lastName}
              onChange={(e) => {
                setLastName(e.target.value);
                setErrors((prev) => ({ ...prev, lastName: "" }));
              }}
              placeholder="Doe"
              aria-invalid={Boolean(errors.lastName)}
            />
            {errors.lastName && (
              <p className="text-sm text-destructive">{errors.lastName}</p>
            )}
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="amb-password">{t("auth.passwordLabel")}</Label>
          <Input
            id="amb-password"
            type="password"
            value={password}
            onChange={(e) => {
              setPassword(e.target.value);
              setErrors((prev) => ({ ...prev, password: "" }));
            }}
            placeholder={t("settings.minChars")}
            autoComplete="new-password"
            aria-invalid={Boolean(errors.password)}
          />
          {errors.password && (
            <p className="text-sm text-destructive">{errors.password}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="amb-commission">{t("admin.commissionRatePercent")}</Label>
          <Input
            id="amb-commission"
            type="number"
            value={commissionRate}
            onChange={(e) => {
              setCommissionRate(e.target.value);
              setErrors((prev) => ({ ...prev, commission: "" }));
            }}
            min={0}
            max={100}
            step={0.01}
            aria-invalid={Boolean(errors.commission)}
          />
          <p className="text-xs text-muted-foreground">Default: 20%</p>
          {errors.commission && (
            <p className="text-sm text-destructive">{errors.commission}</p>
          )}
        </div>
      </form>
    </SlideOverPanel>
  );
}

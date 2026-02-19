"use client";

import { useCallback, useState } from "react";
import { Copy, Check, Loader2, Pencil } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useAmbassadorReferralCode, useUpdateReferralCode } from "@/hooks/use-ambassador";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";

export function ReferralCodeCard() {
  const { data, isLoading } = useAmbassadorReferralCode();
  const updateMutation = useUpdateReferralCode();
  const [isEditing, setIsEditing] = useState(false);
  const [newCode, setNewCode] = useState("");
  const [copied, setCopied] = useState(false);

  const referralCode = (data as { referral_code?: string })?.referral_code ?? "";

  const handleCopy = useCallback(() => {
    const url = `${window.location.origin}/signup?ref=${referralCode}`;
    navigator.clipboard.writeText(url).then(() => {
      setCopied(true);
      toast.success("Referral link copied!");
      setTimeout(() => setCopied(false), 2000);
    });
  }, [referralCode]);

  const handleSave = useCallback(() => {
    const sanitized = newCode.toUpperCase().replace(/[^A-Z0-9]/g, "");
    if (sanitized.length < 3) {
      toast.error("Code must be at least 3 characters");
      return;
    }
    updateMutation.mutate(sanitized, {
      onSuccess: () => {
        toast.success("Referral code updated");
        setIsEditing(false);
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }, [newCode, updateMutation]);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-32" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-12 w-full" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Your Referral Code</CardTitle>
        <CardDescription>
          Share this code with trainers to earn commissions
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isEditing ? (
          <div className="flex items-center gap-2">
            <Input
              value={newCode}
              onChange={(e) =>
                setNewCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, ""))
              }
              placeholder="NEW-CODE"
              maxLength={20}
              className="font-mono"
            />
            <Button
              size="sm"
              onClick={handleSave}
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                "Save"
              )}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsEditing(false)}
            >
              Cancel
            </Button>
          </div>
        ) : (
          <div className="flex items-center gap-3">
            <div className="flex-1 rounded-lg border bg-muted/50 px-4 py-3">
              <span className="font-mono text-lg font-bold tracking-wider">
                {referralCode || "NOT SET"}
              </span>
            </div>
            <Button variant="outline" size="icon" onClick={handleCopy} disabled={!referralCode}>
              {copied ? (
                <Check className="h-4 w-4 text-green-600" />
              ) : (
                <Copy className="h-4 w-4" />
              )}
            </Button>
            <Button
              variant="outline"
              size="icon"
              onClick={() => {
                setNewCode(referralCode);
                setIsEditing(true);
              }}
            >
              <Pencil className="h-4 w-4" />
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

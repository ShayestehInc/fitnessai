"use client";

import { useCallback, useRef, useState } from "react";
import { toast } from "sonner";
import { Loader2, Trash2, Upload } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import {
  useUpdateProfile,
  useUploadProfileImage,
  useDeleteProfileImage,
} from "@/hooks/use-settings";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
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

export function ProfileSection() {
  const { user } = useAuth();
  const updateProfile = useUpdateProfile();
  const uploadImage = useUploadProfileImage();
  const deleteImage = useDeleteProfileImage();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [firstName, setFirstName] = useState(user?.first_name ?? "");
  const [lastName, setLastName] = useState(user?.last_name ?? "");
  const [businessName, setBusinessName] = useState(
    user?.business_name ?? "",
  );

  const handleSave = useCallback(() => {
    updateProfile.mutate(
      {
        first_name: firstName,
        last_name: lastName,
        business_name: businessName,
      },
      {
        onSuccess: () => toast.success("Profile updated"),
        onError: () => toast.error("Failed to update profile"),
      },
    );
  }, [firstName, lastName, businessName, updateProfile]);

  const handleImageUpload = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      if (file.size > 5 * 1024 * 1024) {
        toast.error("Image must be under 5MB");
        return;
      }

      const allowed = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
      ];
      if (!allowed.includes(file.type)) {
        toast.error("Only JPEG, PNG, GIF, and WebP are allowed");
        return;
      }

      uploadImage.mutate(file, {
        onSuccess: () => toast.success("Profile image updated"),
        onError: () => toast.error("Failed to upload image"),
      });

      // Reset input so the same file can be re-selected
      e.target.value = "";
    },
    [uploadImage],
  );

  const handleImageRemove = useCallback(() => {
    deleteImage.mutate(undefined, {
      onSuccess: () => toast.success("Profile image removed"),
      onError: () => toast.error("Failed to remove image"),
    });
  }, [deleteImage]);

  const initials = user
    ? `${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase() ||
      user.email.charAt(0).toUpperCase()
    : "?";

  const isImageLoading = uploadImage.isPending || deleteImage.isPending;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Profile</CardTitle>
        <CardDescription>
          Update your personal information and profile image
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Profile Image */}
        <div className="flex items-center gap-4">
          <div className="relative">
            <Avatar className="h-16 w-16">
              {user?.profile_image && (
                <AvatarImage src={user.profile_image} alt="Profile" />
              )}
              <AvatarFallback className="text-lg">{initials}</AvatarFallback>
            </Avatar>
            {isImageLoading && (
              <div className="absolute inset-0 flex items-center justify-center rounded-full bg-black/50">
                <Loader2 className="h-5 w-5 animate-spin text-white" />
              </div>
            )}
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => fileInputRef.current?.click()}
              disabled={isImageLoading}
            >
              <Upload className="mr-1.5 h-3.5 w-3.5" aria-hidden="true" />
              Upload
            </Button>
            {user?.profile_image && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleImageRemove}
                disabled={isImageLoading}
              >
                <Trash2 className="mr-1.5 h-3.5 w-3.5" aria-hidden="true" />
                Remove
              </Button>
            )}
          </div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/png,image/gif,image/webp"
            className="hidden"
            onChange={handleImageUpload}
            aria-label="Upload profile image"
          />
        </div>

        {/* Form Fields */}
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="firstName">First name</Label>
            <Input
              id="firstName"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              maxLength={150}
              placeholder="Your first name"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="lastName">Last name</Label>
            <Input
              id="lastName"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              maxLength={150}
              placeholder="Your last name"
            />
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="businessName">Business name</Label>
          <Input
            id="businessName"
            value={businessName}
            onChange={(e) => setBusinessName(e.target.value)}
            maxLength={200}
            placeholder="Your business or gym name"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="email">Email</Label>
          <Input
            id="email"
            value={user?.email ?? ""}
            disabled
            className="bg-muted"
          />
          <p className="text-xs text-muted-foreground">
            Email cannot be changed
          </p>
        </div>

        <Button
          onClick={handleSave}
          disabled={updateProfile.isPending}
        >
          {updateProfile.isPending && (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
          )}
          Save changes
        </Button>
      </CardContent>
    </Card>
  );
}

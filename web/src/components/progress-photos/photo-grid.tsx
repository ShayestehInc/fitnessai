"use client";

import { useState } from "react";
import { Camera, GitCompare, ImageIcon } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { CategoryFilter } from "./category-filter";
import { PhotoDetailDialog } from "./photo-detail-dialog";
import { UploadDialog } from "./upload-dialog";
import { ComparisonView } from "./comparison-view";
import { useProgressPhotos } from "@/hooks/use-progress-photos";
import type { ProgressPhoto, PhotoCategory } from "@/types/progress";

interface PhotoGridProps {
  traineeId?: number;
  readOnly?: boolean;
}

function PhotoGridSkeleton() {
  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
      {Array.from({ length: 8 }).map((_, i) => (
        <Skeleton key={i} className="aspect-[3/4] w-full rounded-lg" />
      ))}
    </div>
  );
}

export function PhotoGrid({ traineeId, readOnly = false }: PhotoGridProps) {
  const [category, setCategory] = useState<PhotoCategory>("all");
  const [page, setPage] = useState(1);
  const [selectedPhoto, setSelectedPhoto] = useState<ProgressPhoto | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [compareOpen, setCompareOpen] = useState(false);

  const { data, isLoading, isError, refetch } = useProgressPhotos({
    category,
    traineeId,
    page,
  });

  const photos = data?.results ?? [];
  const totalPages = data ? Math.ceil(data.count / 20) : 0;

  // Group photos by date.
  const grouped: Record<string, ProgressPhoto[]> = {};
  for (const photo of photos) {
    const dateKey = photo.date;
    if (!grouped[dateKey]) grouped[dateKey] = [];
    grouped[dateKey].push(photo);
  }
  const sortedDates = Object.keys(grouped).sort((a, b) => b.localeCompare(a));

  function handlePhotoClick(photo: ProgressPhoto) {
    setSelectedPhoto(photo);
    setDetailOpen(true);
  }

  function handleCategoryChange(cat: PhotoCategory) {
    setCategory(cat);
    setPage(1);
  }

  return (
    <div className="space-y-4">
      {/* Header with filter and add button */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <CategoryFilter selected={category} onSelect={handleCategoryChange} />
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCompareOpen(true)}
            disabled={photos.length < 2}
          >
            <GitCompare className="mr-2 h-4 w-4" />
            Compare
          </Button>
          {!readOnly && (
            <Button onClick={() => setUploadOpen(true)} size="sm">
              <Camera className="mr-2 h-4 w-4" />
              Add Photo
            </Button>
          )}
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <PhotoGridSkeleton />
      ) : isError ? (
        <ErrorState
          message="Failed to load progress photos"
          onRetry={() => refetch()}
        />
      ) : photos.length === 0 ? (
        <EmptyState
          icon={ImageIcon}
          title="No progress photos yet"
          description={
            readOnly
              ? "This trainee hasn't uploaded any progress photos."
              : "Start tracking your transformation by uploading your first photo."
          }
          action={
            !readOnly ? (
              <Button onClick={() => setUploadOpen(true)} size="sm">
                <Camera className="mr-2 h-4 w-4" />
                Take First Photo
              </Button>
            ) : undefined
          }
        />
      ) : (
        <>
          {sortedDates.map((dateKey) => {
            const datePhotos = grouped[dateKey];
            const formattedDate = new Date(dateKey).toLocaleDateString(
              "en-US",
              { year: "numeric", month: "long", day: "numeric" },
            );

            return (
              <div key={dateKey}>
                <h3 className="mb-3 text-sm font-semibold text-muted-foreground">
                  {formattedDate}
                </h3>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
                  {datePhotos.map((photo) => (
                    <button
                      key={photo.id}
                      onClick={() => handlePhotoClick(photo)}
                      className="group relative aspect-[3/4] overflow-hidden rounded-lg bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                      aria-label={`${photo.category} progress photo from ${formattedDate}`}
                    >
                      {photo.photo_url ? (
                        <img
                          src={photo.photo_url}
                          alt={`${photo.category} progress photo`}
                          className="h-full w-full object-cover transition-transform group-hover:scale-105"
                          loading="lazy"
                        />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center">
                          <ImageIcon className="h-8 w-8 text-muted-foreground" />
                        </div>
                      )}
                      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-2">
                        <Badge
                          variant="secondary"
                          className="text-xs capitalize bg-white/20 text-white backdrop-blur-sm"
                        >
                          {photo.category}
                        </Badge>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-2 pt-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
              >
                Previous
              </Button>
              <span className="text-sm text-muted-foreground">
                Page {page} of {totalPages}
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
              >
                Next
              </Button>
            </div>
          )}
        </>
      )}

      {/* Dialogs */}
      <PhotoDetailDialog
        photo={selectedPhoto}
        open={detailOpen}
        onOpenChange={setDetailOpen}
        readOnly={readOnly}
      />

      {!readOnly && (
        <UploadDialog open={uploadOpen} onOpenChange={setUploadOpen} />
      )}

      <ComparisonView
        photos={photos}
        open={compareOpen}
        onOpenChange={setCompareOpen}
      />
    </div>
  );
}

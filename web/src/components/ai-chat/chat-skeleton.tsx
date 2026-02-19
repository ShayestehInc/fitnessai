import { Skeleton } from "@/components/ui/skeleton";

export function ChatSkeleton() {
  return (
    <div className="flex flex-col items-center justify-center py-16">
      <Skeleton className="mb-4 h-16 w-16 rounded-full" />
      <Skeleton className="mb-2 h-6 w-32" />
      <Skeleton className="mb-8 h-4 w-64" />
      <div className="flex gap-2">
        <Skeleton className="h-8 w-48 rounded-full" />
        <Skeleton className="h-8 w-40 rounded-full" />
        <Skeleton className="h-8 w-44 rounded-full" />
      </div>
    </div>
  );
}

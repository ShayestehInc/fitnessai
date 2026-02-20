"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { Search, X, Loader2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useDebounce } from "@/hooks/use-debounce";
import { useSearchMessages } from "@/hooks/use-messaging";
import { SearchResultItem } from "./search-result-item";
import type { SearchMessageResult } from "@/types/messaging";

interface MessageSearchProps {
  onResultClick: (result: SearchMessageResult) => void;
  onClose: () => void;
}

export function MessageSearch({ onResultClick, onClose }: MessageSearchProps) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const inputRef = useRef<HTMLInputElement>(null);
  const debouncedQuery = useDebounce(query, 300);

  const { data, isLoading, isFetching, isError, refetch } = useSearchMessages(
    debouncedQuery,
    page,
  );

  // Reset page when raw query changes (not debounced) to avoid stale query + wrong page
  const handleQueryChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setQuery(e.target.value);
      setPage(1);
    },
    [],
  );

  // Auto-focus input on mount
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  // Handle Esc key
  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      }
    },
    [onClose],
  );

  const showHint = query.length > 0 && query.length < 2;
  const showResults = debouncedQuery.length >= 2;
  const hasResults = data && data.results.length > 0;
  // Show skeleton on initial load; show inline spinner on page changes / refetches
  const showSkeleton = showResults && isLoading;
  const showInlineLoading = showResults && !isLoading && isFetching;

  return (
    <div className="flex h-full flex-col" onKeyDown={handleKeyDown}>
      {/* Search input */}
      <div className="flex items-center gap-2 border-b px-3 py-2">
        <Search className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
        <Input
          ref={inputRef}
          value={query}
          onChange={handleQueryChange}
          placeholder="Search messages..."
          className="h-8 border-0 bg-transparent p-0 shadow-none focus-visible:ring-0"
          aria-label="Search messages"
        />
        {isFetching && (
          <Loader2
            className="h-4 w-4 shrink-0 animate-spin text-muted-foreground"
            aria-hidden="true"
          />
        )}
        {query && (
          <Button
            variant="ghost"
            size="sm"
            className="h-6 w-6 shrink-0 p-0"
            onClick={() => {
              setQuery("");
              setPage(1);
            }}
            aria-label="Clear search"
          >
            <X className="h-3.5 w-3.5" />
          </Button>
        )}
        <Button
          variant="ghost"
          size="sm"
          className="shrink-0 text-xs text-muted-foreground"
          onClick={onClose}
        >
          Esc
        </Button>
      </div>

      {/* Results area */}
      <div className="flex-1 overflow-y-auto">
        {showHint && (
          <p className="px-4 py-8 text-center text-sm text-muted-foreground">
            Type at least 2 characters to search
          </p>
        )}

        {showSkeleton && (
          <div className="space-y-1 p-3">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="flex items-start gap-3 px-1 py-2">
                <Skeleton className="h-8 w-8 shrink-0 rounded-full" />
                <div className="flex-1 space-y-2">
                  <Skeleton className="h-3 w-24" />
                  <Skeleton className="h-3 w-full" />
                  <Skeleton className="h-3 w-3/4" />
                </div>
              </div>
            ))}
          </div>
        )}

        {showResults && isError && (
          <div className="p-4">
            <EmptyState
              icon={Search}
              title="Search failed"
              description="Something went wrong. Please try again."
              action={
                <Button variant="outline" size="sm" onClick={() => refetch()}>
                  Try again
                </Button>
              }
            />
          </div>
        )}

        {showResults && !isLoading && !isError && !hasResults && (
          <EmptyState
            icon={Search}
            title="No messages match your search"
            description="Try a different search term."
          />
        )}

        {showResults && !isLoading && !isError && hasResults && (
          <>
            <p className="px-4 py-2 text-xs text-muted-foreground">
              {data.count} result{data.count !== 1 ? "s" : ""} found
            </p>
            <div
              className={showInlineLoading ? "opacity-60 transition-opacity" : ""}
              role="list"
              aria-label="Search results"
            >
              {data.results.map((result) => (
                <SearchResultItem
                  key={result.message_id}
                  result={result}
                  query={debouncedQuery}
                  onClick={onResultClick}
                />
              ))}
            </div>
            {/* Pagination */}
            {data.num_pages > 1 && (
              <div className="flex items-center justify-between border-t px-4 py-2">
                <Button
                  variant="ghost"
                  size="sm"
                  disabled={!data.has_previous || isFetching}
                  onClick={() => setPage((p) => p - 1)}
                  aria-label="Previous page"
                >
                  Previous
                </Button>
                <span className="text-xs text-muted-foreground">
                  Page {data.page} of {data.num_pages}
                </span>
                <Button
                  variant="ghost"
                  size="sm"
                  disabled={!data.has_next || isFetching}
                  onClick={() => setPage((p) => p + 1)}
                  aria-label="Next page"
                >
                  Next
                </Button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

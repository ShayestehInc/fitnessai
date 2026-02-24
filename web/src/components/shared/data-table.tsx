"use client";

import { useRef, useCallback, useEffect } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";

export interface Column<T> {
  key: string;
  header: string;
  cell: (row: T) => React.ReactNode;
  className?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  totalCount?: number;
  page?: number;
  pageSize?: number;
  onPageChange?: (page: number) => void;
  onRowClick?: (row: T) => void;
  /** Generates an aria-label for each clickable row (for screen readers). */
  rowAriaLabel?: (row: T) => string;
  keyExtractor: (row: T) => string | number;
}

export function DataTable<T>({
  columns,
  data,
  totalCount,
  page = 1,
  pageSize = 20,
  onPageChange,
  onRowClick,
  rowAriaLabel,
  keyExtractor,
}: DataTableProps<T>) {
  const totalPages =
    totalCount !== undefined ? Math.ceil(totalCount / pageSize) : 1;
  const showPagination = totalCount !== undefined && totalPages > 1;

  const scrollRef = useRef<HTMLDivElement>(null);

  const updateScrollHint = useCallback(() => {
    const el = scrollRef.current;
    if (!el) return;
    const atEnd = el.scrollLeft + el.clientWidth >= el.scrollWidth - 1;
    el.classList.toggle("scrolled-end", atEnd);
  }, []);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    updateScrollHint();
    el.addEventListener("scroll", updateScrollHint, { passive: true });
    return () => el.removeEventListener("scroll", updateScrollHint);
  }, [updateScrollHint]);

  return (
    <div>
      <div ref={scrollRef} className="table-scroll-hint overflow-x-auto rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              {columns.map((col) => (
                <TableHead key={col.key} className={col.className}>
                  {col.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center text-muted-foreground"
                >
                  No results found.
                </TableCell>
              </TableRow>
            ) : (
              data.map((row) => (
                <TableRow
                  key={keyExtractor(row)}
                  onClick={onRowClick ? () => onRowClick(row) : undefined}
                  onKeyDown={
                    onRowClick
                      ? (e: React.KeyboardEvent) => {
                          if (e.key === "Enter" || e.key === " ") {
                            e.preventDefault();
                            onRowClick(row);
                          }
                        }
                      : undefined
                  }
                  tabIndex={onRowClick ? 0 : undefined}
                  role={onRowClick ? "button" : undefined}
                  aria-label={
                    onRowClick && rowAriaLabel
                      ? rowAriaLabel(row)
                      : undefined
                  }
                  className={
                    onRowClick
                      ? "cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"
                      : undefined
                  }
                >
                  {columns.map((col) => (
                    <TableCell key={col.key} className={col.className}>
                      {col.cell(row)}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
      {showPagination && (
        <div className="flex items-center justify-between px-2 py-4">
          <p className="text-sm text-muted-foreground" aria-label={`Page ${page} of ${totalPages}, ${totalCount} total items`}>
            <span className="hidden sm:inline">Page {page} of {totalPages} ({totalCount} total)</span>
            <span className="sm:hidden" aria-hidden="true">{page}/{totalPages}</span>
          </p>
          <nav className="flex items-center gap-2" aria-label="Table pagination">
            <Button
              variant="outline"
              size="sm"
              className="min-h-[44px] min-w-[44px] sm:min-h-0 sm:min-w-0"
              onClick={() => onPageChange?.(page - 1)}
              disabled={page <= 1}
              aria-label="Go to previous page"
            >
              <ChevronLeft className="h-4 w-4" aria-hidden="true" />
              <span className="hidden sm:inline">Previous</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="min-h-[44px] min-w-[44px] sm:min-h-0 sm:min-w-0"
              onClick={() => onPageChange?.(page + 1)}
              disabled={page >= totalPages}
              aria-label="Go to next page"
            >
              <span className="hidden sm:inline">Next</span>
              <ChevronRight className="h-4 w-4" aria-hidden="true" />
            </Button>
          </nav>
        </div>
      )}
    </div>
  );
}

"use client";

import { cn } from "@/lib/utils";
import type { PhotoCategory } from "@/types/progress";

const CATEGORIES: { label: string; value: PhotoCategory }[] = [
  { label: "All", value: "all" },
  { label: "Front", value: "front" },
  { label: "Side", value: "side" },
  { label: "Back", value: "back" },
  { label: "Other", value: "other" },
];

interface CategoryFilterProps {
  selected: PhotoCategory;
  onSelect: (category: PhotoCategory) => void;
}

export function CategoryFilter({ selected, onSelect }: CategoryFilterProps) {
  return (
    <div className="flex gap-2" role="radiogroup" aria-label="Photo category filter">
      {CATEGORIES.map((cat) => (
        <button
          key={cat.value}
          role="radio"
          aria-checked={selected === cat.value}
          onClick={() => onSelect(cat.value)}
          className={cn(
            "rounded-full px-4 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
            selected === cat.value
              ? "bg-primary text-primary-foreground"
              : "bg-muted text-muted-foreground hover:bg-muted/80",
          )}
        >
          {cat.label}
        </button>
      ))}
    </div>
  );
}

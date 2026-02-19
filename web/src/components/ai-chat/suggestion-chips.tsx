"use client";

const SUGGESTIONS = [
  "Who needs attention this week?",
  "Generate a weekly summary",
  "Compare trainee compliance",
  "Suggest meal plans for my trainees",
  "Which trainees are falling behind?",
];

interface SuggestionChipsProps {
  onSelect: (suggestion: string) => void;
}

export function SuggestionChips({ onSelect }: SuggestionChipsProps) {
  return (
    <div className="flex flex-wrap justify-center gap-2">
      {SUGGESTIONS.map((s) => (
        <button
          key={s}
          onClick={() => onSelect(s)}
          className="rounded-full border bg-background px-4 py-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        >
          {s}
        </button>
      ))}
    </div>
  );
}

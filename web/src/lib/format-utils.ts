const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
});

export function formatCurrency(value: string | number): string {
  const num = typeof value === "number" ? value : parseFloat(value);
  if (isNaN(num)) return "$0.00";
  return currencyFormatter.format(num);
}

/**
 * Format a coupon discount value based on its type.
 * Returns a human-readable string like "25%", "$10.00", or "14 days".
 */
export function formatDiscount(type: string, value: string): string {
  const num = parseFloat(value);
  if (isNaN(num)) return String(value);
  if (type === "percent") return `${num}%`;
  if (type === "fixed") return currencyFormatter.format(num);
  if (type === "free_trial") return `${num} days`;
  return String(num);
}

/**
 * Get initials from a first/last name pair.
 * Returns uppercase initials (e.g. "JD" for "Jane Doe").
 */
export function getInitials(firstName: string, lastName: string): string {
  const first = firstName.charAt(0).toUpperCase();
  const last = lastName.charAt(0).toUpperCase();
  return `${first}${last}`.trim();
}

"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import type { AdminCouponListItem } from "@/types/admin";

interface CouponListProps {
  coupons: AdminCouponListItem[];
  onRowClick: (coupon: AdminCouponListItem) => void;
}

const STATUS_VARIANT: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
  active: "default",
  expired: "secondary",
  revoked: "destructive",
  exhausted: "outline",
};

function formatDiscountValue(coupon: AdminCouponListItem): string {
  const value = parseFloat(coupon.discount_value);
  if (coupon.coupon_type === "percent") return `${value}%`;
  if (coupon.coupon_type === "fixed") {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(value);
  }
  if (coupon.coupon_type === "free_trial") return `${value} days`;
  return String(value);
}

const columns: Column<AdminCouponListItem>[] = [
  {
    key: "code",
    header: "Code",
    cell: (row) => <span className="font-mono font-medium">{row.code}</span>,
  },
  {
    key: "type",
    header: "Type",
    cell: (row) => (
      <Badge variant="outline">
        {row.coupon_type === "free_trial"
          ? "Free Trial"
          : row.coupon_type.charAt(0).toUpperCase() +
            row.coupon_type.slice(1)}
      </Badge>
    ),
  },
  {
    key: "discount",
    header: "Discount",
    cell: (row) => formatDiscountValue(row),
  },
  {
    key: "applies_to",
    header: "Applies To",
    cell: (row) =>
      row.applies_to.charAt(0).toUpperCase() + row.applies_to.slice(1),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={STATUS_VARIANT[row.status] ?? "secondary"}>
        {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
        <span className="sr-only"> status</span>
      </Badge>
    ),
  },
  {
    key: "usage",
    header: "Usage",
    cell: (row) =>
      `${row.current_uses}${row.max_uses > 0 ? ` / ${row.max_uses}` : " / Unlimited"}`,
  },
  {
    key: "valid_until",
    header: "Valid Until",
    cell: (row) =>
      row.valid_until
        ? format(new Date(row.valid_until), "MMM d, yyyy")
        : "No expiry",
  },
];

export function CouponList({ coupons, onRowClick }: CouponListProps) {
  return (
    <DataTable
      columns={columns}
      data={coupons}
      keyExtractor={(row) => row.id}
      onRowClick={onRowClick}
    />
  );
}

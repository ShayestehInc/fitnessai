"use client";

import { format } from "date-fns";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import { COUPON_STATUS_VARIANT } from "@/lib/admin-constants";
import { formatDiscount } from "@/lib/format-utils";
import type { AdminCouponListItem } from "@/types/admin";

interface CouponListProps {
  coupons: AdminCouponListItem[];
  onRowClick: (coupon: AdminCouponListItem) => void;
}

const columns: Column<AdminCouponListItem>[] = [
  {
    key: "code",
    header: "Code",
    cell: (row) => (
      <span className="inline-block max-w-[180px] truncate font-mono font-medium" title={row.code}>
        {row.code}
      </span>
    ),
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
    cell: (row) => formatDiscount(row.coupon_type, row.discount_value),
  },
  {
    key: "applies_to",
    header: "Applies To",
    className: "hidden md:table-cell",
    cell: (row) =>
      row.applies_to.charAt(0).toUpperCase() + row.applies_to.slice(1),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={COUPON_STATUS_VARIANT[row.status] ?? "secondary"}>
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
    className: "hidden md:table-cell",
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

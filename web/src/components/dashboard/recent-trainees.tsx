"use client";

import Link from "next/link";
import { formatDistanceToNow } from "date-fns";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import type { TraineeListItem } from "@/types/trainer";

interface RecentTraineesProps {
  trainees: TraineeListItem[];
}

export function RecentTrainees({ trainees }: RecentTraineesProps) {
  if (trainees.length === 0) return null;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Trainees</CardTitle>
        <CardDescription>Latest trainees to join your program</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Program</TableHead>
                <TableHead>Joined</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {trainees.slice(0, 10).map((t) => (
                <TableRow key={t.id}>
                  <TableCell>
                    <Link
                      href={`/trainees/${t.id}`}
                      className="font-medium hover:underline"
                    >
                      {`${t.first_name} ${t.last_name}`.trim() || t.email}
                    </Link>
                    <p className="truncate text-xs text-muted-foreground">{t.email}</p>
                  </TableCell>
                  <TableCell>
                    <Badge variant={t.profile_complete ? "default" : "secondary"}>
                      {t.profile_complete ? "Active" : "Onboarding"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {t.current_program?.name ?? "None"}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {formatDistanceToNow(new Date(t.created_at), {
                      addSuffix: true,
                    })}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

#!/usr/bin/env bash
#
# Daily PostgreSQL backup for FitnessAI.
# Runs via cron as the deploy user. Keeps 7 days of backups.
#
set -euo pipefail

BACKUP_DIR="/opt/fitnessai/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/fitnessai_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=7

echo "[$(date)] Starting backup..."

# Dump database via docker exec, compress with gzip
docker exec fitnessai_db pg_dump -U "${DB_USER:-postgres}" "${DB_NAME:-fitnessai}" | gzip > "$BACKUP_FILE"

# Verify backup is non-empty
if [ ! -s "$BACKUP_FILE" ]; then
    echo "[$(date)] ERROR: Backup file is empty, removing."
    rm -f "$BACKUP_FILE"
    exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Backup created: $BACKUP_FILE ($BACKUP_SIZE)"

# Remove backups older than retention period
DELETED=$(find "$BACKUP_DIR" -name "fitnessai_*.sql.gz" -mtime +${RETENTION_DAYS} -print -delete | wc -l)
echo "[$(date)] Removed $DELETED backup(s) older than ${RETENTION_DAYS} days."

echo "[$(date)] Backup complete."

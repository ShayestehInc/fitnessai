#!/bin/bash
# Strip simulator-platform frameworks from inside an IPA.
# Apple rejects uploads that contain simulator-only binaries.
set -euo pipefail

IPA="$1"
if [ -z "$IPA" ] || [ ! -f "$IPA" ]; then
  echo "Usage: $0 <path-to-ipa>"
  exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Extracting IPA..."
unzip -q "$IPA" -d "$WORK_DIR"

CHANGED=0
while IFS= read -r framework; do
  binary="${framework}/$(basename "${framework}" .framework)"
  if [ ! -f "$binary" ]; then
    continue
  fi

  # Check if any LC_BUILD_VERSION references SIMULATOR platform
  if otool -lv "$binary" 2>/dev/null | grep -A5 "LC_BUILD_VERSION" | grep -q "IOSSIMULATOR"; then
    echo "Removing simulator framework: $(basename "$framework")"
    rm -rf "$framework"
    CHANGED=1
  fi
done < <(find "$WORK_DIR/Payload" -name '*.framework' -type d)

if [ "$CHANGED" -eq 0 ]; then
  echo "No simulator frameworks found — IPA unchanged."
  exit 0
fi

echo "Re-packaging IPA..."
rm -f "$IPA"
pushd "$WORK_DIR" > /dev/null
zip -qr "$IPA" Payload
popd > /dev/null
echo "Done — simulator frameworks removed from IPA."

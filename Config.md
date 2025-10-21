

#!/bin/sh
set -euo pipefail

PROJECT_NAME=$(basename "$PROJECT_FILE_PATH" .xcodeproj)
XCCONFIG="${PROJECT_DIR}/${PROJECT_NAME}/BuildNumber.xcconfig"
STATE_FILE="${PROJECT_DIR}/${PROJECT_NAME}/.buildnumber.global"

DAY=$(date '+%y%m%d')

COUNT=0
if [ -f "$STATE_FILE" ]; then
  COUNT=$(cat "$STATE_FILE" | tr -d '[:space:]' || true)
  if ! echo "$COUNT" | grep -Eq '^[0-9]+$'; then
    COUNT=0
  fi
fi
COUNT=$(( COUNT + 1 ))

# CFBundleVersion doit rester un entier croissant
CFBUNDLEVERSION="$COUNT"

# Optionnel: une chaîne lisible pour affichage
VISIBLE_BUILD="${DAY}.${COUNT}"

mkdir -p "$(dirname "$XCCONFIG")"
: > "$XCCONFIG"
echo "CURRENT_PROJECT_VERSION = $CFBUNDLEVERSION" >> "$XCCONFIG"
echo "VISIBLE_BUILD = ${VISIBLE_BUILD}" >> "$XCCONFIG"

echo "$COUNT" > "$STATE_FILE"

echo "Updated build number to: CFBundleVersion=$CFBUNDLEVERSION, visible=$VISIBLE_BUILD"

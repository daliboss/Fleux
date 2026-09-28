#!/usr/bin/env bash

# Configurable defaults
REMOTE="${1:-origin}"
BRANCH="${2:-Lineage-24.0}"
BATCH_SIZE="${3:-2000}"

echo "=================================================="
echo " Starting Chunked Push"
echo " Remote:     $REMOTE"
echo " Branch:     $BRANCH"
echo " Batch size: $BATCH_SIZE commits"
echo "=================================================="

# 1. Fetch all commit hashes in chronological order (oldest -> newest)
echo "--> Reading commit history..."
mapfile -t COMMITS < <(git rev-list --reverse "$BRANCH")
TOTAL_COMMITS=${#COMMITS[@]}

if [ "$TOTAL_COMMITS" -eq 0 ]; then
  echo "Error: No commits found for branch '$BRANCH'."
  exit 1
fi

echo "--> Total commits to process: $TOTAL_COMMITS"

# 2. Loop through history in steps of BATCH_SIZE
for (( i=$BATCH_SIZE; i<$TOTAL_COMMITS; i+=$BATCH_SIZE )); do
  # Index is 0-based, so $i-1 is the commit at position $i
  COMMIT_HASH="${COMMITS[$((i - 1))]}"
  PERCENT=$(( (i * 100) / TOTAL_COMMITS ))
  
  echo ""
  echo " Processing batch: Commit $i / $TOTAL_COMMITS (~$PERCENT%)"
  echo " Target Hash: $COMMIT_HASH"
  echo "--------------------------------------------------"

  until git push "$REMOTE" "$COMMIT_HASH:refs/heads/$BRANCH" --no-thin; do
    echo "Warning: Push failed on commit $COMMIT_HASH. Retrying in 5 seconds..."
    sleep 5
  done
done

# 3. Push the remaining tip of the branch
echo ""
echo " Pushing final branch tip ($BRANCH)..."
echo "--------------------------------------------------"
until git push "$REMOTE" "$BRANCH" --no-thin; do
  echo "Warning: Final push failed. Retrying in 5 seconds..."
  sleep 5
done

echo ""
echo "=================================================="
echo " Success! All $TOTAL_COMMITS commits pushed to $REMOTE/$BRANCH"
echo "=================================================="

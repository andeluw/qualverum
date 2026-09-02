#!/usr/bin/env bash
set -euo pipefail

# Runs from anywhere by moving to the repo root first.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BENCHMARK="Evaluation/Datasets/TenderBenchmark"
DATASET="tmskss/eu-tenders-with-questions-for-agentic-checklist-filling"

# Newer installs ship "hf", older ones "huggingface-cli".
if command -v hf >/dev/null 2>&1; then
  HF=hf
elif command -v huggingface-cli >/dev/null 2>&1; then
  HF=huggingface-cli
else
  echo "Error: the Hugging Face CLI is not installed. Install it, then run this again."
  exit 1
fi

mkdir -p "$BENCHMARK"

# Skip the download when the benchmark folder already holds data.
if find "$BENCHMARK" -mindepth 1 ! -name ".gitignore" | grep -q .; then
  echo "Tender benchmark already exists at $BENCHMARK"
  exit 0
fi

echo "Downloading tender benchmark..."
"$HF" download "$DATASET" --repo-type dataset --local-dir "$BENCHMARK"

# Flatten the "data" subfolder Hugging Face sometimes nests things under.
if [ -d "$BENCHMARK/data" ]; then
  cp -R "$BENCHMARK/data/." "$BENCHMARK/"
  rm -rf "$BENCHMARK/data"
fi

rm -f "$BENCHMARK/.gitattributes"
rm -f "$BENCHMARK/README.md"
rm -rf "$BENCHMARK/.cache"

# Keep the folder tracked but its downloaded contents local only.
printf '*\n!.gitignore\n' > "$BENCHMARK/.gitignore"

echo
echo "Tender benchmark ready at $BENCHMARK"

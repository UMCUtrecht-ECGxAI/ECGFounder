#!/usr/bin/env bash
# Downloads pre-trained ECGFounder checkpoints from Hugging Face into ./checkpoint/
set -euo pipefail

REPO="PKUDigitalHealth/ECGFounder"
BASE_URL="https://huggingface.co/${REPO}/resolve/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKPOINT_DIR="${SCRIPT_DIR}/checkpoint"

FILES=(
    "12_lead_ECGFounder.pth"
    "1_lead_ECGFounder.pth"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

check_downloader() {
    if command -v curl &>/dev/null; then
        echo "curl"
    elif command -v wget &>/dev/null; then
        echo "wget"
    else
        echo "Error: neither curl nor wget found. Install one and retry." >&2
        exit 1
    fi
}

download_file() {
    local filename="$1"
    local dest="${CHECKPOINT_DIR}/${filename}"
    local tmp="${dest}.part"
    local url="${BASE_URL}/${filename}"

    if [[ -f "$dest" ]]; then
        echo "  [skip] ${filename} already present."
        return
    fi

    echo "  [download] ${filename}"

    # Clean up any leftover partial file on exit/error
    trap 'rm -f "$tmp"' ERR INT TERM

    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fSL --progress-bar \
            ${HF_TOKEN:+-H "Authorization: Bearer ${HF_TOKEN}"} \
            -o "$tmp" "$url"
    else
        wget -q --show-progress \
            ${HF_TOKEN:+--header "Authorization: Bearer ${HF_TOKEN}"} \
            -O "$tmp" "$url"
    fi

    mv "$tmp" "$dest"
    trap - ERR INT TERM
    echo "  [done]   ${filename}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

DOWNLOADER="$(check_downloader)"
mkdir -p "$CHECKPOINT_DIR"

echo "Checkpoint directory : ${CHECKPOINT_DIR}"
echo "Hugging Face repo    : ${REPO}"
[[ -n "${HF_TOKEN:-}" ]] && echo "Auth                 : HF_TOKEN set"
echo ""

for file in "${FILES[@]}"; do
    download_file "$file"
done

echo ""
echo "All checkpoints ready."

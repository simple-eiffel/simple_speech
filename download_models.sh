#!/bin/bash
# Download whisper.cpp models from HuggingFace
# Usage: ./download_models.sh [model_name]
# Models: tiny, base, small, medium, large-v3

set -e

MODELS_DIR="./models"
BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

mkdir -p "$MODELS_DIR"

download_model() {
    local model=$1
    local filename="ggml-${model}.bin"
    local url="${BASE_URL}/${filename}"
    local dest="${MODELS_DIR}/${filename}"
    
    if [ -f "$dest" ]; then
        echo "Model already exists: $dest"
        return
    fi
    
    echo "Downloading $filename..."
    curl -L -o "$dest" "$url"
    echo "Downloaded: $dest"
}

# Default to base.en if no argument
MODEL=${1:-base.en}

case $MODEL in
    tiny|tiny.en)
        download_model "tiny.en"
        ;;
    base|base.en)
        download_model "base.en"
        ;;
    small|small.en)
        download_model "small.en"
        ;;
    medium|medium.en)
        download_model "medium.en"
        ;;
    large|large-v3)
        download_model "large-v3"
        ;;
    all-en)
        download_model "tiny.en"
        download_model "base.en"
        download_model "small.en"
        download_model "medium.en"
        ;;
    *)
        echo "Usage: $0 [tiny|base|small|medium|large|all-en]"
        echo ""
        echo "Model sizes:"
        echo "  tiny.en    - 39 MB  (fastest, least accurate)"
        echo "  base.en    - 142 MB (good balance)"
        echo "  small.en   - 466 MB (better accuracy)"
        echo "  medium.en  - 1.5 GB (high accuracy)"
        echo "  large-v3   - 2.9 GB (best accuracy)"
        exit 1
        ;;
esac

echo "Done!"

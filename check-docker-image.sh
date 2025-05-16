#!/bin/bash

echo ""
echo "---------------------------------------------------------------------------------------------------------------"


DOCKER_RUN_SCRIPT="./docker-run-cmd.sh"
IMAGE_TAR_PATH="/opt/appdata/docker-run/images/adv.tar"  # 📦 Declare the image tar path here

# Extract image name from docker run command (last non-option word)
IMAGE_NAME=$(awk '
  {
    for (i = 1; i <= NF; i++) {
      if ($i == "--name") name = $(i+1)
      if ($i !~ /^-/) last = $i
    }
  }
  END { print last }
' "$DOCKER_RUN_SCRIPT")

if [[ -z "$IMAGE_NAME" ]]; then
  echo "❌ Could not extract image name from $DOCKER_RUN_SCRIPT"
  exit 1
fi

if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
  echo "✅ Image '$IMAGE_NAME' already exists."
else
  echo "🖼️  Image '$IMAGE_NAME' not found locally."
  if [[ -f "$IMAGE_TAR_PATH" ]]; then
    echo "📦 Loading image from $IMAGE_TAR_PATH..."
    docker load --input "$IMAGE_TAR_PATH"
    echo "✅ Image loaded."
  else
    echo "❌ Image tar file not found at $IMAGE_TAR_PATH. Cannot proceed without image."
    exit 1
  fi
fi


echo ""
echo "---------------------------------------------------------------------------------------------------------------"

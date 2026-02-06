#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -i IMAGE_NAME [options]

Options:
  -i IMAGE_NAME      Full image base name (e.g. ghcr.io/OWNER/repo)
  -r RELEASE_TAG     Release tag to add (e.g. v1.0.0)
  -p                 Push built images to registry
  --context DIR      Build context directory (default: .)
  --file DOCKERFILE  Dockerfile to use (default: Dockerfile)
  --tutor            Use Tutor to build Open edX images (requires 'tutor' in PATH)
  --source SRC       Source image (repo:tag or pattern) to re-tag after tutor build
  --retag-only       Do not run tutor; only re-tag the existing source image to target names
  -h, --help         Show this help

Examples:
  $0 -i ghcr.io/myorg/myapp -r v1.0.0 -p
  $0 -i ghcr.io/myorg/myapp --tutor --source overhangio/openedx:21.0.0 -p
  $0 -i ghcr.io/myorg/myapp --source overhangio/openedx:21.0.0 --retag-only -p
EOF
  exit 2
}

PUSH=false
RELEASE=""
IMAGE=""
CONTEXT="."
DOCKERFILE="Dockerfile"
USE_TUTOR=false
SOURCE=""
RETAG_ONLY=false

# parse args (support long options)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) RELEASE="$2"; shift 2 ;;
    -p) PUSH=true; shift ;;
    -i) IMAGE="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --file) DOCKERFILE="$2"; shift 2 ;;
    --tutor) USE_TUTOR=true; shift ;;
    --source) SOURCE="$2"; shift 2 ;;
    --retag-only) RETAG_ONLY=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [ -z "$IMAGE" ]; then
  echo "ERROR: IMAGE is required" >&2
  usage
fi

# Determine commit short sha (fallback to timestamp if not a git repo)
if git rev-parse --git-dir > /dev/null 2>&1; then
  COMMIT=$(git rev-parse --short HEAD)
else
  COMMIT="local-$(date +%s)"
fi

TAG_COMMIT="sha-$COMMIT"
TAGS=("$IMAGE:$TAG_COMMIT")
if [ -n "$RELEASE" ]; then
  TAGS+=("$IMAGE:$RELEASE")
fi

build_with_docker() {
  for t in "${TAGS[@]}"; do
    echo "Building image $t (context=$CONTEXT, dockerfile=$DOCKERFILE)"
    docker build -f "$DOCKERFILE" -t "$t" "$CONTEXT"
  done
}

find_source_image() {
  # Return a single matching image repo:tag or empty
  if [ -n "$SOURCE" ]; then
    if echo "$SOURCE" | grep -q ':'; then
      # exact repo:tag match
      docker images --format '{{.Repository}}:{{.Tag}}' | grep -xF "$SOURCE" || true
    else
      # treat SOURCE as pattern for repository name
      docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "$SOURCE" || true
    fi
  else
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'openedx|lms|studio|cms|edx|tutor' || true
  fi
}

build_with_tutor() {
  if ! command -v tutor >/dev/null 2>&1; then
    echo "ERROR: tutor command not found in PATH" >&2
    exit 3
  fi
  if [ "$RETAG_ONLY" = true ]; then
    echo "--retag-only set: skipping 'tutor images build' and using existing images";
  else
    echo "Building Open edX images with tutor (this may take a while)"
    tutor images build
  fi

  echo "Locating tutor-built image to re-tag..."
  candidates=$(find_source_image)

  if [ -z "${candidates}" ]; then
    echo "ERROR: No candidate images found after tutor build." >&2
    echo "Run 'docker images' to inspect available images, or re-run with --source <pattern|repo:tag> to specify which image to re-tag." >&2
    exit 4
  fi

  # filter empty lines and count
  count=$(printf "%s" "$candidates" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$count" -gt 1 ]; then
    echo "Multiple candidate images found; please specify --source to disambiguate. Candidates:" >&2
    printf '%s\n' "$candidates"
    exit 5
  fi

  SRC_IMAGE=$(printf '%s' "$candidates")
  echo "Selected source image: $SRC_IMAGE"

  for t in "${TAGS[@]}"; do
    echo "Tagging $SRC_IMAGE -> $t"
    docker tag "$SRC_IMAGE" "$t"
  done
}

if [ "$USE_TUTOR" = true ] || [ "$RETAG_ONLY" = true ]; then
  build_with_tutor
else
  build_with_docker
fi

if [ "$PUSH" = true ]; then
  echo "Pushing images to registry"
  for t in "${TAGS[@]}"; do
    echo "Pushing $t"
    docker push "$t"
  done
fi

echo "Built tags: ${TAGS[*]}"
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -i IMAGE_NAME [-r RELEASE_TAG] [-p] [--context DIR] [--file DOCKERFILE] [--tutor]

Options:
  -i IMAGE_NAME     Full image name (e.g. ghcr.io/OWNER/repo)
  -r RELEASE_TAG    Release tag to add (e.g. v1.0.0)
  -p                Push built images to registry
  --context DIR     Build context directory (default: .)
  --file DOCKERFILE Dockerfile to use (default: Dockerfile)
  --tutor           Use Tutor to build Open edX images (requires `tutor` in PATH)
  --source SRC      Source image name or pattern to re-tag after tutor build (optional)

Example:
  ./ops/build_image.sh -i ghcr.io/myorg/myapp -r v1.0.0 -p
  ./ops/build_image.sh -i ghcr.io/myorg/myapp --tutor -r v1.0.0 -p
EOF
  exit 2
}

PUSH=false
RELEASE=""
IMAGE=""
CONTEXT="."
DOCKERFILE="Dockerfile"
USE_TUTOR=false
SOURCE=""

# parse args (support long options)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) RELEASE="$2"; shift 2 ;;
    -p) PUSH=true; shift ;;
    -i) IMAGE="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --file) DOCKERFILE="$2"; shift 2 ;;
  --tutor) USE_TUTOR=true; shift ;;
  --source) SOURCE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [ -z "$IMAGE" ]; then
  echo "ERROR: IMAGE is required"
  usage
fi

# Determine commit short sha (fallback to timestamp if not a git repo)
if git rev-parse --git-dir > /dev/null 2>&1; then
  COMMIT=$(git rev-parse --short HEAD)
else
  COMMIT="local-$(date +%s)"
fi

TAG_COMMIT="sha-$COMMIT"
TAGS=("$IMAGE:$TAG_COMMIT")
if [ -n "$RELEASE" ]; then
  TAGS+=("$IMAGE:$RELEASE")
fi

build_with_docker() {
  for t in "${TAGS[@]}"; do
    echo "Building image $t (context=$CONTEXT, dockerfile=$DOCKERFILE)"
    docker build -f "$DOCKERFILE" -t "$t" "$CONTEXT"
  done
}

build_with_tutor() {
  if ! command -v tutor >/dev/null 2>&1; then
    echo "ERROR: tutor command not found in PATH"
    exit 3
  fi
  echo "Building Open edX images with tutor (this may take a while)"
  tutor images build

  # After tutor builds images, we need to find the LMS image (or the image
  # specified via --source) and re-tag it to the requested registry tags.
  # If --source was provided, use it as a pattern to locate the built image.
  echo "Locating tutor-built image to re-tag..."
  if [ -n "$SOURCE" ]; then
    candidates=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "$SOURCE" || true)
  else
    # common patterns: openedx, lms, studio, cms, edx, tutor
    candidates=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'openedx|lms|studio|cms|edx|tutor' || true)
  fi

  if [ -z "${candidates}" ]; then
    echo "ERROR: No candidate images found after tutor build."
    echo "Run 'docker images' to inspect available images, or re-run with --source <pattern> to specify which image to re-tag."
    exit 4
  fi

  # Count candidates
  count=$(printf "%s" "$candidates" | wc -l | tr -d ' ')
  if [ "$count" -gt 1 ]; then
    echo "Multiple candidate images found; please specify --source to disambiguate. Candidates:"
    printf '%s
' "$candidates"
    exit 5
  fi

  SRC_IMAGE=$(printf '%s' "$candidates")
  echo "Selected source image: $SRC_IMAGE"

  for t in "${TAGS[@]}"; do
    echo "Tagging $SRC_IMAGE -> $t"
    docker tag "$SRC_IMAGE" "$t"
  done
}

if [ "$USE_TUTOR" = true ]; then
  build_with_tutor
else
  build_with_docker
fi

if [ "$PUSH" = true ]; then
  echo "Pushing images to registry"
  for t in "${TAGS[@]}"; do
    echo "Pushing $t"
    docker push "$t"
  done
fi

echo "Built tags: ${TAGS[*]}"

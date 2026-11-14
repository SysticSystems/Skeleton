#!/usr/bin/env bash
# ============================================================================
# Synapse Engine - Containerized Execution Entrypoint
# Location: synapse.sh
# ============================================================================

set -eo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[SYNAPSE INFO]${NC} $1"; }
log_error() { echo -e "${RED}[SYNAPSE ERROR]${NC} $1" >&2; }
log_succ()  { echo -e "${GREEN}[SYNAPSE SUCCESS]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

if [[ $# -lt 1 ]]; then
    log_error "Missing required action! You must explicitly pass either 'create' or 'run'."
    echo -e "Usage:\n  $0 create\n  $0 run [arguments...]"
    exit 1
fi

ACTION="$1"
shift

# Project name is read strictly from directory name, NOT from .env
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Project directory name '$PROJECT_NAME' must match ^[a-z][a-z0-9_]*$. Create the project with a lowercase name starting with a letter."
    exit 1
fi

ENV_FILE="$SCRIPT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
    set -o allexport
    source <(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$')
    set +o allexport
fi

VERSION_FILE="$PROJECT_ROOT/VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
    log_error "Required project version file 'VERSION' is missing. Restore it with the project's major.minor.patch release version."
    exit 1
fi
PROJECT_VERSION="$(<"$VERSION_FILE")"
if [[ ! "$PROJECT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "'VERSION' must contain a major.minor.patch version such as 0.1.0. Correct the project's VERSION file."
    exit 1
fi
if [[ "${ENABLE_CONAN:-OFF}" == "ON" && -z "${CONAN_PROFILE:-}" ]]; then
    log_error "Missing required setting 'CONAN_PROFILE'. Set it in $ENV_FILE when ENABLE_CONAN=ON."
    exit 1
fi
if [[ "${ENABLE_CONAN:-OFF}" == "ON" && ! -f "$SCRIPT_DIR/.conan/profiles/$CONAN_PROFILE" ]]; then
    log_error "Conan profile '$CONAN_PROFILE' was not found at '.conan/profiles/$CONAN_PROFILE'. Add that profile or correct CONAN_PROFILE in $ENV_FILE."
    exit 1
fi

if command -v podman &> /dev/null; then
    OCI_BIN="podman"
elif command -v docker &> /dev/null; then
    OCI_BIN="docker"
else
    log_error "Neither Podman nor Docker was found in PATH."
    exit 1
fi

IMAGE_NAME="${PROJECT_NAME}_build_image:latest"
CONTAINER_NAME="${PROJECT_NAME}_build_runner"
DOCKERFILE_PATH="$SCRIPT_DIR/.github/workflows/Dockerfile"
BUILD_CONTEXT="$SCRIPT_DIR/.github/workflows"

PROFILE="${CONAN_PROFILE:-disabled}"
CONAN_CACHE_DIR="$SCRIPT_DIR/.conan/cache/${PROFILE,,}"
mkdir -p "$CONAN_CACHE_DIR"

# Capture current host user UID and GID dynamically
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

case "$ACTION" in
    create)
        log_info "Building base environment image '$IMAGE_NAME' (UID=$HOST_UID, GID=$HOST_GID)..."
        if [[ ! -f "$DOCKERFILE_PATH" ]]; then
            log_error "Dockerfile not found at $DOCKERFILE_PATH"
            exit 1
        fi
        $OCI_BIN build \
            -f "$DOCKERFILE_PATH" \
            --build-arg USER_UID="$HOST_UID" \
            --build-arg USER_GID="$HOST_GID" \
            -t "$IMAGE_NAME" "$BUILD_CONTEXT"
        log_succ "Environment image created."
        ;;
    run)
        if ! $OCI_BIN image inspect "$IMAGE_NAME" &> /dev/null; then
            log_error "Build image '$IMAGE_NAME' not found. Run '$0 create' first."
            exit 1
        fi

        if $OCI_BIN ps -aq -f name="^/${CONTAINER_NAME}$" | grep -q .; then
            $OCI_BIN rm -f "$CONTAINER_NAME" > /dev/null
        fi

        TTY_ARGS=""
        [[ -t 0 && -t 1 ]] && TTY_ARGS="-it"
        ENV_ARGS=()
        [[ -f "$ENV_FILE" ]] && ENV_ARGS+=(--env-file "$ENV_FILE")

        log_info "Launching Synapse from base image library..."

        # Mount host project to /project and map Conan cache to developer user home
        $OCI_BIN run --rm $TTY_ARGS \
          --name "$CONTAINER_NAME" \
          --network host \
          --security-opt seccomp=unconfined \
          "${ENV_ARGS[@]}" \
          -v "$PROJECT_ROOT:/project:z" \
          -v "$CONAN_CACHE_DIR:/home/developer/.conan2:z" \
          -w /project \
          "$IMAGE_NAME" \
          "$@"

        log_succ "Synapse execution finished."
        ;;
    *)
        log_error "Invalid action '$ACTION'."
        exit 1
        ;;
esac
#!/bin/bash
set -euo pipefail

# Cross-build helper for Windows artifacts.
# Usage: build-win.sh [-s SRC_DIR] [-o OUT_DIR] [-p PREFIX] [--no-clean] [-j JOBS] [-v] [-D DESTDIR] [--dry-run]

SRC_DIR="/mosml"
OUT_DIR="/out"
PREFIX="/mosml"
DO_CLEAN=1
VERBOSE=0
JOBS=""
DESTDIR_ARG=""
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $0 [options]
Options:
  -s DIR    Source root (default: /mosml)
  -o DIR    Output directory for zip (default: /out)
  -p PREFIX Install PREFIX passed to make (default: /mosml)
  --no-clean   Skip 'make clean' before build
  -D DIR, --destdir DIR  Use this DESTDIR for cross build (overrides ENV DESTDIR)
  --dry-run    Print commands instead of executing them
  -j N      Parallel jobs (default: detected CPU count)
  -v        Verbose (prints commands)
  -h        Show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -s) SRC_DIR="$2"; shift 2;;
        -o) OUT_DIR="$2"; shift 2;;
        -p) PREFIX="$2"; shift 2;;
        --no-clean) DO_CLEAN=0; shift;;
        -D) DESTDIR_ARG="$2"; shift 2;;
        --destdir) DESTDIR_ARG="$2"; shift 2;;
        --dry-run) DRY_RUN=1; shift;;
        -j) JOBS="$2"; shift 2;;
        -v) VERBOSE=1; shift;;
        -h|--help) usage; exit 0;;
        --) shift; break;;
        -*) printf "Unknown option: %s\n" "$1" >&2; usage; exit 2;;
        *) break;;
    esac
done

# Validate JOBS if provided: must be a positive integer
if [ -n "${JOBS:-}" ]; then
    if ! [[ "$JOBS" =~ ^[0-9]+$ ]]; then
        printf "Error: invalid -j value '%s' (must be a positive integer)\n" "$JOBS" >&2
        usage
        exit 2
    fi
    if [ "$JOBS" -eq 0 ]; then
        printf "Error: invalid -j value '%s' (must be greater than zero)\n" "$JOBS" >&2
        usage
        exit 2
    fi
fi

if [ "$VERBOSE" -eq 1 ]; then
    set -x
fi

error_exit() {
    rc=$?
    echo "Error: build failed (exit $rc)" >&2
    exit $rc
}
trap error_exit ERR

# Determine parallel jobs if not provided
if [ -z "$JOBS" ]; then
    if command -v nproc >/dev/null 2>&1; then
        JOBS=$(nproc)
    else
        JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    fi
fi

printf "Source: %s\nOut: %s\nPrefix: %s\nJobs: %s\nDESTDIR_ARG: %s\nDry-run: %s\n" \
    "$SRC_DIR" "$OUT_DIR" "$PREFIX" "$JOBS" "$DESTDIR_ARG" "$DRY_RUN"

# Recompute subdir now that options may have changed
SRC_SUBDIR="$SRC_DIR/src"

# Helper: run or echo a command depending on dry-run. Prints shell-escaped args.
run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '+ '
        for a in "$@"; do
            printf '%q ' "$a"
        done
        printf '\n'
        return 0
    fi
    "$@"
}

run_in_src() {
    if [ "$DRY_RUN" -eq 1 ]; then
        # Show the full subshell command including the cd so dry-run output
        # reflects what would be executed.
        printf '+ (cd %q &&' "$SRC_SUBDIR"
        for a in "$@"; do
            printf ' %q' "$a"
        done
        printf ' )\n'
        return 0
    fi
    (cd "$SRC_SUBDIR" && "$@")
}

if [ ! -d "$SRC_DIR" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Warning: source directory '$SRC_DIR' not found (dry-run)."
    else
        echo "Error: source directory '$SRC_DIR' not found." >&2
        exit 2
    fi
fi

if [ "$DO_CLEAN" -eq 1 ]; then
    printf "Running 'make clean' in %s/src\n" "$SRC_DIR"
    run_in_src make clean
fi

printf "Building world (may take a while)...\n"
run_in_src make world -j"$JOBS"

# Prepare DESTDIR absolute location. Priority: --destdir, ENV DESTDIR, default
if [ -n "$DESTDIR_ARG" ]; then
    WIN_ROOT="$DESTDIR_ARG"
elif [ -n "${DESTDIR-}" ]; then
    WIN_ROOT="$DESTDIR"
else
    WIN_ROOT="$SRC_DIR/win-root"
fi

run_cmd mkdir -p "$WIN_ROOT"

printf "Running cross build (cross_w32)...\n"
run_in_src make DESTDIR="$WIN_ROOT" PREFIX="$PREFIX" cross_w32 -j"$JOBS"

run_cmd mkdir -p "$OUT_DIR"

ZIP_PATH="$OUT_DIR/mosml-windows-x86_64.zip"
printf "Creating zip archive %s\n" "$ZIP_PATH"

# Dry-run prints the command and includes the directory check
if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ [ -d %q ] && (cd %q && zip -r %q mosml)\n' "$WIN_ROOT/mosml" "$WIN_ROOT" "$ZIP_PATH"
else
    # Verify win root exists
    if [ ! -d "$WIN_ROOT" ]; then
        echo "Error: win-root not found after build: $WIN_ROOT" >&2
        exit 2
    fi

    # Verify mosml directory exists inside win root
    if [ ! -d "$WIN_ROOT/mosml" ]; then
        echo "Error: expected directory '$WIN_ROOT/mosml' not found. The cross build should have created it." >&2
        exit 2
    fi

    # Verify zip is available
    if ! command -v zip >/dev/null 2>&1; then
        echo "Error: 'zip' not found. Please install 'zip' to create archive." >&2
        exit 3
    fi

    (cd "$WIN_ROOT" && zip -r "$ZIP_PATH" mosml)
    printf "Done: %s\n" "$ZIP_PATH"
fi

printf "Build finished. The zip is available in %s (mount a host dir to retrieve it).\n" "$OUT_DIR"

exit 0

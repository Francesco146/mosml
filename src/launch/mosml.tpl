#!/bin/bash

stdlib=LIBDIR
mosmlbin=BINDIR
includes=""
options="-conservative"

# Determine history file location (respects XDG Base Directory spec, falls back to HOME)
if [ -n "$XDG_DATA_HOME" ]; then
  history_file="$XDG_DATA_HOME/mosml/history"
else
  # macOS, Windows (MSYS/Git Bash), and systems without XDG
  history_file="$HOME/.local/share/mosml/history"
fi

# Create history directory if possible (ignore errors gracefully)
mkdir -p "$(dirname "$history_file")" 2>/dev/null || true

# Check if rlwrap is available and the session is interactive.
# Store rlwrap invocation as an array so we can safely embed quoted paths.
# We only print warnings when the session is interactive (stdout is a tty).
use_rlwrap=()
if command -v rlwrap >/dev/null 2>&1 && [ -t 1 ]; then
  use_rlwrap=(rlwrap -a -H "$history_file" -s 1000)
elif [ -t 1 ]; then
  echo "Warning: rlwrap not found; running without rlwrap." >&2
  echo "For better command line editing, consider installing rlwrap." >&2
fi

# Disable rlwrap if DISABLE_RLWRAP environment variable is set to 1
if [ -n "$DISABLE_RLWRAP" ] && [ "$DISABLE_RLWRAP" = "1" ]; then
  use_rlwrap=()
fi

while : ; do
  case $1 in
    "")
      exec "${use_rlwrap[@]}" $mosmlbin/camlrunm $stdlib/mosmltop -stdlib $stdlib $includes $options;;
    -I|-include)
      includes="$includes -I $2"
      shift;;
    -P|-perv)
      options="$options -P $2"
      shift;;
    -imptypes)
      options="$options -imptypes"
      ;;
    -m|-msgstyle)
      options="$options -msgstyle $2"
      shift;;
    -quietdec)
      options="$options -quietdec"
      ;;
    -valuepoly)
      options="$options -valuepoly"
      ;;
    -orthodox|-conservative|-liberal)
      options="$options $1"
      ;;
    -stdlib)
      stdlib=$2
      shift;;
    -*)
      echo "Unknown option \"$1\", ignored" >&2;;
    *)
      exec "${use_rlwrap[@]}" $mosmlbin/camlrunm $stdlib/mosmltop -stdlib $stdlib $includes $options $* ;;
  esac
  shift
done



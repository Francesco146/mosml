#!/bin/sh

stdlib=LIBDIR
mosmlbin=BINDIR
includes=""
options="-conservative"

# Check if rlwrap is available and stdin is a terminal
use_rlwrap=""
if [ -t 0 ] && command -v rlwrap >/dev/null 2>&1; then
  use_rlwrap="rlwrap -a -N -H $HOME/.mosml_history -s 1000"
else
  echo "Warning: rlwrap not found or input is not a terminal; running without rlwrap." >&2
  echo "For better command line editing, consider installing rlwrap." >&2
  use_rlwrap=""
fi

# Disable rlwrap if RLWRAP environment variable is already set
if [ -n "$RLWRAP" ]; then
  use_rlwrap=""
fi

while : ; do
  case $1 in
    "")
      exec $use_rlwrap $mosmlbin/camlrunm $stdlib/mosmltop -stdlib $stdlib $includes $options;;
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
      exec $use_rlwrap $mosmlbin/camlrunm $stdlib/mosmltop -stdlib $stdlib $includes $options $* ;;
  esac
  shift
done



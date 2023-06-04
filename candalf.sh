#!/usr/bin/env bash

usage() {
  echo "
Usage: $(basename "$0") [-v | --verbose] [-d | --dry-run] SERVER SPELL_BOOK...

Options:
  -d --dry-run   do not cast any spells, but show what would be casted
  -v --verbose   enable verbose output
  -n --no-color  disable colored output
  -h --help      show this help

Examples:
  candalf example.org book.sh
  candalf --verbose example.org book.sh

  candalf localhost book.sh
  candalf --dry-run localhost book.sh"
  exit 1
}

if [[ ${#} -eq 0 ]]; then
  usage
fi

optspec=":dvnh-:"
while getopts "$optspec" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        dry-run)
          DRY_RUN=1
          ;;
        verbose)
          VERBOSE=1
          ;;
        no-color)
          NO_COLOR=1
          ;;
        help)
          usage
          ;;
        *)
          if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
            usage
          fi
          ;;
      esac;;
    d)
      DRY_RUN=1
      ;;
    v)
      VERBOSE=1
      ;;
    n)
      NO_COLOR=1
      ;;
    h)
      usage
      ;;
    *)
      if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
        usage
      fi
      ;;
  esac
done
shift $((OPTIND-1))

VERBOSE="${VERBOSE:-""}"
test $VERBOSE && set -x
set -Eeuo pipefail

export CANDALF_NO_COLOR="${NO_COLOR:-""}"
export CANDALF_DRY_RUN="${DRY_RUN:-""}"
CANDALF_ROOT=$(dirname "$(realpath "$0")")
CANDALF_SERVER=${1:?"SERVER not set!"}
shift

if [[ "$CANDALF_SERVER" = "localhost" || "$CANDALF_SERVER" = "127.0.0.1" ]]; then
  # shellcheck source=lib/candalf-local.sh
  . "$CANDALF_ROOT"/lib/candalf-local.sh
else
  # shellcheck source=lib/candalf.sh
  . "$CANDALF_ROOT"/lib/candalf.sh
fi

bootstrap "$CANDALF_SERVER"

for SPELL_BOOK in "$@"
do
    echo -e "Applying spells from $SPELL_BOOK\n"
    candalf "$CANDALF_SERVER" "$SPELL_BOOK"
    echo -e "Applying spells from $SPELL_BOOK completed\n"
done


#!/usr/bin/env bash

usage() {
  echo "
Usage: $(basename "$0") [-v | --verbose] SERVER SPELL_BOOK

Options:
  -v --verbose   enable verbose output
  -h --help      show this help

Examples:
  candalf example.org book.sh
  candalf localhost book.sh"
  exit 1
}

if [[ ${#} -eq 0 ]]; then
 usage
fi

optspec=":lvh-:"
while getopts "$optspec" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        verbose)
          VERBOSE=1
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
    l)
      LOCAL=1
      ;;
    v)
      VERBOSE=1
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

CANDALF_ROOT=$(dirname "$(realpath "$0")")
CANDALF_SERVER=${1:?"SERVER not set!"}
SPELL_BOOK=${2:?"SPELL_BOOK not set!"}

if [[ "$CANDALF_SERVER" = "localhost" || "$CANDALF_SERVER" = "127.0.0.1" ]]; then
  . "$CANDALF_ROOT"/lib/candalf-local.sh
else
  . "$CANDALF_ROOT"/lib/candalf.sh
fi

bootstrap "$CANDALF_SERVER" "$SPELL_BOOK"

echo -e "Applying spells from $SPELL_BOOK\n"
candalf "$CANDALF_SERVER" "$SPELL_BOOK"
echo "Applying spells from $SPELL_BOOK completed"


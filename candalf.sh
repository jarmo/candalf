#!/usr/bin/env bash

usage() {
  echo "
Usage: $(basename "$0") [-v | --verbose] [-d | --dry-run] SERVER SPELL_BOOK...

Options:
  -d --dry-run   do not cast any spells, but show what would be casted
  -v --verbose   enable verbose output
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

optspec=":dvh-:"
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

CANDALF_DRY_RUN="${DRY_RUN:-""}"
test $CANDALF_DRY_RUN && echo "!!! No spells will be cast due to dry-run mode being enabled !!!"

CANDALF_ROOT=$(dirname "$(realpath "$0")")
CANDALF_SERVER=${1:?"SERVER not set!"}
shift

if [[ "$CANDALF_SERVER" = "localhost" || "$CANDALF_SERVER" = "127.0.0.1" ]]; then
  . "$CANDALF_ROOT"/lib/candalf-local.sh
else
  . "$CANDALF_ROOT"/lib/candalf.sh
fi

bootstrap "$CANDALF_SERVER"

for SPELL_BOOK in "$@"
do
    echo -e "Applying spells from $SPELL_BOOK\n"
    candalf "$CANDALF_SERVER" "$SPELL_BOOK"
    echo -e "Applying spells from $SPELL_BOOK completed\n"
done


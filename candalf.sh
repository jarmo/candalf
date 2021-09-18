#!/usr/bin/env bash

usage() {
  echo "
Usage: $(basename "$0") [-l | --local] [-v | --verbose] SPELL_BOOK

Options:
  -l --local     apply spells to the local machine
  -v --verbose   enable verbose output
  -h --help      show this help

Examples:
  candalf example.org.sh
  candalf --local example.org.sh"
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
        local)
          LOCAL=1
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

LOCAL="${LOCAL:-""}"
if [[ "$LOCAL" != "" ]]; then
  . "$CANDALF_ROOT"/lib/candalf-local.sh
else
  . "$CANDALF_ROOT"/lib/candalf.sh
fi

SPELL_BOOK=${1:?"SPELL_BOOK not set!"}

bootstrap "$SPELL_BOOK"

echo -e "Applying spells from $SPELL_BOOK\n"
candalf "$SPELL_BOOK"
echo "Applying spells from $SPELL_BOOK completed"


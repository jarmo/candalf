#!/usr/bin/env bash

usage() {
  echo "
Usage: $(basename "$0") [-l | --local] [-v | --verbose] SPELL_BOOK_FILE

Options:
  -l --local     apply spells to the local machine
  -v --verbose   enable verbose output
  -h --help      show this help

Examples:
  candalf example.org
  candalf --local example.org"
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

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

CANDALF_ROOT=$(dirname $(realpath $0))

LOCAL="${LOCAL:-""}"
if [[ "$LOCAL" != "" ]]; then
  . $CANDALF_ROOT/lib/candalf-local.sh
else
  . $CANDALF_ROOT/lib/candalf.sh
fi

CANDALF_FILE=${1:?"SPELL_BOOK_FILE not set!"}

bootstrap "$CANDALF_FILE"

echo -e "Applying spells from $CANDALF_FILE\n"
candalf "$CANDALF_FILE"
echo "Applying spells from $CANDALF_FILE completed"


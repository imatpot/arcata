#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix

shopt -s extglob
shopt -s extdebug

#

bash src/vnc.sh
bash src/install.sh
bash src/server.sh


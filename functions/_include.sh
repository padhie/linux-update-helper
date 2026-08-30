#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/general.sh"     # need to be first
source "$SCRIPT_DIR/pacman.sh"
source "$SCRIPT_DIR/flatpak.sh"
source "$SCRIPT_DIR/aur.sh"
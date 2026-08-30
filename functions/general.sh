#!/bin/bash

BOLD="\033[1m"
ITALIC="\033[3m"
WHITE="\033[37m"
RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

is_manager() {
    case "$selected_package_manager" in
        "$1"|"all") return 0 ;;
        *) return 1 ;;
    esac
}

print_manager() {
    local param="${1,,}"
    case "$param" in
        "pacman") echo -e "${BOLD}${ITALIC}${RED}pacman${RESET}" ;;
        "flatpak") echo -e "${BOLD}${ITALIC}${GREEN}flatpak${RESET}" ;;
        "aur") echo -e "${BOLD}${ITALIC}${BLUE}AUR${RESET}" ;;
        *) echo -e "${BOLD}${ITALIC}${WHITE}$1${RESET}" ;;
    esac
}

appy_update() {
    local filtered_pacman_packages=$1
    local filtered_flatpak_packages=$2
    local filtered_aur_packages=$3

    while true; do
        echo ""
        read -p "Do you want to update? [J/n] " -r
        echo ""

        case "$REPLY" in
            y|Y|j|J|1|true|"")
                update_pacman_packages "$filtered_pacman_packages"
                update_flatpak_packages "$filtered_flatpak_packages"
                update_aur_packages "$filtered_aur_packages"
                break
                ;;
            *)
                echo "🚫 Update abort"
                break
                ;;
        esac
    done

    echo "✅ Update done!"
}
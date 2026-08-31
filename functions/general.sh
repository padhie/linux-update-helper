#!/bin/bash

BOLD="\033[1m"
ITALIC="\033[3m"
WHITE="\033[37m"
RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

load_args() {
    while [ "$#" -ge 1 ]; do
        case "$1" in
            --dryRun)
                dry_run=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --aur)
                package_manager_arg="aur"
                shift
                ;;
            --pacman)
                package_manager_arg="pacman"
                shift
                ;;
            --flatpak)
                package_manager_arg="flatpak"
                shift
                ;;
            *)
                echo "❌ invalid argument: $1"
                echo "possible arguments: $0 [--dryRun] [-f|--force]"
                exit 1
                ;;
        esac
    done
}

get_package_manager() {
    package_manager_parameter="$1"
    let selected_package_manager

    echo "#$package_manager_parameter#" >&2
    if [ "$package_manager_parameter" != "" ]; then
        if is_manager_allowed "$package_manager_parameter"; then
            echo "$package_manager_parameter"
            return
        fi
    fi

    while ! is_manager_allowed "$selected_package_manager"; do
        echo "" >&2
        echo "Select the package manager:" >&2
        echo "1) $(print_manager "pacman")" >&2
        echo "2) $(print_manager "flatpak")" >&2
        echo "3) $(print_manager "aur")" >&2
        echo "0) $(print_manager "all")" >&2
        read -p "Please select (0-3): " choice

        case "$choice" in
            1) selected_package_manager="pacman"   ;;
            2) selected_package_manager="flatpak"   ;;
            3) selected_package_manager="aur"   ;;
            0) selected_package_manager="all"   ;;
            *) echo "❌ Invalid choose. Try again" >&2  ;;
        esac
    done

    echo "$selected_package_manager"
}

is_manager_allowed() {
    case "$1" in
        "pacman"|"flatpak"|"aur"|"all") return 0 ;;
        *) return 1 ;;
    esac
}

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

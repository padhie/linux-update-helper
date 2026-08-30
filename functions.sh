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

get_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

updatable_pacman_packages() {
    if ! is_manager "pacman"; then
        echo ""
        return
    fi

    if ! command -v pacman &>/dev/null; then
        echo "⚠️ $(print_manager "pacman") not installed, $(print_manager "pacman")-Pakages will be skipped." >&2
        echo ""
        return
    fi

    local current_time=$(date +%s)
    local selected_time=$1

    local upgradable_packages
    upgradable_packages=$(pacman -Qu | awk '{print $1}')

    local filtered_packages=""
    for pkg in $upgradable_packages; do
        local pkg_info install_date_raw install_date time_since_install days_old version
        pkg_info=$(LC_ALL=C pacman -Qi "$pkg" 2>/dev/null)
        install_date_raw=$(echo "$pkg_info" | awk -F' : ' '/^Install Date/ {print $2}')
        install_date=$(date -d "$install_date_raw" +%s 2>/dev/null)

        if [ -z "$install_date" ]; then
            echo "⚠️ Install date for $pkg not found, skipped..." >&2
            continue
        fi

        time_since_install=$((current_time - install_date))

        if [ "$selected_time" -eq 0 ] || [ "$time_since_install" -ge "$selected_time" ]; then
            days_old=$((time_since_install / 86400))
            version=$(echo "$pkg_info" | awk -F' : ' '/^Version/ {print $2}')
            echo "📦 $pkg (install for $days_old days, Version: $version)" >&2

            if [ -z "$filtered_packages" ]; then
                filtered_packages="$pkg"
            else
                filtered_packages="$filtered_packages $pkg"
            fi
        fi
    done

    echo "$filtered_packages"
}

updatable_flatpak_packages() {
    if ! is_manager "flatpak"; then
        echo ""
        return
    fi

    if ! command -v flatpak &>/dev/null; then
        echo "⚠️ $(print_manager "flatpak") not installed, $(print_manager "flatpak")-Pakages will be skipped." >&2
        echo ""
        return
    fi

    local current_time=$(date +%s)
    local selected_time=$1

    local flatpak_apps
    flatpak_apps=$(flatpak list --app --columns=application)

    local filtered_packages=""
    for app in $flatpak_apps; do
        local install_path
        install_path=$(flatpak info --show-location "$app" 2>/dev/null)

        if [ -z "$install_path" ] || [ ! -d "$install_path" ]; then
            echo "⚠️ Installpath for $app not found, skipped..." >&2
            continue
        fi

        local install_date
        install_date=$(stat -c %Y "$install_path" 2>/dev/null)

        if [ -z "$install_date" ]; then
            echo "⚠️ Installdate for $app not found, skipped..." >&2
            continue
        fi

        local time_since_install=$((current_time - install_date))

        if [ "$selected_time" -eq 0 ] || [ "$time_since_install" -ge "$selected_time" ]; then
            local days_old=$((time_since_install / 86400))
            local version
            version=$(flatpak info "$app" 2>/dev/null | awk -F': ' '/^Version/ {print $2}')
            echo "📦 $app (install for $days_old days, Version: $version)" >&2

            if [ -z "$filtered_packages" ]; then
                filtered_packages="$app"
            else
                filtered_packages="$filtered_packages $app"
            fi
        fi
    done

    echo "$filtered_packages"
}

updatable_aur_packages() {
    if ! is_manager "aur"; then
        echo ""
        return
    fi

    local aur_helper
    aur_helper=$(get_aur_helper)

    if [ -z "$aur_helper" ]; then
        echo "⚠️ no $(print_manager "aur") package manager (paru/yay) found, $(print_manager "aur") packages will be skipped." >&2
        echo ""
        return
    fi

    local current_time=$(date +%s)
    local selected_time=$1

    local upgradable_packages
    upgradable_packages=$("$aur_helper" -Qua | awk '{print $1}')

    local filtered_packages=""
    for pkg in $upgradable_packages; do
        local pkg_info install_date_raw install_date time_since_install days_old version
        pkg_info=$(LC_ALL=C pacman -Qi "$pkg" 2>/dev/null)
        install_date_raw=$(echo "$pkg_info" | awk -F' : ' '/^Install Date/ {print $2}')
        install_date=$(date -d "$install_date_raw" +%s 2>/dev/null)

        if [ -z "$install_date" ]; then
            echo "⚠️ Install date for $pkg not found, skipped..." >&2
            continue
        fi

        time_since_install=$((current_time - install_date))

        if [ "$selected_time" -eq 0 ] || [ "$time_since_install" -ge "$selected_time" ]; then
            days_old=$((time_since_install / 86400))
            version=$(echo "$pkg_info" | awk -F' : ' '/^Version/ {print $2}')
            echo "📦 $pkg (install for $days_old days, Version: $version)" >&2

            if [ -z "$filtered_packages" ]; then
                filtered_packages="$pkg"
            else
                filtered_packages="$filtered_packages $pkg"
            fi
        fi
    done

    echo "$filtered_packages"
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

update_pacman_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        return
    fi

    echo "🔄 Update $(print_manager "pacman") packages: $packages" >&2
    sudo pacman -S --noconfirm $packages
}

update_flatpak_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        return
    fi

    echo "🔄 Update $(print_manager "flatpak") packages: $packages" >&2
     flatpak update -y $packages
}

update_aur_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        return
    fi

    local aur_helper
    aur_helper=$(get_aur_helper)

    if [ -z "$aur_helper" ]; then
        echo "⚠️ no $(print_manager "aur") package manager (paru/yay) found, $(print_manager "aur") packages will be skipped." >&2
        echo ""
        return
    fi

    echo "🔄 update $(print_manager "AUR") packages: $packages" >&2
    "$aur_helper" -S --noconfirm $packages
}

#!/bin/bash

get_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
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

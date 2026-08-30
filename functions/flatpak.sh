#!/bin/bash

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

update_flatpak_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        return
    fi

    echo "🔄 Update $(print_manager "flatpak") packages: $packages" >&2
     flatpak update -y $packages
}
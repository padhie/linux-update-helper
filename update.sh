#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/functions.sh"

dry_run=false
force=false

while [ "$#" -ge 1 ]; do
    case "$1" in
        --dryRun)
            dry_run=true
            echo "🔍 use dry mode"
            shift
            ;;
        -f|--force)
            force=true
            echo "⚡ use force mode"
            shift
            ;;
        *)
            echo "❌ invalid argument: $1"
            echo "possible arguments: $0 [--dryRun] [-f|--force]"
            exit 1
            ;;
    esac
done

while true; do
    echo "Select the package manager:"
    echo "1) $(print_manager "pacman")"
    echo "2) $(print_manager "flatpak")"
    echo "3) $(print_manager "aur")"
    echo "0) $(print_manager "all")"
    read -p "Please select (0-3): " choice

    case "$choice" in
        1) selected_package_manager="pacman";
           break ;;
        2) selected_package_manager="flatpak";
           break ;;
        3) selected_package_manager="aur";
           break ;;
        0) selected_package_manager="all";
           break ;;
        *) echo "❌ Invalid choose. Try again" ;;
    esac
done

while true; do
    echo "Select the package age:"
    echo "1) 3 Months"
    echo "2) 2 Months"
    echo "3) 1 Month (30 Days)"
    echo "4) 4 Weeks (28 days)"
    echo "5) 3 Weeks"
    echo "6) 2 Weeks"
    echo "7) 1 Week"
    echo "0) now"
    read -p "Please select (0-7): " choice

    case "$choice" in
        0) selected_time=0;
           selection_time_text="now";
           break ;;
        1) selected_time=$((90 * 24 * 60 * 60));
           selection_time_text="3 Months";
           break ;;
        2) selected_time=$((60 * 24 * 60 * 60));
           selection_time_text="2 Months";
           break ;;
        3) selected_time=$((30 * 24 * 60 * 60));
           selection_time_text="1 Month (30 Days)";
           break ;;
        4) selected_time=$((28 * 24 * 60 * 60));
           selection_time_text="4 Weeks ( 28 Days)";
           break ;;
        5) selected_time=$((21 * 24 * 60 * 60));
           selection_time_text="3 Weeks";
           break ;;
        6) selected_time=$((14 * 24 * 60 * 60));
           selection_time_text="2 Weeks";
           break ;;
        7) selected_time=$((7 * 24 * 60 * 60));
           selection_time_text="1 Week";
           break ;;
        *) echo "❌ Invalid choose. Try again" ;;
    esac
done

echo ""
echo "Your selection: "
echo "Package manager: $(print_manager "$selected_package_manager")"
echo "Package age: $selection_time_text"

echo ""
filtered_pacman_packages=$(updatable_pacman_packages "$selected_time")
filtered_flatpak_packages=$(updatable_flatpak_packages "$selected_time")
filtered_aur_packages=$(updatable_aur_packages "$selected_time")

if [ -z "$filtered_pacman_packages" ] && [ -z "$filtered_flatpak_packages" ] && [ -z "$filtered_aur_packages" ]; then
    echo ""
    echo "❌ No package found for your selected date and package manager"
    exit 0
fi

echo ""
echo "📋 Following packages will be updated:"
if is_manager "pacman"; then echo "$(print_manager "pacman"): $filtered_pacman_packages"; fi
if is_manager "flatpak"; then echo "$(print_manager "flatpak"): $filtered_flatpak_packages"; fi
if is_manager "aur"; then echo "$(print_manager "aur"): $filtered_aur_packages"; fi

if [ "$dry_run" = true ]; then
    echo ""
    echo "🔍 Dry-Run: Skip update"
    exit 0
fi

if [ "$force" = true ]; then
    echo ""
    echo "⚡ Force Modus: force updating all packages"
    update_pacman_packages "$filtered_pacman_packages"
    update_flatpak_packages "$filtered_flatpak_packages"
    update_aur_packages "$filtered_aur_packages"
    exit 0
fi

appy_update "$filtered_pacman_packages" "$filtered_flatpak_packages" "$filtered_aur_packages"

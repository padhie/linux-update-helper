#!/bin/bash

# Dry-Run Modus (Standard: false)
dry_run=false
# Force Modus (Standard: false)
force=false

# Funktion zum Aktualisieren von Paketen
update_packages() {
    local packages="$1"
    for pkg in $packages; do
        echo "🔄 Update $pkg..."
        sudo pacman -S "$pkg" --noconfirm
    done
    echo "✅ Update done!"
}

# Argumentprüfung
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

# Liste aller aktualisierbaren Pakete
upgradable_packages=$(pacman -Qu | awk '{print $1}')

# Aktuelles Datum in Sekunden seit Epoch
current_time=$(date +%s)

# Interaktive Auswahl (in gewünschter Reihenfolge)
while true; do
    echo "Wähle eine Option:"
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
           selection_text="now";
           break ;;
        1) selected_time=$((90 * 24 * 60 * 60));
           selection_text="3 Months";
           break ;;
        2) selected_time=$((60 * 24 * 60 * 60));
           selection_text="2 Months";
           break ;;
        3) selected_time=$((30 * 24 * 60 * 60));
           selection_text="1 Month (30 Days)";
           break ;;
        4) selected_time=$((28 * 24 * 60 * 60));
           selection_text="4 Weeks ( 28 Days)";
           break ;;
        5) selected_time=$((21 * 24 * 60 * 60));
           selection_text="3 Weeks";
           break ;;
        6) selected_time=$((14 * 24 * 60 * 60));
           selection_text="2 Weeks";
           break ;;
        7) selected_time=$((7 * 24 * 60 * 60));
           selection_text="1 Week";
           break ;;
        *) echo "❌ Invalid choose. Try again" ;;
    esac
done

echo ""
echo "Your selection: $selection_text"

# Pakete filtern und anzeigen
filtered_packages=""
for pkg in $upgradable_packages; do
    # pacman -Qi ist lokalisiert -> LC_ALL=C erzwingt englische Feldnamen und ein
    # von `date -d` parsebares Datumsformat
    pkg_info=$(LC_ALL=C pacman -Qi "$pkg" 2>/dev/null)

    # Installationsdatum in Sekunden seit Epoch
    install_date_raw=$(echo "$pkg_info" | awk -F' : ' '/^Install Date/ {print $2}')
    install_date=$(date -d "$install_date_raw" +%s 2>/dev/null)

    if [ -z "$install_date" ]; then
        echo "⚠️ Installdate for $pkg not found, skipped..."
        continue
    fi

    time_since_install=$((current_time - install_date))

    if [ "$selected_time" -eq 0 ] || [ "$time_since_install" -ge "$selected_time" ]; then
        days_old=$((time_since_install / 86400))
        version=$(echo "$pkg_info" | awk -F' : ' '/^Version/ {print $2}')
        echo "📦 $pkg (install for $days_old days, Version: $version)"
        if [ -z "$filtered_packages" ]; then
            filtered_packages="$pkg"
        else
            filtered_packages="$filtered_packages $pkg"
        fi
    fi
done

# Bestätigung einholen
if [ -z "$filtered_packages" ]; then
    echo "❌ No package found with your selected date"
    exit 0
fi

echo "📋 Following packages will be updated:"
echo "$filtered_packages" | tr ' ' '\n'

if [ "$dry_run" = true ]; then
    echo "🔍 Dry-Run: Skip update"
    exit 0
fi

if [ "$force" = true ]; then
    echo "⚡ Force Modus: force updating all packages"
    update_packages "$filtered_packages"
    exit 0
fi

while true; do
    read -p "Do you want to udpate? [J/n] " -r
    echo
    case "$REPLY" in
        y|Y|j|J|1|true|"")
            update_packages "$filtered_packages"
            break
            ;;
        *)
            echo "🚫 Update abort"
            break
            ;;
    esac
done

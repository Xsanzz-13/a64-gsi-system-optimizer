#!/system/bin/sh

# --- FAST CHARGING BY XSANZ ---

# Path status baterai
STATUS_FILE="/sys/class/power_supply/battery/status"

# Nilai arus saat fast charging (3A)
FAST_CURRENT="3000000"

# Nilai arus normal/reset (0A)
NORMAL_CURRENT="0"

# --- DAFTAR FILE LIMIT ARUS ---
# Inilah kelima path yang akan dikendalikan:
CHARGE_FILES=(
    # Path spesifik BQ2560X
    "/sys/class/power_supply/bq2560x_charger/input_current_limit"
    "/sys/class/power_supply/bq2560x_charger/constant_charge_current"
    
    # Path umum
    "/sys/class/power_supply/battery/input_current_limit"
    "/sys/class/power_supply/battery/constant_charge_current"
    "/sys/class/power_supply/battery/charge_control_limit" 
)

# --- LOGIKA SKRIP (MONITOR 1 DETIK) ---

while true; do
  CURRENT_STATUS=$(cat "$STATUS_FILE")

  # 1. JIKA CHARGING
  if [ "$CURRENT_STATUS" = "Charging" ]; then
    
    # Loop untuk memaksa nilai FAST_CURRENT ke setiap file
    for FILE_PATH in "${CHARGE_FILES[@]}"; do
        if [ -f "$FILE_PATH" ]; then
            # Paksa izin tulis 
            chmod 666 "$FILE_PATH"
            # Tulis Nilai FAST_CURRENT (3000000)
            echo "$FAST_CURRENT" > "$FILE_PATH"
            # Kembalikan ke izin aman
            chmod 644 "$FILE_PATH"
        fi
    done

  # 2. JIKA DICABUT (DISCHARGING): Kembalikan ke 0
  elif [ "$CURRENT_STATUS" = "Discharging" ]; then
    
    # Loop untuk mereset nilai ke NORMAL_CURRENT (0)
    for FILE_PATH in "${CHARGE_FILES[@]}"; do
        if [ -f "$FILE_PATH" ]; then
            # Paksa izin tulis 
            chmod 666 "$FILE_PATH"
            # Tulis Nilai NORMAL_CURRENT (0)
            echo "$NORMAL_CURRENT" > "$FILE_PATH"
            # Kembalikan ke izin aman
            chmod 644 "$FILE_PATH"
        fi
    done
  fi

  # Cek dan ulangi setiap 1 detik
  sleep 1
done
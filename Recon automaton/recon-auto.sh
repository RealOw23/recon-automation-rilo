#!/bin/bash

# Konfigurasi Path (Asumsi skrip dijalankan dari dalam folder scripts/)
INPUT_FILE="../input/domains.txt"
ALL_SUBDOMAINS="../output/all-subdomains.txt"
LIVE_HOSTS="../output/live.txt"
PROGRESS_LOG="../logs/progress.log"
ERROR_LOG="../logs/errors.log"

# Fungsi untuk mendapatkan timestamp
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# 1. Inisialisasi: Pastikan folder dan file tersedia
mkdir -p ../output ../logs
touch "$ALL_SUBDOMAINS" "$LIVE_HOSTS"

echo "===============================================" | tee -a "$PROGRESS_LOG"
echo "$(timestamp) - Memulai Proses Recon Otomatis" | tee -a "$PROGRESS_LOG"
echo "===============================================" | tee -a "$PROGRESS_LOG"

# Cek apakah file input/domains.txt tersedia dan tidak kosong
if [[ ! -f "$INPUT_FILE" || ! -s "$INPUT_FILE" ]]; then
    echo "$(timestamp) - [ERROR] File input/domains.txt tidak ditemukan atau kosong!" | tee -a "$PROGRESS_LOG"
    exit 1
fi

# 2. Proses Subdomain Enumeration dengan Subfinder & Deduplikasi dengan Anew
echo "$(timestamp) - Tahap 1: Enumerasi Subdomain & Deduplikasi" | tee -a "$PROGRESS_LOG"

while read -r domain; do
    if [[ -n "$domain" ]]; then
        echo "$(timestamp) - Memproses domain: $domain" | tee -a "$PROGRESS_LOG"
        # Menjalankan subfinder dan membuang error ke logs/errors.log
        subfinder -d "$domain" -silent 2>> "$ERROR_LOG" | anew "$ALL_SUBDOMAINS" >> "$PROGRESS_LOG"
    fi
done < "$INPUT_FILE"

# 3. Filter Host yang Hidup dengan httpx
echo "$(timestamp) - Tahap 2: Memfilter Host yang Hidup (httpx)" | tee -a "$PROGRESS_LOG"

if [[ -s "$ALL_SUBDOMAINS" ]]; then
    # Menggunakan httpx untuk mendapatkan status code dan title
    # Output diformat sesuai permintaan: URL [Status] [Title]
    cat "$ALL_SUBDOMAINS" | httpx -silent -status-code -title -no-color 2>> "$ERROR_LOG" | anew "$LIVE_HOSTS" | tee -a "$PROGRESS_LOG"
else
    echo "$(timestamp) - [WARNING] Tidak ada subdomain unik yang ditemukan untuk diproses." | tee -a "$PROGRESS_LOG"
fi

# 4. Ringkasan Akhir
UNIQUE_COUNT=$(wc -l < "$ALL_SUBDOMAINS")
LIVE_COUNT=$(wc -l < "$LIVE_HOSTS")

echo "" | tee -a "$PROGRESS_LOG"
echo "------------------- RINGKASAN -------------------" | tee -a "$PROGRESS_LOG"
echo "$(timestamp) - Proses Selesai!" | tee -a "$PROGRESS_LOG"
echo "Total Subdomain Unik: $UNIQUE_COUNT" | tee -a "$PROGRESS_LOG"
echo "Total Live Hosts    : $LIVE_COUNT" | tee -a "$PROGRESS_LOG"
echo "-------------------------------------------------" | tee -a "$PROGRESS_LOG"

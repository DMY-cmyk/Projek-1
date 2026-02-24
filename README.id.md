# Projek-1
Dokumen diperbarui: 2026-02-23

Workspace Rust yang berpusat pada rencana detail untuk menganalisis fundamental Apple Inc. menggunakan API SEC `data.sec.gov`. Kode ini adalah binary starter minimal dan dapat diperluas menjadi alat pengambilan data dan analisis.

## Isi
- `src/main.rs` binary starter.
- `Plan.md` rencana analisis detail.
- `analysis_config.toml` parameter rencana yang digunakan untuk menjalankan analisis.
- `scripts/` pipeline PowerShell untuk pengambilan/ekstraksi/metrik/laporan SEC.
- `research/`, `data/`, `models/`, `outputs/` folder kerja.
- `.gitignore` mencakup output build Rust dan pola kredensial/rahasia.

## Parameter rencana (dari `analysis_config.toml`)
- Tanggal analisis: 2025-01-01.
- Batas pelaporan: tahun fiskal terbaru yang tersedia per 2025-01-01.
- Mata uang/satuan: USD, miliar.
- Panjang histori: 5 tahun tahunan.
- Sumber data: SEC `data.sec.gov` (company facts, submissions, frames opsional).

## Kebutuhan
- Toolchain Rust (cargo + rustc).
- Di Windows, linker MSVC diperlukan untuk build dengan toolchain default.
- PowerShell (untuk skrip analisis).
- Di Windows, .NET charting (System.Windows.Forms.DataVisualization) dibutuhkan untuk merender grafik.

## Mulai cepat
```powershell
cargo run
```

## Pengambilan API SEC (Rust)
Ambil dan cache JSON SEC ke `research/sec/` dengan log permintaan.
```powershell
cargo run -- fetch-sec --cik 0000320193 --user-agent "Name email@domain.com"
```

## Pipeline lengkap (Rust + PowerShell)
Jalankan pipeline end-to-end (fetch, ekstraksi, metrik, valuasi, laporan, grafik).
```powershell
cargo run -- run-pipeline --cik 0000320193 --user-agent "Name email@domain.com" --price 264.58 --as-of-date 2026-02-20
```

## Grafik (PowerShell)
Hasilkan grafik PNG ke `outputs/charts/`.
```powershell
.\scripts\build_charts.ps1
```

## Dashboard (PowerShell)
Hasilkan dashboard monitoring ringan di `outputs/dashboard.md`.
```powershell
.\scripts\build_dashboard.ps1
```

## Log kejadian kunci (PowerShell)
Hasilkan log filing ringkas (10-K/10-Q/8-K) di `outputs/key_events.md`.
```powershell
.\scripts\build_key_events.ps1
```

## Freshness data (PowerShell)
Periksa umur filing terbaru dan snapshot valuasi di `outputs/freshness_report.md`.
```powershell
.\scripts\check_data_freshness.ps1
```

## Change log (PowerShell)
Ringkas delta YoY ke `outputs/change_log.md`.
```powershell
.\scripts\build_change_log.ps1
```

## Drift alerts (PowerShell)
Tandai outlier dibanding rata-rata 5 tahun di `outputs/drift_alerts.md`.
```powershell
.\scripts\build_drift_alerts.ps1
```

## Scenario stress tester (PowerShell)
Hasilkan tabel stress sederhana di `outputs/scenario_stress.md`.
```powershell
.\scripts\build_scenario_stress.ps1
```

## Report pack (PowerShell)
Jalankan semua generator dan tulis run log di `outputs/run_log.md`.
```powershell
.\scripts\build_report_pack.ps1
```

## One-command refresh (PowerShell)
Ambil data SEC dan jalankan report pack dalam satu perintah.
```powershell
.\scripts\refresh_all.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## One-command refresh (dry run)
Validasi input dan tampilkan langkah yang akan dijalankan tanpa network call.
```powershell
.\scripts\refresh_all_dryrun.ps1 -UserAgent "Name email@domain.com" -Price 264.58 -AsOfDate 2026-02-20
```

## Refresh status (PowerShell)
Verifikasi output dan timestamp di `outputs/refresh_status.md`.
```powershell
.\scripts\refresh_all_status.ps1
```

## Quick review (PowerShell)
Ringkas output utama di `outputs/quick_review.md`.
```powershell
.\scripts\build_quick_review.ps1
```

## Cleanup (PowerShell)
Dry-run pembersihan JSON SEC dan run log lama; gunakan `-Execute` untuk menghapus.
```powershell
.\scripts\cleanup_runs.ps1
.\scripts\cleanup_runs.ps1 -Execute
```

## Refresh multiple peer (PowerShell)
Ambil multiple peer terbaru (parsing HTML best-effort) ke `data/peer_multiples.csv`.
```powershell
.\scripts\update_peer_multiples.ps1
```

## Pipeline analisis (PowerShell)
Jalankan ini berurutan setelah mengatur User-Agent SEC yang valid.
```powershell
.\scripts\fetch_sec_sources.ps1 -UserAgent "Name email@domain.com"
.\scripts\extract_companyfacts.ps1 -CompanyFactsPath "research\sec\companyfacts_YYYY-MM-DD.json"
.\scripts\compute_metrics.ps1
.\scripts\validate_financials.ps1
.\scripts\compute_valuation.ps1 -Price 0.00 -AsOfDate YYYY-MM-DD
.\scripts\build_report.ps1
```

## Output
- `data/financials_*.csv` fakta SEC yang diekstrak (USD miliar).
- `data/metrics_*.csv` metrik turunan (margin, pertumbuhan, likuiditas, arus kas).
- `data/valuation_snapshot.csv` snapshot multiple valuasi.
- `data/validation_report.txt` pemeriksaan kesehatan data.
- `data/tag_validation_report.txt` pemeriksaan satuan/periode tag SEC.
- `data/reconciliation_notes.md` catatan rekonsiliasi penjualan bersih.
- `data/one_time_items_notes.md` pos satu kali yang menonjol dari 10-K.
- `data/reconciliation_balance_sheet.md` pemeriksaan persamaan neraca.
- `data/reconciliation_cashflow.md` pemeriksaan perubahan arus kas vs arus kas bersih.
- `outputs/report.md` draf laporan yang dirakit dari tabel.
- `models/dcf_base_case.csv` dan `models/dcf_summary.md` DCF ilustratif.
- `research/notes_debt_liquidity.md` catatan jatuh tempo utang dan sensitivitas bunga.

## Pemecahan masalah
- Jika permintaan ke SEC gagal, pastikan User-Agent berisi nama + email yang nyata dan coba lagi.
- Tag yang hilang umum terjadi di XBRL; periksa `data/validation_report.txt` dan perbarui pemetaan tag di `scripts/extract_companyfacts.ps1`.
- Jika skrip fetch time out, jalankan ulang; endpoint SEC bisa lambat.

## Sorotan rencana
- Kumpulkan 10-K, 10-Q, 8-K, surat pemegang saham, dan transkrip earnings.
- Gunakan API SEC untuk data XBRL yang distandardkan dengan caching dan rate limit.
- Normalisasi ke USD miliar dan rekonsiliasi tag lintas filing.
- Analisis profitabilitas, bauran pertumbuhan, neraca, arus kas, valuasi, dan risiko.
- Validasi data SEC terhadap filing dan catat permintaan API.

## Langkah berikutnya
- Modul Rust untuk pengambilan/cache SEC sudah ditambahkan (`cargo run -- fetch-sec`).
- Grafik dapat dihasilkan dari `data/` melalui `scripts/build_charts.ps1`.
- Data multiple peer disimpan di `data/peer_multiples.csv` dengan sumber di `research/peer_multiples_sources.md`.
- Data fundamental peer disimpan di `data/peer_fundamentals.csv` dengan sumber di `research/peer_fundamentals_sources.md`.

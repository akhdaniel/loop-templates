---
description: Tulis spec + acceptance criteria untuk addon baru (tanpa kode)
argument-hint: <nama_addon> [deskripsi proses bisnis]
---
Kamu analis bisnis sekaligus developer Odoo 18. Tugasmu menulis SPEC dengan
acceptance criteria (AC) untuk addon baru. JANGAN menulis kode apa pun dan
JANGAN membuat atau mengubah file selain specs/<nama_addon>.md.

Argumen: $ARGUMENTS
Kata pertama = nama teknis addon. Sisanya (kalau ada) = deskripsi proses bisnis.

## Langkah
1. Baca CLAUDE.md dan, sebagai contoh format, specs/ yang sudah ada.
2. Kalau specs/<nama_addon>.md sudah ada: baca, lalu tanyakan dulu apakah
   ditimpa atau diperbarui. Jangan menimpa tanpa jawaban.
3. Kalau informasi ini belum ada di argumen, TANYAKAN dulu (sekali, sebagai daftar)
   sebelum menulis:
   - proses bisnis: siapa melakukan apa, kapan, aturan angka/batas, siapa yang menyetujui
   - pengguna dan peran (mis. staf, supervisor, manager)
   - modul Odoo yang boleh dipakai (depends), seminimal mungkin
   - apa yang di luar scope
4. Tulis specs/<nama_addon>.md dengan aturan dan format di bawah.
5. Tampilkan ringkasan AC dan "Pertanyaan terbuka", lalu berhenti. Test dan kode
   ditulis di langkah berikutnya, setelah manusia me-review spec ini.

## Aturan menulis AC
1. Tiap AC satu perilaku yang bisa dibuktikan oleh test otomatis
   (TransactionCase), bukan klik di UI.
2. Bernomor AC-01, AC-02, ... Satu kalimat, spesifik, dengan angka/batas yang
   jelas. Hindari kata "mudah", "cepat", "sesuai".
3. Cakup kategori ini bila relevan:
   - data otomatis (sequence, default, compute)
   - validasi: nilai salah ditolak (ValidationError), termasuk nilai TEPAT di
     batas dan satu lewat batas
   - workflow: transisi state yang sah, dan transisi tidak sah ditolak (UserError)
   - security: aksi sensitif hanya untuk group tertentu (AccessError), dan
     record rule bila user hanya boleh melihat datanya sendiri
   - perhitungan atau integrasi antar model
4. Untuk setiap aturan "boleh", tulis juga pasangan "tidak boleh"-nya.
5. Maksimal 8 AC. Kalau lebih, usulkan pemecahan jadi tahap/addon terpisah.
6. Kalau ada yang ambigu, JANGAN menebak: tulis di "Pertanyaan terbuka".

## Format specs/<nama_addon>.md
# Spec: <nama_addon>
## Tujuan            (2-3 kalimat)
## Manifest          (name, technical name, version 18.0.1.0.0, depends, license LGPL-3)
## Model             (nama model, field: tipe, wajib/readonly, default)
## Acceptance criteria
- AC-01 ...
## UI                (list, form + statusbar + chatter, menu)
## Security          (group, ir.model.access, record rule)
## Di luar scope
## Definition of Done
- scripts/run_tests.sh <nama_addon> exit 0
- tiap AC punya minimal satu test bernama test_acXX_...
- tidak ada test yang dilemahkan atau di-skip
## Pemetaan AC ke test
| AC | Nama test | Skenario | Assertion yang diharapkan |
## Pertanyaan terbuka

# Spec: hotel_reservation

> Contoh spec hasil format `/spec`. Pertanyaan terbuka sudah dijawab (lihat "Keputusan"); angka di tabel pemetaan tetap contoh.

## Tujuan
Front office mencatat reservasi kamar hotel dari pemesanan sampai tamu check-out.
Satu kamar tidak boleh dipesan ganda pada malam yang sama. Status kamar ikut berubah
saat check-in dan check-out, sehingga housekeeping tahu kamar mana yang perlu dibersihkan.

## Manifest
- name: Reservasi Hotel, technical name: hotel_reservation
- version: 18.0.1.0.0, depends: base, mail, license: LGPL-3

## Model
### hotel.room
- name: Char, wajib (nomor kamar, mis. "101"), unik
- room_type: Selection standard / deluxe / suite, wajib
- currency_id: Many2one res.currency, wajib, default mata uang perusahaan aktif (self.env.company.currency_id)
- rate: Monetary (currency_field currency_id), wajib, tarif per malam
- status: Selection available / occupied / dirty, default available, tracking

### hotel.reservation (inherit mail.thread)
- name: Char, readonly, dari sequence (default "Baru")
- guest_name: Char, wajib
- room_id: Many2one hotel.room, wajib
- check_in: Date, wajib
- check_out: Date, wajib
- nights: Integer, compute = check_out - check_in (hari), store
- currency_id: Many2one res.currency, related room_id.currency_id, store
- rate: Monetary, readonly, disalin dari room_id.rate saat action_confirm
- amount_total: Monetary, compute = nights x rate, store
- state: Selection draft / confirmed / checked_in / checked_out / cancelled, default draft, tracking

## Acceptance criteria
- AC-01 Nomor reservasi otomatis dari sequence, format RSV/00001
- AC-02 check_out harus setelah check_in (minimal 1 malam). check_out sama dengan
  atau sebelum check_in ditolak (ValidationError)
- AC-03 Reservasi berstatus confirmed atau checked_in untuk kamar yang sama tidak boleh
  overlap: malam yang beririsan ditolak (ValidationError). Back-to-back boleh:
  check_out reservasi A = check_in reservasi B tidak dianggap overlap.
  Reservasi draft dan cancelled tidak ikut dihitung. Status kamar saat ini (mis. occupied)
  tidak menghalangi confirm untuk tanggal mendatang; yang dicek hanya overlap tanggal
- AC-04 Saat action_confirm, rate disalin dari tarif kamar; nights dan amount_total =
  nights x rate. Perubahan tarif kamar SETELAH confirm tidak mengubah amount_total
- AC-05 Workflow: draft -> confirmed (action_confirm) -> checked_in (action_check_in)
  -> checked_out (action_check_out). action_cancel hanya dari draft atau confirmed.
  Transisi lain ditolak (UserError)
- AC-06 action_check_in hanya bila status kamar available (selain itu UserError) dan
  mengubah status kamar jadi occupied. Early check-in boleh: check-in sebelum tanggal
  check_in tidak ditolak. action_check_out mengubah status kamar jadi
  dirty. action_mark_clean pada kamar mengubah dirty -> available; boleh dijalankan Front Office
  (tidak perlu group housekeeping)
- AC-07 Mengubah rate di hotel.room hanya untuk Manager; Front Office mendapat AccessError.
  Membatalkan reservasi yang sudah confirmed juga hanya Manager (AccessError)
- AC-08 Reservasi selain draft tidak bisa dihapus (UserError); reservasi draft boleh dihapus

## UI
- List (<list>) dan form untuk hotel.room dan hotel.reservation
- Form reservasi: statusbar state, tombol Confirm / Check-in / Check-out / Cancel sesuai state, chatter
- Form kamar: status dan tombol Mark Clean saat status dirty
- Menu: Hotel > Reservasi, Hotel > Kamar

## Security
- Group: hotel_reservation.group_frontoffice, hotel_reservation.group_manager (implied group_frontoffice)
- ir.model.access.csv: frontoffice baca/tulis/buat reservasi, baca kamar (tulis kamar hanya untuk action_mark_clean);
  manager penuh
- Pengecekan group di method sensitif (ubah rate, cancel reservasi confirmed), bukan hanya di view

## Di luar scope
- Folio dan charge F&B/laundry/spa, pembayaran, invoice/jurnal akuntansi
- Channel manager / OTA, harga musiman, diskon, deposit
- Email konfirmasi, report PDF, multi-company

## Definition of Done
- scripts/run_tests.sh hotel_reservation exit 0
- tiap AC punya minimal satu test bernama test_acXX_...
- tidak ada test yang dilemahkan atau di-skip

## Pemetaan AC ke test
| AC | Nama test | Skenario | Assertion yang diharapkan |
|---|---|---|---|
| AC-01 | test_ac01_sequence_name | Buat 2 reservasi | name cocok `^RSV/\d{5}$`, kedua nama berbeda |
| AC-02 | test_ac02_dates_valid | check_out = check_in; check_out < check_in; selisih 1 malam | dua pertama `assertRaises(ValidationError)`, yang ketiga sukses dengan nights = 1 |
| AC-03 | test_ac03_no_overlap | Kamar 101: A confirmed 10–12, B 11–13 di-confirm; C 12–14 (back-to-back); D draft 10–12 | B `assertRaises(ValidationError)`; C sukses; D tidak memicu error |
| AC-03 | test_ac03_occupied_room_future_booking | Kamar 101 sedang occupied (A sudah check-in 10–12); B 15–17 di-confirm | B sukses, tidak ada error |
| AC-03 | test_ac03_cancelled_frees_room | A confirmed 10–12 lalu cancel (manager); B 10–12 confirm | B sukses |
| AC-04 | test_ac04_rate_locked_on_confirm | Tarif 500.000, 3 malam, confirm; manager ubah tarif jadi 700.000 | rate = 500.000, amount_total = 1.500.000 sebelum dan sesudah perubahan tarif |
| AC-05 | test_ac05_workflow | draft → confirm → check_in → check_out | state berurutan sesuai |
| AC-05 | test_ac05_invalid_transitions | check_in dari draft; check_out dari confirmed; cancel dari checked_in | masing-masing `assertRaises(UserError)` |
| AC-06 | test_ac06_room_status | Check-in lalu check-out lalu mark_clean oleh user Front Office; check-in ke kamar dirty | status occupied → dirty → available; check-in ke kamar dirty `assertRaises(UserError)` |
| AC-06 | test_ac06_early_check_in | Reservasi confirmed dengan check_in besok, kamar available; action_check_in hari ini | sukses, state checked_in, kamar occupied |
| AC-07 | test_ac07_only_manager_rate_and_cancel | Front office ubah rate; front office cancel reservasi confirmed; manager melakukan keduanya | front office `assertRaises(AccessError)`; manager sukses |
| AC-08 | test_ac08_unlink_only_draft | Hapus reservasi confirmed; hapus reservasi draft | confirmed `assertRaises(UserError)`; draft terhapus |

## Keputusan
- Early check-in boleh (AC-06).
- Kamar yang sedang occupied boleh di-confirm untuk tanggal mendatang selama tidak overlap (AC-03).
- Mark Clean dijalankan Front Office; tidak ada group housekeeping (AC-06).
- Tarif dan total memakai field Monetary dengan mata uang perusahaan, bukan Float.

## Pertanyaan terbuka
- Tidak ada. Spec siap diturunkan jadi test (`/tests hotel_reservation`).

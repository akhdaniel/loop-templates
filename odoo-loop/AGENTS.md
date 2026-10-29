# Aturan project: odoo-loop

## Konteks
- Odoo 18, addon custom ada di addons/
- Spec di specs/<addon>.md adalah sumber kebenaran

## Definisi selesai (satu-satunya)
- Jalankan: scripts/run_tests.sh <nama_addon>
- Selesai HANYA kalau exit code 0 dan tercetak "=== LULUS ==="
- Jangan klaim selesai tanpa menjalankannya dan membaca hasilnya

## Aturan kerja
1. Awal sesi: baca spec dan PROGRESS.md
2. Kerjakan satu bagian kecil per iterasi, jalankan verifikasi, baru lanjut
3. DILARANG mengubah, menghapus, atau melemahkan file di tests/
   (dikunci lewat .tests.lock). Kalau test tampak salah: berhenti,
   tulis di PROGRESS.md, minta review manusia
4. DILARANG mengubah scripts/, .tests.lock, .pylintrc, dan .env.test
5. Jangan menambah fitur di luar scope spec
6. Akhir tiap iterasi: tulis ringkasan ke PROGRESS.md
7. Error yang sama 3 iterasi berturut-turut: berhenti, tulis hipotesis

## Konvensi Odoo 18
- View list pakai <list>, bukan <tree>
- Tanpa attrs/states: pakai invisible="state != 'draft'"
- Form pakai <chatter/>, model pakai _inherit = ['mail.thread']
- Setiap model punya baris di ir.model.access.csv, plus record rule bila perlu
- Manifest: version 18.0.x.y.z, license, semua file data terdaftar, depends lengkap
- Teks terjemahan pakai self.env._('...'), bukan _() global
- Error ke user: UserError / ValidationError / AccessError, bukan assert
- Computes and constraints must work on a NEW record in the form (onchange), where
  company_id / currency_id can still be empty. Never call currency_id.compare_amounts /
  .round / .is_zero directly; fall back first:
  `currency = rec.currency_id or (rec.company_id or self.env.company).currency_id`
  (otherwise: "ValueError: Expected singleton: res.currency()" on clicking New)
- A form only loads defaults for fields that are in the view. If company_id is shown
  with groups="base.group_multi_company", also add `<field name="company_id" invisible="1"/>`
  so related fields (currency_id) are filled for single-company users
- TransactionCase tests create records through the ORM and never run the form onchange,
  so green tests do not prove the New button works: open the form once by hand
  
## Larangan keamanan
- Jangan sentuh database selain db_test
- Jangan jalankan rm -rf, git push, dropdb, atau DROP DATABASE
  selain lewat scripts/run_tests.sh
- Jangan install paket sistem tanpa izin

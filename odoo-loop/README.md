# odoo-loop: Starter Praktik Loop Engineering (petty_cash)

Repo latihan training **Vibecoding Odoo dengan Loop Engineering** (Xerpium x VITRAINING).
Isinya fondasi dari e-book *Loop Engineering di Odoo*, diadaptasi supaya Odoo
dijalankan langsung dari command line (tanpa Docker).

Tugasmu: biarkan agent AI (Claude Code atau OpenCode) membangun addon `petty_cash`
sampai `scripts/run_tests.sh` keluar dengan exit 0. Spec dan test sudah disiapkan.

## Isi repo

| File | Fungsi |
|---|---|
| `specs/petty_cash.md` | Spec dan acceptance criteria AC-01 s/d AC-06 |
| `addons/petty_cash/tests/` | Test turunan AC (7 test). Addon-nya sendiri BELUM ada |
| `scripts/run_tests.sh` | Hakim: lint, DB bersih, install addon, test, vonis |
| `AGENTS.md` (+ `CLAUDE.md`) | Aturan project untuk semua agent |
| `PROGRESS.md` | Ingatan antar iterasi |
| `.claude/` | Permission, hook (PreToolUse + Stop), slash command, reviewer Claude Code |
| `opencode.json`, `.opencode/` | Permission, command, reviewer OpenCode |
| `scripts/run_loop*.sh` | Loop luar sesi (Claude Code / OpenCode) |
| `.pylintrc` | pylint-odoo, tanpa dua aturan khusus OCA (author & README.rst) |

## 1. Persiapan (lakukan SEBELUM hari training)

Butuh Linux, macOS, atau Windows dengan WSL2. Python 3.10 sampai 3.12, PostgreSQL 14+.

```bash
# Source Odoo 18
mkdir -p ~/odoo18 && cd ~/odoo18
git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git odoo
python3 -m venv venv
venv/bin/pip install -r odoo/requirements.txt
venv/bin/pip install flake8 pylint-odoo

# User PostgreSQL untuk Odoo (boleh create/drop database)
sudo -u postgres createuser --createdb --pwprompt odoo     # isi password: odoo
```

Kalau `pip install` gagal di `psycopg2` atau `python-ldap`, pasang dulu
`libpq-dev libldap2-dev libsasl2-dev` (Ubuntu/Debian), atau ganti baris
`psycopg2` di requirements dengan `psycopg2-binary`.
Pengguna macOS: `brew install coreutils` supaya ada `sha256sum`.

Tool AI (minimal satu, sudah bisa login):

```bash
npm install -g @anthropic-ai/claude-code   # Claude Code
npm install -g opencode-ai                 # OpenCode
```

Opsional: `jq` (dipakai hook Claude Code).

## 2. Siapkan repo

```bash
cd odoo-loop
cp .env.test.example .env.test     # lalu sesuaikan path di dalamnya
git init && git add -A && git commit -m "chore: starter odoo-loop"
scripts/run_tests.sh
```

Hasil yang benar di tahap ini: **GAGAL** dengan pesan
`addons/petty_cash/__manifest__.py belum ada`. Itu tandanya hakim hidup.

## 3. Review lalu kunci test

Baca `specs/petty_cash.md` dan `addons/petty_cash/tests/test_petty_cash.py`.
Kalau sudah yakin test-nya benar:

```bash
find addons/petty_cash/tests -name '*.py' -exec sha256sum {} + > .tests.lock
git add -A && git commit -m "test: acceptance tests petty_cash (locked)"
```

## 4. Jalankan loop

**Claude Code, loop di dalam sesi (Stop hook):**

```bash
LOOP_MODE=1 MODULE=petty_cash claude
# lalu ketik: /implement petty_cash
```

**Claude Code, loop di luar sesi:** `scripts/run_loop.sh petty_cash`

**OpenCode:** jalankan `opencode`, pilih agent `build`, ketik `/implement petty_cash`.
Atau loop luar sesi: `scripts/run_loop_opencode.sh petty_cash`

Satu putaran hakim butuh sekitar 30 detik sampai 1 menit.

## 5. Selesai? Review dulu

1. Jalankan sendiri `scripts/run_tests.sh` sekali lagi: harus `=== LULUS ===`.
2. `git diff HEAD --stat -- addons/petty_cash/tests` harus kosong.
3. Minta reviewer: Claude Code `pakai subagent odoo-reviewer buat review diff`,
   OpenCode `@odoo-reviewer review diff`.
4. Install di DB dev-mu dan klik alurnya sekali di UI:
   `venv/bin/python odoo/odoo-bin --addons-path=odoo/addons,<repo>/addons -d dev_pc -i petty_cash`
5. Commit: `git commit -am "feat(petty_cash): AC-01..AC-06 hijau"`

## Aturan penting

- Hakim hanya mau menyentuh DB yang namanya mengandung `test`. Jangan pernah arahkan ke production.
- Jangan edit `tests/`, `scripts/`, `.tests.lock`, `.pylintrc` saat loop berjalan.
  Kalau memang perlu, kamu (manusia) yang ubah lalu regenerate `.tests.lock`.

## Addon baru: mulai dari /spec

`/spec <nama_addon> [deskripsi proses bisnis]` menulis `specs/<nama_addon>.md`: acceptance criteria bernomor, pemetaan AC ke test, dan pertanyaan terbuka. Command ini tidak menulis kode. Ada di Claude Code (`.claude/commands/spec.md`) dan OpenCode (`.opencode/commands/spec.md`).

`/tests <nama_addon>` menulis **draf** test dari spec ke `drafts/<nama_addon>/tests/`, tanpa kode addon. Draf sengaja tidak ditulis langsung ke `addons/*/tests/` (folder itu dikunci untuk agent). Kamu yang me-review lalu memindahkannya, dan perintahnya dicetak di akhir output `/tests`.

Urutannya: `/spec` → review spec → `/tests` → review draf, salin ke `addons/<nama_addon>/tests/` → hakim harus GAGAL → kunci `.tests.lock` → `/implement <nama_addon>`.

### Catatan untuk addon kedua dan seterusnya

- **Kunci test semua addon sekaligus**: `find addons/*/tests -name '*.py' -exec sha256sum {} + > .tests.lock`. Kalau hanya `addons/<addon_baru>/tests`, lock lama tertimpa dan test addon lain tidak terkunci lagi.
- **Jalankan `/spec` dan `/tests` tanpa `LOOP_MODE=1`** (cukup `claude` biasa). Dengan LOOP_MODE, Stop hook menjalankan hakim yang pasti gagal karena addon belum ada, sehingga Claude dipaksa terus bekerja.
- **Saat loop, set MODULE ke addon yang dikerjakan**: `LOOP_MODE=1 MODULE=<nama_addon> claude`. Tanpa MODULE, Stop hook menguji `petty_cash`.
- **Satu PROGRESS.md per pekerjaan**: sebelum `/implement` addon baru, ganti checklist di `PROGRESS.md` dengan tahap addon itu (atau tambahkan bagian baru); `/implement` selalu membaca file ini.
- **Menambah fitur ke addon yang sudah ada**: perbarui AC di spec, jalankan `/tests`, lalu bandingkan dulu `diff -u addons/<addon>/tests/test_<addon>.py drafts/<addon>/tests/test_<addon>.py` sebelum menyalin. Setelah itu kunci ulang.

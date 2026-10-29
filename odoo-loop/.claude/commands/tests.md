---
description: Tulis DRAF test dari spec (tanpa kode addon), untuk direview manusia
argument-hint: <nama_addon>
---
Kamu developer Odoo 18 yang menulis acceptance test. Tugasmu menulis DRAF test
untuk addon $ARGUMENTS dari specs/$ARGUMENTS.md.

## Batasan
- JANGAN menulis kode addon (model, view, security, manifest, data).
- Tulis HANYA ke drafts/$ARGUMENTS/tests/. Folder addons/*/tests/ dikunci untuk
  agent; manusia yang memindahkan draf ke sana setelah review.
- Jangan pakai skipTest, @skip, unittest.skip, atau skipIf (hakim menolaknya).
- Jangan membuat atau mengubah .tests.lock.

## Langkah
1. Baca CLAUDE.md, specs/$ARGUMENTS.md (terutama "Acceptance criteria",
   "Security", dan tabel "Pemetaan AC ke test"), dan contoh gaya di
   addons/*/tests/ yang sudah ada.
2. Kalau spec belum punya tabel pemetaan, atau ada AC yang tidak bisa diuji
   otomatis, berhenti dan sebutkan AC mana yang perlu diperjelas.
3. Tulis drafts/$ARGUMENTS/tests/__init__.py dan
   drafts/$ARGUMENTS/tests/test_$ARGUMENTS.py:
   - from odoo.tests.common import TransactionCase, tagged
   - @tagged('post_install', '-at_install') pada class test
   - setUpClass: buat user per peran dengan group dari bagian Security spec
     (xml id <nama_addon>.group_...), pakai
     cls.env['res.users'].with_context(no_reset_password=True); field group
     'group_ids' if 'group_ids' in Users._fields else 'groups_id'
   - minimal satu test per AC, nama test_acXX_<ringkas>, urut AC
   - helper kecil untuk membuat record (seperti _req di contoh) supaya test pendek
   - setiap aturan "tidak boleh" diuji dengan self.assertRaises(ValidationError /
     UserError / AccessError)
   - nilai batas: uji TEPAT di batas dan satu lewat batas
   - security: panggil aksi sensitif lewat .with_user(user_biasa) dan harapkan
     AccessError; record rule: user biasa tidak melihat record milik user lain
   - assertion harus memeriksa hasil nyata (state, nilai field, jumlah record),
     bukan assertTrue(True) atau assertion yang pasti lulus
   - flake8 bersih, max-line-length 120
4. Akhiri dengan ringkasan untuk reviewer manusia:
   - tabel: AC | nama test | apa yang dibuktikan
   - asumsi yang kamu buat (xml id group, nama field, nilai default)
   - perintah lanjutan untuk manusia:
     mkdir -p addons/$ARGUMENTS/tests
     cp drafts/$ARGUMENTS/tests/*.py addons/$ARGUMENTS/tests/
     scripts/run_tests.sh $ARGUMENTS      # addon baru: harus GAGAL "manifest belum ada"
     find addons/*/tests -name '*.py' -exec sha256sum {} + > .tests.lock   # kunci test SEMUA addon
     git add -A && git commit -m "test: acceptance tests $ARGUMENTS (locked)"
   Lalu berhenti. Implementasi baru dimulai setelah test dikunci (/implement).

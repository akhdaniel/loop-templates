# Spec: petty_cash

## Tujuan
Karyawan mengajukan dana kas kecil. Pengajuan kecil (sampai Rp1.000.000)
langsung disetujui otomatis; pengajuan besar harus disetujui manager.
Setelah disetujui, manager menandai dana sudah dibayar.

## Manifest
- name: Kas Kecil, technical name: petty_cash
- version: 18.0.1.0.0, depends: base, mail, license: LGPL-3

## Model: petty.cash.request (inherit mail.thread)
- name: Char, readonly, dari sequence (default "Baru")
- requester_id: Many2one res.users, wajib, default user login
- amount: Float, wajib
- purpose: Char, wajib
- state: Selection draft / submitted / approved / paid, default draft, tracking
- approved_by: Many2one res.users, readonly

## Acceptance criteria
- AC-01 Nomor pengajuan otomatis dari sequence, format PC/00001
- AC-02 amount harus lebih dari 0; nilai 0 atau negatif ditolak (ValidationError)
- AC-03 Workflow: draft -> submitted (action_submit) -> approved (action_approve)
  -> paid (action_pay). action_pay hanya dari approved; selain itu UserError
- AC-04 Saat action_submit: amount <= 1.000.000 langsung approved;
  amount > 1.000.000 menjadi submitted dan menunggu manager
- AC-05 action_approve dan action_pay hanya untuk group Manager;
  user biasa mendapat AccessError. Saat approve, approved_by = user yang menyetujui
- AC-06 User biasa hanya melihat pengajuan miliknya; Manager melihat semua

## UI
- List (<list>) dan form view untuk petty.cash.request
- Form: statusbar state, tombol Submit / Approve / Pay sesuai state, chatter
- Menu: Kas Kecil > Pengajuan

## Security
- Group: petty_cash.group_user, petty_cash.group_manager (implied group_user)
- ir.model.access.csv untuk kedua group
- Record rule: user biasa hanya pengajuan miliknya; manager semua

## Di luar scope
- Akuntansi/jurnal, email notifikasi, report PDF, multi-currency, reject

## Definition of Done
- scripts/run_tests.sh keluar dengan exit 0
- Semua AC-01 sampai AC-06 punya minimal satu test
- Tidak ada test yang dihapus, dilemahkan, atau di-skip

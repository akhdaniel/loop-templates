from odoo import Command
from odoo.exceptions import AccessError, UserError, ValidationError
from odoo.tests.common import TransactionCase, tagged


@tagged('post_install', '-at_install')
class TestPettyCash(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        base_user = cls.env.ref('base.group_user')
        g_user = cls.env.ref('petty_cash.group_user')
        g_manager = cls.env.ref('petty_cash.group_manager')
        Users = cls.env['res.users'].with_context(no_reset_password=True)
        # Odoo 19 mengganti nama field groups_id menjadi group_ids
        gfield = 'group_ids' if 'group_ids' in Users._fields else 'groups_id'
        cls.user = Users.create({
            'name': 'Budi', 'login': 'budi_pc',
            gfield: [Command.set([base_user.id, g_user.id])],
        })
        cls.user2 = Users.create({
            'name': 'Sari', 'login': 'sari_pc',
            gfield: [Command.set([base_user.id, g_user.id])],
        })
        cls.manager = Users.create({
            'name': 'Pak Manager', 'login': 'manager_pc',
            gfield: [Command.set([base_user.id, g_manager.id])],
        })

    def _req(self, amount=500000, user=None):
        return self.env['petty.cash.request'].with_user(user or self.user).create({
            'amount': amount,
            'purpose': 'Beli ATK',
        })

    def test_ac01_sequence_name(self):
        req = self._req()
        self.assertRegex(req.name, r'^PC/\d{5}$')
        req2 = self._req()
        self.assertNotEqual(req.name, req2.name)

    def test_ac02_amount_positive(self):
        with self.assertRaises(ValidationError):
            self._req(amount=0)
        with self.assertRaises(ValidationError):
            self._req(amount=-5000)

    def test_ac03_workflow(self):
        req = self._req(amount=2500000)
        self.assertEqual(req.state, 'draft')
        req.action_submit()
        self.assertEqual(req.state, 'submitted')
        req.with_user(self.manager).action_approve()
        self.assertEqual(req.state, 'approved')
        req.with_user(self.manager).action_pay()
        self.assertEqual(req.state, 'paid')

    def test_ac03_pay_only_from_approved(self):
        req = self._req(amount=2500000)
        with self.assertRaises(UserError):
            req.with_user(self.manager).action_pay()
        req.action_submit()
        with self.assertRaises(UserError):
            req.with_user(self.manager).action_pay()

    def test_ac04_auto_approve_small_amount(self):
        small = self._req(amount=1000000)  # tepat di batas: masih otomatis
        small.action_submit()
        self.assertEqual(small.state, 'approved')
        big = self._req(amount=1000001)
        big.action_submit()
        self.assertEqual(big.state, 'submitted')

    def test_ac05_only_manager_can_approve_and_pay(self):
        req = self._req(amount=2500000)
        req.action_submit()
        with self.assertRaises(AccessError):
            req.with_user(self.user).action_approve()
        self.assertEqual(req.state, 'submitted')
        req.with_user(self.manager).action_approve()
        self.assertEqual(req.approved_by, self.manager)
        with self.assertRaises(AccessError):
            req.with_user(self.user).action_pay()
        self.assertEqual(req.state, 'approved')

    def test_ac06_record_rule(self):
        req = self._req(user=self.user)
        Req = self.env['petty.cash.request']
        domain = [('id', '=', req.id)]
        self.assertFalse(Req.with_user(self.user2).search(domain))
        self.assertTrue(Req.with_user(self.user).search(domain))
        self.assertTrue(Req.with_user(self.manager).search(domain))

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  double _salary = 0;
  List<Expense> _expenses = [];
  int _tabIndex = 0;
  bool _loading = true;

  final _salaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final salary = await _storage.loadSalary();
    final expenses = await _storage.loadExpenses();
    setState(() {
      _salary = salary;
      _expenses = expenses;
      _salaryController.text = salary > 0 ? salary.toStringAsFixed(0) : '';
      _loading = false;
    });
  }

  String _fmt(double n) {
    final f = NumberFormat('#,##0', 'en_US');
    return '${f.format(n)} ج.م';
  }

  double get _totalSpent => _expenses.fold(0, (a, b) => a + b.amount);
  double get _remaining => _salary - _totalSpent;

  Map<String, double> get _groupTotals {
    final map = {'احتياجات': 0.0, 'رغبات': 0.0, 'ادخار': 0.0};
    for (final e in _expenses) {
      final g = groupOf(e.category);
      map[g] = (map[g] ?? 0) + e.amount;
    }
    return map;
  }

  Map<String, double> get _catTotals {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> _saveSalary() async {
    final v = double.tryParse(_salaryController.text) ?? 0;
    setState(() => _salary = v);
    await _storage.saveSalary(v);
  }

  Future<void> _addExpense(Expense e) async {
    setState(() => _expenses.add(e));
    await _storage.saveExpenses(_expenses);
  }

  Future<void> _deleteExpense(String id) async {
    setState(() => _expenses.removeWhere((e) => e.id == id));
    await _storage.saveExpenses(_expenses);
  }

  void _openAddSheet() {
    final itemCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = kCategories.first.name;
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مصروف جديد',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 14),
                const Text('البند',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(
                      hintText: 'مثال: غدا، تاكسي، فاتورة نت'),
                ),
                const SizedBox(height: 12),
                const Text('الفئة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(),
                  items: kCategories
                      .map((c) => DropdownMenuItem(
                          value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => category = v!),
                ),
                const SizedBox(height: 12),
                const Text('المبلغ (جنيه)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0'),
                ),
                const SizedBox(height: 12),
                const Text('التاريخ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setSheetState(() => date = picked);
                  },
                  child: Text(DateFormat('yyyy-MM-dd').format(date)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text);
                      if (itemCtrl.text.trim().isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('اكتب البند والمبلغ صح الأول')),
                        );
                        return;
                      }
                      _addExpense(Expense(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        item: itemCtrl.text.trim(),
                        category: category,
                        amount: amount,
                        date: date,
                      ));
                      Navigator.pop(ctx);
                      setState(() => _tabIndex = 1);
                    },
                    child: const Text('إضافة المصروف',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final views = [_buildSummary(), _buildLog(), _buildSettings()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('📒 دفتر مصروفاتي',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(child: views[_tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'الملخص'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'السجل'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }

  Widget _buildSummary() {
    final groupTotals = _groupTotals;
    final catTotals = _catTotals;
    final catRows = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ملخص الشهر',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _salary <= 0
                          ? AppColors.paper2
                          : (_remaining >= 0
                              ? const Color(0xFFDCEBE5)
                              : const Color(0xFFF3DCD6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _salary <= 0
                          ? 'حدّد مرتبك'
                          : (_remaining >= 0 ? 'في حدود المرتب' : 'تجاوزت المرتب'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _salary <= 0
                            ? AppColors.inkSoft
                            : (_remaining >= 0 ? AppColors.teal : AppColors.rust),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _receiptRow('المرتب الشهري', _fmt(_salary)),
              _receiptRow('إجمالي المصروفات', _fmt(_totalSpent)),
              const Divider(height: 20),
              _receiptRow('المتبقي', _fmt(_remaining), bold: true),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('قاعدة 50/30/20',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              ...kGroupTarget.keys.map((g) {
                final val = groupTotals[g] ?? 0;
                final pct = _salary > 0 ? val / _salary : 0.0;
                final target = kGroupTarget[g]!;
                final color = g == 'احتياجات'
                    ? AppColors.teal
                    : (g == 'رغبات' ? AppColors.gold : const Color(0xFF3A6EA5));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${_fmt(val)} · ${(pct * 100).toStringAsFixed(1)}% (الهدف ${(target * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0, 1),
                              minHeight: 12,
                              backgroundColor: AppColors.paper2,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حسب الفئة',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              if (catRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'لسه مفيش مصاريف مسجلة.\nدوس على زرار + وسجل أول مصروف.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  ),
                )
              else
                ...catRows.map((e) => _receiptRow(e.key, _fmt(e.value))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.bold,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildLog() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'السجل فاضي لسه.\nدوس على زرار + تحت وابدأ تسجّل مصاريفك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }
    final sorted = [..._expenses]..sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<Expense>> byDate = {};
    for (final e in sorted) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      byDate.putIfAbsent(key, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: byDate.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 4),
                child: Text(entry.key,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
              ),
              ...entry.value.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.item, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(e.category,
                                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Text(_fmt(e.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.rust),
                          onPressed: () => _deleteExpense(e.id),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المرتب الشهري',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'مثال: 10000'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _saveSalary,
                  child: const Text('حفظ المرتب',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إعادة الضبط',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('هيمسح كل المصاريف المسجلة بشكل نهائي.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rust,
                    side: const BorderSide(color: AppColors.rust),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تأكيد المسح'),
                        content: const Text('متأكد إنك عايز تمسح كل المصاريف؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('إلغاء')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('مسح')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      setState(() => _expenses = []);
                      await _storage.saveExpenses(_expenses);
                    }
                  },
                  child: const Text('امسح كل المصاريف'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

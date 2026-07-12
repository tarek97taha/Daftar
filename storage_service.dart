import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class StorageService {
  static const _salaryKey = 'salary';
  static const _expensesKey = 'expenses';

  Future<double> loadSalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_salaryKey) ?? 0;
  }

  Future<void> saveSalary(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_salaryKey, value);
  }

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expensesKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_expensesKey, raw);
  }
}

class Category {
  final String name;
  final String group; // احتياجات | رغبات | ادخار

  const Category(this.name, this.group);
}

const List<Category> kCategories = [
  Category('أكل', 'احتياجات'),
  Category('مواصلات', 'احتياجات'),
  Category('سكن', 'احتياجات'),
  Category('فواتير', 'احتياجات'),
  Category('اشتراكات', 'رغبات'),
  Category('تسلية', 'رغبات'),
  Category('تسوق', 'رغبات'),
  Category('خروجات', 'رغبات'),
  Category('ادخار', 'ادخار'),
  Category('سداد ديون', 'ادخار'),
  Category('تانية', 'رغبات'),
];

const Map<String, double> kGroupTarget = {
  'احتياجات': 0.50,
  'رغبات': 0.30,
  'ادخار': 0.20,
};

String groupOf(String categoryName) {
  final match = kCategories.where((c) => c.name == categoryName);
  if (match.isEmpty) return 'رغبات';
  return match.first.group;
}

class Expense {
  final String id;
  final String item;
  final String category;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.item,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        item: json['item'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

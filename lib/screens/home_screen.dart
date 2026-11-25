import 'package:flutter/material.dart';
import 'package:smartcart/database/database_helper.dart';
import 'package:smartcart/models/models.dart';
import 'package:smartcart/screens/delete_account_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'Усі',
    'Продукти',
    'Овочі та фрукти',
    'Молочне',
    'М’ясо та риба',
    'Напої',
    'Побутова хімія',
    'Інше',
  ];

  static const List<String> _units = ['шт', 'кг', 'л', 'уп', 'г'];

  List<ShoppingItem> _items = [];
  String _selectedCategory = 'Усі';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items =
      await DatabaseHelper.instance.getItemsByUser(widget.user.id!);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Не вдалося завантажити список: $e');
    }
  }

  List<ShoppingItem> get _filteredItems {
    if (_selectedCategory == 'Усі') return _items;
    return _items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  double get _totalPlanned =>
      _items.fold(0.0, (sum, item) => sum + item.plannedTotal);

  double get _totalActual =>
      _items.fold(0.0, (sum, item) => sum + item.actualTotal);

  int get _boughtCount => _items.where((item) => item.isBought).length;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _toggleBought(ShoppingItem item, bool? value) async {
    final newBought = value ?? false;
    final updatedActual =
    (newBought && item.actualQty == 0) ? item.plannedQty : item.actualQty;

    final updatedItem = item.copyWith(
      isBought: newBought,
      actualQty: updatedActual,
    );

    await DatabaseHelper.instance.updateItem(updatedItem);
    await _loadItems();
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    if (item.id == null) return;
    await DatabaseHelper.instance.deleteItem(item.id!);
    await _loadItems();
    if (mounted) {
      _showSnackBar('Товар «${item.title}» видалено');
    }
  }

  Future<void> _logout() async {
    await DatabaseHelper.instance.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _showPriceHistoryDialog(ShoppingItem item) async {
    if (item.id == null) return;
    final history = await DatabaseHelper.instance.getPriceHistory(item.id!);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Історія цін: ${item.title}',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Одиниця виміру: ${item.unit}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Записів про зміну ціни ще немає')),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = history[index];
                        final isLatest = index == 0;
                        double? diff;
                        if (index + 1 < history.length) {
                          diff = record.price - history[index + 1].price;
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isLatest
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            child: Icon(
                              diff == null
                                  ? Icons.sell_outlined
                                  : (diff > 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded),
                              color: diff == null
                                  ? colorScheme.primary
                                  : (diff > 0
                                  ? colorScheme.error
                                  : Colors.green.shade700),
                            ),
                          ),
                          title: Text(
                            '${record.price.toStringAsFixed(2)} ₴ / ${item.unit}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(_formatDateTime(record.recordedAt)),
                          trailing: diff == null
                              ? Chip(
                            label: Text(
                              isLatest && history.length == 1
                                  ? 'Початкова'
                                  : 'Старт',
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                              : Text(
                            '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(2)} ₴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: diff > 0
                                  ? colorScheme.error
                                  : Colors.green.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openItemForm({ShoppingItem? existingItem}) async {
    final isEditing = existingItem != null;
    final formKey = GlobalKey<FormState>();

    final titleController =
    TextEditingController(text: existingItem?.title ?? '');
    final plannedQtyController = TextEditingController(
      text: existingItem != null ? _formatQty(existingItem.plannedQty) : '1',
    );
    final actualQtyController = TextEditingController(
      text: existingItem != null ? _formatQty(existingItem.actualQty) : '0',
    );
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.price.toStringAsFixed(2) : '',
    );

    String selectedCategory = existingItem?.category ?? 'Продукти';
    String selectedUnit = existingItem?.unit ?? 'шт';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? 'Редагувати товар' : 'Новий товар',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Назва товару',
                          hintText: 'Наприклад: Молоко 2.5%',
                          prefixIcon: Icon(Icons.shopping_basket_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введіть назву товару';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Категорія',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories
                                  .where((c) => c != 'Усі')
                                  .map(
                                    (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedCategory = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Од. виміру',
                              ),
                              items: _units
                                  .map(
                                    (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: plannedQtyController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'План (к-сть)',
                                prefixIcon: Icon(Icons.event_note_outlined),
                              ),
                              validator: (value) {
                                final parsed = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Введіть > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: actualQtyController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Факт (к-сть)',
                                prefixIcon: Icon(Icons.check_circle_outline),
                              ),
                              validator: (value) {
                                final parsed = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                );
                                if (parsed == null || parsed < 0) {
                                  return 'Введіть ≥ 0';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Ціна за 1 $selectedUnit (₴)',
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Введіть коректну ціну';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final plannedQty = double.parse(
                            plannedQtyController.text.replaceAll(',', '.'),
                          );
                          final actualQty = double.parse(
                            actualQtyController.text.replaceAll(',', '.'),
                          );
                          final price = double.parse(
                            priceController.text.replaceAll(',', '.'),
                          );

                          if (isEditing) {
                            final updated = existingItem.copyWith(
                              title: titleController.text.trim(),
                              category: selectedCategory,
                              plannedQty: plannedQty,
                              actualQty: actualQty,
                              unit: selectedUnit,
                              price: price,
                            );
                            await DatabaseHelper.instance.updateItem(updated);
                          } else {
                            final newItem = ShoppingItem(
                              userId: widget.user.id!,
                              title: titleController.text.trim(),
                              category: selectedCategory,
                              plannedQty: plannedQty,
                              actualQty: actualQty,
                              unit: selectedUnit,
                              price: price,
                            );
                            await DatabaseHelper.instance.insertItem(newItem);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadItems();
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          isEditing ? 'Зберегти зміни' : 'Додати до списку',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleItems = _filteredItems;
    final budgetDiff = _totalActual - _totalPlanned;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SmartCart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Привіт, ${widget.user.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'delete') {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DeleteAccountScreen(user: widget.user),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.user.email,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Вийти з акаунту'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Видалити акаунт',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              elevation: 0,
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetric(
                            label: 'Заплановано (План)',
                            value: '${_totalPlanned.toStringAsFixed(2)} ₴',
                            icon: Icons.assignment_outlined,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _SummaryMetric(
                            label: 'Витрачено (Факт)',
                            value: '${_totalActual.toStringAsFixed(2)} ₴',
                            icon: Icons.shopping_cart_checkout_rounded,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Куплено: $_boughtCount з ${_items.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          budgetDiff == 0
                              ? 'В межах плану'
                              : (budgetDiff > 0
                              ? 'Перевищення: +${budgetDiff.toStringAsFixed(2)} ₴'
                              : 'Економія: ${budgetDiff.abs().toStringAsFixed(2)} ₴'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: budgetDiff > 0
                                ? colorScheme.error
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleItems.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _items.isEmpty
                          ? 'Список покупок порожній'
                          : 'У цій категорії товарів немає',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Натисніть кнопку «Додати товар», щоб спланувати покупки',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: item.isBought,
                              onChanged: (val) =>
                                  _toggleBought(item, val),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: item.isBought
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: item.isBought
                                          ? colorScheme
                                          .onSurfaceVariant
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.category} • ${item.price.toStringAsFixed(2)} ₴ / ${item.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Історія цін',
                              icon: const Icon(Icons.history_rounded),
                              onPressed: () =>
                                  _showPriceHistoryDialog(item),
                            ),
                            IconButton(
                              tooltip: 'Редагувати',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openItemForm(existingItem: item),
                            ),
                            IconButton(
                              tooltip: 'Видалити',
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _deleteItem(item),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'План: ${_formatQty(item.plannedQty)} ${item.unit} (${item.plannedTotal.toStringAsFixed(2)} ₴)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Факт: ${_formatQty(item.actualQty)} ${item.unit} (${item.actualTotal.toStringAsFixed(2)} ₴)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: item.actualQty >
                                      item.plannedQty
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Додати товар'),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color textColor;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
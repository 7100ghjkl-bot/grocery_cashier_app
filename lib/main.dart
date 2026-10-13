import 'package:flutter/material.dart';

void main() {
  runApp(const GroceryPOSApp());
}

class GroceryPOSApp extends StatelessWidget {
  const GroceryPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الكاشير والمحاسبة الاحترافي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1B5E20),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainPOSScreen(),
    );
  }
}

// نموذج المنتج
class Product {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final double cost;
  int stock;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
  });
}

// نموذج عنصر السلة
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
  double get profit => (product.price - product.cost) * quantity;
}

// نموذج سجل البيع
class SaleRecord {
  final String id;
  final DateTime date;
  final double totalAmount;
  final double totalProfit;
  final int itemCount;

  SaleRecord({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.totalProfit,
    required this.itemCount,
  });
}

class MainPOSScreen extends StatefulWidget {
  const MainPOSScreen({super.key});

  @override
  State<MainPOSScreen> createState() => _MainPOSScreenState();
}

class _MainPOSScreenState extends State<MainPOSScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // قاعدة بيانات المنتجات التجريبية
  final List<Product> _products = [
    Product(id: '1', barcode: '6291001', name: 'ماء 500 مل', price: 100.0, cost: 70.0, stock: 150),
    Product(id: '2', barcode: '6291002', name: 'عصير طازج 1 لتر', price: 500.0, cost: 350.0, stock: 40),
    Product(id: '3', barcode: '6291003', name: 'حليب ممتاز 1 لتر', price: 700.0, cost: 550.0, stock: 30),
    Product(id: '4', barcode: '6291004', name: 'خبز ابيض', price: 100.0, cost: 70.0, stock: 200),
    Product(id: '5', barcode: '6291005', name: 'شاي 100 كيس', price: 1200.0, cost: 950.0, stock: 25),
    Product(id: '6', barcode: '6291006', name: 'سكر 1 كجم', price: 900.0, cost: 750.0, stock: 60),
  ];

  List<Product> _filteredProducts = [];
  final List<CartItem> _cart = [];
  final List<SaleRecord> _salesHistory = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_products);
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((p) {
          return p.name.contains(query) || p.barcode.contains(query);
        }).toList();
      }
    });
  }

  // معالجة البحث بالباركون (إضافة فورية للسلة عند التطابق التام)
  void _onBarcodeSubmitted(String code) {
    if (code.isEmpty) return;
    final index = _products.indexWhere((p) => p.barcode == code);
    if (index >= 0) {
      _addToCart(_products[index]);
      _searchController.clear();
      _filterProducts('');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المنتج غير مسجل في النظام!')),
      );
    }
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نفدت الكمية من المخزون!')),
      );
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        if (_cart[index].quantity < product.stock) {
          _cart[index].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تجاوزت الكمية المتوفرة في المخزون!')),
          );
        }
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _updateCartQuantity(CartItem item, int delta) {
    setState(() {
      item.quantity += delta;
      if (item.quantity <= 0) {
        _cart.remove(item);
      } else if (item.quantity > item.product.stock) {
        item.quantity = item.product.stock;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وصلت للكمية القصوى المتاحة في المخزن!')),
        );
      }
    });
  }

  void _processCheckout() {
    if (_cart.isEmpty) return;

    double totalAmount = _cart.fold(0, (sum, item) => sum + item.total);
    double totalProfit = _cart.fold(0, (sum, item) => sum + item.profit);
    int itemCount = _cart.fold(0, (sum, item) => sum + item.quantity);

    setState(() {
      // خصم الكميات من المخزون
      for (var item in _cart) {
        item.product.stock -= item.quantity;
      }

      // إضافة الفاتورة للسجل
      _salesHistory.insert(
        0,
        SaleRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          totalAmount: totalAmount,
          totalProfit: totalProfit,
          itemCount: itemCount,
        ),
      );

      _cart.clear();
      _filterProducts(_searchController.text);
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        title: const Text('تمت عملية البيع بنجاح'),
        content: Text('إجمالي الفاتورة: $totalAmount ريال\nتم تحديث المخزون وطباعة الإيصال.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('موافق', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _addNewProduct(String barcode, String name, double price, double cost, int stock) {
    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      barcode: barcode,
      name: name,
      price: price,
      cost: cost,
      stock: stock,
    );

    setState(() {
      _products.add(newProduct);
      _filterProducts(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: const Text('نظام الكاشير والمحاسبة الذكي', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 2,
        ),
        body: _selectedNavIndex == 0
            ? _buildPOSLayout()
            : _selectedNavIndex == 1
                ? _buildInventoryLayout()
                : _buildReportsLayout(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedNavIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'الكاشير والبيع'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المخزون والمنتجات'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير والأرباح'),
          ],
        ),
      ),
    );
  }

  // واجهة الكاشير (نقطة البيع)
  Widget _buildPOSLayout() {
    double totalCartAmount = _cart.fold(0, (sum, item) => sum + item.total);

    return Row(
      children: [
        // قسم المنتجات والبحث (الجانب الأيمن)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  onSubmitted: _onBarcodeSubmitted,
                  decoration: InputDecoration(
                    hintText: 'امسح الباركون أو اكتب اسم المنتج...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1B5E20)),
                      onPressed: () {},
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = _filteredProducts[i];
                    final bool isOut = p.stock <= 0;
                    return InkWell(
                      onTap: () => _addToCart(p),
                      child: Card(
                        elevation: 2,
                        color: isOut ? Colors.red.shade50 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isOut ? Colors.red : Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'المتوفّر: ${p.stock}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOut ? Colors.red : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                p.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${p.price} ريال',
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),

        // قسم الفاتورة الحالية (الجانب الأيسر)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الفاتورة الحالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_cart.length} أصناف', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(child: Text('السلة فارغة، اضغط على منتج لإضافته'))
                    : ListView.separated(
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = _cart[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${item.product.price} × ${item.quantity} = ${item.total} ريال'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _updateCartQuantity(item, -1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () => _updateCartQuantity(item, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '$totalCartAmount ريال',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _cart.isNotEmpty ? _processCheckout : null,
                        icon: const Icon(Icons.print),
                        label: const Text('إتمام الدفع وطباعة الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // واجهة إدارة المخزون
  Widget _buildInventoryLayout() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج جديد', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final p = _products[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: p.stock > 10 ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(Icons.inventory, color: p.stock > 10 ? Colors.green : Colors.red),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('الباركون: ${p.barcode} | التكلفة: ${p.cost} ريال'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('سعر البيع: ${p.price} ريال', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                  Text('الكمية: ${p.stock}', style: TextStyle(color: p.stock <= 0 ? Colors.red : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // واجهة التقارير والأرباح
  Widget _buildReportsLayout() {
    double totalSales = _salesHistory.fold(0, (sum, s) => sum + s.totalAmount);
    double totalProfits = _salesHistory.fold(0, (sum, s) => sum + s.totalProfit);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('إجمالي المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$totalSales ريال', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('صافي الأرباح', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$totalProfits ريال', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('سجل الفواتير الأخيرة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: _salesHistory.isEmpty
                ? const Center(child: Text('لا توجد عمليات بيع مسجلة حتى الآن.'))
                : ListView.builder(
                    itemCount: _salesHistory.length,
                    itemBuilder: (ctx, i) {
                      final sale = _salesHistory[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long, color: Color(0xFF1B5E20)),
                          title: Text('فاتورة #${sale.id.substring(sale.id.length - 5)}'),
                          subtitle: Text('عدد الأصناف: ${sale.itemCount}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${sale.totalAmount} ريال', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('ربح: ${sale.totalProfit} ريال', style: const TextStyle(fontSize: 12, color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final barcodeController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة منتج جديد للمخزن'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: barcodeController, decoration: const InputDecoration(labelText: 'رمز الباركون')),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المنتج')),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر البيع')),
              TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر التكلفة (الشراء)')),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المخزونة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                _addNewProduct(
                  barcodeController.text.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : barcodeController.text,
                  nameController.text,
                  double.parse(priceController.text),
                  double.tryParse(costController.text) ?? 0.0,
                  int.tryParse(stockController.text) ?? 0,
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('إضافة للمخزن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

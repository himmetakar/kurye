import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../providers/app_provider.dart';
import '../../models/order.dart';
import '../../models/courier_request.dart';
import '../../models/restaurant.dart';

// ───────── Brand Color Constants ─────────
const _kBg = Color(0xFFF8FAFC);          // slate-50
const _kWhite = Colors.white;
const _kBorder = Color(0xFFE2E8F0);      // slate-200
const _kBorderLight = Color(0xFFF1F5F9); // slate-100
const _kTextHead = Color(0xFF0F172A);    // slate-900
const _kTextBody = Color(0xFF475569);    // slate-600
const _kTextMuted = Color(0xFF94A3B8);   // slate-400
const _kIndigo = Color(0xFF4F46E5);      // indigo-600
const _kIndigoPale = Color(0xFFEEF2FF);  // indigo-50
const _kIndigoBorder = Color(0xFFC7D2FE); // indigo-200
const _kPurple = Color(0xFF7C3AED);      // purple-600
const _kOrange = Color(0xFFF97316);      // orange-500

class RestaurantPanelView extends StatefulWidget {
  final String restaurantId;

  const RestaurantPanelView({super.key, required this.restaurantId});

  @override
  State<RestaurantPanelView> createState() => _RestaurantPanelViewState();
}

class _RestaurantPanelViewState extends State<RestaurantPanelView> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();

  // Courier Request controllers
  final _reqDurationController = TextEditingController();
  final _reqDescController = TextEditingController();
  int _reqCount = 1;
  String _reqType = 'daimi';
  String _reqMotor = 'yes';

  String _activeTab = 'orders'; // 'orders' or 'requests'
  String _orderSubTab = 'yeni'; // 'yeni' (araniyor/kabul_edildi), 'yolda' (teslim_alindi/tasimada), 'tamamlandi' (teslim_edildi/iptal)
  bool _isPoolOrder = false;
  bool _creating = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _reqDurationController.dispose();
    _reqDescController.dispose();
    super.dispose();
  }

  void _callCourier(AppProvider provider) {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _creating = true;
      });

      // Offset coordinates around restaurant to simulate delivery point
      final double rLat = provider.activeRestaurant.latitude;
      final double rLon = provider.activeRestaurant.longitude;
      final double lat = rLat + (0.01 - (0.02 * (DateTime.now().millisecond / 1000)));
      final double lon = rLon + (0.01 - (0.02 * (DateTime.now().microsecond / 1000000)));

      provider.callCourier(
        restaurantId: widget.restaurantId,
        customerName: _customerNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        price: double.parse(_priceController.text),
        lat: lat,
        lon: lon,
        poolOrder: _isPoolOrder,
      );

      _customerNameController.clear();
      _addressController.clear();
      _phoneController.clear();
      _priceController.clear();

      setState(() {
        _isPoolOrder = false;
        _creating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurye çağrısı yapıldı! 🛵'), backgroundColor: _kIndigo),
      );
    }
  }

  void _fillMockData() {
    final list = [
      {'name': 'Ahmet Yılmaz', 'addr': 'Cumhuriyet Mah. Vatan Cad. No:14, Çankaya/Ankara', 'tel': '05321112233', 'price': '120.0'},
      {'name': 'Selin Kaya', 'addr': 'Atatürk Mah. 45. Sok. Gökkuşağı Sitesi B Blok, Çankaya/Ankara', 'tel': '05445556677', 'price': '190.0'},
      {'name': 'Caner Demir', 'addr': 'Hürriyet Cad. Barış İş Hanı Kat:3, Çankaya/Ankara', 'tel': '05334445566', 'price': '240.0'},
    ];
    final item = list[Random().nextInt(list.length)];
    _customerNameController.text = item['name']!;
    _addressController.text = item['addr']!;
    _phoneController.text = item['tel']!;
    _priceController.text = item['price']!;
  }

  void _loadLocationFromGps(AppProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS Koordinatları alınıyor...')),
    );

    try {
      final double lat = 39.9208 + (Random().nextDouble() - 0.5) * 0.01;
      final double lon = 32.8541 + (Random().nextDouble() - 0.5) * 0.01;

      final response = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon')).timeout(const Duration(seconds: 4));
      String resolvedAddress = 'Çankaya, Ankara (GPS)';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        resolvedAddress = data['display_name'] ?? resolvedAddress;
      }

      provider.updateRestaurant(widget.restaurantId, {
        'latitude': lat,
        'longitude': lon,
        'address': resolvedAddress,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum Güncellendi: $resolvedAddress'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      provider.updateRestaurant(widget.restaurantId, {
        'latitude': 39.9208,
        'longitude': 32.8541,
        'address': 'Çankaya, Ankara (Manuel)',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS bağlantı hatası, varsayılan konum atandı.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _showWebhookDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _WebhookSimulatorDialog(
        restaurantId: widget.restaurantId,
        restaurantName: provider.activeRestaurant.name,
        onSimulated: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Webhook siparişi kurye havuzuna düştü! 🚀'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showSettingsDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _RestaurantSettingsDialog(
        restaurant: provider.activeRestaurant,
        onSaved: (updates) {
          provider.updateRestaurant(widget.restaurantId, updates);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ayarlar başarıyla kaydedildi.'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _handleRequestSubmit(AppProvider provider) {
    if (_reqDurationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen vardiya / çalışma süre detayını girin.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    provider.createCourierRequest(
      restaurantId: widget.restaurantId,
      type: _reqType,
      durationDetails: _reqDurationController.text,
      motorcycleRequired: _reqMotor,
      count: _reqCount,
      description: _reqDescController.text,
    );

    _reqDurationController.clear();
    _reqDescController.clear();
    setState(() {
      _reqCount = 1;
      _reqType = 'daimi';
      _reqMotor = 'yes';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kurye talebi admin onayına gönderildi! ✅'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant Title & Settings Bar
            _buildRestaurantHeader(provider),
            const SizedBox(height: 20),

            // Top Tab Navigation Bar (Sipariş & Kurye Çağrı vs Kurye Talepleri)
            _buildTopNavBar(),
            const SizedBox(height: 24),

            // Main Content Area (Responsive Split or Stacking)
            if (_activeTab == 'orders')
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildOrderForm(provider)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildOrdersListSection(provider)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildOrderForm(provider),
                        const SizedBox(height: 24),
                        _buildOrdersListSection(provider),
                      ],
                    )
            else if (_activeTab == 'requests')
              _buildCourierRequestsSection(provider)
            else
              _buildAnalyticsSection(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantHeader(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFF59E0B)], // orange-500 to amber-500
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.activeRestaurant.name} Şubesi',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.activeRestaurant.isDedicatedMode
                      ? '🚀 Özel Kurye Modu (Sadece size özel atanan kuryeler)'
                      : '🏊 Havuz Kurye Modu (Şehirdeki boş kuryeler çağrılır)',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.globe, color: Colors.white, size: 18),
                tooltip: 'Webhook Simülatörü',
                onPressed: () => _showWebhookDialog(provider),
              ),
              IconButton(
                icon: const Icon(LucideIcons.mapPin, color: Colors.white, size: 18),
                tooltip: 'GPS Konum Güncelle',
                onPressed: () => _loadLocationFromGps(provider),
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white, size: 18),
                tooltip: 'Şube API Ayarları',
                onPressed: () => _showSettingsDialog(provider),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), // slate-100
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'orders'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'orders' ? _kWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 'orders'
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shoppingBag, color: _activeTab == 'orders' ? _kIndigo : _kTextBody, size: 14),
                    const SizedBox(width: 8),
                    Text('Sipariş & Kurye Çağrı', style: TextStyle(color: _activeTab == 'orders' ? _kIndigo : _kTextBody, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'requests'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'requests' ? _kWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 'requests'
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.clipboardList, color: _activeTab == 'requests' ? _kIndigo : _kTextBody, size: 14),
                    const SizedBox(width: 8),
                    Text('Kurye Talepleri', style: TextStyle(color: _activeTab == 'requests' ? _kIndigo : _kTextBody, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'analytics'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'analytics' ? _kWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 'analytics'
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.barChart3, color: _activeTab == 'analytics' ? _kIndigo : _kTextBody, size: 14),
                    const SizedBox(width: 8),
                    Text('İstatistik & Rapor', style: TextStyle(color: _activeTab == 'analytics' ? _kIndigo : _kTextBody, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kurye Çağır', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w900)),
                TextButton(
                  onPressed: _fillMockData,
                  child: const Text('Test Bilgisi Doldur', style: TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              decoration: _inputDecoration('Müşteri Adı Soyadı', LucideIcons.user),
              validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              style: const TextStyle(color: _kTextHead, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration('Teslimat Adresi', LucideIcons.mapPin),
              validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              style: const TextStyle(color: _kTextHead, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration('Telefon Numarası', LucideIcons.phone),
                    validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                    style: const TextStyle(color: _kTextHead, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration('Tutar (TL)', LucideIcons.coins),
                    validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                    style: const TextStyle(color: _kTextHead, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isPoolOrder,
              onChanged: (val) => setState(() => _isPoolOrder = val ?? false),
              title: const Text('Ortak Havuz Siparişi (Havuz Kurye Çağır)', style: TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.bold)),
              subtitle: const Text('Özel kuryeniz yerine havuz kuryelerinden biri atansın', style: TextStyle(color: _kTextMuted, fontSize: 9)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: _kIndigo,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _creating ? null : () => _callCourier(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kIndigo,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _creating
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kurye Çağır', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersListSection(AppProvider provider) {
    final activeOrders = provider.orders.where((o) => o.restaurantId == widget.restaurantId).toList();

    // Grouping orders for sub tabs
    List<OrderModel> ordersToShow = [];
    if (_orderSubTab == 'yeni') {
      ordersToShow = activeOrders.where((o) => ['araniyor', 'kabul_edildi'].contains(o.status)).toList();
    } else if (_orderSubTab == 'yolda') {
      ordersToShow = activeOrders.where((o) => ['teslim_alindi', 'tasimada'].contains(o.status)).toList();
    } else {
      ordersToShow = activeOrders.where((o) => ['teslim_edildi', 'iptal'].contains(o.status)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pill-tabs for Order Sub states
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _buildOrderSubTabButton('yeni', 'Yeni / Bekleyen'),
              _buildOrderSubTabButton('yolda', 'Yolda'),
              _buildOrderSubTabButton('tamamlandi', 'Teslim Edildi'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ordersToShow.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Bu grupta aktif sipariş bulunmuyor.', style: TextStyle(color: _kTextMuted))),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ordersToShow.length,
                itemBuilder: (context, index) {
                  final order = ordersToShow[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Müşteri: ${order.customerName}', style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${order.price} TL', style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('📍 Adres: ${order.deliveryAddress}', style: const TextStyle(color: _kTextBody, fontSize: 10)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.assignedCourierId != null ? 'Kurye: ${order.assignedCourierId}' : 'Kurye Aranıyor...',
                              style: TextStyle(
                                color: order.assignedCourierId != null ? _kIndigo : _kOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (order.status == 'araniyor' || order.status == 'kabul_edildi')
                              TextButton(
                                onPressed: () {
                                  provider.cancelOrder(order.id);
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text('Çağrıyı İptal Et', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                              )
                          ],
                        )
                      ],
                    ),
                  );
                },
              )
      ],
    );
  }

  Widget _buildOrderSubTabButton(String subTab, String label) {
    final active = _orderSubTab == subTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderSubTab = subTab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? _kWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? _kIndigo : _kTextBody,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourierRequestsSection(AppProvider provider) {
    final requests = provider.courierRequests.where((r) => r.restaurantId == widget.restaurantId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Form to create request
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kurye Talebi Oluştur', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _reqType,
                      items: const [
                        DropdownMenuItem(value: 'daimi', child: Text('Daimi / Kadrolu')),
                        DropdownMenuItem(value: 'gecici', child: Text('Geçici / Süreli')),
                      ],
                      onChanged: (val) => setState(() => _reqType = val ?? 'daimi'),
                      decoration: const InputDecoration(labelText: 'Talep Türü'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _reqMotor,
                      items: const [
                        DropdownMenuItem(value: 'yes', child: Text('Motorlu Kurye')),
                        DropdownMenuItem(value: 'no', child: Text('Motorsuz / Şube Motorlu')),
                      ],
                      onChanged: (val) => setState(() => _reqMotor = val ?? 'yes'),
                      decoration: const InputDecoration(labelText: 'Motor Tercihi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _reqDurationController,
                      decoration: _inputDecoration('Vardiya / Çalışma Saatleri (Örn: 10:00 - 22:00)', LucideIcons.clock),
                      style: const TextStyle(fontSize: 11, color: _kTextHead),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text('Kurye Sayısı:', style: TextStyle(fontSize: 10, color: _kTextBody)),
                      IconButton(
                        icon: const Icon(LucideIcons.minusCircle, size: 16),
                        onPressed: _reqCount > 1 ? () => setState(() => _reqCount--) : null,
                      ),
                      Text('$_reqCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kTextHead)),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, size: 16),
                        onPressed: () => setState(() => _reqCount++),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reqDescController,
                maxLines: 2,
                decoration: _inputDecoration('Ekstra Açıklama / Arayış Notu', LucideIcons.edit),
                style: const TextStyle(fontSize: 11, color: _kTextHead),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handleRequestSubmit(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kIndigo,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Talebi Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'GÖNDERİLEN KURYE TALEPLERİ',
            style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),

        requests.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Daha önce gönderilmiş kurye talebi bulunmuyor.', style: TextStyle(color: _kTextMuted))),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Talep: ${req.count}x ${req.type == 'daimi' ? 'Kadrolu' : 'Geçici'} Kurye',
                              style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('⏱️ Vardiya: ${req.durationDetails}', style: const TextStyle(color: _kTextMuted, fontSize: 9)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: req.status == 'approved' ? Colors.green.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                              color: req.status == 'approved' ? Colors.green.shade700 : Colors.amber.shade700,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              )
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextMuted, fontSize: 11),
      prefixIcon: Icon(icon, color: _kIndigo, size: 14),
      filled: true,
      fillColor: _kBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
    );
  }

  Widget _buildAnalyticsSection(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gelen Sipariş Kaynakları (Bu Ay)', style: TextStyle(color: _kTextHead, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Pazaryeri ve kendi kanallarınızdan gelen sipariş dağılımı.', style: TextStyle(color: _kTextBody, fontSize: 12)),
          const SizedBox(height: 24),
          Row(
            children: [
               Expanded(child: _buildAnalyticCard('Yemeksepeti', '%40', 120, const Color(0xFFEA004B), const Color(0xFFFCE4EC))),
               const SizedBox(width: 12),
               Expanded(child: _buildAnalyticCard('Getir', '%35', 105, const Color(0xFF5D3EBD), const Color(0xFFEDE7F6))),
            ]
          ),
          const SizedBox(height: 12),
          Row(
            children: [
               Expanded(child: _buildAnalyticCard('Gel-Al / Telefon', '%15', 45, _kOrange, const Color(0xFFFFF3E0))),
               const SizedBox(width: 12),
               Expanded(child: _buildAnalyticCard('Trendyol Yemek', '%10', 30, const Color(0xFFF27A1A), const Color(0xFFFFF3E0))),
            ]
          ),
          const SizedBox(height: 24),
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: _kIndigoPale, borderRadius: BorderRadius.circular(16)),
             child: const Row(
               children: [
                  Icon(LucideIcons.barChart3, color: _kIndigo),
                  SizedBox(width: 12),
                  Expanded(child: Text('Toplam 300 siparişin %85\'i pazaryerlerinden gelirken, %15\'i kendi kanallarınızdan (Gel-Al / Telefon) gelmiştir.', style: TextStyle(color: _kIndigo, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4))),
               ]
             )
          )
        ]
      )
    );
  }

  Widget _buildAnalyticCard(String title, String perc, int count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(title, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Row(
             crossAxisAlignment: CrossAxisAlignment.baseline,
             textBaseline: TextBaseline.alphabetic,
             children: [
                Text(perc, style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(width: 6),
                Text('($count sipariş)', style: TextStyle(color: fg.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
             ]
           )
        ]
      )
    );
  }
}

class _WebhookSimulatorDialog extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final VoidCallback onSimulated;

  const _WebhookSimulatorDialog({required this.restaurantId, required this.restaurantName, required this.onSimulated});

  @override
  State<_WebhookSimulatorDialog> createState() => _WebhookSimulatorDialogState();
}

class _WebhookSimulatorDialogState extends State<_WebhookSimulatorDialog> {
  String _providerSlug = 'migros';
  final _jsonController = TextEditingController();

  final _migrosMock = '''{
  "provider": {"slug": "migros", "kaynak": "Migros Yemek"},
  "totalPrice": 400.0,
  "client": {
    "name": "Mehmet I.",
    "clientPhoneNumber": "5060957232",
    "deliveryAddress": {"address": "Balcali Mh. Guney Kampus 5. Sokak Bina No:2 Daire No:61", "city": "Adana"}
  }
}''';

  final _trendyolMock = '''{
  "provider": {"slug": "ty", "kaynak": "Trendyol Yemek"},
  "totalPrice": 350.0,
  "client": {
    "name": "Fatma G.",
    "clientPhoneNumber": "5449887766",
    "deliveryAddress": {"address": "Karsiyaka Mh. Ataturk Bulvari No:108 D:4", "city": "Izmir"}
  }
}''';

  @override
  void initState() {
    super.initState();
    _jsonController.text = _migrosMock;
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kWhite,
      title: const Text('Webhook Entegrasyon Simülatörü', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entegrasyonlardan gelen webhook çağrılarını taklit edin:',
              style: TextStyle(color: _kTextBody, fontSize: 11),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _providerSlug,
              items: const [
                DropdownMenuItem(value: 'migros', child: Text('Migros Yemek')),
                DropdownMenuItem(value: 'ty', child: Text('Trendyol Yemek')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _providerSlug = val;
                    _jsonController.text = val == 'migros' ? _migrosMock : _trendyolMock;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jsonController,
              maxLines: 8,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: _kTextHead),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Payload JSON'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat', style: TextStyle(color: _kTextMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final parsed = jsonDecode(_jsonController.text);
              final provider = Provider.of<AppProvider>(context, listen: false);
              provider.callCourier(
                restaurantId: widget.restaurantId,
                customerName: parsed['client']?['name'] ?? 'Müşteri',
                address: parsed['client']?['deliveryAddress']?['address'] ?? 'Adres',
                phone: parsed['client']?['clientPhoneNumber'] ?? '05000000000',
                price: parsed['totalPrice'] != null ? double.parse(parsed['totalPrice'].toString()) : 100.0,
                lat: provider.activeRestaurant.latitude + 0.004,
                lon: provider.activeRestaurant.longitude + 0.004,
                poolOrder: true,
              );
              widget.onSimulated();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hatalı JSON: $e'), backgroundColor: Colors.red),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kIndigo),
          child: const Text('Siparişi Simüle Et', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

class _RestaurantSettingsDialog extends StatefulWidget {
  final Restaurant restaurant;
  final Function(Map<String, dynamic>) onSaved;

  const _RestaurantSettingsDialog({required this.restaurant, required this.onSaved});

  @override
  State<_RestaurantSettingsDialog> createState() => _RestaurantSettingsDialogState();
}

class _RestaurantSettingsDialogState extends State<_RestaurantSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _dedicatedMode;
  late TextEditingController _nameController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _dedicatedMode = widget.restaurant.isDedicatedMode;
    _nameController = TextEditingController(text: widget.restaurant.name);
    _addressController = TextEditingController(text: widget.restaurant.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kWhite,
      title: const Text('Şube API & Çalışma Ayarları', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Şube Adı'),
                style: const TextStyle(color: _kTextHead, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Şube Adresi'),
                style: const TextStyle(color: _kTextHead, fontSize: 11),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _dedicatedMode,
                onChanged: (val) => setState(() => _dedicatedMode = val),
                title: const Text('Özel Kurye Modu (Dedicated)', style: TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: const Text('Sadece şubeye atanan kuryeler çağrı alır', style: TextStyle(color: _kTextMuted, fontSize: 9)),
                activeColor: _kIndigo,
                contentPadding: EdgeInsets.zero,
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat', style: TextStyle(color: _kTextMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSaved({
              'name': _nameController.text,
              'address': _addressController.text,
              'isDedicatedMode': _dedicatedMode,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kIndigo),
          child: const Text('Ayarları Kaydet', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

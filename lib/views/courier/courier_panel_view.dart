import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../providers/app_provider.dart';
import '../../models/courier.dart';
import '../../models/order.dart';
import '../widgets/courier_map_widget.dart';
import '../widgets/shift_scheduler_widget.dart';
import '../../services/js_helper.dart';

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

class CourierPanelView extends StatefulWidget {
  final String courierId;

  const CourierPanelView({super.key, required this.courierId});

  @override
  State<CourierPanelView> createState() => _CourierPanelViewState();
}

class _CourierPanelViewState extends State<CourierPanelView> {
  // Navigation active panel tab: 'deliveries' | 'shift' | 'jobs' | 'stats'
  String _activePanel = 'deliveries';

  // Sound triggering state to prevent multiple play calls
  String? _lastPromptedOrderId;

  // Filters for stats cüzdan tab
  String _statsFilterMode = 'today'; // 'today', 'weekly', 'monthly', 'all'
  String _statsStartDate = '';
  String _statsEndDate = '';

  // Job Listings Filters
  String _filterCity = '';
  String _filterDistrict = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _statsStartDate = now.toIso8601String().split('T')[0];
    _statsEndDate = now.toIso8601String().split('T')[0];
  }

  void _playWebCoinSound() {
    if (kIsWeb) {
      triggerWebCoinSound();
    }
  }

  void _showProfileSettingsDialog(AppProvider provider, Courier courier) {
    showDialog(
      context: context,
      builder: (ctx) => _CourierProfileSettingsDialog(
        courier: courier,
        onSaved: (updates) {
          provider.updateCourier(courier.id, updates);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi.'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final courier = provider.couriers.firstWhere(
      (c) => c.id == widget.courierId,
      orElse: () => provider.couriers.first,
    );

    // Look for new unacknowledged order assigned to this courier
    final pendingUnacknowledgedOrder = provider.orders.firstWhere(
      (o) => o.assignedCourierId == courier.id && o.status == 'kabul_edildi' && o.acknowledged == false,
      orElse: () => OrderModel(id: '', restaurantId: '', restaurantName: '', customerName: '', deliveryAddress: '', phone: '', price: 0, status: '', createdAt: '', latitude: 0, longitude: 0, isDelayed: false, acknowledged: true, poolOrder: false, reportedNotReceived: false),
    );

    // Trigger sound if a new order lands
    if (pendingUnacknowledgedOrder.id.isNotEmpty && pendingUnacknowledgedOrder.id != _lastPromptedOrderId) {
      _lastPromptedOrderId = pendingUnacknowledgedOrder.id;
      _playWebCoinSound();
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40.0 : 16.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Header Alert (Mobile/Web Notice)
                  if (!kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, color: Colors.amber.shade800, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En Doğru Konum Tespiti ve Rota Takibi İçin Cep Telefonunuzdan Giriş Yapın.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Courier Header Stats Dashboard
                  _buildProfileHeaderCard(provider, courier),
                  const SizedBox(height: 20),

                  // Premium Custom Pill Tab Bar Navigation
                  _buildCustomPillTabBar(),
                  const SizedBox(height: 24),

                  // Active Tab Router
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildActiveTabContent(provider, courier),
                  ),
                ],
              ),
            ),
          ),

          // 1. Pending Company Invitation overlay
          if (courier.pendingCompanyId != null && courier.pendingCompanyId!.isNotEmpty)
            _buildCompanyInvitationOverlay(provider, courier),

          // 2. Full-Screen New Order Alert overlay
          if (pendingUnacknowledgedOrder.id.isNotEmpty)
            _buildNewOrderFullscreenAlert(provider, courier, pendingUnacknowledgedOrder),
        ],
      ),
    );
  }

  Widget _buildCustomPillTabBar() {
    return Container(
      padding: const EdgeInsets.all(4), // p-1 in tailwind = 4px
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // slate-100
        borderRadius: BorderRadius.circular(16), // rounded-2xl
      ),
      child: Row(
        children: [
          _buildPillTabButton('deliveries', LucideIcons.bike, 'Teslimatlar'),
          _buildPillTabButton('shift', LucideIcons.calendar, 'Vardiyam'),
          _buildPillTabButton('jobs', LucideIcons.briefcase, 'İlanlar'),
          _buildPillTabButton('stats', LucideIcons.coins, 'İstatistikler'),
        ],
      ),
    );
  }

  Widget _buildPillTabButton(String panelId, IconData icon, String title) {
    final isActive = _activePanel == panelId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePanel = panelId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _kWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? _kIndigo : _kTextBody, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? _kIndigo : _kTextBody,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(AppProvider provider, Courier courier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  courier.email.contains('kurye1')
                      ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256'
                      : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courier.name,
                      style: const TextStyle(color: _kTextHead, fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'Puan: ${courier.rating} | Skor: ${courier.performanceScore}',
                          style: const TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, color: _kIndigo, size: 18),
                onPressed: () => _showProfileSettingsDialog(provider, courier),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorderLight, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStatColumn('Cüzdanım', '${courier.earningsWallet.round()} TL', const Color(0xFF059669)),
              _buildHeaderStatColumn('Teslimat', '${courier.deliveriesCount} Paket', _kIndigo),
              _buildHeaderStatColumn('Kabul Oranı', '%${courier.acceptanceRate}', courier.acceptanceRate < 85 ? Colors.red : Colors.green.shade600),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: _kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent(AppProvider provider, Courier courier) {
    switch (_activePanel) {
      case 'deliveries':
        return _buildDeliveriesTab(provider, courier);
      case 'shift':
        return Container(
          key: const ValueKey('shift'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: ShiftSchedulerWidget(courierId: courier.id),
        );
      case 'jobs':
        return _buildJobsTab(provider, courier);
      case 'stats':
        return _buildStatsTab(provider, courier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDeliveriesTab(AppProvider provider, Courier courier) {
    final activeOrders = provider.orders.where((o) =>
      o.assignedCourierId == courier.id &&
      !['teslim_edildi', 'iptal'].contains(o.status)
    ).toList();

    return Column(
      key: const ValueKey('deliveries'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GPS & Teleport Controls (only for logged-in courier)
        if (provider.currentUser?['role'] == 'kurye')
          _buildGpsControlsCard(provider, courier, activeOrders),

        const SizedBox(height: 20),

        // 3. Aktif Görevler Kartı
        if (activeOrders.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'AKTİF DAĞITIM GÖREVLERİ',
              style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
          ...activeOrders.map((order) => _buildOrderCard(provider, courier, order)),
        ] else
          _buildEmptyDeliveriesView(courier),

        // 4. Hedef Ödül Primleri Progress barlar
        _buildTargetRewardsCard(provider, courier),
      ],
    );
  }

  Widget _buildDemoCourierPicker(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SİMÜLE EDİLEN KURYE SEÇİMİ',
            style: TextStyle(color: _kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.couriers.map((c) {
              final isActive = c.id == widget.courierId;
              return ChoiceChip(
                label: Text(c.name),
                selected: isActive,
                selectedColor: _kIndigoPale,
                backgroundColor: _kBg,
                labelStyle: TextStyle(
                  color: isActive ? _kIndigo : _kTextBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                side: BorderSide(color: isActive ? _kIndigoBorder : _kBorder),
                onSelected: (_) {
                  provider.setDemoActiveCourierId(c.id);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsControlsCard(AppProvider provider, Courier courier, List<OrderModel> activeOrders) {
    final hasActiveOrder = activeOrders.isNotEmpty;
    final order = hasActiveOrder ? activeOrders.first : null;
    final restaurant = hasActiveOrder
        ? provider.restaurants.firstWhere((r) => r.id == order!.restaurantId, orElse: () => provider.restaurants.first)
        : provider.restaurants.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(LucideIcons.compass, color: _kIndigo, size: 14),
                  SizedBox(width: 8),
                  Text('KURYE KONTROL PANELİ', style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                ],
              ),
              if (courier.courierCompanyId != null)
                TextButton.icon(
                  onPressed: () {
                    provider.updateCourier(courier.id, {'courierCompanyId': null});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Firmadan ayrıldınız. Havuz kuryesi olarak atandınız.')),
                    );
                  },
                  icon: const Icon(LucideIcons.logOut, size: 10, color: Colors.red),
                  label: const Text('İşten Ayrıl', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.updateCourierLocation(courier.id, restaurant.latitude, restaurant.longitude);
                    provider.confirmCourierAtRestaurant(courier.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kIndigo,
                    side: const BorderSide(color: _kIndigoBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Restorana Getir (15m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Coordinates around Muğla far away
                    provider.updateCourierLocation(courier.id, restaurant.latitude + 0.02, restaurant.longitude + 0.02);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kTextBody,
                    side: const BorderSide(color: _kBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Uzağa Git (2.5 km)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Restorana Uzaklık:', style: TextStyle(color: _kTextBody, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(
                courier.isAtRestaurant ? 'Sıradasınız (Kuyrukta)' : 'Restoran Dışında',
                style: TextStyle(
                  color: courier.isAtRestaurant ? Colors.green.shade600 : Colors.amber.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Konum Koordinat:', style: TextStyle(color: _kTextMuted, fontSize: 9)),
                Text(
                  '${courier.latitude.toStringAsFixed(5)}, ${courier.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: _kTextBody, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                provider.callCourier(
                  restaurantId: courier.assignedRestaurantId ?? provider.restaurants.first.id,
                  customerName: 'Demo Müşteri (Mobil)',
                  address: 'Atatürk Bulvarı No:14, Çankaya',
                  phone: '05553332211',
                  price: 150.0,
                  lat: courier.latitude + 0.005,
                  lon: courier.longitude + 0.005,
                  poolOrder: false,
                  forceCourierId: courier.id,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simüle edilen sipariş size atandı! 🔔'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(LucideIcons.bellRing, size: 14, color: Colors.white),
              label: const Text('Bana Test Siparişi Gönder', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(AppProvider provider, Courier courier, OrderModel order) {
    final isAccepted = order.status == 'kabul_edildi';
    final isPickedUp = order.status == 'teslim_alindi' || order.status == 'tasimada';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: order.isDelayed ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID & status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SİPARİŞ #${order.id.split('_').last}',
                      style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPickedUp ? const Color(0xFFF0F9FF) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: isPickedUp ? const Color(0xFF0369A1) : const Color(0xFF047857),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Details grid
                _buildOrderCardDetailRow('Restoran', order.restaurantName),
                _buildOrderCardDetailRow('Alıcı Müşteri', order.customerName),
                _buildOrderCardDetailRow('Teslimat Adresi', order.deliveryAddress),
                _buildOrderCardDetailRow('Müşteri Tel', order.phone),
                _buildOrderCardDetailRow('Hak Ediş Bedeli', '${order.price} TL'),
                const SizedBox(height: 16),

                // Map Preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    child: CourierMapWidget(
                      courierLat: courier.latitude,
                      courierLon: courier.longitude,
                      restaurantLat: provider.restaurants.first.latitude,
                      restaurantLon: provider.restaurants.first.longitude,
                      courierName: courier.name,
                      restaurantName: order.restaurantName,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWhite,
                border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: _buildOrderActionButtons(provider, order, courier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCardDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _kTextBody, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActionButtons(AppProvider provider, OrderModel order, Courier courier) {
    final isAccepted = order.status == 'kabul_edildi';

    if (isAccepted) {
      return ElevatedButton.icon(
        onPressed: courier.isAtRestaurant
            ? () => provider.pickupPackage(order.id, courier.id)
            : null,
        icon: const Icon(LucideIcons.shoppingBag, size: 14, color: Colors.white),
        label: const Text('Paketi Restorandan Aldım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          disabledBackgroundColor: Colors.grey.shade300,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => provider.deliverPackage(order.id, courier.id),
              icon: const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white),
              label: const Text('Teslimatı Tamamladım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kIndigo,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final res = await provider.cancelAssignedOrder(order.id, courier.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'])),
              );
            },
            icon: const Icon(LucideIcons.xCircle, size: 14, color: Colors.red),
            label: const Text('İptal', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEmptyDeliveriesView(Courier courier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kIndigoPale, shape: BoxShape.circle),
            child: const Icon(LucideIcons.bike, color: _kIndigo, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            courier.isAtRestaurant ? 'Restoranda Sıradasınız' : 'Müsait / Sipariş Bekleniyor',
            style: TextStyle(
              color: courier.isAtRestaurant ? Colors.green.shade600 : Colors.amber.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni Sipariş Çağrısı Bekleniyor...',
            style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            courier.isAtRestaurant
                ? 'Sıra numaranız: #${courier.queuePosition + 1}. Restorandan kurye çağrıldığında ilk size bildirim düşecektir.'
                : 'Hizmet havuzunda sıraya dahil olmak için restorana (100m sınırına) yaklaşmanız gerekir.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextMuted, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRewardsCard(AppProvider provider, Courier courier) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEDEF ÖDÜL PRİMLERİ',
            style: TextStyle(color: _kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          // Daily Target Simulation
          _buildProgressRow('Günlük Hedef (150 TL Prim)', courier.deliveriesCount, 15),
          const SizedBox(height: 14),
          // Weekly Target Simulation
          _buildProgressRow('Haftalık Hedef (1500 TL Prim)', courier.deliveriesCount, 80),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int value, int target) {
    final double pct = min(1.0, value / target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _kTextBody, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('$value / $target Paket', style: const TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: _kBg,
            valueColor: AlwaysStoppedAnimation<Color>(pct >= 1.0 ? Colors.green.shade500 : _kIndigo),
            minHeight: 6,
          ),
        )
      ],
    );
  }

  Widget _buildJobsTab(AppProvider provider, Courier courier) {
    final requests = provider.courierRequests.where((r) => r.status == 'published_as_job' || r.status == 'pending').toList();

    return Column(
      key: const ValueKey('jobs'),
      children: [
        // District filter header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterCity.isEmpty ? null : _filterCity,
                  hint: const Text('İl Seçin', style: TextStyle(fontSize: 11)),
                  items: const [
                    DropdownMenuItem(value: 'Muğla', child: Text('Muğla')),
                    DropdownMenuItem(value: 'Ankara', child: Text('Ankara')),
                    DropdownMenuItem(value: 'İstanbul', child: Text('İstanbul')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filterCity = val ?? '';
                    });
                  },
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(hintText: 'İlçe Arayın', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (val) {
                    setState(() {
                      _filterDistrict = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('Aktif kurye arama ilanı bulunmuyor.', style: TextStyle(color: _kTextMuted)),
          )
        else
          ...requests.map((req) {
            final isApplied = courier.assignedRestaurantId == req.restaurantId;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(req.restaurantName, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _kIndigoPale, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          req.type.toUpperCase(),
                          style: const TextStyle(color: _kIndigo, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(req.description, style: const TextStyle(color: _kTextBody, fontSize: 11, height: 1.4)),
                  const SizedBox(height: 16),
                  const Divider(color: _kBorderLight),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⏱️ Vardiya: ${req.durationDetails}', style: const TextStyle(color: _kTextMuted, fontSize: 9)),
                          const SizedBox(height: 2),
                          Text('🏍️ Motor: ${req.motorcycleRequired == 'yes' ? 'Kendi Motorlu' : 'Şube Motorlu'}', style: const TextStyle(color: _kTextMuted, fontSize: 9)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: isApplied
                            ? null
                            : () {
                                provider.assignCourierToRequest(req.id, courier.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Başvuru onaylandı! Şubeye kurye olarak atandınız.'), backgroundColor: Colors.green),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApplied ? Colors.grey : _kIndigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(isApplied ? 'Atandınız' : 'Kabul Et / Başvur', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatsTab(AppProvider provider, Courier courier) {
    final logs = courier.earningsLog;

    return Column(
      key: const ValueKey('stats'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date filter row selector
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatsFilterButton('today', 'Bugün'),
              _buildStatsFilterButton('weekly', 'Haftalık'),
              _buildStatsFilterButton('monthly', 'Aylık'),
              _buildStatsFilterButton('all', 'Tümü'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('Finansal hareket geçmişi bulunmuyor.', style: TextStyle(color: _kTextMuted))),
          )
        else
          ...logs.map((log) {
            final isCredit = log.amount > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.note, style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(log.timestamp.split('T')[0], style: const TextStyle(color: _kTextMuted, fontSize: 9)),
                    ],
                  ),
                  Text(
                    '${isCredit ? '+' : ''}${log.amount.round()} TL',
                    style: TextStyle(
                      color: isCredit ? Colors.green.shade600 : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatsFilterButton(String mode, String label) {
    final active = _statsFilterMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _statsFilterMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kIndigoPale : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _kIndigo : _kTextBody,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInvitationOverlay(AppProvider provider, Courier courier) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _kIndigoPale, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.building, color: _kIndigo, size: 36),
                ),
                const SizedBox(height: 24),
                const Text('Firma Daveti Alındı!', style: TextStyle(color: _kTextHead, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Bir kurye firması sizi kendi bünyesinde çalıştırmak üzere davet gönderdi. Kabul etmeniz durumunda firmanın hakediş kurallarına tabi olacaksınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextBody, fontSize: 11, height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          provider.updateCourier(courier.id, {
                            'courierCompanyId': courier.pendingCompanyId,
                            'pendingCompanyId': null,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Davet kabul edildi!'), backgroundColor: Colors.green),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Kabul Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.updateCourier(courier.id, {
                            'pendingCompanyId': null,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Davet reddedildi.'), backgroundColor: Colors.redAccent),
                          );
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _kBorder)),
                        child: const Text('Reddet', style: TextStyle(color: _kTextBody)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewOrderFullscreenAlert(AppProvider provider, Courier courier, OrderModel order) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _kIndigo, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.bell, color: Colors.amber, size: 48),
                const SizedBox(height: 20),
                const Text('YENİ SİPARİŞ ATANDI!', style: TextStyle(color: _kTextHead, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text(order.restaurantName, style: const TextStyle(color: _kIndigo, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(order.deliveryAddress, textAlign: TextAlign.center, style: const TextStyle(color: _kTextBody, fontSize: 11)),
                      const SizedBox(height: 10),
                      Text('${order.price} TL', style: TextStyle(color: Colors.green.shade600, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    provider.acceptOrder(order.id, courier.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Geliyorum! (Siparişi Onayla)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourierProfileSettingsDialog extends StatefulWidget {
  final Courier courier;
  final Function(Map<String, dynamic>) onSaved;

  const _CourierProfileSettingsDialog({required this.courier, required this.onSaved});

  @override
  State<_CourierProfileSettingsDialog> createState() => _CourierProfileSettingsDialogState();
}

class _CourierProfileSettingsDialogState extends State<_CourierProfileSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ibanController;

  // SMS OTP state
  bool _otpSent = false;
  String _simulatedCode = '';
  final _otpController = TextEditingController();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.courier.name);
    _ibanController = TextEditingController(text: widget.courier.iban ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _triggerIbanOtp() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _otpSent = true;
        _simulatedCode = '1234'; // Default simulation code
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kWhite,
          title: const Text('SMS Simülatörü', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
          content: const Text('Güvenliğiniz için IBAN değişikliği SMS kodu gönderildi!\n\nKod: 1234', style: TextStyle(color: _kTextBody, fontSize: 12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: _kIndigo, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kWhite,
      title: const Text('Profil & Hesap Bilgileri', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_otpSent) ...[
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: _kTextHead, fontSize: 11),
                  decoration: _inputDecoration('Ad Soyad', LucideIcons.user),
                  validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ibanController,
                  style: const TextStyle(color: _kTextHead, fontSize: 11),
                  decoration: _inputDecoration('IBAN Numarası (TR...)', LucideIcons.wallet),
                  validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('SMS onay kodu telefonunuza iletildi.', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kTextHead, fontSize: 14, letterSpacing: 4),
                  decoration: _inputDecoration('SMS Onay Kodu (1234)', LucideIcons.lock),
                ),
                if (_errorText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ]
              ]
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
            if (!_otpSent) {
              if (widget.courier.iban != _ibanController.text) {
                // IBAN changed, request OTP verification
                _triggerIbanOtp();
              } else {
                // Update directly
                widget.onSaved({
                  'name': _nameController.text,
                });
              }
            } else {
              if (_otpController.text == '1234') {
                widget.onSaved({
                  'name': _nameController.text,
                  'iban': _ibanController.text,
                });
              } else {
                setState(() {
                  _errorText = 'Kod geçersiz. Lütfen tekrar deneyin.';
                });
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kIndigo),
          child: Text(_otpSent ? 'Doğrula ve Kaydet' : 'Değişiklikleri Kaydet', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
}

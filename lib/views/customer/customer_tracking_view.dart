import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/order.dart';
import '../widgets/courier_map_widget.dart';

class CustomerTrackingView extends StatefulWidget {
  final String orderId;
  final VoidCallback onBack;

  const CustomerTrackingView({super.key, required this.orderId, required this.onBack});

  @override
  State<CustomerTrackingView> createState() => _CustomerTrackingViewState();
}

class _CustomerTrackingViewState extends State<CustomerTrackingView> {
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    // Find matching order details
    final order = provider.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => provider.orders.isNotEmpty ? provider.orders.first : _dummyOrder(),
    );

    final courier = order.assignedCourierId != null
        ? provider.couriers.firstWhere((c) => c.id == order.assignedCourierId, orElse: () => provider.couriers.first)
        : null;

    final restaurant = provider.restaurants.firstWhere(
      (r) => r.id == order.restaurantId,
      orElse: () => provider.restaurants.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 955
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: widget.onBack,
        ),
        title: const Text('Sipariş Takibi', style: TextStyle(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline stepper card
            _buildTimelineCard(order),
            
            const SizedBox(height: 24),
            
            // Map
            SizedBox(
              height: 300,
              child: CourierMapWidget(
                courierLat: courier?.latitude ?? restaurant.latitude,
                courierLon: courier?.longitude ?? restaurant.longitude,
                restaurantLat: restaurant.latitude,
                restaurantLon: restaurant.longitude,
                courierName: courier?.name ?? 'Şube',
                restaurantName: order.customerName,
              ),
            ),

            const SizedBox(height: 24),
            
            // Details summary card
            _buildCourierSummaryCard(order, courier),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(OrderModel order) {
    int activeStep = 0;
    if (order.status == 'kabul_edildi') activeStep = 1;
    if (['teslim_alindi', 'tasimada'].contains(order.status)) activeStep = 2;
    if (order.status == 'teslim_edildi') activeStep = 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // Slate 900
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tahmini Teslimat Süresi', style: TextStyle(color: const Color(0xFF475569), fontSize: 11)),
              Text(
                order.isDelayed ? 'GECİKME' : '15-25 Dk',
                style: TextStyle(color: order.isDelayed ? Colors.redAccent : Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Row layout representing timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep('Sipariş Alındı', activeStep >= 0),
              _buildStep('Kurye Atandı', activeStep >= 1),
              _buildStep('Yolda', activeStep >= 2),
              _buildStep('Teslim Edildi', activeStep >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String text, bool completed) {
    return Column(
      children: [
        Icon(
          completed ? LucideIcons.checkCircle : LucideIcons.circle,
          color: completed ? Colors.green : const Color(0xFF94A3B8),
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(color: completed ? const Color(0xFF0F172A) : const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCourierSummaryCard(OrderModel order, dynamic courier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // Slate 900
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.bike, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier != null ? 'Kuryeniz: ${courier.name}' : 'Kuryeniz Aranıyor...',
                  style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                if (courier != null) ...[
                  Text(
                    'Ortalama Teslimat Süresi: ${courier.avgDeliveryTimeMinutes} dk | Değerlendirme: ★ ${courier.rating}',
                    style: const TextStyle(color: const Color(0xFF64748B), fontSize: 9),
                  )
                ] else ...[
                  const Text('Lütfen bekleyin, en uygun kurye yönlendiriliyor.', style: TextStyle(color: const Color(0xFF64748B), fontSize: 9))
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  OrderModel _dummyOrder() {
    return OrderModel(
      id: '',
      restaurantId: '',
      restaurantName: '',
      customerName: '',
      deliveryAddress: '',
      phone: '',
      price: 0,
      status: 'araniyor',
      createdAt: '',
      latitude: 0,
      longitude: 0,
      isDelayed: false,
      acknowledged: false,
      poolOrder: false,
      reportedNotReceived: false,
    );
  }
}

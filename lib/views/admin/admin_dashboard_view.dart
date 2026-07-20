import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/company.dart';
import '../../models/restaurant.dart';
import '../../models/courier.dart';
import '../../models/contact_message.dart';

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

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  String _activeTab = 'companies'; // 'companies' | 'restaurants' | 'couriers' | 'contact' | 'support'

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
            // 1. Title & Header Info
            _buildAdminHeader(),
            const SizedBox(height: 20),

            // 2. Metrics Overview Row
            _buildMetricsOverview(provider),
            const SizedBox(height: 20),

            // 3. Custom Pill Nav Bar
            _buildPillNavBar(isDesktop),
            const SizedBox(height: 24),

            // 4. Tab router content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildActiveTabContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Süper Admin Dashboard', style: TextStyle(color: _kTextHead, fontSize: 16, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('SaaS Yönetimi ve Platform Genel Ayarları', style: TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(LucideIcons.shieldCheck, color: _kIndigo, size: 24),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(AppProvider provider) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildMetricBox('FİRMALAR', '${provider.companies.length}', _kIndigo),
        _buildMetricBox('ŞUBELER', '${provider.restaurants.length}', _kOrange),
        _buildMetricBox('KURYE SAYISI', '${provider.couriers.length}', Colors.green.shade600),
        _buildMetricBox('TOPLAM SİPARİŞ', '${provider.orders.length}', Colors.amber.shade700),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPillNavBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), // slate-100
      child: Wrap(
        children: [
          _buildPillTabButton('companies', LucideIcons.building2, 'Firmalar'),
          _buildPillTabButton('restaurants', LucideIcons.chefHat, 'Restoranlar'),
          _buildPillTabButton('couriers', LucideIcons.bike, 'Kuryeler'),
          _buildPillTabButton('contact', LucideIcons.mail, 'Talepler'),
          _buildPillTabButton('support', LucideIcons.messageSquare, 'Destek'),
        ],
      ),
    );
  }

  Widget _buildPillTabButton(String id, IconData icon, String title) {
    final active = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _kIndigo : _kTextBody, size: 14),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: active ? _kIndigo : _kTextBody, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(AppProvider provider) {
    switch (_activeTab) {
      case 'companies':
        return _buildCompaniesList(provider);
      case 'restaurants':
        return _buildRestaurantsList(provider);
      case 'couriers':
        return _buildCouriersList(provider);
      case 'contact':
        return _buildContactMessagesList(provider);
      case 'support':
        return _buildSupportChatsList(provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCompaniesList(AppProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.companies.length,
      itemBuilder: (context, index) {
        final c = provider.companies[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('E-Posta: ${c.email} | Tel: ${c.phone}', style: const TextStyle(color: _kTextMuted, fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text(c.status.toUpperCase(), style: TextStyle(color: Colors.green.shade700, fontSize: 8, fontWeight: FontWeight.w900)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsList(AppProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.restaurants.length,
      itemBuilder: (context, index) {
        final r = provider.restaurants[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Adres: ${r.address}', style: const TextStyle(color: _kTextMuted, fontSize: 10)),
              const SizedBox(height: 4),
              Text('Yetkili: ${r.managerName} (${r.managerPhone})', style: const TextStyle(color: _kTextBody, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouriersList(AppProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.couriers.length,
      itemBuilder: (context, index) {
        final c = provider.couriers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Telefon: ${c.phone} | Puan: ${c.rating}', style: const TextStyle(color: _kTextMuted, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.isShadowBanned ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.isShadowBanned ? 'CEZALI' : 'TEMİZ',
                  style: TextStyle(
                    color: c.isShadowBanned ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactMessagesList(AppProvider provider) {
    if (provider.contactMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
        child: const Center(child: Text('Gelen kurumsal teklif talebi bulunmuyor.', style: TextStyle(color: _kTextMuted))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.contactMessages.length,
      itemBuilder: (context, index) {
        final msg = provider.contactMessages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(msg.name, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                    onPressed: () => provider.deleteContactMessage(msg.id),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Kurum: ${msg.company} | Tel: ${msg.phone}', style: const TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(msg.message, style: const TextStyle(color: _kTextBody, fontSize: 11, height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportChatsList(AppProvider provider) {
    if (provider.supportChats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
        child: const Center(child: Text('Aktif destek talebi bulunmuyor.', style: TextStyle(color: _kTextMuted))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.supportChats.keys.length,
      itemBuilder: (context, index) {
        final orderId = provider.supportChats.keys.elementAt(index);
        final messages = provider.supportChats[orderId]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sipariş ID: #$orderId', style: const TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Son Mesaj: ${messages.isNotEmpty ? messages.last.text : 'Yok'}', style: const TextStyle(color: _kTextHead, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

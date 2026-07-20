import os
import re

with open('lib/views/marketing/marketing_view.dart', 'r', encoding='utf-8') as f:
    code = f.read()

sim_class = '''
class InteractiveSimulatorCard extends StatefulWidget {
  const InteractiveSimulatorCard({super.key});

  @override
  State<InteractiveSimulatorCard> createState() => _InteractiveSimulatorCardState();
}

class _InteractiveSimulatorCardState extends State<InteractiveSimulatorCard> {
  int _step = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _step = (_step + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _dot(Colors.red.shade400),
                  const SizedBox(width: 5), _dot(Colors.amber),
                  const SizedBox(width: 5), _dot(Colors.green),
                ],
              ),
              const Text('KURYEAPP // SIMULATOR', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _orderCard(
          badge: 'Yeni Sipariş', badgeBg: const Color(0xFFFEF3C7), badgeText: const Color(0xFFB45309),
          orderId: '#YS-8742', title: '1x Karışık Pizza, Kola', location: 'Çankaya, Ankara',
          status: 'Kurye Aranıyor...', statusColor: Colors.amber.shade700, icon: LucideIcons.loader,
        );
      case 1:
        return _orderCard(
          badge: 'Kurye Atandı', badgeBg: const Color(0xFFE0E7FF), badgeText: const Color(0xFF4338CA),
          orderId: '#YS-8742', title: 'Ahmet (Kurye) yola çıktı', location: 'Çankaya, Ankara',
          status: 'Teslimata Gidiyor (3 dk)', statusColor: const Color(0xFF4F46E5), icon: LucideIcons.bike,
        );
      case 2:
      default:
        return Column(
          children: [
            _orderCard(
              badge: 'Teslim Edildi', badgeBg: const Color(0xFFD1FAE5), badgeText: const Color(0xFF065F46),
              orderId: '#YS-8742', title: 'Sipariş Teslim Edildi', location: 'Çankaya, Ankara',
              status: 'Başarılı Teslimat', statusColor: const Color(0xFF10B981), icon: LucideIcons.checkCircle,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Müşteriye SMS ve takip linki gönderildi.', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            )
          ],
        );
    }
  }

  Widget _dot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _orderCard({
    required String badge, required Color badgeBg, required Color badgeText,
    required String orderId, required String title, required String location,
    required String status, required Color statusColor, required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(badge, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              Text(orderId, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(location, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Icon(icon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
'''

if 'InteractiveSimulatorCard' not in code:
    code += '\n' + sim_class

if 'import \'dart:async\';' not in code:
    code = code.replace("import '../../providers/app_provider.dart';", "import '../../providers/app_provider.dart';\nimport 'dart:async';")

start_right = code.find('final right = Stack(')
end_right = code.find('if (isDesktop) {', start_right)
if start_right != -1 and end_right != -1:
    code = code[:start_right] + 'final right = Transform.scale(scale: 1.1, child: const InteractiveSimulatorCard());\n\n    ' + code[end_right:]

mobile_layout_code = '''
  Widget _buildMobileLayout(AppProvider provider) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          elevation: 0,
          backgroundColor: _kIndigo,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Kurye App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kIndigo, _kPurple], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                        child: const Text('%100 Bulut Tabanlı', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Akıllı Kurye Takip ve Teslimat Yönetimi', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Siparişlerinizi en gelişmiş teslimat altyapısıyla yöneterek verimliliğinizi ikiye katlayın.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: _kBg,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _heroStat('2000+', 'Aktif Şube', false),
                      _heroStat('100K+', 'Günlük Paket', false),
                      _heroStat('%99.4', 'Başarılı ETA', true),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildSectionTitle('Gelişmiş Özellikler', LucideIcons.sparkles, _kIndigo),
                _buildQuickFeatures(),
                const SizedBox(height: 40),
                _buildSectionTitle('Sıkça Sorulanlar', LucideIcons.helpCircle, _kPurple),
                _buildFaqSection(),
                const SizedBox(height: 140),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: _kTextHead, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildQuickFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _quickCard(LucideIcons.refreshCw, '%100 Otomatik Atama', 'Yapay zeka algoritması ile paketler 60 saniyede atanır.'),
          const SizedBox(height: 12),
          _quickCard(LucideIcons.mapPin, 'Canlı Harita Takibi', 'GPS üzerinden kuryelerinizi ve teslimatları anlık izleyin.'),
          const SizedBox(height: 12),
          _quickCard(LucideIcons.building2, 'Tüm Entegrasyonlar', 'Yemeksepeti, Trendyol Go, Getir tek API ile entegre.'),
        ],
      ),
    );
  }
'''

build_idx = code.find('Widget build(BuildContext context) {')
end_build_idx = code.find('// ─────────────── HEADER ───────────────')
original_build = code[build_idx:end_build_idx]

new_build = '''Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;
    final isMd = w > 768;

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: _kBg,
        body: _buildMobileLayout(provider),
        bottomSheet: Container(
          color: Colors.transparent, 
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 12 : 24,
            left: 20, right: 20, top: 12
          ),
          child: GestureDetector(
            onTap: widget.onPanelClick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _kIndigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.building2, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Yönetim Paneline Giriş Yap', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(isDesktop, provider),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMd ? 48 : 16, vertical: isMd ? 64 : 32),
                    child: Column(
                      children: [
                        Container(key: _homeKey, child: _buildHeroSection(isDesktop, isMd)),
                        const SizedBox(height: 80),
                        _buildQuickInfoSection(isMd),
                        const SizedBox(height: 80),
                        _buildDivider(),
                        const SizedBox(height: 80),
                        Container(key: _featuresKey, child: _buildFeaturesSection(isDesktop)),
                        const SizedBox(height: 80),
                        _buildDivider(),
                        const SizedBox(height: 80),
                        Container(key: _pricingKey, child: _buildPricingSection()),
                        const SizedBox(height: 80),
                        _buildDivider(),
                        const SizedBox(height: 80),
                        Container(key: _faqKey, child: _buildFaqSection()),
                        const SizedBox(height: 80),
                        _buildDivider(),
                        const SizedBox(height: 80),
                        Container(key: _contactKey, child: _buildContactSection(provider, isDesktop)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

''' + mobile_layout_code

code = code.replace(original_build, new_build)

code = code.replace('.withOpacity(', '.withValues(alpha: ')

with open('lib/views/marketing/marketing_view.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Done')

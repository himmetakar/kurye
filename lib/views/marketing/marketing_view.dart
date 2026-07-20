import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/job_posting.dart';
import 'dart:async';
import 'components/interactive_simulator_card.dart';

// ───────── Renk Sabitleri (React ile birebir) ─────────
const _kBg = Color(0xFFF8FAFC);          // slate-50
const _kWhite = Colors.white;
const _kBorder = Color(0xFFE2E8F0);      // slate-200
const _kBorderLight = Color(0xFFF1F5F9); // slate-100
const _kTextHead = Color(0xFF0F172A);    // slate-900 / slate-855
const _kTextBody = Color(0xFF475569);    // slate-600
const _kTextMuted = Color(0xFF94A3B8);   // slate-400
const _kIndigo = Color(0xFF4F46E5);      // indigo-600
const _kIndigoPale = Color(0xFFEEF2FF);  // indigo-50
const _kIndigoBorder = Color(0xFFC7D2FE); // indigo-200
const _kPurple = Color(0xFF7C3AED);      // purple-600
const _kOrange = Color(0xFFF97316);      // orange-500
const _kOrangePale = Color(0xFFFFF7ED);  // orange-50
const _kGreen = Color(0xFF10B981);       // emerald-500

class MarketingView extends StatefulWidget {
  final VoidCallback onPanelClick;
  final ValueChanged<String>? onTrackingClick;
  final ValueChanged<String>? onRegisterClick;

  const MarketingView({
    super.key,
    required this.onPanelClick,
    this.onTrackingClick,
    this.onRegisterClick,
  });

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final _homeKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _postingsKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _contactKey = GlobalKey();

  int? _openFaq;
  bool _isSubmitted = false;
  int _selectedFeatureTab = 0;

  String? _searchCity;
  String? _searchDistrict;

  final _faqData = const [
    {
      'q': 'Sistem hangi pazaryerleri ile entegre çalışmaktadır?',
      'a': 'KuryeApp; tüm popüler yemek ve market sipariş kanalları, pazaryerleri ve kurye vale sistemlerinizle doğrudan API entegrasyonuna sahiptir.'
    },
    {
      'q': 'Kuryelerin takibini nasıl sağlıyoruz?',
      'a': 'Kuryelerimizin kullandığı mobil uygulama üzerinden alınan anlık GPS verileri sayesinde, tüm kuryelerin konumlarını, hızlarını ve teslimat süreçlerini yönetici haritası üzerinden canlı olarak izleyebilirsiniz.'
    },
    {
      'q': 'Otomatik atama (Auto-Assign) algoritması nasıl çalışır?',
      'a': 'Geliştirdiğimiz yapay zeka algoritması; siparişi hazırlayan restoranın konumu ile aktif durumdaki kuryelerin mesafelerini, kuryelerin üzerindeki aktif iş yüklerini ve geçmiş performans puanlarını anlık analiz ederek paketi en uygun kuryeye 60 saniye içinde otomatik atar.'
    },
    {
      'q': 'Kurye performansı nasıl ölçülüyor?',
      'a': 'Kuryelerin siparişi teslim alma süresi, rota dışına çıkma durumları, teslimat ETA sapmaları ve iptal oranları hesaplanarak otomatik performans skoru çıkarılır.'
    },
    {
      'q': 'Kurulum veya başlangıç ücreti var mı?',
      'a': 'Hayır. KuryeApp\'te hiçbir kurulum, lisans veya gizli başlangıç ücreti bulunmamaktadır. Ön ödeme yapmadan sistemi hemen kullanmaya başlayabilirsiniz.'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut, alignment: 0.0);
    }
  }

  void _handleSubmit(AppProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitted = true);
    provider.submitContactForm(
      _nameController.text, _emailController.text,
      _phoneController.text, _companyController.text, _messageController.text,
    );
    _nameController.clear(); _emailController.clear();
    _phoneController.clear(); _companyController.clear();
    _messageController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talebiniz başarıyla alındı! En kısa sürede sizinle iletişime geçeceğiz. 🚀'), backgroundColor: _kIndigo),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSubmitted = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
                        Container(key: _postingsKey, child: _buildJobPostingsSection(provider)),
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


  Widget _buildMobileLayout(AppProvider provider) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 360,
          pinned: true,
          elevation: 0,
          backgroundColor: _kPurple,
          title: const Text('Kurye App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kPurple, _kIndigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                        child: const Text('%100 Bulut Tabanlı', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Akıllı Kurye Takip ve Teslimat Yönetimi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Siparişlerinizi en gelişmiş teslimat altyapısıyla yöneterek verimliliğinizi ikiye katlayın.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.5)),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _showDemoSelectionDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(LucideIcons.playCircle, size: 16, color: _kIndigo),
                              SizedBox(width: 8),
                              Text('Panel Demosunu Dene', style: TextStyle(color: _kIndigo, fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _mobileNavLink('Özellikler', () => _scrollToSection(_featuresKey)),
                    const SizedBox(width: 16),
                    _mobileNavLink('Fiyatlama', () => _scrollToSection(_pricingKey)),
                    const SizedBox(width: 16),
                    _mobileNavLink('İş İlanları', () => _scrollToSection(_postingsKey)),
                    const SizedBox(width: 16),
                    _mobileNavLink('SSS', () => _scrollToSection(_faqKey)),
                    const SizedBox(width: 16),
                    _mobileNavLink('İletişim', () => _scrollToSection(_contactKey)),
                  ],
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
                // Stats Row
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
                
                // Animated Simulator
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: InteractiveSimulatorCard(),
                ),

                // Quick Info Section (Otomatik Atama, Harita, Entegrasyonlar)
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: _featuresKey,
                    child: _buildQuickInfoSection(false),
                  ),
                ),

                // Pricing Section
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: _pricingKey,
                    child: _buildPricingSection(),
                  ),
                ),

                // Job Postings Section
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: _postingsKey,
                    child: _buildJobPostingsSection(provider),
                  ),
                ),

                // FAQ Section
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: _faqKey,
                    child: _buildFaqSection(),
                  ),
                ),

                // Contact Section
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    key: _contactKey,
                    child: _buildContactSection(provider, false),
                  ),
                ),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
// ─────────────── HEADER ───────────────
  Widget _buildHeader(bool isDesktop, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: _kBorderLight)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => _scrollToSection(_homeKey),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kIndigo,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_kIndigo, _kPurple],
                        ).createShader(b),
                        child: const Text('Kurye App', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ),
                      const Text('Akıllı Teslimat Platformu', style: TextStyle(color: _kTextMuted, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Nav Links (Desktop)
            if (isDesktop) ...[
              _navLink('Ana Sayfa', () => _scrollToSection(_homeKey)),
              _navLink('Özellikler', () => _scrollToSection(_featuresKey)),
              _navLink('Fiyatlar', () => _scrollToSection(_pricingKey)),
              _navLink('İş İlanları', () => _scrollToSection(_postingsKey)),
              _navLink('S.S.S.', () => _scrollToSection(_faqKey)),
              _navLink('İletişim', () => _scrollToSection(_contactKey)),
              const SizedBox(width: 24),
            ],
            // Panel Button
            GestureDetector(
              onTap: widget.onPanelClick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.building2, size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Yönetim Paneli', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: _kTextBody),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _mobileNavLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ─────────────── HERO ───────────────
  
  void _showDemoSelectionDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Panel Demosu', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        content: const Text('Hangi paneli lokal veriyle test etmek istersiniz?', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          _buildDemoOption(ctx, provider, 'Restoran Paneli', LucideIcons.store, 'restoran', Colors.orange),
          const SizedBox(height: 8),
          _buildDemoOption(ctx, provider, 'Kurye Firması', LucideIcons.building2, 'firma', Colors.purple),
          const SizedBox(height: 8),
          _buildDemoOption(ctx, provider, 'Kurye Uygulaması', LucideIcons.bike, 'kurye', Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildDemoOption(BuildContext ctx, AppProvider provider, String title, IconData icon, String role, MaterialColor color) {
    return InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        final success = await provider.loginAsDemo(role);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo girişi başarısız')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.shade600, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop, bool isMd) {

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _kIndigoPale,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _kIndigoBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(LucideIcons.sparkles, size: 11, color: _kIndigo),
              SizedBox(width: 6),
              Text('%100 Bulut Tabanlı ve Otomatik', style: TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // H1 with gradient span
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.5, color: _kTextHead),
            children: [
              const TextSpan(text: 'Akıllı Kurye Takip ve\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [_kIndigo, _kPurple]).createShader(b),
                  child: const Text('Teslimat Yönetimi', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kurye App ile kurye takibini, restoran siparişlerinizi ve pazaryeri entegrasyonlarını tek çatı altında yönetin. Mesafe analiziyle otomatik kurye atama, canlı harita takibi ve anlık raporlama ile teslimat operasyonunuzu sıfır hata ile yönetin.',
          style: TextStyle(color: _kTextBody, fontSize: 13, height: 1.7, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 28),
        // Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: () => _showDemoSelectionDialog(context, Provider.of<AppProvider>(context, listen: false)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Panel Demosu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onPanelClick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.building2, size: 14, color: _kTextHead),
                    SizedBox(width: 8),
                    Text('Yönetim Paneline Giriş', style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Stats row
        Container(
          padding: const EdgeInsets.only(top: 24),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorderLight))),
          child: Row(
            children: [
              _heroStat('2000+', 'Aktif Şube', false),
              const SizedBox(width: 32),
              _heroStat('100K+', 'Günlük Paket', false),
              const SizedBox(width: 32),
              _heroStat('%99.4', 'Başarılı ETA', true),
            ],
          ),
        ),
      ],
    );

    final right = Transform.scale(scale: 1.1, child: const InteractiveSimulatorCard());

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: left),
          const SizedBox(width: 48),
          Expanded(flex: 6, child: right),
        ],
      );
    }
    return Column(children: [left, const SizedBox(height: 40), right]);
  }

  Widget _heroStat(String val, String label, bool highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(color: highlight ? _kIndigo : _kTextHead, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ],
    );
  }

  Widget _dot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _orderCard({
    required String badge, required Color badgeBg, required Color badgeText,
    required String orderId, required String title, required String location,
    required String status, required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(badge, style: TextStyle(color: badgeText, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
              Text(orderId, style: const TextStyle(color: _kTextMuted, fontSize: 8, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(location, style: const TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w600)),
              Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────── QUICK INFO ───────────────
  Widget _buildQuickInfoSection(bool isMd) {
    return Column(
      children: [
        const Text('Hızlı ve Hatasız Operasyon', style: TextStyle(color: _kTextHead, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        const Text('Siparişlerinizi en gelişmiş teslimat altyapısıyla yöneterek kurye verimliliğinizi ikiye katlayın.',
          textAlign: TextAlign.center, style: TextStyle(color: _kTextBody, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 40),
        if (isMd)
          Row(children: [
            Expanded(child: _quickCard(LucideIcons.refreshCw, '%100 Otomatik Kurye Atama', 'Kuryelerin mesafesini, paket yükünü ve performans skorunu ölçen yapay zeka algoritması sayesinde paketi kuryeye 60 saniyede otomatik atar.')),
            const SizedBox(width: 24),
            Expanded(child: _quickCard(LucideIcons.mapPin, 'Canlı Harita ve Kurye Takibi', 'Kuryelerin anlık GPS koordinatlarını harita üzerinde izleyerek müşterilerinize canlı sipariş takip linki gönderebilirsiniz.')),
            const SizedBox(width: 24),
            Expanded(child: _quickCard(LucideIcons.building2, 'Tüm Entegrasyonlar Tek Havuzda', 'Tüm popüler yemek ve market sipariş kanallarını tek API altyapısı ile şubenize bağlar.')),
          ])
        else
          Column(children: [
            _quickCard(LucideIcons.refreshCw, '%100 Otomatik Kurye Atama', 'Kuryelerin mesafesini, paket yükünü ve performans skorunu ölçen yapay zeka algoritması sayesinde paketi kuryeye 60 saniyede otomatik atar.'),
            const SizedBox(height: 16),
            _quickCard(LucideIcons.mapPin, 'Canlı Harita ve Kurye Takibi', 'Kuryelerin anlık GPS koordinatlarını harita üzerinde izleyerek müşterilerinize canlı sipariş takip linki gönderebilirsiniz.'),
            const SizedBox(height: 16),
            _quickCard(LucideIcons.building2, 'Tüm Entegrasyonlar Tek Havuzda', 'Tüm popüler yemek ve market sipariş kanallarını tek API altyapısı ile şubenize bağlar.'),
          ]),
      ],
    );
  }

  Widget _quickCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _kIndigoPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kIndigoBorder)),
            child: Icon(icon, color: _kIndigo, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: _kTextBody, fontSize: 11, height: 1.65, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: _kBorderLight);

  // ─────────────── FEATURES (İnteraktif Tab Sistemi) ───────────────
  // Tab veri yapısı
  static const _tabData = [
    {
      'label': 'Restoran Modülü',
      'icon': LucideIcons.chefHat,
      'accent': _kOrange,
      'accentPale': Color(0xFFFFF7ED),
      'desc': 'Restoran operasyonunuzu uçtan uca dijitalleştirin.',
    },
    {
      'label': 'Kurye & Firma',
      'icon': LucideIcons.bike,
      'accent': _kPurple,
      'accentPale': Color(0xFFF5F3FF),
      'desc': 'Kurye filosunu ve firma süreçlerini tek ekrandan yönetin.',
    },
    {
      'label': 'Müşteri Deneyimi',
      'icon': LucideIcons.users,
      'accent': _kIndigo,
      'accentPale': _kIndigoPale,
      'desc': 'Müşteri memnuniyetini artıran akıllı teslimat araçları.',
    },
  ];

  static const _allFeatures = [
    // --- Restoran (index 0) ---
    [
      {'icon': LucideIcons.chefHat, 'title': 'Özel Kurye Talep Sistemi', 'desc': 'Saatlik, günlük ya da daimi özel kurye kiralama taleplerini kurye firmalarına kolayca iletin.'},
      {'icon': LucideIcons.clock, 'title': 'Çalışma Saati Yönetimi', 'desc': 'Kuryelerin haftalık vardiyalarını planlayın, günlük giriş/çıkış saatlerini canlı takip edin.'},
      {'icon': LucideIcons.calendar, 'title': 'İzin Yönetimi', 'desc': 'Panel veya mobil üzerinden yapılan izin ve tatil taleplerini onaylayın.'},
      {'icon': LucideIcons.dollarSign, 'title': 'Finans ve Cari Yönetimi', 'desc': 'Restoran cari hesapları, paket başı ücretler, kurye hak edişleri ve ödemeleri raporlayın.'},
      {'icon': LucideIcons.award, 'title': 'Ceza ve Ödül Yönetimi', 'desc': 'Geciken paketler ve reddedilen çağrılarda kurye ceza/ödül skorunu otomatik hesaplayın.'},
      {'icon': LucideIcons.building2, 'title': 'Çoklu Pazaryeri Entegrasyonu', 'desc': 'Tüm popüler yemek ve market sipariş kanallarını tek API ile şubenize bağlayın.'},
      {'icon': LucideIcons.mapPin, 'title': 'Canlı Kurye Harita Takibi', 'desc': 'Aktif kuryelerin konumlarını, hızlarını ve teslimat süreçlerini yönetici haritasından izleyin.'},
      {'icon': LucideIcons.barChart3, 'title': 'Detaylı Şube Raporlama', 'desc': 'Sipariş sayıları, teslimat süreleri, verimlilik oranları ve finansal durumu gösteren raporlar.'},
    ],
    // --- Kurye & Firma (index 1) ---
    [
      {'icon': LucideIcons.building2, 'title': 'Kurye Filosu Yönetimi', 'desc': 'Firma sahipleri tüm kuryelerin konumlarını, aktif durumlarını ve hakedişlerini tek ekrandan yönetir.'},
      {'icon': LucideIcons.mail, 'title': 'İş İlanı ve Başvuru Sistemi', 'desc': 'Kurye firmalarının açtığı iş ilanlarına kuryeler mobil uygulama üzerinden başvuru yapabilir.'},
      {'icon': LucideIcons.bike, 'title': 'Esnaf Kurye Ortamı', 'desc': 'Şahıs şirketi olan esnaf kuryeler için esnek çalışma saatleri ve performansa dayalı prim sistemi.'},
      {'icon': LucideIcons.clock, 'title': 'Vardiya Planlaması', 'desc': 'Kuryelerin haftalık çalışma saatlerini, vardiyalarını ve sistem aktiflik sürelerini mobil takip etmesi.'},
      {'icon': LucideIcons.calendar, 'title': 'İzin Talebi ve Yönetimi', 'desc': 'Kuryelerin izin taleplerini mobil uygulama üzerinden şube yöneticisine iletmesi ve takip etmesi.'},
      {'icon': LucideIcons.dollarSign, 'title': 'Finans ve Cüzdan Yönetimi', 'desc': 'Paket başı kazançlar, prim hak edişleri, bahşişler ve IBAN tanımlayarak ödeme talebi oluşturma.'},
      {'icon': LucideIcons.award, 'title': 'Performans Takip Ekranı', 'desc': 'SLA ihlalleri, gecikme cezaları ve prim ödülleri ile kuryenin anlık performans puanını şeffaf izleme.'},
      {'icon': LucideIcons.navigation, 'title': 'Rota Optimizasyonu', 'desc': 'Teslimat adresi için tek tıkla popüler harita uygulamaları ile en kısa rotayı çizme.'},
      {'icon': LucideIcons.shieldCheck, 'title': 'AI Yüz Doğrulaması', 'desc': 'Güvenlik amacıyla kurye profil resminin kasksız ve maskesiz olmasını doğrulayan yapay zeka modülü.'},
    ],
    // --- Müşteri (index 2) ---
    [
      {'icon': LucideIcons.phone, 'title': 'SMS ile Bilgilendirme', 'desc': 'Sipariş teslim alındığında müşteriye otomatik bilgilendirme SMS\'i ve canlı takip linki anında gönderilir.'},
      {'icon': LucideIcons.navigation, 'title': 'Anlık Kurye Konum Takibi', 'desc': 'Müşteriler özel link üzerinden haritada kuryenin konumunu ve tahmini varış süresini canlı izler.'},
      {'icon': LucideIcons.messageSquare, 'title': 'Akıllı Sohbet Sistemi', 'desc': 'Sipariş teslim sürecindeyken kurye ile müşteri arasında uygulama içi gizli ve güvenli yazışma ortamı.'},
      {'icon': LucideIcons.shieldCheck, 'title': 'Temassız Teslimat Modülü', 'desc': 'Kapıya bırakma veya temassız teslimat gibi müşteri tercihlerini kuryeye net şekilde ileten notlar sistemi.'},
      {'icon': LucideIcons.award, 'title': 'Teslimat Sonrası Değerlendirme', 'desc': 'Müşterilerin teslimat sonrasında kuryenin hizmet kalitesini puanlayabileceği geri bildirim sistemi.'},
    ],
  ];

  Widget _buildFeaturesSection(bool isDesktop) {
    final tab = _tabData[_selectedFeatureTab];
    final accent = tab['accent'] as Color;
    final accentPale = tab['accentPale'] as Color;
    final features = _allFeatures[_selectedFeatureTab] as List;

    return Column(
      children: [
        _sectionBadge('Gelişmiş Modüller'),
        const SizedBox(height: 12),
        const Text(
          'Akıllı Özellikler ve Modüller',
          style: TextStyle(color: _kTextHead, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        const Text(
          'Teslimat operasyonunuzun her aşamasını otomatikleştiren, verimliliği artıran ve maliyetleri düşüren zengin özellikler.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextBody, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 48),

        // ── Akıllı Mesafe Banner ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kIndigo.withValues(alpha: 0.08), _kPurple.withValues(alpha: 0.04), _kBg],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kIndigo.withValues(alpha: 0.2)),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kIndigo,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.3), blurRadius: 10)],
                      ),
                      child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Akıllı Mesafe & Otomatik Atama Altyapısı',
                              style: TextStyle(color: _kTextHead, fontSize: 15, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('YAPAY ZEKA DESTEKLİ — En yakın kurye 60 saniyede otomatik atanır.',
                              style: TextStyle(color: _kTextBody, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    _inlineStat('60 sn', 'Ortalama Atama'),
                    const SizedBox(width: 24),
                    _inlineStat('%99.4', 'Başarılı ETA'),
                    const SizedBox(width: 24),
                    _inlineStat('2000+', 'Aktif Şube'),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _kIndigo, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Akıllı Mesafe & Otomatik Atama',
                              style: TextStyle(color: _kTextHead, fontSize: 14, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('YAPAY ZEKA DESTEKLİ — En yakın kurye 60 saniyede otomatik atanır.',
                        style: TextStyle(color: _kTextBody, fontSize: 11)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _inlineStat('60 sn', 'Atama'),
                        _inlineStat('%99.4', 'Başarılı ETA'),
                        _inlineStat('2000+', 'Şube'),
                      ],
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 40),

        // ── Tab Seçici ──
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorderLight),
          ),
          child: Row(
            children: List.generate(_tabData.length, (i) {
              final t = _tabData[i];
              final isActive = _selectedFeatureTab == i;
              final tAccent = t['accent'] as Color;
              final tAccentPale = t['accentPale'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFeatureTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _kWhite : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isActive
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isActive ? tAccentPale : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(t['icon'] as IconData,
                              size: 14,
                              color: isActive ? tAccent : _kTextMuted),
                        ),
                        if (MediaQuery.of(context).size.width > 380) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t['label'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? _kTextHead : _kTextMuted,
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),

        // Active tab description
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Padding(
            key: ValueKey(_selectedFeatureTab),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              tab['desc'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextBody, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Feature Grid (Animated) ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: _buildFeatureGrid(
            key: ValueKey(_selectedFeatureTab),
            features: features,
            accent: accent,
            accentPale: accentPale,
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid({
    required Key key,
    required List features,
    required Color accent,
    required Color accentPale,
    required bool isDesktop,
  }) {
    final cards = features.map<Widget>((item) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorderLight),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData, color: accent, size: 17),
            ),
            const SizedBox(height: 12),
            Text(item['title'] as String,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 6),
            Text(item['desc'] as String,
                style: const TextStyle(color: _kTextBody, fontSize: 11, height: 1.65, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        // Responsive columns based on parentWidth
        final int crossAxisCount;
        if (parentWidth > 950) {
          crossAxisCount = 3;
        } else if (parentWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final double spacing = 16.0;
        final double cardWidth = (parentWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(
            width: cardWidth,
            child: c,
          )).toList(),
        );
      },
    );
  }

  Widget _inlineStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(val, style: const TextStyle(color: _kIndigo, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  // ─────────────── PRICING ───────────────
  Widget _buildPricingSection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            _sectionBadge('Bütçenize Uygun'),
            const SizedBox(height: 12),
            const Text('Şeffaf Tek Fiyatlandırma', style: TextStyle(color: _kTextHead, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            const Text('Kurulum ücreti yok, gizli maliyet yok, aylık sabit ücret yok. Sadece kullandığınız kadar ödeyin.',
              textAlign: TextAlign.center, style: TextStyle(color: _kTextBody, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 48),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kIndigo, width: 2),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.1), blurRadius: 32, offset: const Offset(0, 12))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('TÜM ÖZELLİKLER DAHİL', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hepsi Bir Arada Plan', style: TextStyle(color: _kIndigo, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text('2.5 TL', style: TextStyle(color: _kTextHead, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        SizedBox(width: 6),
                        Text('/ paket başı', style: TextStyle(color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Herhangi bir sabit aylık abonelik ücreti veya taahhüt bulunmamaktadır. Tüm gelişmiş modülleri ek bir ücret ödemeden sınırsız kullanın.',
                      style: TextStyle(color: _kTextBody, fontSize: 12, height: 1.6, fontWeight: FontWeight.w500)),
                    const Divider(height: 32, color: _kBorderLight),
                    const Text('DAHİL OLAN ÖZELLİKLER', style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    ...[
                      '%100 Otomatik Kurye Atama Algoritması',
                      'Canlı Harita & Anlık Teslimat Takibi',
                      'Pazaryeri & Sipariş API Entegrasyonları',
                      'Kurye Mobil Uygulaması (iOS & Android)',
                      'Otomatik Hakediş & Finans Raporlaması',
                      'Detaylı SLA & Kurye Performans Analizleri',
                      'Sınırsız Kurye, Şube ve Kullanıcı Ekleme',
                      'Kurulum / Başlangıç Ücreti Yok',
                    ].map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.circleCheckBig, color: _kGreen, size: 14),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f, style: const TextStyle(color: _kTextBody, fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: widget.onPanelClick,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Text('Hemen Ücretsiz Başla', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── FAQ ───────────────
  Widget _buildFaqSection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            _sectionBadge('Sıkça Sorulan Sorular'),
            const SizedBox(height: 12),
            const Text('Sıkça Sorulan Sorular',
              style: TextStyle(color: _kTextHead, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            const SizedBox(height: 40),
            ..._faqData.asMap().entries.map((e) {
              final idx = e.key;
              final faq = e.value;
              final isOpen = _openFaq == idx;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorderLight),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _openFaq = isOpen ? null : idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(faq['q']!, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w700))),
                            const SizedBox(width: 12),
                            Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              size: 16, color: isOpen ? _kIndigo : _kTextMuted),
                          ],
                        ),
                      ),
                    ),
                    if (isOpen) ...[
                      const Divider(height: 1, color: _kBorderLight),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Text(faq['a']!, style: const TextStyle(color: _kTextBody, fontSize: 12, height: 1.65, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────── CONTACT ───────────────
  Widget _buildContactSection(AppProvider provider, bool isDesktop) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionBadge('Bize Ulaşın'),
        const SizedBox(height: 16),
        const Text('İletişim',
          style: TextStyle(color: _kTextHead, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        const SizedBox(height: 12),
        const Text('Sistem hakkında detaylı bilgi almak, özel entegrasyon taleplerinizi görüşmek veya demo kurulum desteği istemek için form üzerinden bize ulaşın.',
          style: TextStyle(color: _kTextBody, fontSize: 12, height: 1.65, fontWeight: FontWeight.w500)),
      ],
    );

    final form = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (isDesktop) ...[
              Row(children: [
                Expanded(child: _formField('Adınız Soyadınız', _nameController, false)),
                const SizedBox(width: 16),
                Expanded(child: _formField('E-Posta Adresiniz', _emailController, false, type: TextInputType.emailAddress)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _formField('Telefon Numarası', _phoneController, false, type: TextInputType.phone)),
                const SizedBox(width: 16),
                Expanded(child: _formField('Restoran / Firma Adı', _companyController, false)),
              ]),
            ] else ...[
              _formField('Adınız Soyadınız', _nameController, false),
              const SizedBox(height: 14),
              _formField('E-Posta Adresiniz', _emailController, false, type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _formField('Telefon Numarası', _phoneController, false, type: TextInputType.phone),
              const SizedBox(height: 14),
              _formField('Restoran / Firma Adı', _companyController, false),
            ],
            const SizedBox(height: 14),
            _formField('Mesajınız', _messageController, true),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isSubmitted ? null : () => _handleSubmit(provider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSubmitted ? _kTextMuted : _kIndigo,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.15), blurRadius: 8)],
                ),
                child: Text(_isSubmitted ? 'Gönderiliyor...' : 'Talep Gönder',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: details),
          const SizedBox(width: 48),
          Expanded(flex: 7, child: form),
        ],
      );
    }
    return Column(children: [details, const SizedBox(height: 32), form]);
  }



  Widget _formField(String label, TextEditingController ctrl, bool multiline, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: multiline ? 4 : 1,
          validator: (v) => (v == null || v.isEmpty) ? 'Bu alan zorunludur' : null,
          style: const TextStyle(color: _kTextHead, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kIndigo, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  // ─────────────── JOB POSTINGS ───────────────
  Widget _buildJobPostingsSection(AppProvider provider) {
    final filteredPostings = provider.jobPostings.where((ilan) {
      if (_searchCity != null && ilan.city != _searchCity) return false;
      if (_searchDistrict != null && ilan.district != _searchDistrict) return false;
      return true;
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            _sectionBadge('İş Fırsatları'),
            const SizedBox(height: 12),
            const Text('Aktif Kurye İş İlanları', style: TextStyle(color: _kTextHead, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            const Text('Kurye arayan restoranlar, firmalar ve lojistik ağlarının ilanlarını inceleyin, hemen kazanmaya başlayın.',
              textAlign: TextAlign.center, style: TextStyle(color: _kTextBody, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),

            // ── Ergonomic Search Filter Panel ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorderLight),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                children: [
                  // City Dropdown
                  Expanded(
                    flex: isDesktop ? 3 : 0,
                    child: DropdownButtonFormField<String>(
                      value: _searchCity,
                      dropdownColor: _kWhite,
                      decoration: InputDecoration(
                        labelText: 'Şehir (İl) Seçin',
                        labelStyle: const TextStyle(color: _kTextMuted, fontSize: 11),
                        prefixIcon: const Icon(LucideIcons.mapPin, color: _kIndigo, size: 14),
                        filled: true,
                        fillColor: _kBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: kTurkeyCities.keys.map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _searchCity = val;
                          _searchDistrict = null;
                        });
                      },
                      style: const TextStyle(color: _kTextHead, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),

                  // District Dropdown
                  Expanded(
                    flex: isDesktop ? 3 : 0,
                    child: DropdownButtonFormField<String>(
                      value: _searchDistrict,
                      dropdownColor: _kWhite,
                      decoration: InputDecoration(
                        labelText: 'İlçe Seçin',
                        labelStyle: const TextStyle(color: _kTextMuted, fontSize: 11),
                        prefixIcon: const Icon(LucideIcons.compass, color: _kIndigo, size: 14),
                        filled: true,
                        fillColor: _kBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: (_searchCity == null ? <String>[] : kTurkeyCities[_searchCity]!).map((dist) => DropdownMenuItem(
                        value: dist,
                        child: Text(dist),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _searchDistrict = val;
                        });
                      },
                      style: const TextStyle(color: _kTextHead, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),

                  // Clear Filters button
                  if (_searchCity != null || _searchDistrict != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchCity = null;
                          _searchDistrict = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.x, color: Colors.red.shade600, size: 14),
                            const SizedBox(width: 6),
                            Text('Filtreleri Temizle', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ── Grid of Listings ──
            if (filteredPostings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorderLight),
                ),
                child: const Column(
                  children: [
                    Icon(LucideIcons.info, size: 36, color: _kTextMuted),
                    SizedBox(height: 12),
                    Text('Aradığınız kriterlere uygun iş ilanı bulunamadı.', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Filtreleri değiştirerek farklı bölgeleri inceleyebilirsiniz.', style: TextStyle(color: _kTextMuted, fontSize: 11)),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final double parentWidth = constraints.maxWidth;
                  final int cols = parentWidth > 800 ? 2 : 1;
                  final double spacing = 16.0;
                  final double width = (parentWidth - (spacing * (cols - 1))) / cols;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: filteredPostings.map((ilan) => SizedBox(
                      width: width,
                      child: _buildJobCard(ilan),
                    )).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobPosting ilan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kIndigoPale, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.briefcase, color: _kIndigo, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(ilan.salary, style: const TextStyle(color: _kGreen, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ilan.title, style: const TextStyle(color: _kTextHead, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(ilan.companyName, style: const TextStyle(color: _kIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: _kTextMuted)),
              const SizedBox(width: 6),
              const Icon(LucideIcons.mapPin, color: _kTextMuted, size: 10),
              const SizedBox(width: 4),
              Text('${ilan.city} / ${ilan.district ?? ""}', style: const TextStyle(color: _kTextMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(ilan.description, style: const TextStyle(color: _kTextBody, fontSize: 12, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showApplyDialog(ilan),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Text('Kurye Olarak Başvur', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(JobPosting ilan) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;

    if (user != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(LucideIcons.circleCheckBig, color: _kGreen, size: 20),
              SizedBox(width: 8),
              Text('Başvuru Yapıldı', style: TextStyle(color: _kTextHead, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ilan.title, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Yayınlayan: ${ilan.companyName}', style: const TextStyle(color: _kIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Bu ilana başarıyla başvurdunuz! 🎉 İş veren firma en kısa sürede profilinizi inceleyerek sizinle iletişime geçecektir.',
                style: TextStyle(color: _kTextBody, fontSize: 12, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: _kTextMuted)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(LucideIcons.sparkles, color: _kIndigo, size: 20),
            SizedBox(width: 8),
            Text('İlana Başvur', style: TextStyle(color: _kTextHead, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ilan.title, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Yayınlayan: ${ilan.companyName}', style: const TextStyle(color: _kIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Bu ilana başvurmak ve sistemdeki diğer ilanları incelemek için kurye hesabınızın olması gerekmektedir. Hemen üye olup başvurabilirsiniz!',
              style: TextStyle(color: _kTextBody, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: _kTextMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mobil uygulama indirme linki gönderildi! 📱'), backgroundColor: _kIndigo),
              );
            },
            child: const Text('Uygulamayı İndir', style: TextStyle(color: _kIndigo, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onRegisterClick != null) {
                widget.onRegisterClick!('kurye');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kurye Olarak Üye Ol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─────────────── FOOTER ───────────────
  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(top: BorderSide(color: _kBorderLight)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _footerLink('Ana Sayfa', () => _scrollToSection(_homeKey)),
              _footerLink('Özellikler', () => _scrollToSection(_featuresKey)),
              _footerLink('Fiyatlar', () => _scrollToSection(_pricingKey)),
              _footerLink('İş İlanları', () => _scrollToSection(_postingsKey)),
              _footerLink('S.S.S.', () => _scrollToSection(_faqKey)),
              _footerLink('İletişim', () => _scrollToSection(_contactKey)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('© 2026 Kurye App. Tüm hakları saklıdır. Akıllı Kurye Takip ve Teslimat Yönetim Platformu.',
            textAlign: TextAlign.center, style: TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: const TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _sectionBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: _kIndigoPale,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kIndigoBorder),
      ),
      child: Text(label, style: const TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}



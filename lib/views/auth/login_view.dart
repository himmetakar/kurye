import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';

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
const _kGreen = Color(0xFF10B981);       // emerald-500

class LoginView extends StatefulWidget {
  final VoidCallback onBack;

  const LoginView({super.key, required this.onBack});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Registration controllers
  final _cNameController = TextEditingController();
  final _cSurnameController = TextEditingController();
  final _cLivingCityController = TextEditingController();
  final _cWorkingCityController = TextEditingController();
  final _cLicenseController = TextEditingController();
  final _cTaxController = TextEditingController();

  final _rNameController = TextEditingController();
  final _rManagerController = TextEditingController();
  final _rAddressController = TextEditingController();

  final _compNameController = TextEditingController();
  final _compAddressController = TextEditingController();

  String _activeTab = 'quick'; // 'quick' or 'phone'
  bool _otpSent = false;
  String _sentOtpCode = '';
  bool _loading = false;
  String _errorMessage = '';

  // Registration states
  bool _isRegistering = false;
  String? _regRole; // 'kurye', 'restoran', 'firma'
  bool _rulesAccepted = false;
  String _cMotorcycle = 'yes';
  String _cCourierType = 'esnaf';
  String _cExperience = '1-3';
  String _cPhotoUrl = '';
  String _cPhotoSuccess = '';
  String _cPhotoError = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _cNameController.dispose();
    _cSurnameController.dispose();
    _cLivingCityController.dispose();
    _cWorkingCityController.dispose();
    _cLicenseController.dispose();
    _cTaxController.dispose();
    _rNameController.dispose();
    _rManagerController.dispose();
    _rAddressController.dispose();
    _compNameController.dispose();
    _compAddressController.dispose();
    super.dispose();
  }

  void _sendSimulatedOtp() {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _otpSent = true;
          _sentOtpCode = '1234';
          _otpController.text = '1234'; // Autofill simulation
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama kodu 1234 gönderildi (Demo).'), backgroundColor: _kIndigo),
        );
      }
    });
  }

  Future<void> _verifyOtp(AppProvider provider) async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (_otpController.text == '1234') {
      final res = await provider.loginByPhone(_phoneController.text);
      if (mounted) {
        setState(() => _loading = false);
        if (res['success'] == true) {
          // Success
        } else {
          if (res['message'] == 'Bu telefon numarası kayıtlı değil.') {
            setState(() {
              _isRegistering = true;
              _regRole = null;
            });
          } else {
            setState(() => _errorMessage = res['message'] ?? 'Giriş hatası');
          }
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Geçersiz doğrulama kodu (Demo için 1234 girin).';
        });
      }
    }
  }

  void _handleQuickLogin(AppProvider provider, String email, String role) async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    final success = await provider.login(email, role);
    setState(() => _loading = false);
    if (!success) {
      setState(() => _errorMessage = 'Demo girişi yapılamadı.');
    }
  }

  Future<void> _handleRegistration(AppProvider provider) async {
    if (!_regFormKey.currentState!.validate()) return;
    if (_regRole == 'kurye' && !_rulesAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kurye çalışma kurallarını kabul edin.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    Map<String, dynamic> result;
    if (_regRole == 'kurye') {
      result = await provider.registerCourier(
        phone: _phoneController.text,
        name: _cNameController.text,
        surname: _cSurnameController.text,
        livingCity: _cLivingCityController.text,
        workingCity: _cWorkingCityController.text,
        extraFields: {
          'hasMotorcycle': _cMotorcycle,
          'courierType': _cCourierType,
          'experienceYears': _cExperience,
          'ehliyet': _cLicenseController.text,
          'vergiLevhasi': _cCourierType == 'esnaf' ? _cTaxController.text : null,
          'profilePhoto': _cPhotoUrl.isNotEmpty ? _cPhotoUrl : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256',
        },
      );
    } else if (_regRole == 'restoran') {
      result = await provider.registerRestaurant(
        phone: _phoneController.text,
        name: _rNameController.text,
        managerName: _rManagerController.text,
        address: _rAddressController.text,
      );
    } else {
      result = await provider.registerCompany(
        phone: _phoneController.text,
        name: _compNameController.text,
        address: _compAddressController.text,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
        setState(() {
          _isRegistering = false;
          _regRole = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Kayıt başarısız.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kIndigoPale.withValues(alpha: 0.5),
              _kBg,
              const Color(0xFFF5F3FF).withValues(alpha: 0.5), // Purple pale
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Safe bar + Custom Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: _kTextHead),
                      onPressed: _isRegistering
                          ? () {
                              setState(() {
                                if (_regRole != null) {
                                  _regRole = null;
                                } else {
                                  _isRegistering = false;
                                  _otpSent = false;
                                }
                              });
                            }
                          : widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRegistering
                          ? (_regRole == null ? 'Üyelik Tipi Seçimi' : 'Yeni Kayıt Formu')
                          : 'Hesabınıza Giriş Yapın',
                      style: const TextStyle(color: _kTextHead, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            // Form body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: _isRegistering && _regRole == 'kurye' ? 700 : 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _kBorderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: _isRegistering ? _buildRegistrationFlow(provider) : _buildLoginFlow(provider),
                  ),
                ),
              ),
            ),
            // Footer Info
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'KuryeApp SaaS Platform v2.0',
                style: TextStyle(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginFlow(AppProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'KURYELOJİSTİK SaaS',
            style: TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Hesabınıza Giriş Yapın',
            style: TextStyle(color: _kTextHead, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 24),

        // Tab switches
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton('quick', 'Hızlı Giriş', LucideIcons.users),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTabButton('phone', 'SMS Giriş', LucideIcons.phone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_activeTab == 'quick')
          _buildQuickLoginTab(provider)
        else
          _buildPhoneLoginTab(provider),

        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ]
      ],
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
          _errorMessage = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _kWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? _kIndigo : _kTextMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _kTextHead : _kTextMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLoginTab(AppProvider provider) {
    return Column(
      children: [
        _buildQuickRoleButton(
          title: 'Restoran Paneli',
          subtitle: 'Sipariş oluştur, kurye çağır, SLA takip et',
          gradientStart: const Color(0xFFFFF7ED),
          gradientEnd: const Color(0xFFFFEDD5),
          borderColor: const Color(0xFFFED7AA),
          accentColor: _kOrange,
          icon: LucideIcons.chefHat,
          onTap: () => _handleQuickLogin(provider, 'restoran@kurye.com', 'restoran'),
        ),
        const SizedBox(height: 12),
        _buildQuickRoleButton(
          title: 'Kurye Firması',
          subtitle: 'Filo, hakedişler, bölgeler, ilan yönetimi',
          gradientStart: const Color(0xFFF5F3FF),
          gradientEnd: const Color(0xFFEDE9FE),
          borderColor: const Color(0xFFDDD6FE),
          accentColor: _kPurple,
          icon: LucideIcons.building2,
          onTap: () => _handleQuickLogin(provider, 'iletisim@hizlikurye.com', 'firma'),
        ),
        const SizedBox(height: 12),
        _buildQuickRoleButton(
          title: 'Süper Yönetici (SaaS)',
          subtitle: 'Tüm firmaları ve restoran biletlerini yönet',
          gradientStart: const Color(0xFFEFF6FF),
          gradientEnd: const Color(0xFFDBEAFE),
          borderColor: const Color(0xFFBFDBFE),
          accentColor: Colors.blue.shade600,
          icon: LucideIcons.shieldCheck,
          onTap: () => _handleQuickLogin(provider, 'admin@kurye.com', 'superadmin'),
        ),
        const SizedBox(height: 16),
        const Divider(color: _kBorderLight, height: 1),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(LucideIcons.bike, size: 14, color: _kIndigo),
            SizedBox(width: 8),
            Text(
              'DEMO KURYELERİMİZ',
              style: TextStyle(color: _kTextHead, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickRoleButton(
          title: 'Kurye: Ahmet',
          subtitle: 'Puan: 4.9 | ahmet@kurye.com',
          gradientStart: const Color(0xFFEEF2FF),
          gradientEnd: const Color(0xFFE0E7FF),
          borderColor: const Color(0xFFC7D2FE),
          accentColor: _kIndigo,
          icon: LucideIcons.bike,
          onTap: () => _handleQuickLogin(provider, 'ahmet@kurye.com', 'kurye'),
        ),
        const SizedBox(height: 8),
        _buildQuickRoleButton(
          title: 'Kurye: Mehmet',
          subtitle: 'Puan: 4.7 | mehmet@kurye.com',
          gradientStart: const Color(0xFFEEF2FF),
          gradientEnd: const Color(0xFFE0E7FF),
          borderColor: const Color(0xFFC7D2FE),
          accentColor: _kIndigo,
          icon: LucideIcons.bike,
          onTap: () => _handleQuickLogin(provider, 'mehmet@kurye.com', 'kurye'),
        ),
        const SizedBox(height: 8),
        _buildQuickRoleButton(
          title: 'Kurye: Can',
          subtitle: 'Puan: 4.4 | can@kurye.com',
          gradientStart: const Color(0xFFEEF2FF),
          gradientEnd: const Color(0xFFE0E7FF),
          borderColor: const Color(0xFFC7D2FE),
          accentColor: _kIndigo,
          icon: LucideIcons.bike,
          onTap: () => _handleQuickLogin(provider, 'can@kurye.com', 'kurye'),
        ),
        const SizedBox(height: 8),
        _buildQuickRoleButton(
          title: 'Kurye: Burak',
          subtitle: 'Puan: 4.8 | burak@kurye.com',
          gradientStart: const Color(0xFFEEF2FF),
          gradientEnd: const Color(0xFFE0E7FF),
          borderColor: const Color(0xFFC7D2FE),
          accentColor: _kIndigo,
          icon: LucideIcons.bike,
          onTap: () => _handleQuickLogin(provider, 'burak@kurye.com', 'kurye'),
        ),
        const SizedBox(height: 8),
        _buildQuickRoleButton(
          title: 'Kurye: Mustafa',
          subtitle: 'Puan: 4.1 | mustafa@kurye.com',
          gradientStart: const Color(0xFFEEF2FF),
          gradientEnd: const Color(0xFFE0E7FF),
          borderColor: const Color(0xFFC7D2FE),
          accentColor: _kIndigo,
          icon: LucideIcons.bike,
          onTap: () => _handleQuickLogin(provider, 'mustafa@kurye.com', 'kurye'),
        ),
      ],
    );
  }

  Widget _buildQuickRoleButton({
    required String title,
    required String subtitle,
    required Color gradientStart,
    required Color gradientEnd,
    required Color borderColor,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _kTextHead, fontWeight: FontWeight.w900, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _kTextBody, fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: _kTextMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLoginTab(AppProvider provider) {
    if (!_otpSent) {
      return Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Telefon numaranızı girin. Sisteme kayıtlı iseniz tek tıkla giriş yapabilir, değilseniz yeni üyelik formu açılacaktır.',
              style: TextStyle(color: _kTextBody, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
              decoration: _inputDecoration('Telefon Numarası (05xx)', LucideIcons.phone),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Telefon girin';
                if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Geçersiz telefon';
                return null;
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading ? null : _sendSimulatedOtp,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _loading
                    ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Text('SMS Kodu Gönder', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Demo Giriş Telefonları:', style: TextStyle(color: _kTextHead, fontSize: 9, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Ahmet: 0530 111 11 11 | Mehmet: 0530 222 22 22\n• Can: 0530 333 33 33 | Restoran: 0542 333 33 33', style: TextStyle(color: _kIndigo, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return Form(
        key: _otpFormKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(LucideIcons.checkCircle, color: _kGreen, size: 14),
                  SizedBox(width: 6),
                  Text('SMS Kodu Gönderildi!', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(color: _kTextHead, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: _inputDecoration('Doğrulama Kodu (Demo: 1234)', LucideIcons.lock),
              validator: (v) => v == null || v.isEmpty ? 'Kodu girin' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading ? null : () => _verifyOtp(provider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _loading
                    ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Text('Kodu Doğrula ve Giriş Yap', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRegistrationFlow(AppProvider provider) {
    if (_regRole == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni Üyelik / Başvuru',
            style: TextStyle(color: _kTextHead, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Numaranız (${_phoneController.text}) sisteme kayıtlı değil. Hangi rolde kayıt olmak istediğinizi seçin:',
            style: const TextStyle(color: _kTextBody, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildRoleSelectButton('kurye', 'Kurye Başvurusu', LucideIcons.bike, _kGreen),
          const SizedBox(height: 12),
          _buildRoleSelectButton('restoran', 'Restoran / Şube Kaydı', LucideIcons.chefHat, _kOrange),
          const SizedBox(height: 12),
          _buildRoleSelectButton('firma', 'Kurye Firması Kaydı', LucideIcons.building2, _kPurple),
        ],
      );
    }

    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _regRole == 'kurye'
                ? 'Kurye İş Başvuru Formu'
                : _regRole == 'restoran'
                    ? 'Restoran / Şube Kaydı'
                    : 'Kurye Firması Kaydı',
            style: const TextStyle(color: _kTextHead, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),

          if (_regRole == 'kurye') _buildCourierFields(),
          if (_regRole == 'restoran') _buildRestaurantFields(),
          if (_regRole == 'firma') _buildCompanyFields(),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _loading ? null : () => _handleRegistration(provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kIndigo, _kPurple]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: _loading
                        ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Text('Kayıt Ol ve Giriş Yap', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _regRole = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Text('Geri', style: TextStyle(color: _kTextBody, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoleSelectButton(String role, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _regRole = role;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorderLight),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorderLight)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: _kTextHead, fontWeight: FontWeight.w900, fontSize: 12)),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: _kTextMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cNameController,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Adınız', LucideIcons.user),
                validator: (v) => v == null || v.isEmpty ? 'Ad girin' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cSurnameController,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Soyadınız', LucideIcons.user),
                validator: (v) => v == null || v.isEmpty ? 'Soyad girin' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cLivingCityController,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Yaşadığınız Şehir', LucideIcons.mapPin),
                validator: (v) => v == null || v.isEmpty ? 'Şehir girin' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cWorkingCityController,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Çalışılacak Şehir', LucideIcons.mapPin),
                validator: (v) => v == null || v.isEmpty ? 'Şehir girin' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _cMotorcycle,
                dropdownColor: _kWhite,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Motosiklet Durumu', LucideIcons.bike),
                items: const [
                  DropdownMenuItem(value: 'yes', child: Text('Kendi Motorum Var')),
                  DropdownMenuItem(value: 'no', child: Text('Kendi Motorum Yok')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _cMotorcycle = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _cCourierType,
                dropdownColor: _kWhite,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Çalışma Modeli', LucideIcons.briefcase),
                items: const [
                  DropdownMenuItem(value: 'esnaf', child: Text('Esnaf Kurye (Şahıs Şirketi)')),
                  DropdownMenuItem(value: 'isci', child: Text('İşçi Kurye (SGK)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _cCourierType = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _cExperience,
                dropdownColor: _kWhite,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Sürüş Deneyimi', LucideIcons.award),
                items: const [
                  DropdownMenuItem(value: '1-3', child: Text('1-3 Yıl Deneyimli')),
                  DropdownMenuItem(value: '3-5', child: Text('3-5 Yıl Deneyimli')),
                  DropdownMenuItem(value: '5+', child: Text('5+ Yıl Deneyimli')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _cExperience = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cLicenseController,
                style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Ehliyet No/Barkod', LucideIcons.shieldAlert),
                validator: (v) => v == null || v.isEmpty ? 'Ehliyet girin' : null,
              ),
            ),
          ],
        ),
        if (_cCourierType == 'esnaf') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _cTaxController,
            style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
            decoration: _inputDecoration('Vergi Levhası Barkodu', LucideIcons.fileText),
            validator: (v) => _cCourierType == 'esnaf' && (v == null || v.isEmpty) ? 'Vergi levhası girin' : null,
          ),
        ],
        const SizedBox(height: 16),

        // Face recognition simulator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yüz Tanımalı Profil Fotoğrafı Yükle *', style: TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.w800)),
                  if (_cPhotoUrl.isNotEmpty) const Text('Yüklendi ✅', style: TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('⚠️ Güvenlik için kasksız, gözlüksüz ve maskesiz olmalıdır.', style: TextStyle(color: _kTextBody, fontSize: 9, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _cPhotoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256';
                          _cPhotoSuccess = 'Yapay Zeka Analizi: Net yüz tespit edildi! Kabul edildi. ✅';
                          _cPhotoError = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cPhotoUrl.isNotEmpty && _cPhotoError.isEmpty ? _kTextBody : _kIndigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('📷 Fotoğraf Yükle (Kasksız)', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _cPhotoUrl = '';
                          _cPhotoError = 'Analiz Hatası: Kask/maske algılandı! Tekrar deneyin. ❌';
                          _cPhotoSuccess = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cPhotoError.isNotEmpty ? Colors.redAccent.withValues(alpha: 0.15) : _kBg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _cPhotoError.isNotEmpty ? Colors.redAccent : _kBorder)),
                      ),
                      child: Text('🪖 Kasklı Fotoğraf', style: TextStyle(fontSize: 10, color: _cPhotoError.isNotEmpty ? Colors.redAccent : _kTextBody, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              if (_cPhotoSuccess.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_cPhotoSuccess, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
              if (_cPhotoError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_cPhotoError, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rules Agreement Contract
        const Text('Kurye Çalışma ve Performans Kuralları', style: TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorderLight),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Atanan siparişe 60 saniye içinde onay verilmezse iptal edilir.\n'
                  '2. Sipariş kabul oranı %85 altına düşen kuryeler 30 dk pasife alınır.\n'
                  '3. Rota ETA süresini 15 dakikadan fazla aşan kuryelere prim kesintisi uygulanır.\n'
                  '4. Günlük 1 adet üzeri iptallerde kurye puanı düşürülür.\n'
                  '5. Günde 3 kez paket reddi alan kuryeler shadow ban alırlar.',
                  style: TextStyle(color: _kTextBody, fontSize: 10, height: 1.4, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rulesAccepted,
                activeColor: _kIndigo,
                onChanged: (val) {
                  if (val != null) setState(() => _rulesAccepted = val);
                },
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '5 maddelik kurye çalışma ve ceza kurallarını okudum, kabul ediyorum.',
                style: TextStyle(color: _kTextBody, fontSize: 10, height: 1.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRestaurantFields() {
    return Column(
      children: [
        TextFormField(
          controller: _rNameController,
          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Restoran Adı', LucideIcons.store),
          validator: (v) => v == null || v.isEmpty ? 'Restoran adı girin' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rManagerController,
          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Yetkili Adı Soyadı', LucideIcons.user),
          validator: (v) => v == null || v.isEmpty ? 'Yetkili girin' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rAddressController,
          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Restoran Adresi', LucideIcons.map),
          validator: (v) => v == null || v.isEmpty ? 'Adres girin' : null,
        ),
      ],
    );
  }

  Widget _buildCompanyFields() {
    return Column(
      children: [
        TextFormField(
          controller: _compNameController,
          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Firma Adı', LucideIcons.building2),
          validator: (v) => v == null || v.isEmpty ? 'Firma adı girin' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _compAddressController,
          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Firma Adresi', LucideIcons.map),
          validator: (v) => v == null || v.isEmpty ? 'Firma adresi girin' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: _kIndigo, size: 16),
      filled: true,
      fillColor: _kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kIndigo, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    );
  }
}

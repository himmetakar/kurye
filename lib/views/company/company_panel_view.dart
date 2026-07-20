import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/courier.dart';
import '../../models/shift.dart';

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

class CompanyPanelView extends StatefulWidget {
  final String companyId;

  const CompanyPanelView({super.key, required this.companyId});

  @override
  State<CompanyPanelView> createState() => _CompanyPanelViewState();
}

class _CompanyPanelViewState extends State<CompanyPanelView> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _jobDescController = TextEditingController();
  final _jobSalaryController = TextEditingController();

  String? _selectedCity;
  String? _selectedDistrict;

  String _activeTab = 'fleet'; // 'fleet' | 'shifts' | 'postings' | 'finance'

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescController.dispose();
    _jobSalaryController.dispose();
    super.dispose();
  }

  void _publishJob(AppProvider provider) {
    if (_formKey.currentState!.validate()) {
      if (_selectedCity == null || _selectedDistrict == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen il ve ilçe seçin.'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      final company = provider.companies.firstWhere((c) => c.id == widget.companyId, orElse: () => provider.companies.first);

      provider.addJobPosting(
        companyId: widget.companyId,
        companyName: company.name,
        title: _jobTitleController.text,
        description: _jobDescController.text,
        city: _selectedCity!,
        district: _selectedDistrict!,
        salary: _jobSalaryController.text,
      );

      _jobTitleController.clear();
      _jobDescController.clear();
      _jobSalaryController.clear();
      setState(() {
        _selectedCity = null;
        _selectedDistrict = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İş ilanı başarıyla yayınlandı! 📢'), backgroundColor: _kIndigo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final companyCouriers = provider.couriers.where((c) => c.courierCompanyId == widget.companyId).toList();
    final pendingShifts = provider.shifts.where((s) => s.companyId == widget.companyId && s.status == 'submitted').toList();

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Header card
            _buildCompanyHeader(provider),
            const SizedBox(height: 20),

            // Top Pill Nav Bar
            _buildPillNavBar(),
            const SizedBox(height: 24),

            // Active tab content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildActiveTabContent(provider, companyCouriers, pendingShifts),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(AppProvider provider) {
    final company = provider.companies.firstWhere((c) => c.id == widget.companyId, orElse: () => provider.companies.first);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], // indigo-600 to violet-600
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${company.name} Panel', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Kurye havuzu, bölge sınırları ve restoran işbirlikleri.', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(LucideIcons.building, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildPillNavBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), // slate-100
      child: Row(
        children: [
          _buildPillTabButton('fleet', LucideIcons.users, 'Filomuz'),
          _buildPillTabButton('shifts', LucideIcons.calendarCheck, 'Vardiyalar'),
          _buildPillTabButton('postings', LucideIcons.megaphone, 'İlanlar'),
          _buildPillTabButton('finance', LucideIcons.creditCard, 'Finans'),
        ],
      ),
    );
  }

  Widget _buildPillTabButton(String id, IconData icon, String title) {
    final active = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _kWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? _kIndigo : _kTextBody, size: 14),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: active ? _kIndigo : _kTextBody, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(AppProvider provider, List<Courier> companyCouriers, List<Shift> pendingShifts) {
    switch (_activeTab) {
      case 'fleet':
        return _buildFleetSection(companyCouriers);
      case 'shifts':
        return _buildShiftsSection(provider, pendingShifts);
      case 'postings':
        return _buildJobPostingSection(provider);
      case 'finance':
        return _buildFinanceSection(companyCouriers);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFleetSection(List<Courier> fleet) {
    if (fleet.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
        child: Column(
          children: const [
            Icon(LucideIcons.users, size: 40, color: _kTextMuted),
            SizedBox(height: 12),
            Text('Kayıtlı kuryeniz bulunmuyor.', style: TextStyle(color: _kTextMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fleet.length,
      itemBuilder: (context, index) {
        final courier = fleet[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(courier.name, style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: courier.status == 'musait' ? Colors.green : Colors.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Durum: ${courier.status.toUpperCase()}', style: TextStyle(color: courier.status == 'musait' ? Colors.green.shade600 : Colors.amber.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Performans Puanı: ⭐ ${courier.rating}', style: const TextStyle(color: _kTextMuted, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${courier.earningsWallet.round()} TL', style: const TextStyle(color: _kIndigo, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Cüzdan Bakiye', style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftsSection(AppProvider provider, List<Shift> shiftList) {
    if (shiftList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
        child: Column(
          children: const [
            Icon(LucideIcons.calendarCheck, size: 40, color: _kTextMuted),
            SizedBox(height: 12),
            Text('Onay bekleyen vardiya talebi bulunmuyor.', style: TextStyle(color: _kTextMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shiftList.length,
      itemBuilder: (context, index) {
        final shift = shiftList[index];
        final courier = provider.couriers.firstWhere((c) => c.id == shift.courierId, orElse: () => provider.couriers.first);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kurye: ${courier.name}', style: const TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Hafta Başlangıcı: ${shift.weekStartDate}', style: const TextStyle(color: _kTextBody, fontSize: 11)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.approveShift(shift.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vardiya onaylandı!'), backgroundColor: Colors.green));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.rejectShift(shift.id, 'Uygun Değil');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vardiya reddedildi.'), backgroundColor: Colors.redAccent));
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: _kBorder)),
                      child: const Text('Reddet', style: TextStyle(color: _kTextBody)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobPostingSection(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Yeni İş İlanı Yayınla', style: TextStyle(color: _kTextHead, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobTitleController,
              decoration: _inputDecoration('İlan Başlığı', LucideIcons.user),
              validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              style: const TextStyle(color: _kTextHead, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobDescController,
              maxLines: 3,
              decoration: _inputDecoration('İlan Açıklaması', LucideIcons.edit),
              validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              style: const TextStyle(color: _kTextHead, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: _kWhite,
                    decoration: _inputDecoration('Şehir (İl)', LucideIcons.mapPin),
                    items: kTurkeyCities.keys.map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedDistrict = null;
                      });
                    },
                    validator: (v) => v == null ? 'Gerekli' : null,
                    style: const TextStyle(color: _kTextHead, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    dropdownColor: _kWhite,
                    decoration: _inputDecoration('İlçe', LucideIcons.mapPin),
                    items: (_selectedCity == null ? <String>[] : kTurkeyCities[_selectedCity]!).map((dist) => DropdownMenuItem(
                      value: dist,
                      child: Text(dist),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                      });
                    },
                    validator: (v) => v == null ? 'Gerekli' : null,
                    style: const TextStyle(color: _kTextHead, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobSalaryController,
              decoration: _inputDecoration('Hak Ediş / Ücret', LucideIcons.coins),
              validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              style: const TextStyle(color: _kTextHead, fontSize: 11),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _publishJob(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kIndigo,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('İlanı Yayınla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSection(List<Courier> fleet) {
    final double totalWallet = fleet.fold(0.0, (sum, c) => sum + c.earningsWallet);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              const Text('FİLO TOPLAM HAK EDİŞ BİRİKİMİ', style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('${totalWallet.round()} TL', style: const TextStyle(color: _kTextHead, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Kuryelerinizin hesabında biriken toplam tutar.', style: TextStyle(color: _kTextMuted, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('KURYE DETAYLI FİNANS DÖKÜMÜ', style: TextStyle(color: _kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
        ...fleet.map((courier) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(courier.name, style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${courier.earningsWallet.round()} TL', style: TextStyle(color: Colors.green.shade600, fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
            ))
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

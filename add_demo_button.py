import os

with open('lib/views/marketing/marketing_view.dart', 'r', encoding='utf-8') as f:
    code = f.read()

dialog_code = '''
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
'''

if '_showDemoSelectionDialog' not in code:
    code = code.replace('Widget _buildHeroSection(bool isDesktop, bool isMd) {', dialog_code)

old_buttons = '''        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: widget.onPanelClick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: _kIndigo,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _kIndigo.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Demoyu İncele', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _scrollToSection(_featuresKey),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: const Text('Özellikleri Keşfet', style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ),'''

new_buttons = '''        Wrap(
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
        ),'''

code = code.replace(old_buttons, new_buttons)

mobile_text = "Text('Siparişlerinizi en gelişmiş teslimat altyapısıyla yöneterek verimliliğinizi ikiye katlayın.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.5)),"
mobile_new = '''Text('Siparişlerinizi en gelişmiş teslimat altyapısıyla yöneterek verimliliğinizi ikiye katlayın.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.5)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _showDemoSelectionDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(LucideIcons.playCircle, size: 16, color: _kIndigo),
                              SizedBox(width: 8),
                              Text('Panel Demosunu Dene', style: TextStyle(color: _kIndigo, fontWeight: FontWeight.w900, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),'''

if "Panel Demosunu Dene" not in code:
    code = code.replace(mobile_text, mobile_new)

with open('lib/views/marketing/marketing_view.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updates applied to marketing_view.dart")

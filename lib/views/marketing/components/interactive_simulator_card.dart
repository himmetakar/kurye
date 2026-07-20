import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';

const _kBg = Color(0xFFF8FAFC);
const _kWhite = Colors.white;
const _kBorderLight = Color(0xFFF1F5F9);
const _kTextHead = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF94A3B8);
const _kIndigo = Color(0xFF4F46E5);
const _kPurple = Color(0xFF7C3AED);
const _kGreen = Color(0xFF10B981);
const _kOrange = Color(0xFFF97316);
const _kIndigoBorder = Color(0xFFC7D2FE);
const _kIndigoPale = Color(0xFFEEF2FF);
const _kBorder = Color(0xFFE2E8F0);
const _kTextBody = Color(0xFF475569);

class InteractiveSimulatorCard extends StatefulWidget {
  const InteractiveSimulatorCard({super.key});

  @override
  State<InteractiveSimulatorCard> createState() => _InteractiveSimulatorCardState();
}

class _InteractiveSimulatorCardState extends State<InteractiveSimulatorCard> {
  int _step = 1; // Start directly at step 1 instead of 0
  String _typedText = '';
  final String _targetText = '1x Karışık Pizza, 1x Kola';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // SliverList lazily builds items when they scroll into view.
    // So this will fire automatically when the card becomes visible!
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startSimulation();
    });
  }

  void _startSimulation() {
    if (!mounted) return;
    setState(() {
      _step = 1;
      _typedText = '';
    });

    int charIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (charIndex < _targetText.length) {
        setState(() {
          _typedText += _targetText[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _step = 2);
            _simulateSearching();
          }
        });
      }
    });
  }

  void _simulateSearching() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _step = 3);
        _simulateSms(); // Trigger SMS at step 3 (kurye atandı)
        _simulateOnWay();
      }
    });
  }

  void _simulateOnWay() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _step = 4);
        _resetSimulation();
      }
    });
  }

  void _simulateSms() {
    // SMS visibility is bound to _step >= 3 now
  }

  void _resetSimulation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _startSimulation(); // Loop automatically
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _step > 0 ? _kIndigoBorder : _kBorderLight, width: _step > 0 ? 2 : 1),
          boxShadow: [BoxShadow(color: (_step > 0 ? _kIndigo : Colors.black).withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CANLI SİMÜLASYON', style: TextStyle(color: _kIndigo, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Icon(LucideIcons.loader, color: _kIndigo, size: 16),
                  ],
                ),
                const Divider(height: 24, color: _kBorderLight),
                _buildSimContent()
              ],
            ),
            // Drop-down SMS Simulator Banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              top: _step >= 3 ? -40 : -120, // Drop from above the card
              right: -10, // Anchor to top right
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _step >= 3 ? 1.0 : 0.0,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: _kBorderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.messageSquare, color: _kGreen, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Müşteriye SMS Gitti', style: TextStyle(color: _kTextHead, fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Kuryemiz paketinizi almak için restoranımıza doğru yola çıktı. Canlı takip: kurye.app/os-8742', style: TextStyle(color: _kTextBody, fontSize: 10, height: 1.3)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(4)),
                child: const Text('Online Platform', style: TextStyle(color: Color(0xFFBE123C), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Text('#os-8742', style: TextStyle(color: _kTextMuted, fontSize: 10)),
           ]
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(LucideIcons.shoppingBag, size: 16, color: _kTextMuted),
            const SizedBox(width: 8),
            Text(_step == 1 ? '$_typedText|' : _targetText, style: const TextStyle(color: _kTextHead, fontSize: 14, fontWeight: FontWeight.bold)),
          ]
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 14, color: _kTextMuted),
            SizedBox(width: 8),
            Text('Çankaya, Ankara', style: TextStyle(color: _kTextBody, fontSize: 12)),
          ]
        ),
        
        const SizedBox(height: 16),
        _buildStatusArea(),
      ]
    );
  }

  Widget _buildStatusArea() {
    if (_step == 1) {
      return const SizedBox(height: 60);
    }
    
    if (_step == 2) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706))),
            SizedBox(width: 12),
            Text('En uygun kurye aranıyor (AI Algoritması)...', style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold)),
          ]
        )
      );
    }
    
    if (_step >= 3) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kIndigoPale, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: _kIndigo, child: Icon(LucideIcons.bike, color: Colors.white, size: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ahmet Yılmaz', style: TextStyle(color: _kIndigo, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(_step == 3 ? 'Paketi Almaya Gidiyor' : 'Teslimata Çıktı', style: TextStyle(color: _kTextBody, fontSize: 11)),
                    ]
                  )
                ),
                Icon(LucideIcons.checkCircle2, color: _step >= 4 ? _kGreen : _kBorder, size: 20)
              ]
            )
          ),
          if (_step >= 4) ...[
             const SizedBox(height: 12),
             TweenAnimationBuilder(
               duration: const Duration(seconds: 3),
               tween: Tween<double>(begin: 0, end: 1),
               builder: (context, val, child) {
                 return Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Icon(LucideIcons.store, size: 16, color: _kTextMuted),
                         Expanded(
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 8),
                             child: LinearProgressIndicator(value: val, backgroundColor: _kBorderLight, color: _kGreen, minHeight: 4, borderRadius: BorderRadius.circular(2)),
                           )
                         ),
                         const Icon(LucideIcons.home, size: 16, color: _kTextMuted),
                       ]
                     )
                   ]
                 );
               }
             )
          ]
        ]
      );
    }
    
    return const SizedBox();
  }
}


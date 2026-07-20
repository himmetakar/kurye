import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';

// ───────── Brand Color Constants ─────────
const _kWhite = Colors.white;
const _kBorderLight = Color(0xFFF1F5F9); // slate-100
const _kTextHead = Color(0xFF0F172A);    // slate-900
const _kTextMuted = Color(0xFF94A3B8);   // slate-400
const _kIndigo = Color(0xFF4F46E5);      // indigo-600
const _kIndigoPale = Color(0xFFEEF2FF);  // indigo-50
const _kIndigoBorder = Color(0xFFC7D2FE); // indigo-200

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(
          bottom: BorderSide(color: _kBorderLight, width: 1),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kIndigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Kurye App',
                            style: TextStyle(color: _kTextHead, fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _kIndigoPale,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _kIndigoBorder),
                            ),
                            child: const Text(
                              'PANEL',
                              style: TextStyle(color: _kIndigo, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AKILLI TESLİMAT PLATFORMU',
                        style: TextStyle(color: _kTextMuted, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),

              // User Info & Session Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Info
                  if (user != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user['name'] ?? user['email'].toString().split('@')[0],
                          style: const TextStyle(color: _kTextHead, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user['role'].toString().toUpperCase(),
                          style: const TextStyle(color: _kIndigo, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
                      onPressed: () => provider.logout(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

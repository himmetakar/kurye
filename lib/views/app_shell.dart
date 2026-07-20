import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'widgets/header_widget.dart';
import 'marketing/marketing_view.dart';
import 'auth/login_view.dart';
import 'courier/courier_panel_view.dart';
import 'restaurant/restaurant_panel_view.dart';
import 'company/company_panel_view.dart';
import 'admin/admin_dashboard_view.dart';
import 'customer/customer_tracking_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showLogin = false;
  String? _selectedTrackingOrderId;
  bool _startWithRegister = false;
  String? _initialRole;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // 1. Loading screen
    if (!provider.isDataReady) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC), // Slate 50
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF4F46E5)),
        ),
      );
    }

    // 2. Public Customer Tracking view (if trackingId is set)
    if (_selectedTrackingOrderId != null) {
      return CustomerTrackingView(
        orderId: _selectedTrackingOrderId!,
        onBack: () {
          setState(() {
            _selectedTrackingOrderId = null;
          });
        },
      );
    }

    // 3. User session checking
    final user = provider.currentUser;

    if (user == null) {
      // Login View
      if (_showLogin) {
        return LoginView(
          startWithRegister: _startWithRegister,
          initialRole: _initialRole,
          onBack: () {
            setState(() {
              _showLogin = false;
            });
          },
        );
      }
      // Public Landing Page / Marketing
      return MarketingView(
        onPanelClick: () {
          setState(() {
            _showLogin = true;
            _startWithRegister = false;
            _initialRole = null;
          });
        },
        onRegisterClick: (role) {
          setState(() {
            _showLogin = true;
            _startWithRegister = true;
            _initialRole = role;
          });
        },
        onTrackingClick: (orderId) {
          setState(() {
            _selectedTrackingOrderId = orderId;
          });
        },
      );
    }

    // 4. Authenticated Screens
    final role = user['role'] as String;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Column(
        children: [
          // Header Widget
          const HeaderWidget(),

          Expanded(
            child: _buildRoleContent(provider, role, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleContent(AppProvider provider, String role, bool isDesktop) {
    // A. Standalone Courier Mode (Doesn't use split screen)
    if (role == 'kurye') {
      return CourierPanelView(courierId: provider.currentUser!['id']);
    }

    // B. Split Simulator Mode (Visible only if demoMode is enabled)
    if (provider.demoMode) {
      if (isDesktop) {
        return Row(
          children: [
            // Left Column: Main Dashboard based on Role
            Expanded(
              flex: 5,
              child: _buildRoleDashboard(role, provider.currentUser!['id']),
            ),
            // Divider
            Container(width: 1, color: const Color(0xFFE2E8F0)), // Slate 200
            // Right Column: Courier Panel Simulator
            Expanded(
              flex: 4,
              child: CourierPanelView(courierId: provider.demoActiveCourierId),
            ),
          ],
        );
      } else {
        // Mobile Layout: Stacking Tabs or toggle button
        return Column(
          children: [
            Expanded(
              child: _buildRoleDashboard(role, provider.currentUser!['id']),
            ),
            // Divider
            Container(height: 2, color: const Color(0xFF4F46E5)),
            // Display mini simulator container
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Simülasyon Kurye Takibi Aktif (Görünümü bölmek için geniş ekran kullanın)',
                style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }
    }

    // C. Standalone Dashboard Mode (For Production)
    return _buildRoleDashboard(role, provider.currentUser!['id']);
  }

  Widget _buildRoleDashboard(String role, String userId) {
    if (role == 'superadmin') {
      return const AdminDashboardView();
    } else if (role == 'firma') {
      return CompanyPanelView(companyId: userId);
    } else if (role == 'restoran') {
      return RestaurantPanelView(restaurantId: userId);
    }
    return const Center(child: Text('Yetkisiz Erişim.', style: TextStyle(color: Color(0xFF0F172A))));
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

import '../models/company.dart';
import '../models/restaurant.dart';
import '../models/courier.dart';
import '../models/order.dart';
import '../models/shift.dart';
import '../models/notification_model.dart';
import '../models/job_posting.dart';
import '../models/courier_request.dart';
import '../models/contact_message.dart';
import '../models/support_message.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class AppProvider with ChangeNotifier {
  // Firebase activation flag (matches isFirebaseActive in JS)
  bool _isFirebaseActive = true;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // State Lists
  List<Company> _companies = [];
  List<Restaurant> _restaurants = [];
  List<Courier> _couriers = [];
  List<OrderModel> _orders = [];
  List<Shift> _shifts = [];
  List<NotificationModel> _notifications = [];
  List<JobPosting> _jobPostings = [];
  List<CourierRequest> _courierRequests = [];
  List<ContactMessage> _contactMessages = [];
  Map<String, List<SupportMessage>> _supportChats = {};

  // UI State
  Map<String, dynamic>? _currentUser;
  bool _demoMode = false;
  String _demoActiveCourierId = 'kurye1';
  String _activeRestaurantId = 'restoran1';
  bool _isDataReady = false;

  // Active Timers
  Timer? _assignmentTimer;
  Map<String, int> _localTimers = {};

  // Getters
  List<Company> get companies => _companies;
  List<Restaurant> get restaurants => _restaurants;
  List<Courier> get couriers => _couriers;
  List<OrderModel> get orders => _orders;
  List<Shift> get shifts => _shifts;
  List<NotificationModel> get notifications => _notifications;
  List<JobPosting> get jobPostings => _jobPostings;
  List<CourierRequest> get courierRequests => _courierRequests;
  List<ContactMessage> get contactMessages => _contactMessages;
  Map<String, List<SupportMessage>> get supportChats => _supportChats;
  
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get demoMode => _demoMode;
  String get demoActiveCourierId => _demoActiveCourierId;
  String get activeRestaurantId => _activeRestaurantId;
  bool get isDataReady => _isDataReady;

  Restaurant get activeRestaurant {
    return _restaurants.firstWhere(
      (r) => r.id == _activeRestaurantId,
      orElse: () => _restaurants.isNotEmpty ? _restaurants.first : _defaultRestaurants.first,
    );
  }

  AppProvider() {
    _initData();
  }

  // ─────────────────────────────────────────────────────────────
  // DATA INITIALIZATION & SYNC
  // ─────────────────────────────────────────────────────────────

  Future<void> _initData() async {
    // Load local storage first to prevent blank screens
    await _loadFromLocal();

    // Check if Firebase is initialized
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseActive = true;
      } else {
        _isFirebaseActive = false;
      }
    } catch (_) {
      _isFirebaseActive = false;
    }

    if (_isFirebaseActive) {
      _listenToFirebase();
    } else {
      _isDataReady = true;
      notifyListeners();
    }

    // Resume services if user was logged in
    if (_currentUser != null) {
      _registerTokenAndStartServices(_currentUser!);
    }

    // Start background activity ticker (GPS, Eta simulation, auto-reassignment checks)
    _startPeriodicTicker();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final compRaw = prefs.getString('companies');
      if (compRaw != null) {
        _companies = (jsonDecode(compRaw) as List).map((i) => Company.fromJson(i)).toList();
      } else {
        _companies = [_defaultCompany];
      }

      final restRaw = prefs.getString('restaurants');
      if (restRaw != null) {
        _restaurants = (jsonDecode(restRaw) as List).map((i) => Restaurant.fromJson(i)).toList();
      } else {
        _restaurants = _defaultRestaurants;
      }

      final courRaw = prefs.getString('couriers');
      if (courRaw != null) {
        _couriers = (jsonDecode(courRaw) as List).map((i) => Courier.fromJson(i)).toList();
      } else {
        _couriers = _defaultCouriers;
      }

      final ordersRaw = prefs.getString('orders');
      if (ordersRaw != null) {
        _orders = (jsonDecode(ordersRaw) as List).map((i) => OrderModel.fromJson(i)).toList();
      }

      final userRaw = prefs.getString('currentUser');
      if (userRaw != null) {
        _currentUser = jsonDecode(userRaw);
      }

      // Restore demo mode flag (false = real Firebase login)
      _demoMode = prefs.getBool('demoMode') ?? false;

      final jobRaw = prefs.getString('jobPostings');
      if (jobRaw != null) {
        _jobPostings = (jsonDecode(jobRaw) as List).map((i) => JobPosting.fromJson(i)).toList();
      } else {
        _jobPostings = _defaultJobPostings;
      }

      final reqRaw = prefs.getString('courierRequests');
      if (reqRaw != null) {
        _courierRequests = (jsonDecode(reqRaw) as List).map((i) => CourierRequest.fromJson(i)).toList();
      } else {
        _courierRequests = _defaultCourierRequests;
      }

      final contactRaw = prefs.getString('contactMessages');
      if (contactRaw != null) {
        _contactMessages = (jsonDecode(contactRaw) as List).map((i) => ContactMessage.fromJson(i)).toList();
      } else {
        _contactMessages = _defaultContactMessages;
      }
    } catch (e) {
      print('Local cache read error: $e');
    }
  }

  void _listenToFirebase() {
    // Basic snapshot listeners mimicking React project
    _listenCollection<Company>('companies', (list) => _companies = list);
    _listenCollection<Restaurant>('restaurants', (list) => _restaurants = list);
    _listenCollection<Courier>('couriers', (list) => _couriers = list);
    _listenCollection<OrderModel>('orders', (list) => _orders = list);
    _listenCollection<Shift>('shifts', (list) => _shifts = list);
    _listenCollection<NotificationModel>('notifications', (list) => _notifications = list);
    _listenCollection<JobPosting>('jobPostings', (list) => _jobPostings = list);
    _listenCollection<CourierRequest>('courierRequests', (list) => _courierRequests = list);
    _listenCollection<ContactMessage>('contactMessages', (list) => _contactMessages = list);

    // Support chats custom sync
    _db.collection('supportChats').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        var rawMessages = doc.data()['messages'] as List?;
        if (rawMessages != null) {
          _supportChats[doc.id] = rawMessages.map((i) => SupportMessage.fromJson(i)).toList();
        }
      }
      _isDataReady = true;
      notifyListeners();
    }, onError: (err) {
      print('Firebase chat sync error: $err');
      _isDataReady = true;
      notifyListeners();
    });
  }

  void _listenCollection<T>(String colName, Function(List<T>) updateState) {
    _db.collection(colName).snapshots().listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Seed default mock data if Firestore collection is empty
        await _seedCollection(colName);
      } else {
        List<T> list = [];
        for (var doc in snapshot.docs) {
          var data = doc.data();
          data['id'] = doc.id;
          if (T == Company) list.add(Company.fromJson(data) as T);
          if (T == Restaurant) list.add(Restaurant.fromJson(data) as T);
          if (T == Courier) list.add(Courier.fromJson(data) as T);
          if (T == OrderModel) list.add(OrderModel.fromJson(data) as T);
          if (T == Shift) list.add(Shift.fromJson(data) as T);
          if (T == NotificationModel) list.add(NotificationModel.fromJson(data) as T);
          if (T == JobPosting) list.add(JobPosting.fromJson(data) as T);
          if (T == CourierRequest) list.add(CourierRequest.fromJson(data) as T);
          if (T == ContactMessage) list.add(ContactMessage.fromJson(data) as T);
        }
        updateState(list);
        _saveToLocal(colName, list);
        _isDataReady = true;
        notifyListeners();
      }
    });
  }

  Future<void> _seedCollection(String colName) async {
    var batch = _db.batch();
    List<dynamic> defaults = [];
    if (colName == 'companies') defaults = [_defaultCompany];
    if (colName == 'restaurants') defaults = _defaultRestaurants;
    if (colName == 'couriers') defaults = _defaultCouriers;
    if (colName == 'jobPostings') defaults = _defaultJobPostings;
    if (colName == 'courierRequests') defaults = _defaultCourierRequests;
    if (colName == 'contactMessages') defaults = _defaultContactMessages;

    for (var item in defaults) {
      var docRef = _db.collection(colName).doc(item.id);
      batch.set(docRef, item.toJson());
    }
    await batch.commit();
  }

  Future<void> _saveToLocal(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data is List) {
      prefs.setString(key, jsonEncode(data.map((i) => i.toJson()).toList()));
    } else {
      prefs.setString(key, jsonEncode(data));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FIRESTORE HELPER WRAPPERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _firestoreSet(String colName, String docId, Map<String, dynamic> data) async {
    if (_isFirebaseActive) {
      await _db.collection(colName).doc(docId).set(data);
    }
  }

  Future<void> _firestoreUpdate(String colName, String docId, Map<String, dynamic> updates) async {
    if (_isFirebaseActive) {
      await _db.collection(colName).doc(docId).update(updates);
    }
  }

  Future<void> _firestoreDelete(String colName, String docId) async {
    if (_isFirebaseActive) {
      await _db.collection(colName).doc(docId).delete();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CORE DISPATCH & TIMER TICKER (GPS & Reassignments)
  // ─────────────────────────────────────────────────────────────

  void _startPeriodicTicker() {
    _assignmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // 1. Process Order ETA & Inactivity Penalties
      bool stateChanged = false;
      for (var order in _orders) {
        if (['araniyor', 'kabul_edildi', 'teslim_alindi'].contains(order.status)) {
          final created = DateTime.parse(order.createdAt);
          final diff = now.difference(created).inSeconds;

          // Late/Delayed flags (if active > 75 seconds)
          if (diff > 75 && !order.isDelayed) {
            final updatedOrder = OrderModel(
              id: order.id,
              restaurantId: order.restaurantId,
              restaurantName: order.restaurantName,
              customerName: order.customerName,
              deliveryAddress: order.deliveryAddress,
              phone: order.phone,
              price: order.price,
              status: order.status,
              createdAt: order.createdAt,
              latitude: order.latitude,
              longitude: order.longitude,
              isDelayed: true,
              delayReason: 'Tahmini teslimat süresi aşıldı',
              acknowledged: order.acknowledged,
              poolOrder: order.poolOrder,
              reportedNotReceived: order.reportedNotReceived,
            );
            _orders = _orders.map((o) => o.id == order.id ? updatedOrder : o).toList();
            _firestoreUpdate('orders', order.id, {'isDelayed': true, 'delayReason': 'Tahmini teslimat süresi aşıldı'});
            stateChanged = true;
          }

          // 2. Auto-reject unacknowledged orders after 180 seconds (3 mins)
          if (order.assignedCourierId != null && order.status == 'kabul_edildi' && !order.acknowledged) {
            final assignedTime = DateTime.parse(order.assignedAt ?? order.createdAt);
            final elapsed = now.difference(assignedTime).inSeconds;

            if (elapsed >= 180) {
              _handleAutoReject(order);
              stateChanged = true;
            }
          }
        }
      }

      // 3. Reactivate suspended couriers
      for (var courier in _couriers) {
        if (courier.status == 'pasif' && courier.lastDeactivatedAt != null) {
          final deacTime = DateTime.parse(courier.lastDeactivatedAt!);
          final diffMins = now.difference(deacTime).inMinutes;
          final limit = courier.id.startsWith('kurye') ? 5 : 30; // 5 mins in demo, 30 mins in prod
          if (diffMins >= limit) {
            _reactivateCourier(courier.id);
            stateChanged = true;
          }
        }
      }

      if (stateChanged) {
        notifyListeners();
      }
    });
  }

  void _handleAutoReject(OrderModel order) {
    final courierId = order.assignedCourierId!;
    final courier = _couriers.firstWhere((c) => c.id == courierId);
    
    // Decrease acceptance rate and penalize
    final int newAssigned = courier.assignedOrdersCount; // already incremented when assigned
    final int newAccepted = courier.acceptedOrdersCount;
    final int accRate = ((newAccepted / (newAssigned > 0 ? newAssigned : 1)) * 100).round();
    
    String finalStatus = 'musait';
    String? deacAt;
    if (accRate < 85) {
      finalStatus = 'pasif';
      deacAt = DateTime.now().toIso8601String();
    }

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final isSameDay = courier.lastViolationDate == todayStr;
    final newViolations = isSameDay ? courier.dailyViolationCount + 1 : 1;
    
    bool shadowBan = courier.isShadowBanned;
    String? shadowBanAt = courier.shadowBannedAt;
    if (newViolations >= 3) {
      shadowBan = true;
      shadowBanAt = DateTime.now().toIso8601String();
    }

    final updatedCourier = _copyCourierWith(
      courier,
      status: finalStatus,
      acceptanceRate: accRate,
      lastDeactivatedAt: deacAt,
      dailyViolationCount: newViolations,
      lastViolationDate: todayStr,
      isShadowBanned: shadowBan,
      shadowBannedAt: shadowBanAt,
    );

    _couriers = _couriers.map((c) => c.id == courierId ? updatedCourier : c).toList();

    // Reassign order excluding this courier
    final restaurant = _restaurants.firstWhere((r) => r.id == order.restaurantId);
    
    final nextCourier = _findNextAvailableCourier(restaurant, courierId, order);
    
    final updatedOrder = OrderModel(
      id: order.id,
      restaurantId: order.restaurantId,
      restaurantName: order.restaurantName,
      customerName: order.customerName,
      deliveryAddress: order.deliveryAddress,
      phone: order.phone,
      price: order.price,
      status: nextCourier != null ? 'kabul_edildi' : 'araniyor',
      createdAt: order.createdAt,
      assignedCourierId: nextCourier?.id,
      assignedAt: nextCourier != null ? DateTime.now().toIso8601String() : null,
      acknowledged: false,
      latitude: order.latitude,
      longitude: order.longitude,
      isDelayed: order.isDelayed,
      poolOrder: order.poolOrder,
      reportedNotReceived: order.reportedNotReceived,
    );

    _orders = _orders.map((o) => o.id == order.id ? updatedOrder : o).toList();

    // Firestore Sync
    _firestoreUpdate('couriers', courierId, {
      'status': finalStatus,
      'acceptanceRate': accRate,
      'lastDeactivatedAt': deacAt,
      'dailyViolationCount': newViolations,
      'lastViolationDate': todayStr,
      'isShadowBanned': shadowBan,
      'shadowBannedAt': shadowBanAt,
    });

    _firestoreUpdate('orders', order.id, {
      'status': nextCourier != null ? 'kabul_edildi' : 'araniyor',
      'assignedCourierId': nextCourier?.id,
      'assignedAt': nextCourier != null ? DateTime.now().toIso8601String() : null,
      'acknowledged': false,
    });

    if (nextCourier != null) {
      _incrementCourierAssignedCount(nextCourier.id, order.id);
    }
  }

  void _reactivateCourier(String courierId) {
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        return _copyCourierWith(c, status: 'musait', lastDeactivatedAt: null);
      }
      return c;
    }).toList();
    _firestoreUpdate('couriers', courierId, {'status': 'musait', 'lastDeactivatedAt': null});
  }

  // ─────────────────────────────────────────────────────────────
  // BUSINESS OPERATIONS & ACTIONS
  // ─────────────────────────────────────────────────────────────

  // --- Auth / User Sessions ---
  void setDemoMode(bool mode) {
    _demoMode = mode;
    _saveToLocal('demoMode', mode);
    notifyListeners();
  }

  void setDemoActiveCourierId(String id) {
    _demoActiveCourierId = id;
    notifyListeners();
  }

  void setActiveRestaurantId(String id) {
    _activeRestaurantId = id;
    notifyListeners();
  }

  Future<bool> login(String email, String role) async {
    // Reset demo mode and re-enable Firebase for real logins
    _demoMode = false;
    _isFirebaseActive = Firebase.apps.isNotEmpty;

    // Simple role auth logic mimicking original code
    Map<String, dynamic>? user;
    if (role == 'superadmin' && email == 'admin@kurye.com') {
      user = {'email': email, 'role': role, 'id': 'admin'};
    } else if (role == 'restoran') {
      final r = _restaurants.firstWhere((res) => res.email == email, orElse: () => _restaurants.first);
      user = {'email': email, 'role': role, 'id': r.id, 'name': r.name};
      // IMPORTANT: update active restaurant to the real one, clear any demo residue
      _activeRestaurantId = r.id;
    } else if (role == 'firma') {
      final f = _companies.firstWhere((co) => co.email == email, orElse: () => _companies.first);
      user = {'email': email, 'role': role, 'id': f.id, 'name': f.name};
    } else if (role == 'kurye') {
      final c = _couriers.firstWhere((cu) => cu.email == email, orElse: () => _couriers.first);
      user = {'email': email, 'role': role, 'id': c.id, 'name': c.name};
      _demoActiveCourierId = c.id;
    }

    if (user != null) {
      _currentUser = user;
      await _saveToLocal('currentUser', user);
      await _saveToLocal('demoMode', false);
      
      // Setup push notifications and geolocation services
      _registerTokenAndStartServices(user);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginAsDemo(String role) async {
    _isFirebaseActive = false; // Disable Firebase writes for demo users
    _demoMode = true;
    
    Map<String, dynamic>? user;
    if (role == 'restoran') {
      user = {'email': 'demo@restoran.com', 'role': role, 'id': 'demo_restoran', 'name': 'Demo Restoran'};
      if (!_restaurants.any((r) => r.id == 'demo_restoran')) {
         final base = _restaurants.isNotEmpty ? _restaurants.first : null;
         if (base != null) {
           final json = base.toJson();
           json['id'] = 'demo_restoran';
           json['name'] = 'Demo Restoran';
           json['email'] = 'demo@restoran.com';
           _restaurants.add(Restaurant.fromJson(json));
         }
      }
      _activeRestaurantId = 'demo_restoran';
    } else if (role == 'firma') {
      user = {'email': 'demo@firma.com', 'role': role, 'id': 'demo_firma', 'name': 'Demo Firma'};
      if (!_companies.any((c) => c.id == 'demo_firma')) {
         final base = _companies.isNotEmpty ? _companies.first : null;
         if (base != null) {
           final json = base.toJson();
           json['id'] = 'demo_firma';
           json['name'] = 'Demo Firma';
           json['email'] = 'demo@firma.com';
           _companies.add(Company.fromJson(json));
         }
      }
    } else if (role == 'kurye') {
      user = {'email': 'demo@kurye.com', 'role': role, 'id': 'demo_kurye', 'name': 'Demo Kurye'};
      if (!_couriers.any((c) => c.id == 'demo_kurye')) {
         final base = _couriers.isNotEmpty ? _couriers.first : null;
         if (base != null) {
           final json = base.toJson();
           json['id'] = 'demo_kurye';
           json['name'] = 'Demo Kurye';
           json['email'] = 'demo@kurye.com';
           json['courierCompanyId'] = 'demo_firma';
           _couriers.add(Courier.fromJson(json));
         }
      }
      _demoActiveCourierId = 'demo_kurye';
    }

    if (user != null) {
      _currentUser = user;
      // Do not save demo user to SharedPreferences to keep it ephemeral
      notifyListeners();
      return true;
    }
    return false;
  }


  Future<void> logout() async {
    if (_currentUser != null && _currentUser!['role'] == 'kurye') {
      await LocationService.stopTracking();
    }
    
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('currentUser');
    notifyListeners();
  }

  void _registerTokenAndStartServices(Map<String, dynamic> user) async {
    // 1. Push notifications setup
    if (_isFirebaseActive) {
      final permissionGranted = await NotificationService.requestPermissions();
      if (permissionGranted) {
        final token = await NotificationService.getDeviceToken();
        if (token != null) {
          final role = user['role'] as String;
          final userId = user['id'] as String;
          String? collection;
          if (role == 'kurye') {
            collection = 'couriers';
          } else if (role == 'restoran') {
            collection = 'restaurants';
          } else if (role == 'firma') {
            collection = 'companies';
          }

          if (collection != null) {
            _firestoreUpdate(collection, userId, {'fcmToken': token});
          }
        }
      }
    }

    // 2. Start GPS Geolocation Tracking if the user is a courier
    if (user['role'] == 'kurye') {
      final courierId = user['id'] as String;
      await LocationService.startTracking((double lat, double lon) {
        updateCourierLocation(courierId, lat, lon);
      });
    }
  }

  // --- Geolocation update ---
  void updateCourierLocation(String courierId, double lat, double lon) {
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        // Detect arrival at restaurant (within 100 meters)
        final rest = _restaurants.firstWhere(
          (r) => r.id == (c.assignedRestaurantId ?? 'restoran1'),
          orElse: () => _restaurants.first,
        );
        final dist = _calculateDistance(lat, lon, rest.latitude, rest.longitude);
        final atRest = dist <= 100;
        final String? arrivedAt = atRest && !c.isAtRestaurant ? DateTime.now().toIso8601String() : c.arrivedAtRestaurantAt;

        return _copyCourierWith(
          c,
          latitude: lat,
          longitude: lon,
          isAtRestaurant: atRest,
          arrivedAtRestaurantAt: arrivedAt,
        );
      }
      return c;
    }).toList();

    _firestoreUpdate('couriers', courierId, {
      'latitude': lat,
      'longitude': lon,
    });
    notifyListeners();
  }

  void confirmCourierAtRestaurant(String courierId) {
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        return _copyCourierWith(c, isAtRestaurant: true, arrivedAtRestaurantAt: DateTime.now().toIso8601String());
      }
      return c;
    }).toList();
    _firestoreUpdate('couriers', courierId, {
      'isAtRestaurant': true,
      'arrivedAtRestaurantAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  // --- Order lifecycle actions ---
  Future<void> callCourier({
    required String restaurantId,
    required String customerName,
    required String address,
    required String phone,
    required double price,
    required double lat,
    required double lon,
    bool poolOrder = false,
    String? forceCourierId,
  }) async {
    final orderId = 'siparis_${DateTime.now().millisecondsSinceEpoch}';
    final restaurant = _restaurants.firstWhere((r) => r.id == restaurantId);
    
    // Find closest or priority courier
    Courier? selectedCourier;
    if (forceCourierId != null) {
      selectedCourier = _couriers.firstWhere((c) => c.id == forceCourierId, orElse: () => _couriers.first);
    } else if (!poolOrder) {
      selectedCourier = _findNextAvailableCourier(restaurant, null, null);
    }

    final newOrder = OrderModel(
      id: orderId,
      restaurantId: restaurantId,
      restaurantName: restaurant.name,
      customerName: customerName,
      deliveryAddress: address,
      phone: phone,
      price: price,
      status: selectedCourier != null ? 'kabul_edildi' : 'araniyor',
      createdAt: DateTime.now().toIso8601String(),
      latitude: lat,
      longitude: lon,
      isDelayed: false,
      acknowledged: false,
      poolOrder: poolOrder,
      assignedCourierId: selectedCourier?.id,
      assignedAt: selectedCourier != null ? DateTime.now().toIso8601String() : null,
      reportedNotReceived: false,
    );

    _orders = [newOrder, ..._orders];
    _firestoreSet('orders', orderId, newOrder.toJson());

    if (selectedCourier != null) {
      _incrementCourierAssignedCount(selectedCourier.id, orderId);
    }
    notifyListeners();
  }

  void acceptOrder(String orderId, String courierId) {
    final nowStr = DateTime.now().toIso8601String();
    
    // Fetch pricing settings based on courier's company
    final courier = _couriers.firstWhere((c) => c.id == courierId);
    final company = _companies.firstWhere((co) => co.id == courier.courierCompanyId, orElse: () => _defaultCompany);
    
    // Calculate earnings index
    final int activePackagesCount = _orders.where((o) => 
      o.assignedCourierId == courierId && 
      ['araniyor', 'kabul_edildi', 'teslim_alindi'].contains(o.status) && 
      o.id != orderId
    ).length;

    final packageIndex = activePackagesCount + 1;
    double earnAmt = 40.0;
    if (packageIndex == 1) {
      earnAmt = company.pricing.firstPackageRate;
    } else if (packageIndex == 2) {
      earnAmt = company.pricing.secondPackageRate;
    } else {
      earnAmt = company.pricing.thirdPackageRate;
    }

    final nextStatus = activePackagesCount > 0 ? 'tasimada' : 'kabul_edildi';

    // Update Order
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: nextStatus,
          createdAt: o.createdAt,
          assignedCourierId: courierId,
          assignedAt: o.assignedAt ?? nowStr,
          acknowledged: true,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    // Update Courier
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        final newLogs = List<EarningsLogEntry>.from(c.earningsLog);
        newLogs.add(EarningsLogEntry(
          orderId: orderId,
          amount: earnAmt,
          type: 'paket',
          timestamp: nowStr,
          note: '$packageIndex. Paket Teslimatı',
        ));

        return _copyCourierWith(
          c,
          status: 'aktif',
          acceptedOrdersCount: c.acceptedOrdersCount + 1,
          earningsWallet: c.earningsWallet + earnAmt,
          earningsLog: newLogs,
        );
      }
      return c;
    }).toList();

    _firestoreUpdate('orders', orderId, {'status': nextStatus, 'acknowledged': true});
    _firestoreUpdate('couriers', courierId, {
      'status': 'aktif',
      'acceptedOrdersCount': courier.acceptedOrdersCount + 1,
      'earningsWallet': courier.earningsWallet + earnAmt,
      'earningsLog': _couriers.firstWhere((c) => c.id == courierId).earningsLog.map((e) => e.toJson()).toList(),
    });
    notifyListeners();
  }

  void acknowledgeOrder(String orderId, String courierId) {
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: o.status,
          createdAt: o.createdAt,
          assignedCourierId: o.assignedCourierId,
          assignedAt: o.assignedAt,
          acknowledged: true,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();
    _firestoreUpdate('orders', orderId, {'acknowledged': true});
    notifyListeners();
  }

  void declineOrder(String orderId, String courierId) {
    final courier = _couriers.firstWhere((c) => c.id == courierId);
    
    // Penalize and look for next courier
    final int newAssigned = courier.assignedOrdersCount;
    final int newAccepted = courier.acceptedOrdersCount;
    final int accRate = ((newAccepted / (newAssigned > 0 ? newAssigned : 1)) * 100).round();
    
    String finalStatus = 'musait';
    String? deacAt;
    if (accRate < 85) {
      finalStatus = 'pasif';
      deacAt = DateTime.now().toIso8601String();
    }

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final isSameDay = courier.lastViolationDate == todayStr;
    final newViolations = isSameDay ? courier.dailyViolationCount + 1 : 1;

    bool shadowBan = courier.isShadowBanned;
    String? shadowBanAt = courier.shadowBannedAt;
    if (newViolations >= 3) {
      shadowBan = true;
      shadowBanAt = DateTime.now().toIso8601String();
    }

    final updatedCourier = _copyCourierWith(
      courier,
      status: finalStatus,
      acceptanceRate: accRate,
      lastDeactivatedAt: deacAt,
      dailyViolationCount: newViolations,
      lastViolationDate: todayStr,
      isShadowBanned: shadowBan,
      shadowBannedAt: shadowBanAt,
    );

    _couriers = _couriers.map((c) => c.id == courierId ? updatedCourier : c).toList();

    // Reassign order
    final order = _orders.firstWhere((o) => o.id == orderId);
    final restaurant = _restaurants.firstWhere((r) => r.id == order.restaurantId);
    
    final nextCourier = _findNextAvailableCourier(restaurant, courierId, order);
    
    final updatedOrder = OrderModel(
      id: order.id,
      restaurantId: order.restaurantId,
      restaurantName: order.restaurantName,
      customerName: order.customerName,
      deliveryAddress: order.deliveryAddress,
      phone: order.phone,
      price: order.price,
      status: nextCourier != null ? 'kabul_edildi' : 'araniyor',
      createdAt: order.createdAt,
      assignedCourierId: nextCourier?.id,
      assignedAt: nextCourier != null ? DateTime.now().toIso8601String() : null,
      acknowledged: false,
      latitude: order.latitude,
      longitude: order.longitude,
      isDelayed: order.isDelayed,
      poolOrder: order.poolOrder,
      reportedNotReceived: order.reportedNotReceived,
    );

    _orders = _orders.map((o) => o.id == orderId ? updatedOrder : o).toList();

    // Firebase Sync
    _firestoreUpdate('couriers', courierId, {
      'status': finalStatus,
      'acceptanceRate': accRate,
      'lastDeactivatedAt': deacAt,
      'dailyViolationCount': newViolations,
      'lastViolationDate': todayStr,
      'isShadowBanned': shadowBan,
      'shadowBannedAt': shadowBanAt,
    });

    _firestoreUpdate('orders', orderId, {
      'status': nextCourier != null ? 'kabul_edildi' : 'araniyor',
      'assignedCourierId': nextCourier?.id,
      'assignedAt': nextCourier != null ? DateTime.now().toIso8601String() : null,
      'acknowledged': false,
    });

    if (nextCourier != null) {
      _incrementCourierAssignedCount(nextCourier.id, orderId);
    }
    notifyListeners();
  }

  void pickupPackage(String orderId, String courierId) {
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: 'teslim_alindi',
          createdAt: o.createdAt,
          assignedCourierId: courierId,
          assignedAt: o.assignedAt,
          pickedUpAt: DateTime.now().toIso8601String(),
          acknowledged: o.acknowledged,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    _firestoreUpdate('orders', orderId, {
      'status': 'teslim_alindi',
      'pickedUpAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void deliverPackage(String orderId, String courierId) {
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: 'teslim_edildi',
          createdAt: o.createdAt,
          assignedCourierId: courierId,
          assignedAt: o.assignedAt,
          pickedUpAt: o.pickedUpAt,
          deliveredAt: DateTime.now().toIso8601String(),
          acknowledged: o.acknowledged,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    // Rotate queue & update deliveriesCount
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        return _copyCourierWith(
          c,
          status: 'musait',
          deliveriesCount: c.deliveriesCount + 1,
        );
      }
      return c;
    }).toList();

    // Rotate queue position
    _rotateQueuePosition(courierId);

    _firestoreUpdate('orders', orderId, {
      'status': 'teslim_edildi',
      'deliveredAt': DateTime.now().toIso8601String(),
    });
    
    _firestoreUpdate('couriers', courierId, {
      'status': 'musait',
      'deliveriesCount': _couriers.firstWhere((c) => c.id == courierId).deliveriesCount,
    });
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: 'iptal',
          createdAt: o.createdAt,
          assignedCourierId: o.assignedCourierId,
          assignedAt: o.assignedAt,
          acknowledged: o.acknowledged,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    _firestoreUpdate('orders', orderId, {'status': 'iptal'});
    notifyListeners();
  }

  Future<Map<String, dynamic>> cancelAssignedOrder(String orderId, String courierId) async {
    final courier = _couriers.firstWhere((c) => c.id == courierId);
    final dailyCancels = courier.dailyCancellationsCount;
    
    final updates = <String, dynamic>{};
    String resultMessage = "";

    if (dailyCancels >= 1) {
      // Exceeded daily free cancel, deduct score and rate
      final double newWallet = courier.earningsWallet - 50.0; // Penalty fee
      final newLogs = List<EarningsLogEntry>.from(courier.earningsLog);
      newLogs.add(EarningsLogEntry(
        orderId: orderId,
        amount: -50.0,
        type: 'ceza',
        timestamp: DateTime.now().toIso8601String(),
        note: 'Sipariş İptal Cezası',
      ));
      
      final newScore = max(0, courier.performanceScore - 5);
      final newRating = max(1.0, courier.rating - 0.2);

      _couriers = _couriers.map((c) {
        if (c.id == courierId) {
          return _copyCourierWith(
            c,
            status: 'musait',
            earningsWallet: newWallet,
            earningsLog: newLogs,
            performanceScore: newScore,
            rating: newRating,
            penaltiesCount: c.penaltiesCount + 1,
          );
        }
        return c;
      }).toList();

      updates['earningsWallet'] = newWallet;
      updates['earningsLog'] = newLogs.map((e) => e.toJson()).toList();
      updates['performanceScore'] = newScore;
      updates['rating'] = newRating;
      updates['penaltiesCount'] = courier.penaltiesCount + 1;
      updates['status'] = 'musait';
      
      resultMessage = "Sipariş cezalı olarak iptal edildi. 5 performans puanı ve 0.2 puan kesildi. Wallet'a 50 TL ceza yansıtıldı.";
    } else {
      // Free cancel
      _couriers = _couriers.map((c) {
        if (c.id == courierId) {
          return _copyCourierWith(
            c,
            status: 'musait',
            dailyCancellationsCount: 1,
          );
        }
        return c;
      }).toList();

      updates['dailyCancellationsCount'] = 1;
      updates['status'] = 'musait';
      
      resultMessage = "Günlük ücretsiz iptal hakkınız kullanıldı. Performansınız etkilenmedi.";
    }

    // Reassign order
    final order = _orders.firstWhere((o) => o.id == orderId);
    final restaurant = _restaurants.firstWhere((r) => r.id == order.restaurantId);
    final nextCourier = _findNextAvailableCourier(restaurant, courierId, order);

    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: nextCourier != null ? 'kabul_edildi' : 'araniyor',
          createdAt: o.createdAt,
          assignedCourierId: nextCourier?.id,
          assignedAt: nextCourier != null ? DateTime.now().toIso8601String() : null,
          acknowledged: false,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    _firestoreUpdate('couriers', courierId, updates);
    _firestoreUpdate('orders', orderId, {
      'status': nextCourier != null ? 'kabul_edildi' : 'araniyor',
      'assignedCourierId': nextCourier?.id,
      'assignedAt': nextCourier != null ? DateTime.now().toIso8601String() : null,
      'acknowledged': false,
    });

    if (nextCourier != null) {
      _incrementCourierAssignedCount(nextCourier.id, orderId);
    }
    
    notifyListeners();
    return {'success': true, 'message': resultMessage};
  }

  bool reassignPackage(String orderId, String currentCourierId, String targetCourierId) {
    final nowStr = DateTime.now().toIso8601String();
    
    // Transfer order details
    _orders = _orders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          restaurantId: o.restaurantId,
          restaurantName: o.restaurantName,
          customerName: o.customerName,
          deliveryAddress: o.deliveryAddress,
          phone: o.phone,
          price: o.price,
          status: 'kabul_edildi',
          createdAt: o.createdAt,
          assignedCourierId: targetCourierId,
          assignedAt: nowStr,
          acknowledged: false,
          latitude: o.latitude,
          longitude: o.longitude,
          isDelayed: o.isDelayed,
          poolOrder: o.poolOrder,
          reportedNotReceived: o.reportedNotReceived,
        );
      }
      return o;
    }).toList();

    // Set current courier back to musait
    _couriers = _couriers.map((c) {
      if (c.id == currentCourierId) {
        return _copyCourierWith(c, status: 'musait');
      }
      if (c.id == targetCourierId) {
        return _copyCourierWith(c, status: 'aktif');
      }
      return c;
    }).toList();

    _firestoreUpdate('orders', orderId, {
      'assignedCourierId': targetCourierId,
      'status': 'kabul_edildi',
      'assignedAt': nowStr,
      'acknowledged': false
    });
    _firestoreUpdate('couriers', currentCourierId, {'status': 'musait'});
    _firestoreUpdate('couriers', targetCourierId, {'status': 'aktif'});

    notifyListeners();
    return true;
  }

  // --- Lead Forms / Contact Messages ---
  void submitContactForm(String name, String email, String phone, String company, String message) {
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final newMsg = ContactMessage(
      id: msgId,
      name: name,
      email: email,
      phone: phone,
      company: company,
      message: message,
      createdAt: DateTime.now().toIso8601String(),
    );

    _contactMessages = [newMsg, ..._contactMessages];
    _firestoreSet('contactMessages', msgId, newMsg.toJson());
    notifyListeners();
  }

  void deleteContactMessage(String id) {
    _contactMessages = _contactMessages.where((m) => m.id != id).toList();
    _firestoreDelete('contactMessages', id);
    notifyListeners();
  }

  // --- Shifts scheduler ---
  void submitShift(String courierId, String weekStartDate, Map<String, dynamic> days) {
    final courier = _couriers.firstWhere((c) => c.id == courierId);
    final shiftId = 'shift_${DateTime.now().millisecondsSinceEpoch}';
    final newShift = Shift(
      id: shiftId,
      courierId: courierId,
      companyId: courier.courierCompanyId,
      restaurantId: courier.assignedRestaurantId,
      weekStartDate: weekStartDate,
      days: days,
      status: 'submitted',
      submittedAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );

    _shifts = [
      ..._shifts.where((s) => !(s.courierId == courierId && s.weekStartDate == weekStartDate)),
      newShift
    ];

    // Notification
    final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final notif = NotificationModel(
      id: notifId,
      type: 'shift_submitted',
      targetRole: 'firma',
      targetId: courier.courierCompanyId,
      courierId: courierId,
      courierName: courier.name,
      shiftId: shiftId,
      weekStartDate: weekStartDate,
      read: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    _notifications = [notif, ..._notifications];

    _firestoreSet('shifts', shiftId, newShift.toJson());
    _firestoreSet('notifications', notifId, notif.toJson());
    notifyListeners();
  }

  void approveShift(String shiftId) {
    final reviewedAt = DateTime.now().toIso8601String();
    
    _shifts = _shifts.map((s) {
      if (s.id == shiftId) {
        return Shift(
          id: s.id,
          courierId: s.courierId,
          companyId: s.companyId,
          restaurantId: s.restaurantId,
          weekStartDate: s.weekStartDate,
          days: s.days,
          status: 'approved',
          submittedAt: s.submittedAt,
          reviewedAt: reviewedAt,
          reviewNote: s.reviewNote,
          createdAt: s.createdAt,
        );
      }
      return s;
    }).toList();

    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    
    // Notification to Courier
    final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final notif = NotificationModel(
      id: notifId,
      type: 'shift_approved',
      targetRole: 'kurye',
      targetId: shift.courierId,
      shiftId: shiftId,
      weekStartDate: shift.weekStartDate,
      read: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    _notifications = [notif, ..._notifications];
    _firestoreUpdate('shifts', shiftId, {'status': 'approved', 'reviewedAt': reviewedAt});
    _firestoreSet('notifications', notifId, notif.toJson());
    notifyListeners();
  }

  void rejectShift(String shiftId, String note) {
    final reviewedAt = DateTime.now().toIso8601String();

    _shifts = _shifts.map((s) {
      if (s.id == shiftId) {
        return Shift(
          id: s.id,
          courierId: s.courierId,
          companyId: s.companyId,
          restaurantId: s.restaurantId,
          weekStartDate: s.weekStartDate,
          days: s.days,
          status: 'rejected',
          submittedAt: s.submittedAt,
          reviewedAt: reviewedAt,
          reviewNote: note,
          createdAt: s.createdAt,
        );
      }
      return s;
    }).toList();

    final shift = _shifts.firstWhere((s) => s.id == shiftId);

    // Notification to Courier
    final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final notif = NotificationModel(
      id: notifId,
      type: 'shift_rejected',
      targetRole: 'kurye',
      targetId: shift.courierId,
      shiftId: shiftId,
      weekStartDate: shift.weekStartDate,
      message: note,
      read: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    _notifications = [notif, ..._notifications];
    _firestoreUpdate('shifts', shiftId, {'status': 'rejected', 'reviewedAt': reviewedAt, 'reviewNote': note});
    _firestoreSet('notifications', notifId, notif.toJson());
    notifyListeners();
  }

  // --- Job Posting CRUD ---
  void addJobPosting(String companyId, String title, String description, String city, String salary) {
    final postingId = 'ilan_${DateTime.now().millisecondsSinceEpoch}';
    final company = _companies.firstWhere((c) => c.id == companyId);
    
    final newPosting = JobPosting(
      id: postingId,
      companyId: companyId,
      companyName: company.name,
      title: title,
      description: description,
      city: city,
      salary: salary,
      createdAt: DateTime.now().toIso8601String(),
    );

    _jobPostings = [newPosting, ..._jobPostings];
    _firestoreSet('jobPostings', postingId, newPosting.toJson());
    notifyListeners();
  }

  void deleteJobPosting(String id) {
    _jobPostings = _jobPostings.where((j) => j.id != id).toList();
    _firestoreDelete('jobPostings', id);
    notifyListeners();
  }

  void createCourierRequest({
    required String restaurantId,
    required String type,
    required String durationDetails,
    required String motorcycleRequired,
    required int count,
    required String description,
  }) {
    final reqId = 'talep_${DateTime.now().millisecondsSinceEpoch}';
    final restaurant = _restaurants.firstWhere((r) => r.id == restaurantId);
    
    final newReq = CourierRequest(
      id: reqId,
      restaurantId: restaurantId,
      restaurantName: restaurant.name,
      type: type,
      durationDetails: durationDetails,
      motorcycleRequired: motorcycleRequired,
      count: count,
      description: description,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    _courierRequests = [newReq, ..._courierRequests];
    _firestoreSet('courierRequests', reqId, newReq.toJson());

    final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final notif = NotificationModel(
      id: notifId,
      type: 'new_courier_request',
      targetRole: 'superadmin',
      message: '${restaurant.name} şubesi yeni kurye talebi oluşturdu.',
      createdAt: DateTime.now().toIso8601String(),
      read: false,
    );
    _notifications = [notif, ..._notifications];
    _firestoreSet('notifications', notifId, notif.toJson());

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS AND SIMULATION ALGORITHMS
  // ─────────────────────────────────────────────────────────────

  Courier? _findNextAvailableCourier(Restaurant restaurant, String? excludeCourierId, OrderModel? activeOrder) {
    // 1. Get pool couriers or dedicated couriers matching restaurant
    final matchingCouriers = _couriers.where((c) {
      if (c.id == excludeCourierId) return false;
      if (c.status != 'musait' || c.isShadowBanned) return false;
      
      if (restaurant.isDedicatedMode) {
        // Dedicated mode: Must be inside restaurant's dedicatedCourierIds
        return restaurant.dedicatedCourierIds.contains(c.id);
      } else {
        // Pool mode: Must belong to the same company as the restaurant, and not be dedicated to another restaurant
        return c.courierCompanyId == restaurant.courierCompanyId && c.assignedRestaurantId == null;
      }
    }).toList();

    if (matchingCouriers.isEmpty) return null;

    // 2. Sort by distance, queuePosition, rating
    matchingCouriers.sort((a, b) {
      // Calculate distances to restaurant
      final distA = _calculateDistance(a.latitude, a.longitude, restaurant.latitude, restaurant.longitude);
      final distB = _calculateDistance(b.latitude, b.longitude, restaurant.latitude, restaurant.longitude);

      // Priority 1: Queue position
      final qComp = a.queuePosition.compareTo(b.queuePosition);
      if (qComp != 0) return qComp;

      // Priority 2: Distance (closer is better)
      final dComp = distA.compareTo(distB);
      if (dComp != 0) return dComp;

      // Priority 3: Rating (higher is better)
      return b.rating.compareTo(a.rating);
    });

    return matchingCouriers.first;
  }

  void _incrementCourierAssignedCount(String courierId, String orderId) {
    _couriers = _couriers.map((c) {
      if (c.id == courierId) {
        final newAssigned = c.assignedOrdersCount + 1;
        final newAccRate = ((c.acceptedOrdersCount / newAssigned) * 100).round();
        
        return _copyCourierWith(
          c,
          status: 'araniyor',
          assignedOrdersCount: newAssigned,
          acceptanceRate: newAccRate,
          lastAssignedOrderId: orderId,
          lastAssignedAt: DateTime.now().toIso8601String(),
        );
      }
      return c;
    }).toList();

    _firestoreUpdate('couriers', courierId, {
      'status': 'araniyor',
      'assignedOrdersCount': _couriers.firstWhere((c) => c.id == courierId).assignedOrdersCount,
      'acceptanceRate': _couriers.firstWhere((c) => c.id == courierId).acceptanceRate,
      'lastAssignedOrderId': orderId,
      'lastAssignedAt': DateTime.now().toIso8601String(),
    });
  }

  void _rotateQueuePosition(String courierId) {
    final target = _couriers.firstWhere((c) => c.id == courierId);
    final others = _couriers.where((c) => c.id != courierId).toList();
    
    // Sort others by queuePosition
    others.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
    
    // Re-assign indices sequentially
    for (int i = 0; i < others.length; i++) {
      final oldC = others[i];
      others[i] = _copyCourierWith(oldC, queuePosition: i);
    }

    final updatedTarget = _copyCourierWith(target, queuePosition: others.length);
    
    _couriers = _couriers.map((c) {
      if (c.id == courierId) return updatedTarget;
      final idx = others.indexWhere((o) => o.id == c.id);
      return idx != -1 ? others[idx] : c;
    }).toList();

    // Firebase batch updates
    for (var c in _couriers) {
      _firestoreUpdate('couriers', c.id, {'queuePosition': c.queuePosition});
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)) * 1000; // Returns distance in meters
  }

  Courier _copyCourierWith(
    Courier c, {
    String? status,
    int? queuePosition,
    int? deliveriesCount,
    int? penaltiesCount,
    double? latitude,
    double? longitude,
    bool? isAtRestaurant,
    String? arrivedAtRestaurantAt,
    double? earningsWallet,
    List<EarningsLogEntry>? earningsLog,
    double? rating,
    int? avgDeliveryTimeMinutes,
    int? performanceScore,
    int? assignedOrdersCount,
    int? acceptedOrdersCount,
    int? acceptanceRate,
    int? weeklyAcceptanceRate,
    int? dailyCancellationsCount,
    String? lastDeactivatedAt,
    bool? isShadowBanned,
    int? dailyViolationCount,
    String? lastViolationDate,
    String? shadowBannedAt,
    String? lastAssignedOrderId,
    String? lastAssignedAt,
    String? iban,
    String? pendingCompanyId,
  }) {
    return Courier(
      id: c.id,
      name: c.name,
      phone: c.phone,
      email: c.email,
      courierCompanyId: c.courierCompanyId,
      assignedRestaurantId: c.assignedRestaurantId,
      status: status ?? c.status,
      queuePosition: queuePosition ?? c.queuePosition,
      deliveriesCount: deliveriesCount ?? c.deliveriesCount,
      penaltiesCount: penaltiesCount ?? c.penaltiesCount,
      latitude: latitude ?? c.latitude,
      longitude: longitude ?? c.longitude,
      isAtRestaurant: isAtRestaurant ?? c.isAtRestaurant,
      arrivedAtRestaurantAt: arrivedAtRestaurantAt ?? c.arrivedAtRestaurantAt,
      earningsWallet: earningsWallet ?? c.earningsWallet,
      earningsLog: earningsLog ?? c.earningsLog,
      rating: rating ?? c.rating,
      avgDeliveryTimeMinutes: avgDeliveryTimeMinutes ?? c.avgDeliveryTimeMinutes,
      performanceScore: performanceScore ?? c.performanceScore,
      assignedOrdersCount: assignedOrdersCount ?? c.assignedOrdersCount,
      acceptedOrdersCount: acceptedOrdersCount ?? c.acceptedOrdersCount,
      acceptanceRate: acceptanceRate ?? c.acceptanceRate,
      weeklyAcceptanceRate: weeklyAcceptanceRate ?? c.weeklyAcceptanceRate,
      dailyCancellationsCount: dailyCancellationsCount ?? c.dailyCancellationsCount,
      lastDeactivatedAt: lastDeactivatedAt ?? c.lastDeactivatedAt,
      isShadowBanned: isShadowBanned ?? c.isShadowBanned,
      dailyViolationCount: dailyViolationCount ?? c.dailyViolationCount,
      lastViolationDate: lastViolationDate ?? c.lastViolationDate,
      shadowBannedAt: shadowBannedAt ?? c.shadowBannedAt,
      lastAssignedOrderId: lastAssignedOrderId ?? c.lastAssignedOrderId,
      lastAssignedAt: lastAssignedAt ?? c.lastAssignedAt,
      iban: iban ?? c.iban,
      pendingCompanyId: pendingCompanyId ?? c.pendingCompanyId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MOCK DEFAULTS (Mirrors AppContext.jsx initial variables)
  // ─────────────────────────────────────────────────────────────

  final Company _defaultCompany = Company(
    id: 'firma1',
    name: 'Hızlı Kurye A.Ş.',
    phone: '08503030303',
    email: 'iletisim@hizlikurye.com',
    status: 'active',
    pricing: CompanyPricing(firstPackageRate: 40, secondPackageRate: 25, thirdPackageRate: 15),
    bonuses: CompanyBonuses(monthlyBonusActive: true, monthlyBonusThreshold: 200, monthlyBonusAmount: 1500),
  );

  final List<Restaurant> _defaultRestaurants = [
    Restaurant(
      id: 'restoran1',
      name: 'Lezzet Restoranı',
      phone: '05447605359',
      email: 'restoran@kurye.com',
      address: 'Düğerek Mahallesi, Menteşe/Muğla',
      managerName: 'Mehmet Sorumlu',
      managerPhone: '05447605359',
      latitude: 37.2155,
      longitude: 28.3622,
      courierCompanyId: 'firma1',
      dedicatedCourierIds: [],
      isDedicatedMode: false,
    ),
    Restaurant(
      id: 'restoran2',
      name: 'Kebap Evi',
      phone: '05321234567',
      email: 'kebap@kurye.com',
      address: 'Kızılay, Ankara',
      managerName: 'Ahmet Sorumlu',
      managerPhone: '05321234567',
      latitude: 39.9209,
      longitude: 32.8550,
      courierCompanyId: 'firma1',
      dedicatedCourierIds: [],
      isDedicatedMode: false,
    ),
    Restaurant(
      id: 'restoran3',
      name: 'Pizza House',
      phone: '05559876543',
      email: 'pizza@kurye.com',
      address: 'Çankaya, Ankara',
      managerName: 'Veli Sorumlu',
      managerPhone: '05559876543',
      latitude: 39.9100,
      longitude: 32.8400,
      courierCompanyId: 'firma1',
      dedicatedCourierIds: ['kurye4', 'kurye5'],
      isDedicatedMode: true,
    ),
  ];

  final List<Courier> _defaultCouriers = [
    Courier(
      id: 'kurye1',
      name: 'Ahmet',
      phone: '05301111111',
      email: 'ahmet@kurye.com',
      courierCompanyId: 'firma1',
      status: 'musait',
      queuePosition: 0,
      deliveriesCount: 14,
      penaltiesCount: 1,
      latitude: 39.9208,
      longitude: 32.8541,
      isAtRestaurant: true,
      arrivedAtRestaurantAt: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      earningsWallet: 560.0,
      earningsLog: [
        EarningsLogEntry(orderId: 'siparis_init1', amount: 40.0, type: 'paket', timestamp: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), note: '1. Paket Teslimatı'),
        EarningsLogEntry(orderId: 'siparis_init2', amount: 40.0, type: 'paket', timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), note: '1. Paket Teslimatı'),
      ],
      rating: 4.9,
      avgDeliveryTimeMinutes: 16,
      performanceScore: 95,
      assignedOrdersCount: 10,
      acceptedOrdersCount: 10,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    ),
    Courier(
      id: 'kurye2',
      name: 'Mehmet',
      phone: '05302222222',
      email: 'mehmet@kurye.com',
      courierCompanyId: 'firma1',
      status: 'musait',
      queuePosition: 1,
      deliveriesCount: 18,
      penaltiesCount: 0,
      latitude: 39.9220,
      longitude: 32.8560,
      isAtRestaurant: false,
      earningsWallet: 720.0,
      earningsLog: [
        EarningsLogEntry(orderId: 'siparis_init3', amount: 40.0, type: 'paket', timestamp: DateTime.now().toIso8601String(), note: '1. Paket Teslimatı'),
      ],
      rating: 4.7,
      avgDeliveryTimeMinutes: 18,
      performanceScore: 90,
      assignedOrdersCount: 10,
      acceptedOrdersCount: 10,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    ),
    Courier(
      id: 'kurye3',
      name: 'Can',
      phone: '05303333333',
      email: 'can@kurye.com',
      courierCompanyId: 'firma1',
      status: 'musait',
      queuePosition: 2,
      deliveriesCount: 11,
      penaltiesCount: 2,
      latitude: 39.9250,
      longitude: 32.8580,
      isAtRestaurant: false,
      earningsWallet: 440.0,
      earningsLog: [],
      rating: 4.4,
      avgDeliveryTimeMinutes: 22,
      performanceScore: 82,
      assignedOrdersCount: 10,
      acceptedOrdersCount: 10,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    ),
    Courier(
      id: 'kurye4',
      name: 'Burak',
      phone: '05304444444',
      email: 'burak@kurye.com',
      courierCompanyId: 'firma1',
      assignedRestaurantId: 'restoran3',
      status: 'musait',
      queuePosition: 3,
      deliveriesCount: 15,
      penaltiesCount: 1,
      latitude: 39.9300,
      longitude: 32.8600,
      isAtRestaurant: false,
      earningsWallet: 600.0,
      earningsLog: [],
      rating: 4.8,
      avgDeliveryTimeMinutes: 17,
      performanceScore: 93,
      assignedOrdersCount: 10,
      acceptedOrdersCount: 10,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    ),
    Courier(
      id: 'kurye5',
      name: 'Mustafa',
      phone: '05305555555',
      email: 'mustafa@kurye.com',
      courierCompanyId: 'firma1',
      assignedRestaurantId: 'restoran3',
      status: 'musait',
      queuePosition: 4,
      deliveriesCount: 9,
      penaltiesCount: 3,
      latitude: 39.9100,
      longitude: 32.8400,
      isAtRestaurant: false,
      earningsWallet: 360.0,
      earningsLog: [],
      rating: 4.1,
      avgDeliveryTimeMinutes: 25,
      performanceScore: 78,
      assignedOrdersCount: 10,
      acceptedOrdersCount: 10,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    ),
  ];

  final List<JobPosting> _defaultJobPostings = [
    JobPosting(
      id: 'ilan1',
      companyId: 'firma1',
      companyName: 'Hızlı Kurye A.Ş.',
      title: 'Çankaya Bölgesi Kendi Motorlu Kurye Arayışı',
      description: 'Çankaya bölgesinde aktif çalışacak kendi motoru olan kurye arkadaşlar arıyoruz. Paket başı 40 TL + Günlük bonuslar.',
      city: 'Ankara',
      salary: 'Paket Başı 40 TL + Prim',
      createdAt: DateTime.now().toIso8601String(),
    )
  ];

  final List<CourierRequest> _defaultCourierRequests = [
    CourierRequest(
      id: 'talep1',
      restaurantId: 'restoran1',
      restaurantName: 'Lezzet Restoranı',
      type: 'daimi',
      durationDetails: 'Haftada 6 gün, 10:00 - 22:00 saatleri arası',
      motorcycleRequired: 'yes',
      count: 2,
      description: 'A2 ehliyeti olan, kılık kıyafetine özen gösteren kalıcı kurye arkadaş arıyoruz.',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    )
  ];

  final List<ContactMessage> _defaultContactMessages = [
    ContactMessage(
      id: 'msg_init1',
      name: 'Can Yılmaz',
      email: 'canyilmaz@test.com',
      phone: '05554443322',
      company: 'Burger House',
      message: 'Sisteminizin entegrasyonu hakkında bilgi almak istiyoruz. Günlük 500+ paket kapasitemiz var.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    )
  ];

  // Normalized phone formatting helper
  String _normalizePhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (!clean.startsWith('90')) {
      clean = '90$clean';
    }
    return '+$clean';
  }

  Future<Map<String, dynamic>> loginByPhone(String phone) async {
    String cleanPhone = _normalizePhone(phone);

    // 1. Search courier
    for (var c in _couriers) {
      if (_normalizePhone(c.phone) == cleanPhone) {
        final user = {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'email': c.email,
          'role': 'kurye'
        };
        _currentUser = user;
        _demoActiveCourierId = c.id;
        await _saveToLocal('currentUser', user);
        _registerTokenAndStartServices(user);
        notifyListeners();
        return {'success': true, 'role': 'kurye', 'message': 'Hoş geldiniz, ${c.name}!'};
      }
    }

    // 2. Search restaurant
    for (var r in _restaurants) {
      if (_normalizePhone(r.managerPhone) == cleanPhone || _normalizePhone(r.phone) == cleanPhone) {
        final user = {
          'id': r.id,
          'name': r.name,
          'phone': r.phone,
          'email': r.email,
          'role': 'restoran'
        };
        _currentUser = user;
        _activeRestaurantId = r.id;
        await _saveToLocal('currentUser', user);
        _registerTokenAndStartServices(user);
        notifyListeners();
        return {'success': true, 'role': 'restoran', 'message': 'Hoş geldiniz, Sorumlu ${r.managerName}! (${r.name})'};
      }
    }

    // 3. Search company
    for (var f in _companies) {
      if (_normalizePhone(f.phone) == cleanPhone) {
        final user = {
          'id': f.id,
          'name': f.name,
          'phone': f.phone,
          'email': f.email,
          'role': 'firma'
        };
        _currentUser = user;
        await _saveToLocal('currentUser', user);
        _registerTokenAndStartServices(user);
        notifyListeners();
        return {'success': true, 'role': 'firma', 'message': 'Hoş geldiniz, ${f.name} Firma Yöneticisi!'};
      }
    }

    return {'success': false, 'message': 'Bu telefon numarası kayıtlı değil.'};
  }

  Future<Map<String, dynamic>> registerCourier({
    required String phone,
    required String name,
    required String surname,
    required String livingCity,
    required String workingCity,
    required Map<String, dynamic> extraFields,
  }) async {
    final newCourier = Courier(
      id: 'kurye_${DateTime.now().millisecondsSinceEpoch}',
      name: '$name $surname',
      phone: phone,
      email: '$phone@kurye.com',
      courierCompanyId: null,
      status: 'musait',
      queuePosition: _couriers.length,
      deliveriesCount: 0,
      penaltiesCount: 0,
      latitude: 37.21 + (Random().nextDouble() - 0.5) * 0.05,
      longitude: 28.35 + (Random().nextDouble() - 0.5) * 0.05,
      isAtRestaurant: false,
      earningsWallet: 0,
      earningsLog: [],
      rating: 5.0,
      avgDeliveryTimeMinutes: 15,
      performanceScore: 100,
      assignedOrdersCount: 0,
      acceptedOrdersCount: 0,
      acceptanceRate: 100,
      weeklyAcceptanceRate: 100,
      dailyCancellationsCount: 0,
      isShadowBanned: false,
      dailyViolationCount: 0,
    );

    _couriers = [..._couriers, newCourier];
    await _saveToLocal('couriers', _couriers);
    _firestoreSet('couriers', newCourier.id, newCourier.toJson());

    final user = {
      'id': newCourier.id,
      'name': newCourier.name,
      'phone': newCourier.phone,
      'email': newCourier.email,
      'role': 'kurye'
    };
    _currentUser = user;
    _demoActiveCourierId = newCourier.id;
    await _saveToLocal('currentUser', user);
    _registerTokenAndStartServices(user);
    notifyListeners();

    return {'success': true, 'role': 'kurye', 'message': 'Kurye kaydınız başarıyla tamamlandı!'};
  }

  Future<Map<String, dynamic>> registerRestaurant({
    required String phone,
    required String name,
    required String managerName,
    required String address,
  }) async {
    final newRestaurant = Restaurant(
      id: 'restoran_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      managerName: managerName,
      managerPhone: phone,
      email: '$phone@restoran.com',
      address: address,
      latitude: 39.92 + (Random().nextDouble() - 0.5) * 0.05,
      longitude: 32.85 + (Random().nextDouble() - 0.5) * 0.05,
      isDedicatedMode: false,
      dedicatedCourierIds: [],
      courierCompanyId: 'firma1',
    );

    _restaurants = [..._restaurants, newRestaurant];
    await _saveToLocal('restaurants', _restaurants);
    _firestoreSet('restaurants', newRestaurant.id, newRestaurant.toJson());

    final user = {
      'id': newRestaurant.id,
      'name': newRestaurant.name,
      'phone': newRestaurant.phone,
      'email': newRestaurant.email,
      'role': 'restoran'
    };
    _currentUser = user;
    _activeRestaurantId = newRestaurant.id;
    await _saveToLocal('currentUser', user);
    _registerTokenAndStartServices(user);
    notifyListeners();

    return {'success': true, 'role': 'restoran', 'message': 'Restoran kaydınız başarıyla tamamlandı!'};
  }

  Future<Map<String, dynamic>> registerCompany({
    required String phone,
    required String name,
    required String address,
  }) async {
    final newCompany = Company(
      id: 'firma_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: '$phone@firma.com',
      status: 'active',
      pricing: CompanyPricing(firstPackageRate: 40, secondPackageRate: 25, thirdPackageRate: 15),
      bonuses: CompanyBonuses(monthlyBonusActive: true, monthlyBonusThreshold: 200, monthlyBonusAmount: 1500),
    );

    _companies = [..._companies, newCompany];
    await _saveToLocal('companies', _companies);
    _firestoreSet('companies', newCompany.id, newCompany.toJson());

    final user = {
      'id': newCompany.id,
      'name': newCompany.name,
      'phone': newCompany.phone,
      'email': newCompany.email,
      'role': 'firma'
    };
    _currentUser = user;
    await _saveToLocal('currentUser', user);
    _registerTokenAndStartServices(user);
    notifyListeners();

    return {'success': true, 'role': 'firma', 'message': 'Kurye firması kaydınız başarıyla tamamlandı!'};
  }

  void updateRestaurant(String id, Map<String, dynamic> updates) {
    _restaurants = _restaurants.map((r) {
      if (r.id == id) {
        final data = r.toJson();
        data.addAll(updates);
        return Restaurant.fromJson(data);
      }
      return r;
    }).toList();
    _firestoreUpdate('restaurants', id, updates);
    notifyListeners();
  }

  void updateCourier(String id, Map<String, dynamic> updates) {
    _couriers = _couriers.map((c) {
      if (c.id == id) {
        final data = c.toJson();
        data.addAll(updates);
        return Courier.fromJson(data);
      }
      return c;
    }).toList();
    _firestoreUpdate('couriers', id, updates);
    notifyListeners();
  }

  void assignCourierToRequest(String requestId, String courierId) {
    _courierRequests = _courierRequests.map((r) {
      if (r.id == requestId) {
        final data = r.toJson();
        data['status'] = 'approved';
        data['assignedCourierId'] = courierId;
        return CourierRequest.fromJson(data);
      }
      return r;
    }).toList();
    
    final req = _courierRequests.firstWhere((r) => r.id == requestId);
    updateCourier(courierId, {'assignedRestaurantId': req.restaurantId});
    _firestoreUpdate('courierRequests', requestId, {'status': 'approved', 'assignedCourierId': courierId});
    notifyListeners();
  }

  @override
  void dispose() {
    _assignmentTimer?.cancel();
    super.dispose();
  }
}

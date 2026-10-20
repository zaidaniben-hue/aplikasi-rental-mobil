import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;
  bool get isConnected => _isInitialized && _client != null;

  static const String defaultUrl = 'https://gmvkixribojgsvnabisn.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtdmtpeHJpYm9qZ3N2bmFiaXNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5NDI4NjQsImV4cCI6MjEwNzUxODg2NH0.p-jMWqtXiRApn2q59mopo6ngdKfhlA8bjRtGddfyAoc';

  static String sanitizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - '/rest/v1'.length);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  // Supabase Configuration
  String? _supabaseUrl = defaultUrl;
  String? _supabaseAnonKey = defaultAnonKey;

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;

  Future<void> initialize({String? url, String? anonKey}) async {
    final targetUrl = sanitizeUrl(url ?? _supabaseUrl ?? defaultUrl);
    final targetKey = (anonKey ?? _supabaseAnonKey ?? defaultAnonKey).trim();

    try {
      await Supabase.initialize(
        url: targetUrl,
        // ignore: deprecated_member_use
        anonKey: targetKey,
        debug: true,
      );
      _client = Supabase.instance.client;
      _supabaseUrl = targetUrl;
      _supabaseAnonKey = targetKey;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase belum diinisialisasi. Hubungkan dengan kredensial Supabase Anda di menu Pengaturan.');
    }
    return _client!;
  }

  // ==========================================
  // SUPABASE DATABASE FETCH OPERATIONS
  // ==========================================

  /// Fetch all fleet vehicles from Supabase
  Future<List<Vehicle>> fetchVehicles() async {
    if (!isConnected) return [];
    try {
      final response = await client
          .from('vehicles')
          .select()
          .order('brand', ascending: true);
      return (response as List).map((row) => Vehicle.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('Supabase fetchVehicles error: $e');
      return [];
    }
  }

  /// Fetch all customers from Supabase
  Future<List<Customer>> fetchCustomers() async {
    if (!isConnected) return [];
    try {
      final response = await client
          .from('customers')
          .select()
          .order('full_name', ascending: true);
      return (response as List).map((row) => Customer.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('Supabase fetchCustomers error: $e');
      return [];
    }
  }

  /// Fetch all rentals from Supabase
  Future<List<Rental>> fetchRentals() async {
    if (!isConnected) return [];
    try {
      final response = await client
          .from('rentals')
          .select('*, vehicle:vehicles(*), customer:customers(*)')
          .order('start_time', ascending: false);
      return (response as List).map((row) => Rental.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('Supabase fetchRentals error: $e');
      return [];
    }
  }

  /// Fetch all maintenance rules from Supabase
  Future<List<MaintenanceRule>> fetchMaintenanceRules() async {
    if (!isConnected) return [];
    try {
      final response = await client
          .from('maintenance_rules')
          .select()
          .order('service_type', ascending: true);
      return (response as List).map((row) => MaintenanceRule.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('Supabase fetchMaintenanceRules error: $e');
      return [];
    }
  }

  /// Fetch all inspections from Supabase
  Future<List<Inspection>> fetchInspections() async {
    if (!isConnected) return [];
    try {
      final response = await client
          .from('inspections')
          .select()
          .order('created_at', ascending: true);
      return (response as List).map((row) => Inspection.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('Supabase fetchInspections error: $e');
      return [];
    }
  }

  // ==========================================
  // SUPABASE SEEDING & SYNC
  // ==========================================

  /// Auto-seed Supabase database if tables are empty
  Future<bool> seedDatabaseIfEmpty({
    required List<Vehicle> vehicles,
    required List<Customer> customers,
    required List<MaintenanceRule> rules,
    required List<Rental> rentals,
    required List<Inspection> inspections,
  }) async {
    if (!isConnected) return false;
    try {
      final existing = await client.from('vehicles').select('id').limit(1);
      if ((existing as List).isNotEmpty) {
        debugPrint('Supabase database already has vehicles; skipping seed.');
        return false;
      }

      debugPrint('Seeding Supabase database with initial fleet, customers, rules, and rentals...');

      // 1. Vehicles
      if (vehicles.isNotEmpty) {
        await client.from('vehicles').upsert(vehicles.map((v) => v.toJson()).toList());
      }
      // 2. Customers
      if (customers.isNotEmpty) {
        await client.from('customers').upsert(customers.map((c) => c.toJson()).toList());
      }
      // 3. Maintenance Rules
      if (rules.isNotEmpty) {
        await client.from('maintenance_rules').upsert(rules.map((r) => r.toJson()).toList());
      }
      // 4. Rentals
      if (rentals.isNotEmpty) {
        await client.from('rentals').upsert(rentals.map((r) => r.toJson()).toList());
      }
      // 5. Inspections
      if (inspections.isNotEmpty) {
        await client.from('inspections').upsert(inspections.map((i) => i.toJson()).toList());
      }

      debugPrint('Supabase database seeded successfully!');
      return true;
    } catch (e) {
      debugPrint('Supabase seedDatabaseIfEmpty error: $e');
      return false;
    }
  }

  // ==========================================
  // SUPABASE MUTATION OPERATIONS (CRUD)
  // ==========================================

  /// Upsert Vehicle
  Future<void> upsertVehicle(Vehicle vehicle) async {
    if (!isConnected) return;
    try {
      await client.from('vehicles').upsert(vehicle.toJson());
    } catch (e) {
      debugPrint('Supabase upsertVehicle error: $e');
    }
  }

  /// Update Vehicle Status & Odometer
  Future<void> updateVehicleStatus(String vehicleId, VehicleStatus status, {int? odometer}) async {
    if (!isConnected) return;
    try {
      final Map<String, dynamic> data = {'status': status.code};
      if (odometer != null) {
        data['odometer_current'] = odometer;
      }
      await client.from('vehicles').update(data).eq('id', vehicleId);
    } catch (e) {
      debugPrint('Supabase updateVehicleStatus error: $e');
    }
  }

  /// Upsert Customer
  Future<void> upsertCustomer(Customer customer) async {
    if (!isConnected) return;
    try {
      await client.from('customers').upsert(customer.toJson());
    } catch (e) {
      debugPrint('Supabase upsertCustomer error: $e');
    }
  }

  /// Insert Rental
  Future<void> insertRental(Rental rental) async {
    if (!isConnected) return;
    try {
      await client.from('rentals').insert(rental.toJson());
    } catch (e) {
      debugPrint('Supabase insertRental error: $e');
    }
  }

  /// Update Rental
  Future<void> updateRental(Rental rental) async {
    if (!isConnected) return;
    try {
      await client.from('rentals').update(rental.toJson()).eq('id', rental.id);
    } catch (e) {
      debugPrint('Supabase updateRental error: $e');
    }
  }

  /// Insert Inspection
  Future<void> insertInspection(Inspection inspection) async {
    if (!isConnected) return;
    try {
      await client.from('inspections').insert(inspection.toJson());
    } catch (e) {
      debugPrint('Supabase insertInspection error: $e');
    }
  }

  /// Update Maintenance Rule after service
  Future<void> updateMaintenanceRule({
    required String vehicleId,
    required String serviceType,
    required int lastServiceKm,
    required DateTime lastServiceDate,
  }) async {
    if (!isConnected) return;
    try {
      await client.from('maintenance_rules').update({
        'last_service_km': lastServiceKm,
        'last_service_date': lastServiceDate.toIso8601String().substring(0, 10),
      }).eq('vehicle_id', vehicleId).eq('service_type', serviceType);
    } catch (e) {
      debugPrint('Supabase updateMaintenanceRule error: $e');
    }
  }

  /// Log Physical Maintenance to maintenance_logs
  Future<void> logMaintenance({
    required String id,
    required String vehicleId,
    String? ruleId,
    required String serviceType,
    required String workshopName,
    required int odometerAtService,
    required double totalCost,
    String? description,
  }) async {
    if (!isConnected) return;
    try {
      await client.from('maintenance_logs').insert({
        'id': id,
        'vehicle_id': vehicleId,
        'rule_id': ruleId,
        'service_type': serviceType,
        'workshop_name': workshopName,
        'entry_date': DateTime.now().toIso8601String().substring(0, 10),
        'completed_date': DateTime.now().toIso8601String().substring(0, 10),
        'odometer_at_service': odometerAtService,
        'total_cost': totalCost,
        'description': description ?? 'Perawatan berkala armada',
        'status': 'COMPLETED',
      });
    } catch (e) {
      debugPrint('Supabase logMaintenance error: $e');
    }
  }

  // ==========================================
  // EDGE FUNCTIONS
  // ==========================================

  // Edge Function: validate-and-book
  Future<Map<String, dynamic>> invokeValidateAndBook({
    required String customerId,
    required String vehicleId,
    required DateTime startTime,
    required DateTime plannedEndTime,
    required double dailyRate,
    double downPayment = 0,
    double depositAmount = 0,
    String? notes,
  }) async {
    final response = await client.functions.invoke(
      'validate-and-book',
      body: {
        'customerId': customerId,
        'vehicleId': vehicleId,
        'startTime': startTime.toIso8601String(),
        'plannedEndTime': plannedEndTime.toIso8601String(),
        'dailyRate': dailyRate,
        'downPayment': downPayment,
        'depositAmount': depositAmount,
        'notes': notes,
      },
    );

    if (response.status != 200 && response.status != 201) {
      final data = response.data;
      final msg = data is Map ? data['error'] : 'Gagal membuat reservasi';
      throw Exception(msg);
    }

    return Map<String, dynamic>.from(response.data);
  }

  // Edge Function: checkout-rental
  Future<Map<String, dynamic>> invokeCheckout({
    required String rentalId,
    required int odometerStart,
    required int fuelLevel,
    required List<BodyDefectPoint> defects,
    String? notes,
    double? depositReceived,
    String? paymentMethod,
  }) async {
    final response = await client.functions.invoke(
      'checkout-rental',
      body: {
        'rentalId': rentalId,
        'odometerStart': odometerStart,
        'fuelLevel': fuelLevel,
        'bodyDefects': defects.map((d) => d.toJson()).toList(),
        'notes': notes,
        'depositReceived': depositReceived,
        'paymentMethod': paymentMethod,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final msg = data is Map ? data['error'] : 'Gagal memproses check-out';
      throw Exception(msg);
    }

    return Map<String, dynamic>.from(response.data);
  }

  // Edge Function: checkin-settlement
  Future<Map<String, dynamic>> invokeCheckin({
    required String rentalId,
    required int odometerEnd,
    required int fuelLevelEnd,
    DateTime? actualEndTime,
    List<BodyDefectPoint>? defectsEnd,
    double damageFeeManual = 0,
    String? notes,
    bool vehicleNeedsMaintenance = false,
  }) async {
    final response = await client.functions.invoke(
      'checkin-settlement',
      body: {
        'rentalId': rentalId,
        'odometerEnd': odometerEnd,
        'fuelLevelEnd': fuelLevelEnd,
        'actualEndTime': (actualEndTime ?? DateTime.now()).toIso8601String(),
        'bodyDefectsEnd': defectsEnd?.map((d) => d.toJson()).toList() ?? [],
        'damageFeeManual': damageFeeManual,
        'notes': notes,
        'vehicleNeedsMaintenance': vehicleNeedsMaintenance,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final msg = data is Map ? data['error'] : 'Gagal memproses check-in';
      throw Exception(msg);
    }

    return Map<String, dynamic>.from(response.data);
  }

  // Edge Function: maintenance-monitor
  Future<Map<String, dynamic>> invokeMaintenanceMonitor() async {
    final response = await client.functions.invoke('maintenance-monitor');
    if (response.status != 200) {
      throw Exception('Gagal mengevaluasi pemeliharaan armada');
    }
    return Map<String, dynamic>.from(response.data);
  }
}

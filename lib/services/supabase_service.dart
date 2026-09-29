import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;
  bool get isConnected => _isInitialized && _client != null;

  // Supabase Configuration
  String? _supabaseUrl;
  String? _supabaseAnonKey;

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;

  Future<void> initialize({required String url, required String anonKey}) async {
    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: true,
      );
      _client = Supabase.instance.client;
      _supabaseUrl = url;
      _supabaseAnonKey = anonKey;
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

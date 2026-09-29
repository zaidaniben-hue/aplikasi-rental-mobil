import 'dart:convert';

enum VehicleStatus {
  tersedia('TERSEDIA', 'Tersedia', 0xFF10B981),
  booking('BOOKING', 'Booking', 0xFF3B82F6),
  disewa('DISEWA', 'Disewa', 0xFF8B5CF6),
  perawatan('PERAWATAN', 'Perawatan', 0xFFF59E0B),
  tidakAktif('TIDAK_AKTIF', 'Tidak Aktif', 0xFFEF4444);

  final String code;
  final String label;
  final int colorValue;
  const VehicleStatus(this.code, this.label, this.colorValue);

  static VehicleStatus fromString(String? val) {
    return VehicleStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == (val ?? '').toUpperCase(),
      orElse: () => VehicleStatus.tersedia,
    );
  }
}

enum HealthLevel {
  hijau('HIJAU', 'Aman (Prima)', 0xFF10B981),
  kuning('KUNING', 'Siaga (Mendekati Servis)', 0xFFF59E0B),
  merah('MERAH', 'Jatuh Tempo (Kunci Unit)', 0xFFEF4444);

  final String code;
  final String label;
  final int colorValue;
  const HealthLevel(this.code, this.label, this.colorValue);

  static HealthLevel fromString(String? val) {
    return HealthLevel.values.firstWhere(
      (e) => e.code.toUpperCase() == (val ?? '').toUpperCase(),
      orElse: () => HealthLevel.hijau,
    );
  }
}

enum UserRole {
  frontDesk('FRONT_DESK', 'Front Desk / Kasir'),
  mechanic('MECHANIC', 'Koordinator Armada / Mekanik'),
  manager('MANAGER', 'Pemilik / Manajer Operasional');

  final String code;
  final String label;
  const UserRole(this.code, this.label);
}

class Vehicle {
  final String id;
  final String plateNumber;
  final String vin;
  final String engineNumber;
  final String brand;
  final String model;
  final int yearMade;
  final String transmission; // 'MANUAL' | 'OTOMATIS'
  final String fuelType; // 'BENSIN' | 'DIESEL' | 'HYBRID' | 'LISTRIK'
  final String category; // 'CITY_CAR' | 'MPV' | 'SUV' | 'MINIBUS'
  int odometerCurrent;
  VehicleStatus status;
  final double dailyRate;
  final String? photoUrl;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.vin,
    required this.engineNumber,
    required this.brand,
    required this.model,
    required this.yearMade,
    required this.transmission,
    required this.fuelType,
    required this.category,
    required this.odometerCurrent,
    required this.status,
    required this.dailyRate,
    this.photoUrl,
    this.isActive = true,
  });

  String get displayName => '$brand $model ($plateNumber)';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      vin: json['vin']?.toString() ?? '',
      engineNumber: json['engine_number']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      yearMade: (json['year_made'] as num?)?.toInt() ?? 2022,
      transmission: json['transmission']?.toString() ?? 'OTOMATIS',
      fuelType: json['fuel_type']?.toString() ?? 'BENSIN',
      category: json['category']?.toString() ?? 'MPV',
      odometerCurrent: (json['odometer_current'] as num?)?.toInt() ?? 0,
      status: VehicleStatus.fromString(json['status']?.toString()),
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 350000,
      photoUrl: json['photo_url']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plate_number': plateNumber,
    'vin': vin,
    'engine_number': engineNumber,
    'brand': brand,
    'model': model,
    'year_made': yearMade,
    'transmission': transmission,
    'fuel_type': fuelType,
    'category': category,
    'odometer_current': odometerCurrent,
    'status': status.code,
    'daily_rate': dailyRate,
    'photo_url': photoUrl,
    'is_active': isActive,
  };
}

class Customer {
  final String id;
  final String nik;
  final String fullName;
  final String simNumber;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String? ktpPhotoUrl;
  final bool isBlacklisted;
  final String? blacklistReason;

  Customer({
    required this.id,
    required this.nik,
    required this.fullName,
    required this.simNumber,
    required this.phoneNumber,
    this.email,
    this.address,
    this.ktpPhotoUrl,
    this.isBlacklisted = false,
    this.blacklistReason,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      simNumber: json['sim_number']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      ktpPhotoUrl: json['ktp_photo_url']?.toString(),
      isBlacklisted: json['is_blacklisted'] ?? false,
      blacklistReason: json['blacklist_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nik': nik,
    'full_name': fullName,
    'sim_number': simNumber,
    'phone_number': phoneNumber,
    'email': email,
    'address': address,
    'ktp_photo_url': ktpPhotoUrl,
    'is_blacklisted': isBlacklisted,
    'blacklist_reason': blacklistReason,
  };
}

class BodyDefectPoint {
  final String id;
  final String view; // 'front' | 'back' | 'left' | 'right'
  final double x; // Relative position 0.0 to 1.0
  final double y; // Relative position 0.0 to 1.0
  final String type; // 'scratch' | 'dent' | 'broken'
  final String severity; // 'low' | 'medium' | 'high'
  final String notes;

  BodyDefectPoint({
    required this.id,
    required this.view,
    required this.x,
    required this.y,
    required this.type,
    this.severity = 'medium',
    this.notes = '',
  });

  factory BodyDefectPoint.fromJson(Map<String, dynamic> json) {
    return BodyDefectPoint(
      id: json['id']?.toString() ?? '',
      view: json['view']?.toString() ?? 'front',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'scratch',
      severity: json['severity']?.toString() ?? 'medium',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'view': view,
    'x': x,
    'y': y,
    'type': type,
    'severity': severity,
    'notes': notes,
  };
}

class Inspection {
  final String id;
  final String rentalId;
  final String vehicleId;
  final String type; // 'CHECK_OUT' | 'CHECK_IN'
  final int odometer;
  final int fuelLevel; // 1 to 8
  final List<BodyDefectPoint> bodyDefects;
  final String notes;
  final String? inspectorId;
  final DateTime createdAt;

  Inspection({
    required this.id,
    required this.rentalId,
    required this.vehicleId,
    required this.type,
    required this.odometer,
    required this.fuelLevel,
    required this.bodyDefects,
    this.notes = '',
    this.inspectorId,
    required this.createdAt,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    List<BodyDefectPoint> defects = [];
    if (json['body_defects'] != null) {
      final dynamic raw = json['body_defects'];
      final List list = raw is String ? jsonDecode(raw) : (raw as List);
      defects = list.map((item) => BodyDefectPoint.fromJson(Map<String, dynamic>.from(item))).toList();
    }

    return Inspection(
      id: json['id']?.toString() ?? '',
      rentalId: json['rental_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CHECK_OUT',
      odometer: (json['odometer'] as num?)?.toInt() ?? 0,
      fuelLevel: (json['fuel_level'] as num?)?.toInt() ?? 8,
      bodyDefects: defects,
      notes: json['notes']?.toString() ?? '',
      inspectorId: json['inspector_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class Rental {
  final String id;
  final String transactionCode;
  final String vehicleId;
  final String customerId;
  final DateTime startTime;
  final DateTime plannedEndTime;
  DateTime? actualEndTime;
  final double dailyRate;
  final int durationDays;
  final double baseAmount;
  double overtimeHours;
  double overtimeFee;
  double fuelFee;
  double damageFee;
  double totalAmount;
  final double depositAmount;
  final double downPayment;
  double refundDeposit;
  final String paymentMethod;
  String paymentStatus;
  String rentalStatus; // 'DRAFT' | 'BOOKED' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED'
  final String? notes;
  Vehicle? vehicle;
  Customer? customer;

  Rental({
    required this.id,
    required this.transactionCode,
    required this.vehicleId,
    required this.customerId,
    required this.startTime,
    required this.plannedEndTime,
    this.actualEndTime,
    required this.dailyRate,
    required this.durationDays,
    required this.baseAmount,
    this.overtimeHours = 0,
    this.overtimeFee = 0,
    this.fuelFee = 0,
    this.damageFee = 0,
    required this.totalAmount,
    this.depositAmount = 0,
    this.downPayment = 0,
    this.refundDeposit = 0,
    this.paymentMethod = 'CASH',
    this.paymentStatus = 'PENDING',
    this.rentalStatus = 'BOOKED',
    this.notes,
    this.vehicle,
    this.customer,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id']?.toString() ?? '',
      transactionCode: json['transaction_code']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      startTime: DateTime.parse(json['start_time']),
      plannedEndTime: DateTime.parse(json['planned_end_time']),
      actualEndTime: json['actual_end_time'] != null ? DateTime.parse(json['actual_end_time']) : null,
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0,
      overtimeFee: (json['overtime_fee'] as num?)?.toDouble() ?? 0,
      fuelFee: (json['fuel_fee'] as num?)?.toDouble() ?? 0,
      damageFee: (json['damage_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0,
      refundDeposit: (json['refund_deposit'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
      paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
      rentalStatus: json['rental_status']?.toString() ?? 'BOOKED',
      notes: json['notes']?.toString(),
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(Map<String, dynamic>.from(json['vehicle'])) : null,
      customer: json['customer'] != null ? Customer.fromJson(Map<String, dynamic>.from(json['customer'])) : null,
    );
  }
}

class MaintenanceRule {
  final String id;
  final String vehicleId;
  final String serviceType;
  final int? intervalKm;
  final int? intervalDays;
  final int lastServiceKm;
  final DateTime lastServiceDate;

  MaintenanceRule({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    this.intervalKm,
    this.intervalDays,
    required this.lastServiceKm,
    required this.lastServiceDate,
  });

  factory MaintenanceRule.fromJson(Map<String, dynamic> json) {
    return MaintenanceRule(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '',
      intervalKm: (json['interval_km'] as num?)?.toInt(),
      intervalDays: (json['interval_days'] as num?)?.toInt(),
      lastServiceKm: (json['last_service_km'] as num?)?.toInt() ?? 0,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date']) 
          : DateTime.now(),
    );
  }
}

class MaintenanceAlert {
  final String serviceType;
  final HealthLevel level;
  final int? kmRemaining;
  final int? daysRemaining;

  MaintenanceAlert({
    required this.serviceType,
    required this.level,
    this.kmRemaining,
    this.daysRemaining,
  });
}

class VehicleHealth {
  final String vehicleId;
  final HealthLevel overallHealth;
  final List<MaintenanceAlert> alerts;

  VehicleHealth({
    required this.vehicleId,
    required this.overallHealth,
    required this.alerts,
  });
}

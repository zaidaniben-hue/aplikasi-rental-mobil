import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/mock_data.dart';

class AppState extends ChangeNotifier {
  // Authentication State
  bool _isAuthenticated = false;
  String _currentUsername = 'Kasir Utama';
  String _currentUserEmail = 'kasir@rentdesk.id';

  bool get isAuthenticated => _isAuthenticated;
  String get currentUsername => _currentUsername;
  String get currentUserEmail => _currentUserEmail;

  bool login({
    required String usernameOrEmail,
    required String password,
    required UserRole role,
  }) {
    if (usernameOrEmail.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }
    _isAuthenticated = true;
    _currentRole = role;
    _currentUsername = usernameOrEmail.contains('@')
        ? usernameOrEmail.split('@').first
        : usernameOrEmail.trim();
    _currentUserEmail = usernameOrEmail.contains('@')
        ? usernameOrEmail.trim()
        : '${usernameOrEmail.toLowerCase().replaceAll(' ', '')}@rentdesk.id';
    notifyListeners();
    return true;
  }

  void logout() {
    _isAuthenticated = false;
    _currentTabIndex = 0;
    notifyListeners();
  }

  // Active User Role
  UserRole _currentRole = UserRole.frontDesk;
  UserRole get currentRole => _currentRole;

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // Active Tab Index
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Data Collections
  List<Vehicle> _vehicles = [];
  List<Customer> _customers = [];
  List<Rental> _rentals = [];
  final List<Inspection> _inspections = [];
  List<MaintenanceRule> _maintenanceRules = [];

  List<Vehicle> get vehicles => _vehicles;
  List<Customer> get customers => _customers;
  List<Rental> get rentals => _rentals;
  List<Inspection> get inspections => _inspections;
  List<MaintenanceRule> get maintenanceRules => _maintenanceRules;

  // Selected Items for Master-Detail Views
  Vehicle? _selectedVehicle;
  Rental? _selectedRental;

  Vehicle? get selectedVehicle => _selectedVehicle;
  Rental? get selectedRental => _selectedRental;

  void selectVehicle(Vehicle? v) {
    _selectedVehicle = v;
    notifyListeners();
  }

  void selectRental(Rental? r) {
    _selectedRental = r;
    notifyListeners();
  }

  // Search & Filter State
  String _vehicleSearchQuery = '';
  VehicleStatus? _statusFilter;
  String? _transmissionFilter;
  String? _categoryFilter;

  String get vehicleSearchQuery => _vehicleSearchQuery;
  VehicleStatus? get statusFilter => _statusFilter;
  String? get transmissionFilter => _transmissionFilter;
  String? get categoryFilter => _categoryFilter;

  void setVehicleSearch(String q) {
    _vehicleSearchQuery = q.toLowerCase();
    notifyListeners();
  }

  void setStatusFilter(VehicleStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTransmissionFilter(String? trans) {
    _transmissionFilter = trans;
    notifyListeners();
  }

  void setCategoryFilter(String? cat) {
    _categoryFilter = cat;
    notifyListeners();
  }

  void clearFilters() {
    _vehicleSearchQuery = '';
    _statusFilter = null;
    _transmissionFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  // Filtered Vehicles for Data Grid & Matrix (<200ms latency)
  List<Vehicle> get filteredVehicles {
    return _vehicles.where((v) {
      if (_statusFilter != null && v.status != _statusFilter) return false;
      if (_transmissionFilter != null && v.transmission != _transmissionFilter) return false;
      if (_categoryFilter != null && v.category != _categoryFilter) return false;

      if (_vehicleSearchQuery.isNotEmpty) {
        final matchesPlate = v.plateNumber.toLowerCase().contains(_vehicleSearchQuery);
        final matchesBrand = v.brand.toLowerCase().contains(_vehicleSearchQuery);
        final matchesModel = v.model.toLowerCase().contains(_vehicleSearchQuery);
        if (!matchesPlate && !matchesBrand && !matchesModel) return false;
      }
      return true;
    }).toList();
  }

  // Initialize Data
  void loadInitialData() {
    _vehicles = SeedData.getVehicles();
    _customers = SeedData.getCustomers();
    _maintenanceRules = SeedData.getMaintenanceRules();
    _rentals = SeedData.getRentals(_vehicles, _customers);

    // Initial inspection for active rental
    if (_rentals.isNotEmpty) {
      final activeRental = _rentals.first;
      _inspections.add(
        Inspection(
          id: 'insp-001',
          rentalId: activeRental.id,
          vehicleId: activeRental.vehicleId,
          type: 'CHECK_OUT',
          odometer: 48900,
          fuelLevel: 8,
          bodyDefects: [
            BodyDefectPoint(
              id: 'def-1',
              view: 'front',
              x: 0.35,
              y: 0.65,
              type: 'scratch',
              severity: 'low',
              notes: 'Goresan tipis bumper depan kiri',
            ),
          ],
          notes: 'Serah terima unit ke pelanggan',
          createdAt: activeRental.startTime,
        ),
      );
    }

    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first;
    }
    if (_rentals.isNotEmpty) {
      _selectedRental = _rentals.first;
    }

    evaluateAllMaintenance();
    notifyListeners();
  }

  // Anti Double-Booking Availability Checker
  bool isVehicleAvailable({
    required String vehicleId,
    required DateTime start,
    required DateTime end,
    String? excludeRentalId,
  }) {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    if (vehicle.status == VehicleStatus.tidakAktif || vehicle.status == VehicleStatus.perawatan) {
      return false;
    }

    for (final r in _rentals) {
      if (r.vehicleId != vehicleId) continue;
      if (r.rentalStatus != 'BOOKED' && r.rentalStatus != 'ACTIVE') continue;
      if (excludeRentalId != null && r.id == excludeRentalId) continue;

      // Overlap condition: start < r.plannedEndTime && end > r.startTime
      if (start.isBefore(r.plannedEndTime) && end.isAfter(r.startTime)) {
        return false;
      }
    }
    return true;
  }

  // Create Rental / Booking
  String? createBooking({
    required String customerId,
    required String vehicleId,
    required DateTime startTime,
    required DateTime plannedEndTime,
    required double dailyRate,
    double downPayment = 0,
    double depositAmount = 0,
    String? notes,
  }) {
    // 1. Blacklist check
    final customer = _customers.firstWhere((c) => c.id == customerId);
    if (customer.isBlacklisted) {
      return 'DITOLAK: Pelanggan terdaftar dalam Daftar Hitam (Blacklist).\nAlasan: ${customer.blacklistReason}';
    }

    // 2. Double-booking check
    final available = isVehicleAvailable(
      vehicleId: vehicleId,
      start: startTime,
      end: plannedEndTime,
    );
    if (!available) {
      return 'KONFLIK JADWAL: Unit kendaraan sudah dibooking/disewa pada rentang tanggal tersebut.';
    }

    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    final diffHours = plannedEndTime.difference(startTime).inHours;
    final durationDays = (diffHours / 24).ceil().clamp(1, 999);
    final baseAmount = durationDays * dailyRate;

    final dateStr = startTime.toIso8601String().substring(0, 10).replaceAll('-', '');
    final suffix = (1000 + _rentals.length * 7).toString();
    final transactionCode = 'RNT-$dateStr-$suffix';

    final newRental = Rental(
      id: 'r-${DateTime.now().millisecondsSinceEpoch}',
      transactionCode: transactionCode,
      vehicleId: vehicleId,
      customerId: customerId,
      startTime: startTime,
      plannedEndTime: plannedEndTime,
      dailyRate: dailyRate,
      durationDays: durationDays,
      baseAmount: baseAmount,
      totalAmount: baseAmount,
      downPayment: downPayment,
      depositAmount: depositAmount,
      paymentMethod: 'TRANSFER',
      paymentStatus: downPayment > 0 ? 'DOWN_PAYMENT' : 'PENDING',
      rentalStatus: 'BOOKED',
      notes: notes,
      vehicle: vehicle,
      customer: customer,
    );

    _rentals.insert(0, newRental);

    // If starting within 24 hours, update vehicle to BOOKING
    if (startTime.difference(DateTime.now()).inHours <= 24 && vehicle.status == VehicleStatus.tersedia) {
      vehicle.status = VehicleStatus.booking;
    }

    notifyListeners();
    return null; // Success
  }

  // Check-Out Handover
  String? processCheckOut({
    required String rentalId,
    required int odometerStart,
    required int fuelLevel,
    required List<BodyDefectPoint> defects,
    String? notes,
    double? depositReceived,
  }) {
    final rental = _rentals.firstWhere((r) => r.id == rentalId);
    if (rental.rentalStatus == 'ACTIVE') {
      return 'Transaksi ini sudah dalam status AKTIF.';
    }

    final vehicle = _vehicles.firstWhere((v) => v.id == rental.vehicleId);

    // Record Inspection
    final inspection = Inspection(
      id: 'insp-${DateTime.now().millisecondsSinceEpoch}',
      rentalId: rentalId,
      vehicleId: vehicle.id,
      type: 'CHECK_OUT',
      odometer: odometerStart,
      fuelLevel: fuelLevel,
      bodyDefects: defects,
      notes: notes ?? 'Inspeksi serah terima check-out',
      createdAt: DateTime.now(),
    );
    _inspections.add(inspection);

    // Update Vehicle
    vehicle.status = VehicleStatus.disewa;
    vehicle.odometerCurrent = odometerStart;

    // Update Rental
    rental.rentalStatus = 'ACTIVE';
    if (depositReceived != null && depositReceived > 0) {
      // update deposit
    }

    notifyListeners();
    return null; // Success
  }

  // Check-In Return
  Map<String, dynamic>? processCheckIn({
    required String rentalId,
    required int odometerEnd,
    required int fuelLevelEnd,
    required DateTime actualEndTime,
    required List<BodyDefectPoint> defectsEnd,
    double damageFee = 0,
    double fuelCostPerBar = 35000,
    String? notes,
    bool vehicleNeedsMaintenance = false,
  }) {
    final rental = _rentals.firstWhere((r) => r.id == rentalId);
    final vehicle = _vehicles.firstWhere((v) => v.id == rental.vehicleId);

    // Fetch checkout inspection
    final checkoutInsp = _inspections.lastWhere(
      (i) => i.rentalId == rentalId && i.type == 'CHECK_OUT',
      orElse: () => Inspection(
        id: '',
        rentalId: rentalId,
        vehicleId: vehicle.id,
        type: 'CHECK_OUT',
        odometer: vehicle.odometerCurrent,
        fuelLevel: 8,
        bodyDefects: [],
        createdAt: rental.startTime,
      ),
    );

    if (odometerEnd < checkoutInsp.odometer) {
      return {'error': 'Odometer akhir tidak boleh lebih kecil dari odometer awal (${checkoutInsp.odometer} km)'};
    }

    // Overtime Calculation
    // Grace period: 60 minutes. >5 hours: full 1 day
    double overtimeHours = 0;
    double overtimeFee = 0;
    final diffMinutes = actualEndTime.difference(rental.plannedEndTime).inMinutes;

    if (diffMinutes > 60) {
      overtimeHours = ((diffMinutes - 60) / 60).ceilToDouble();
      if (overtimeHours > 5) {
        overtimeFee = rental.dailyRate;
      } else {
        overtimeFee = overtimeHours * (rental.dailyRate * 0.10);
      }
    }

    // Fuel Fee
    final fuelDiff = checkoutInsp.fuelLevel - fuelLevelEnd;
    double fuelFee = 0;
    if (fuelDiff > 0) {
      fuelFee = fuelDiff * fuelCostPerBar;
    }

    // Settlement
    final totalAmount = rental.baseAmount + overtimeFee + fuelFee + damageFee;
    final totalPrepaid = rental.downPayment + rental.depositAmount;
    double netDue = totalAmount - totalPrepaid;
    double refundDeposit = 0;

    if (netDue < 0) {
      refundDeposit = netDue.abs();
      netDue = 0;
    }

    // Save Return Inspection
    final inspection = Inspection(
      id: 'insp-${DateTime.now().millisecondsSinceEpoch}',
      rentalId: rentalId,
      vehicleId: vehicle.id,
      type: 'CHECK_IN',
      odometer: odometerEnd,
      fuelLevel: fuelLevelEnd,
      bodyDefects: defectsEnd,
      notes: notes ?? 'Inspeksi pengembalian check-in',
      createdAt: actualEndTime,
    );
    _inspections.add(inspection);

    // Update Rental
    rental.actualEndTime = actualEndTime;
    rental.overtimeHours = overtimeHours;
    rental.overtimeFee = overtimeFee;
    rental.fuelFee = fuelFee;
    rental.damageFee = damageFee;
    rental.totalAmount = totalAmount;
    rental.refundDeposit = refundDeposit;
    rental.rentalStatus = 'COMPLETED';
    rental.paymentStatus = netDue == 0 ? 'PAID' : 'SETTLEMENT_REQUIRED';

    // Update Vehicle
    vehicle.odometerCurrent = odometerEnd;
    if (vehicleNeedsMaintenance || damageFee > 500000) {
      vehicle.status = VehicleStatus.perawatan;
    } else {
      vehicle.status = VehicleStatus.tersedia;
    }

    evaluateAllMaintenance();
    notifyListeners();

    return {
      'success': true,
      'baseAmount': rental.baseAmount,
      'overtimeHours': overtimeHours,
      'overtimeFee': overtimeFee,
      'fuelDiff': fuelDiff > 0 ? fuelDiff : 0,
      'fuelFee': fuelFee,
      'damageFee': damageFee,
      'totalAmount': totalAmount,
      'downPayment': rental.downPayment,
      'depositAmount': rental.depositAmount,
      'refundDeposit': refundDeposit,
      'netDue': netDue,
      'newStatus': vehicle.status.label,
    };
  }

  // Maintenance Health Map
  final Map<String, VehicleHealth> _healthCache = {};

  VehicleHealth getHealthForVehicle(String vehicleId) {
    if (_healthCache.containsKey(vehicleId)) {
      return _healthCache[vehicleId]!;
    }
    return VehicleHealth(
      vehicleId: vehicleId,
      overallHealth: HealthLevel.hijau,
      alerts: [],
    );
  }

  void evaluateAllMaintenance() {
    _healthCache.clear();
    final now = DateTime.now();

    for (final v in _vehicles) {
      final rules = _maintenanceRules.where((r) => r.vehicleId == v.id).toList();
      HealthLevel overall = HealthLevel.hijau;
      final List<MaintenanceAlert> alerts = [];

      for (final r in rules) {
        int? kmRemaining;
        int? daysRemaining;

        if (r.intervalKm != null) {
          final nextDue = r.lastServiceKm + r.intervalKm!;
          kmRemaining = nextDue - v.odometerCurrent;
        }

        if (r.intervalDays != null) {
          final nextDueDate = r.lastServiceDate.add(Duration(days: r.intervalDays!));
          daysRemaining = nextDueDate.difference(now).inDays;
        }

        final isKmRed = kmRemaining != null && kmRemaining <= 0;
        final isDaysRed = daysRemaining != null && daysRemaining <= 0;

        final isKmYellow = kmRemaining != null && kmRemaining <= 500;
        final isDaysYellow = daysRemaining != null && daysRemaining <= 7;

        if (isKmRed || isDaysRed) {
          overall = HealthLevel.merah;
          alerts.add(MaintenanceAlert(
            serviceType: r.serviceType,
            level: HealthLevel.merah,
            kmRemaining: kmRemaining,
            daysRemaining: daysRemaining,
          ));
        } else if (isKmYellow || isDaysYellow) {
          if (overall != HealthLevel.merah) {
            overall = HealthLevel.kuning;
          }
          alerts.add(MaintenanceAlert(
            serviceType: r.serviceType,
            level: HealthLevel.kuning,
            kmRemaining: kmRemaining,
            daysRemaining: daysRemaining,
          ));
        }
      }

      // Auto lock unit if RED and currently TERSEDIA
      if (overall == HealthLevel.merah && v.status == VehicleStatus.tersedia) {
        v.status = VehicleStatus.perawatan;
      }

      _healthCache[v.id] = VehicleHealth(
        vehicleId: v.id,
        overallHealth: overall,
        alerts: alerts,
      );
    }
    notifyListeners();
  }

  // Complete Maintenance and Auto-Restore to TERSEDIA
  void completeMaintenance({
    required String vehicleId,
    required String serviceType,
    required int completedOdometer,
    required String workshopName,
    required double cost,
  }) {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    vehicle.odometerCurrent = completedOdometer;
    vehicle.status = VehicleStatus.tersedia;

    // Update rule if matched
    final matchingRule = _maintenanceRules.where((r) => r.vehicleId == vehicleId && r.serviceType == serviceType).firstOrNull;
    if (matchingRule != null) {
      final idx = _maintenanceRules.indexOf(matchingRule);
      _maintenanceRules[idx] = MaintenanceRule(
        id: matchingRule.id,
        vehicleId: vehicleId,
        serviceType: serviceType,
        intervalKm: matchingRule.intervalKm,
        intervalDays: matchingRule.intervalDays,
        lastServiceKm: completedOdometer,
        lastServiceDate: DateTime.now(),
      );
    }

    evaluateAllMaintenance();
    notifyListeners();
  }

  // Add new vehicle
  void addVehicle(Vehicle v) {
    _vehicles.add(v);
    evaluateAllMaintenance();
    notifyListeners();
  }

  // Add new customer
  void addCustomer(Customer c) {
    _customers.add(c);
    notifyListeners();
  }
}

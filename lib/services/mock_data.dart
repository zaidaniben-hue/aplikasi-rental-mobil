import '../models/models.dart';

class SeedData {
  static List<Vehicle> getVehicles() {
    return [
      Vehicle(
        id: 'v-001',
        plateNumber: 'B 1234 ABC',
        vin: 'MHFM1BA3NPK001234',
        engineNumber: '1NR-FE-889123',
        brand: 'Toyota',
        model: 'Avanza 1.3 G AT',
        yearMade: 2023,
        transmission: 'OTOMATIS',
        fuelType: 'BENSIN',
        category: 'MPV',
        odometerCurrent: 14200,
        status: VehicleStatus.tersedia,
        dailyRate: 400000,
      ),
      Vehicle(
        id: 'v-002',
        plateNumber: 'B 5678 DEF',
        vin: 'MHFM2BA3NPK005678',
        engineNumber: '2GD-FTV-442190',
        brand: 'Toyota',
        model: 'Innova Reborn 2.4 V AT',
        yearMade: 2022,
        transmission: 'OTOMATIS',
        fuelType: 'DIESEL',
        category: 'MPV',
        odometerCurrent: 49750, // Mendekati servis 50,000 km (Kuning!)
        status: VehicleStatus.disewa,
        dailyRate: 650000,
      ),
      Vehicle(
        id: 'v-003',
        plateNumber: 'B 9012 GHI',
        vin: 'JHMDD1780PK009012',
        engineNumber: 'L12B-998811',
        brand: 'Honda',
        model: 'Brio RS CVT',
        yearMade: 2024,
        transmission: 'OTOMATIS',
        fuelType: 'BENSIN',
        category: 'CITY_CAR',
        odometerCurrent: 7800,
        status: VehicleStatus.tersedia,
        dailyRate: 350000,
      ),
      Vehicle(
        id: 'v-004',
        plateNumber: 'B 3456 JKL',
        vin: 'MMBJRKS10PK003456',
        engineNumber: '4N15-U12389',
        brand: 'Mitsubishi',
        model: 'Pajero Sport Dakar 4x2 AT',
        yearMade: 2023,
        transmission: 'OTOMATIS',
        fuelType: 'DIESEL',
        category: 'SUV',
        odometerCurrent: 32100,
        status: VehicleStatus.booking,
        dailyRate: 900000,
      ),
      Vehicle(
        id: 'v-005',
        plateNumber: 'B 7890 MNO',
        vin: 'MHFM3BA3NPK007890',
        engineNumber: '1GD-FTV-771122',
        brand: 'Toyota',
        model: 'Fortuner 2.8 GR Sport AT',
        yearMade: 2023,
        transmission: 'OTOMATIS',
        fuelType: 'DIESEL',
        category: 'SUV',
        odometerCurrent: 50400, // Jatuh tempo servis ganti oli (50,000 km) -> MERAH!
        status: VehicleStatus.perawatan,
        dailyRate: 950000,
      ),
      Vehicle(
        id: 'v-006',
        plateNumber: 'B 2345 PQR',
        vin: 'JTFN1BA3NPK002345',
        engineNumber: '2KD-FTV-662288',
        brand: 'Toyota',
        model: 'HiAce Commuter Manual',
        yearMade: 2021,
        transmission: 'MANUAL',
        fuelType: 'DIESEL',
        category: 'MINIBUS',
        odometerCurrent: 89400,
        status: VehicleStatus.tersedia,
        dailyRate: 1100000,
      ),
      Vehicle(
        id: 'v-007',
        plateNumber: 'B 6789 STU',
        vin: 'MHKG1BA3NPK006789',
        engineNumber: '3NR-VE-332211',
        brand: 'Daihatsu',
        model: 'Sigra 1.2 R MT',
        yearMade: 2023,
        transmission: 'MANUAL',
        fuelType: 'BENSIN',
        category: 'MPV',
        odometerCurrent: 28500,
        status: VehicleStatus.tidakAktif,
        dailyRate: 300000,
      ),
    ];
  }

  static List<Customer> getCustomers() {
    return [
      Customer(
        id: 'c-001',
        nik: '3171012304900001',
        fullName: 'Budi Santoso',
        simNumber: '900412345678',
        phoneNumber: '081288991122',
        email: 'budi.santoso@gmail.com',
        address: 'Jl. Melati No. 12, Kebayoran Baru, Jakarta Selatan',
        isBlacklisted: false,
      ),
      Customer(
        id: 'c-002',
        nik: '3172021508920003',
        fullName: 'Siti Nurhaliza',
        simNumber: '920823456789',
        phoneNumber: '081399887766',
        email: 'siti.nur@outlook.com',
        address: 'Jl. Danau Sunter Utara No. 45, Jakarta Utara',
        isBlacklisted: false,
      ),
      Customer(
        id: 'c-003',
        nik: '3173032511880005',
        fullName: 'Rudi Hermawan (BLACKLIST)',
        simNumber: '881134567890',
        phoneNumber: '081977665544',
        email: 'rudi.h@yahoo.com',
        address: 'Jl. Merdeka Barat No. 8, Jakarta Barat',
        isBlacklisted: true,
        blacklistReason: 'Riwayat penunggakan sewa 21 hari & penahanan kunci cadangan tanpa izin.',
      ),
      Customer(
        id: 'c-004',
        nik: '3174041006950002',
        fullName: 'Dewi Lestari',
        simNumber: '950645678901',
        phoneNumber: '085711223344',
        email: 'dewi.lestari@perusahaan.co.id',
        address: 'Jl. Tebet Timur Raya No. 18, Jakarta Selatan',
        isBlacklisted: false,
      ),
    ];
  }

  static List<MaintenanceRule> getMaintenanceRules() {
    final now = DateTime.now();
    return [
      // Toyota Avanza (v-001)
      MaintenanceRule(
        id: 'mr-001',
        vehicleId: 'v-001',
        serviceType: 'Ganti Oli & Filter Mesin',
        intervalKm: 5000,
        intervalDays: 180,
        lastServiceKm: 10000,
        lastServiceDate: now.subtract(const Duration(days: 45)),
      ),
      MaintenanceRule(
        id: 'mr-002',
        vehicleId: 'v-001',
        serviceType: 'Perpanjangan STNK Tahunan',
        intervalDays: 365,
        lastServiceKm: 0,
        lastServiceDate: now.subtract(const Duration(days: 120)),
      ),
      // Toyota Innova Reborn (v-002) - Odo 49,750, last 45,000, interval 5,000 -> Sisa 250 km (KUNING!)
      MaintenanceRule(
        id: 'mr-003',
        vehicleId: 'v-002',
        serviceType: 'Ganti Oli Mesin Diesel',
        intervalKm: 5000,
        intervalDays: 180,
        lastServiceKm: 45000,
        lastServiceDate: now.subtract(const Duration(days: 60)),
      ),
      // Toyota Fortuner (v-005) - Odo 50,400, last 45,000, interval 5,000 -> Lewat 400 km (MERAH!)
      MaintenanceRule(
        id: 'mr-004',
        vehicleId: 'v-005',
        serviceType: 'Ganti Oli Mesin & Filter Solar',
        intervalKm: 5000,
        intervalDays: 180,
        lastServiceKm: 45000,
        lastServiceDate: now.subtract(const Duration(days: 90)),
      ),
      MaintenanceRule(
        id: 'mr-005',
        vehicleId: 'v-005',
        serviceType: 'Rotasi Ban & Spooring Balancing',
        intervalKm: 10000,
        intervalDays: 180,
        lastServiceKm: 40000,
        lastServiceDate: now.subtract(const Duration(days: 90)),
      ),
      // Toyota HiAce (v-006) - Uji KIR Tiap 6 Bulan
      MaintenanceRule(
        id: 'mr-006',
        vehicleId: 'v-006',
        serviceType: 'Uji Berkala KIR Dishub',
        intervalDays: 180,
        lastServiceKm: 80000,
        lastServiceDate: now.subtract(const Duration(days: 175)), // Sisa 5 hari! (KUNING!)
      ),
    ];
  }

  static List<Rental> getRentals(List<Vehicle> vehicles, List<Customer> customers) {
    final now = DateTime.now();

    final v2 = vehicles.firstWhere((v) => v.id == 'v-002');
    final c1 = customers.firstWhere((c) => c.id == 'c-001');

    final v4 = vehicles.firstWhere((v) => v.id == 'v-004');
    final c2 = customers.firstWhere((c) => c.id == 'c-002');

    return [
      // 1. Sewa Aktif: Innova Reborn dipinjam Budi Santoso
      Rental(
        id: 'r-001',
        transactionCode: 'RNT-20260927-1042',
        vehicleId: v2.id,
        customerId: c1.id,
        startTime: now.subtract(const Duration(days: 2, hours: 3)),
        plannedEndTime: now.add(const Duration(hours: 4)),
        dailyRate: v2.dailyRate,
        durationDays: 3,
        baseAmount: v2.dailyRate * 3,
        totalAmount: v2.dailyRate * 3,
        depositAmount: 500000,
        downPayment: 1000000,
        paymentMethod: 'TRANSFER',
        paymentStatus: 'DOWN_PAYMENT',
        rentalStatus: 'ACTIVE',
        notes: 'Perjalanan dinas keluarga ke Bandung. BBM saat keluar 8/8 full.',
        vehicle: v2,
        customer: c1,
      ),
      // 2. Booking Mendatang: Pajero Sport dipesan Siti Nurhaliza
      Rental(
        id: 'r-002',
        transactionCode: 'RNT-20260928-8819',
        vehicleId: v4.id,
        customerId: c2.id,
        startTime: now.add(const Duration(days: 1)),
        plannedEndTime: now.add(const Duration(days: 4)),
        dailyRate: v4.dailyRate,
        durationDays: 3,
        baseAmount: v4.dailyRate * 3,
        totalAmount: v4.dailyRate * 3,
        depositAmount: 500000,
        downPayment: 900000,
        paymentMethod: 'TRANSFER',
        paymentStatus: 'DOWN_PAYMENT',
        rentalStatus: 'BOOKED',
        notes: 'Wedding organizer car service. Driver mandiri.',
        vehicle: v4,
        customer: c2,
      ),
    ];
  }
}

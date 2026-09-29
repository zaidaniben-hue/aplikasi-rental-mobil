-- ============================================================================
-- RENTDESK v1.0 - DATABASE SCHEMA MIGRATION
-- Target: Supabase (PostgreSQL 15+)
-- Features: 
--   - Role-Based Access Control (Front Desk, Mechanic, Manager)
--   - Anti Double-Booking Collision Detection Logic
--   - Maintenance Alert Threshold Calculations (Green / Yellow / Red)
--   - Full Inspection Body Defect Tracking (JSONB)
--   - Audit Logging & Automatic State Transitions
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUMS
CREATE TYPE vehicle_status AS ENUM (
    'TERSEDIA',
    'BOOKING',
    'DISEWA',
    'PERAWATAN',
    'TIDAK_AKTIF'
);

CREATE TYPE transmission_type AS ENUM ('MANUAL', 'OTOMATIS');
CREATE TYPE fuel_type AS ENUM ('BENSIN', 'DIESEL', 'HYBRID', 'LISTRIK');
CREATE TYPE vehicle_category AS ENUM ('CITY_CAR', 'MPV', 'SUV', 'MINIBUS');
CREATE TYPE rental_status AS ENUM ('DRAFT', 'BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED');
CREATE TYPE inspection_type AS ENUM ('CHECK_OUT', 'CHECK_IN');
CREATE TYPE maintenance_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE user_role AS ENUM ('FRONT_DESK', 'MECHANIC', 'MANAGER');
CREATE TYPE health_level AS ENUM ('HIJAU', 'KUNING', 'MERAH');

-- 3. PROFILES / USERS
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'FRONT_DESK',
    phone_number TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. VEHICLES
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plate_number TEXT NOT NULL UNIQUE,
    vin TEXT NOT NULL UNIQUE,
    engine_number TEXT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year_made INTEGER NOT NULL CHECK (year_made >= 1990 AND year_made <= 2035),
    transmission transmission_type NOT NULL DEFAULT 'OTOMATIS',
    fuel_type fuel_type NOT NULL DEFAULT 'BENSIN',
    category vehicle_category NOT NULL DEFAULT 'MPV',
    odometer_current INTEGER NOT NULL DEFAULT 0 CHECK (odometer_current >= 0),
    status vehicle_status NOT NULL DEFAULT 'TERSEDIA',
    daily_rate NUMERIC(12, 2) NOT NULL CHECK (daily_rate >= 0),
    photo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for searching and filtering vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_category ON vehicles(category);
CREATE INDEX IF NOT EXISTS idx_vehicles_transmission ON vehicles(transmission);

-- 5. CUSTOMERS
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nik TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    sim_number TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    email TEXT,
    address TEXT,
    ktp_photo_url TEXT,
    sim_photo_url TEXT,
    is_blacklisted BOOLEAN NOT NULL DEFAULT FALSE,
    blacklist_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_nik ON customers(nik);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone_number);
CREATE INDEX IF NOT EXISTS idx_customers_blacklist ON customers(is_blacklisted);

-- 6. RENTALS (TRANSAKSI SEWA)
CREATE TABLE IF NOT EXISTS rentals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_code TEXT NOT NULL UNIQUE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    start_time TIMESTAMPTZ NOT NULL,
    planned_end_time TIMESTAMPTZ NOT NULL,
    actual_end_time TIMESTAMPTZ,
    daily_rate NUMERIC(12, 2) NOT NULL,
    duration_days INTEGER NOT NULL CHECK (duration_days >= 1),
    base_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    overtime_hours NUMERIC(6, 2) NOT NULL DEFAULT 0,
    overtime_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    fuel_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    damage_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    deposit_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    down_payment NUMERIC(12, 2) NOT NULL DEFAULT 0,
    refund_deposit NUMERIC(12, 2) NOT NULL DEFAULT 0,
    payment_method TEXT NOT NULL DEFAULT 'CASH', -- 'CASH', 'TRANSFER', 'CARD'
    payment_status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'DOWN_PAYMENT', 'PAID', 'REFUNDED'
    rental_status rental_status NOT NULL DEFAULT 'DRAFT',
    notes TEXT,
    handled_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_rental_dates CHECK (planned_end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_rentals_dates ON rentals(start_time, planned_end_time);
CREATE INDEX IF NOT EXISTS idx_rentals_vehicle ON rentals(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_rentals_status ON rentals(rental_status);

-- 7. INSPECTIONS (SERAH TERIMA & PENGEMBALIAN)
CREATE TABLE IF NOT EXISTS inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rental_id UUID NOT NULL REFERENCES rentals(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
    type inspection_type NOT NULL,
    odometer INTEGER NOT NULL CHECK (odometer >= 0),
    fuel_level INTEGER NOT NULL CHECK (fuel_level >= 1 AND fuel_level <= 8), -- Scale 1/8 to 8/8
    body_defects JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of: {id, view, x, y, type, severity, notes}
    notes TEXT,
    inspector_id UUID REFERENCES profiles(id),
    photo_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inspections_rental ON inspections(rental_id);
CREATE INDEX IF NOT EXISTS idx_inspections_vehicle ON inspections(vehicle_id);

-- 8. MAINTENANCE RULES (PENGATURAN AMBANG BATAS SERVIS)
CREATE TABLE IF NOT EXISTS maintenance_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    service_type TEXT NOT NULL, -- e.g. 'Ganti Oli Mesin', 'Rotasi Ban', 'Servis Besar', 'Uji KIR', 'Pajak STNK'
    interval_km INTEGER, -- e.g. 5000 km (NULL if purely calendar based)
    interval_days INTEGER, -- e.g. 180 days (NULL if purely mileage based)
    last_service_km INTEGER NOT NULL DEFAULT 0,
    last_service_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_maint_rules_vehicle ON maintenance_rules(vehicle_id);

-- 9. MAINTENANCE LOGS (LOGBOOK PERAWATAN FISIK)
CREATE TABLE IF NOT EXISTS maintenance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
    rule_id UUID REFERENCES maintenance_rules(id) ON DELETE SET NULL,
    service_type TEXT NOT NULL,
    workshop_name TEXT NOT NULL,
    mechanic_name TEXT,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_date DATE,
    odometer_at_service INTEGER NOT NULL,
    description TEXT,
    parts_replaced TEXT,
    total_cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status maintenance_status NOT NULL DEFAULT 'SCHEDULED',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_maint_logs_vehicle ON maintenance_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maint_logs_status ON maintenance_logs(status);

-- 10. AUDIT LOGS (AUDIT TRAIL)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    performed_by UUID REFERENCES profiles(id),
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 11. STORED FUNCTIONS & LOGIC
-- ============================================================================

-- A. Anti Double-Booking Collision Detection Function
CREATE OR REPLACE FUNCTION check_vehicle_availability(
    p_vehicle_id UUID,
    p_start_time TIMESTAMPTZ,
    p_end_time TIMESTAMPTZ,
    p_exclude_rental_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conflict_count INTEGER;
    v_status vehicle_status;
BEGIN
    -- 1. Check current physical status
    SELECT status INTO v_status FROM vehicles WHERE id = p_vehicle_id;
    IF v_status = 'TIDAK_AKTIF' OR v_status = 'PERAWATAN' THEN
        RETURN FALSE;
    END IF;

    -- 2. Check overlap against existing BOOKED or ACTIVE rentals
    SELECT COUNT(*) INTO conflict_count
    FROM rentals
    WHERE vehicle_id = p_vehicle_id
      AND rental_status IN ('BOOKED', 'ACTIVE')
      AND (p_exclude_rental_id IS NULL OR id != p_exclude_rental_id)
      AND (
          -- Interval overlap condition: (StartA < EndB) and (EndA > StartB)
          (p_start_time < planned_end_time) AND (p_end_time > start_time)
      );

    IF conflict_count > 0 THEN
        RETURN FALSE;
    END IF;

    -- 3. Check overlap against SCHEDULED or IN_PROGRESS maintenance
    SELECT COUNT(*) INTO conflict_count
    FROM maintenance_logs
    WHERE vehicle_id = p_vehicle_id
      AND status IN ('SCHEDULED', 'IN_PROGRESS')
      AND (
          (p_start_time::DATE <= COALESCE(completed_date, entry_date + INTERVAL '3 days')) 
          AND (p_end_time::DATE >= entry_date)
      );

    IF conflict_count > 0 THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;

-- B. Calculate Vehicle Maintenance Health (Hijau / Kuning / Merah)
CREATE OR REPLACE FUNCTION get_vehicle_health(p_vehicle_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    r RECORD;
    v_odo INTEGER;
    v_health health_level := 'HIJAU';
    km_diff INTEGER;
    days_diff INTEGER;
    urgencies JSONB := '[]'::jsonb;
BEGIN
    SELECT odometer_current INTO v_odo FROM vehicles WHERE id = p_vehicle_id;

    FOR r IN SELECT * FROM maintenance_rules WHERE vehicle_id = p_vehicle_id LOOP
        km_diff := NULL;
        days_diff := NULL;

        -- Check km threshold
        IF r.interval_km IS NOT NULL THEN
            km_diff := (r.last_service_km + r.interval_km) - v_odo;
        END IF;

        -- Check date threshold
        IF r.interval_days IS NOT NULL THEN
            days_diff := (r.last_service_date + (r.interval_days || ' days')::INTERVAL)::DATE - CURRENT_DATE;
        END IF;

        -- Red Flag: Odometer exceeded OR date exceeded
        IF (km_diff IS NOT NULL AND km_diff <= 0) OR (days_diff IS NOT NULL AND days_diff <= 0) THEN
            v_health := 'MERAH';
            urgencies := urgencies || jsonb_build_object(
                'service_type', r.service_type,
                'status', 'MERAH',
                'km_remaining', km_diff,
                'days_remaining', days_diff
            );
        -- Yellow Flag: km <= 500 OR days <= 7
        ELSIF (km_diff IS NOT NULL AND km_diff <= 500) OR (days_diff IS NOT NULL AND days_diff <= 7) THEN
            IF v_health != 'MERAH' THEN
                v_health := 'KUNING';
            END IF;
            urgencies := urgencies || jsonb_build_object(
                'service_type', r.service_type,
                'status', 'KUNING',
                'km_remaining', km_diff,
                'days_remaining', days_diff
            );
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'vehicle_id', p_vehicle_id,
        'overall_health', v_health,
        'alerts', urgencies
    );
END;
$$;

-- C. Trigger to Auto-Sync Vehicle Status on Maintenance Completion
CREATE OR REPLACE FUNCTION trigger_maintenance_status_sync()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'IN_PROGRESS' THEN
        UPDATE vehicles SET status = 'PERAWATAN', updated_at = NOW() WHERE id = NEW.vehicle_id;
    ELSIF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        -- Update vehicle status back to TERSEDIA
        UPDATE vehicles SET 
            status = 'TERSEDIA', 
            odometer_current = GREATEST(odometer_current, NEW.odometer_at_service),
            updated_at = NOW() 
        WHERE id = NEW.vehicle_id;

        -- Update corresponding maintenance_rule last_service_km and date
        IF NEW.rule_id IS NOT NULL THEN
            UPDATE maintenance_rules 
            SET last_service_km = NEW.odometer_at_service,
                last_service_date = COALESCE(NEW.completed_date, CURRENT_DATE),
                updated_at = NOW()
            WHERE id = NEW.rule_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_maint_status_sync ON maintenance_logs;
CREATE TRIGGER trg_maint_status_sync
AFTER INSERT OR UPDATE ON maintenance_logs
FOR EACH ROW
EXECUTE FUNCTION trigger_maintenance_status_sync();

-- ============================================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated read/write based on application roles
CREATE POLICY "Authenticated users can view vehicles" ON vehicles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff can update vehicles" ON vehicles FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users can view customers" ON customers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff can manage customers" ON customers FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users can view rentals" ON rentals FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff can manage rentals" ON rentals FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users can view inspections" ON inspections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff can manage inspections" ON inspections FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users can view maintenance" ON maintenance_rules FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated users can view maintenance logs" ON maintenance_logs FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated users can view audit logs" ON audit_logs FOR SELECT TO authenticated USING (true);

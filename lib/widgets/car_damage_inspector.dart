import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CarDamageInspector extends StatefulWidget {
  final List<BodyDefectPoint> existingDefects;
  final Function(List<BodyDefectPoint>)? onDefectsChanged;
  final bool isReadOnly;
  final String title;

  const CarDamageInspector({
    super.key,
    required this.existingDefects,
    this.onDefectsChanged,
    this.isReadOnly = false,
    this.title = 'Inspeksi Kondisi Fisik Bodi Kendaraan',
  });

  @override
  State<CarDamageInspector> createState() => _CarDamageInspectorState();
}

class _CarDamageInspectorState extends State<CarDamageInspector> {
  String _activeView = 'front'; // 'front', 'back', 'left', 'right'
  late List<BodyDefectPoint> _defects;

  @override
  void initState() {
    super.initState();
    _defects = List.from(widget.existingDefects);
  }

  void _addDefect(Offset localPosition, Size boxSize) async {
    if (widget.isReadOnly) return;

    final normX = (localPosition.dx / boxSize.width).clamp(0.05, 0.95);
    final normY = (localPosition.dy / boxSize.height).clamp(0.05, 0.95);

    String defectType = 'scratch';
    String severity = 'medium';
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.car_crash_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text('Catat Cacat Bodi Baru', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Posisi Tampak: ${_getViewName(_activeView)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              const Text('Jenis Cacat / Kerusakan:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: defectType,
                dropdownColor: AppTheme.surfaceCard,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'scratch', child: Text('Goresan / Lecet (Scratch)')),
                  DropdownMenuItem(value: 'dent', child: Text('Penyok / Baret Dalam (Dent)')),
                  DropdownMenuItem(value: 'broken', child: Text('Pecah / Retak / Hilang (Broken)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => defectType = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('Tingkat Keparahan:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _severityChip('low', 'Ringan', AppTheme.primary, severity, (s) => setDlgState(() => severity = s)),
                  const SizedBox(width: 8),
                  _severityChip('medium', 'Sedang', AppTheme.warning, severity, (s) => setDlgState(() => severity = s)),
                  const SizedBox(width: 8),
                  _severityChip('high', 'Berat', AppTheme.danger, severity, (s) => setDlgState(() => severity = s)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan',
                  hintText: 'Contoh: Tergores tiang, cat mengelupas',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan Titik Cacat'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newPoint = BodyDefectPoint(
        id: 'def-${DateTime.now().millisecondsSinceEpoch}',
        view: _activeView,
        x: normX,
        y: normY,
        type: defectType,
        severity: severity,
        notes: notesController.text.trim(),
      );

      setState(() {
        _defects.add(newPoint);
      });
      widget.onDefectsChanged?.call(_defects);
    }
  }

  Widget _severityChip(String val, String label, Color color, String current, Function(String) onSelect) {
    final isSelected = val == current;
    return InkWell(
      onTap: () => onSelect(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : AppTheme.surfaceInput,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : AppTheme.border, width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getViewName(String v) {
    switch (v) {
      case 'front':
        return 'Tampak Depan';
      case 'back':
        return 'Tampak Belakang';
      case 'left':
        return 'Samping Kiri';
      case 'right':
        return 'Samping Kanan';
      default:
        return v;
    }
  }

  void _removeDefect(BodyDefectPoint point) {
    if (widget.isReadOnly) return;
    setState(() {
      _defects.removeWhere((p) => p.id == point.id);
    });
    widget.onDefectsChanged?.call(_defects);
  }

  @override
  Widget build(BuildContext context) {
    final viewDefects = _defects.where((d) => d.view == _activeView).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
            Text('${_defects.length} titik cacat bodi tercatat', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        // View Selector Buttons
        Row(
          children: [
            _viewTabButton('front', 'Depan', Icons.directions_car_rounded),
            const SizedBox(width: 8),
            _viewTabButton('back', 'Belakang', Icons.shield_rounded),
            const SizedBox(width: 8),
            _viewTabButton('left', 'Samping Kiri', Icons.arrow_back_rounded),
            const SizedBox(width: 8),
            _viewTabButton('right', 'Samping Kanan', Icons.arrow_forward_rounded),
          ],
        ),
        const SizedBox(height: 12),
        // Interactive Canvas Container
        LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth;
            const boxHeight = 220.0;

            return Stack(
              children: [
                // Vehicle Silhouette Background
                GestureDetector(
                  onTapDown: (details) => _addDefect(details.localPosition, Size(boxWidth, boxHeight)),
                  child: Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: CustomPaint(
                      painter: VehicleSilhouettePainter(view: _activeView),
                    ),
                  ),
                ),
                // Render Defect Pins
                ...viewDefects.map((defect) {
                  Color pinColor;
                  switch (defect.severity) {
                    case 'low':
                      pinColor = AppTheme.warning;
                      break;
                    case 'medium':
                      pinColor = Colors.orangeAccent;
                      break;
                    case 'high':
                      pinColor = AppTheme.danger;
                      break;
                    default:
                      pinColor = AppTheme.danger;
                  }

                  return Positioned(
                    left: defect.x * boxWidth - 14,
                    top: defect.y * boxHeight - 14,
                    child: Tooltip(
                      message: '${defect.type.toUpperCase()} (${defect.severity})\n${defect.notes.isEmpty ? 'Tanpa catatan' : defect.notes}',
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isReadOnly) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceCard,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.border)),
                                title: const Text('Hapus Titik Cacat?', style: TextStyle(color: AppTheme.textPrimary)),
                                content: Text('Hapus catatan ${defect.type} di posisi ini?', style: const TextStyle(color: AppTheme.textSecondary)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                                    onPressed: () {
                                      _removeDefect(defect);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: pinColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: pinColor.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.warning_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }),
                // Click hint overlay
                if (!widget.isReadOnly)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Klik pada bodi mobil untuk menandai lecet/cacat',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // List of Defects in this view
        if (viewDefects.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: viewDefects.map((d) {
              return Chip(
                avatar: const Icon(Icons.circle, size: 10, color: AppTheme.danger),
                label: Text('${d.type} (${d.severity}): ${d.notes.isEmpty ? 'Posisi ${_getViewName(d.view)}' : d.notes}'),
                onDeleted: widget.isReadOnly ? null : () => _removeDefect(d),
                deleteIconColor: AppTheme.textMuted,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _viewTabButton(String viewCode, String label, IconData icon) {
    final isSelected = _activeView == viewCode;
    return InkWell(
      onTap: () => setState(() => _activeView = viewCode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleSilhouettePainter extends CustomPainter {
  final String view;
  VehicleSilhouettePainter({required this.view});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBody = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintGlass = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (view) {
      case 'front':
        // Front View Silhouette
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 10), width: size.width * 0.55, height: size.height * 0.65),
          const Radius.circular(20),
        );
        canvas.drawRRect(rect, paintBody);
        // Windshield
        final glass = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 20), width: size.width * 0.45, height: size.height * 0.28),
          const Radius.circular(10),
        );
        canvas.drawRRect(glass, paintGlass);
        // Headlights
        canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * 0.2, cy + 20), width: 35, height: 16), paintGlass);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * 0.2, cy + 20), width: 35, height: 16), paintGlass);
        // Grille
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 35), width: size.width * 0.25, height: 20), const Radius.circular(6)),
          paintGlass,
        );
        break;

      case 'back':
        // Back View Silhouette
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 10), width: size.width * 0.55, height: size.height * 0.65),
          const Radius.circular(20),
        );
        canvas.drawRRect(rect, paintBody);
        // Rear window
        final glass = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 20), width: size.width * 0.45, height: size.height * 0.28),
          const Radius.circular(10),
        );
        canvas.drawRRect(glass, paintGlass);
        // Taillights
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - size.width * 0.2, cy + 15), width: 35, height: 18), const Radius.circular(4)), paintGlass);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + size.width * 0.2, cy + 15), width: 35, height: 18), const Radius.circular(4)), paintGlass);
        // License plate area
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 40), width: 60, height: 18), paintGlass);
        break;

      case 'left':
      case 'right':
        // Side View Silhouette
        final path = Path();
        final startX = size.width * 0.15;
        final endX = size.width * 0.85;

        path.moveTo(startX, cy + 40);
        path.lineTo(startX + 30, cy + 15);
        path.lineTo(startX + 100, cy + 10); // Hood
        path.lineTo(startX + 160, cy - 40); // Windshield
        path.lineTo(endX - 90, cy - 40);   // Roof
        path.lineTo(endX - 30, cy + 10);   // Rear window & trunk
        path.lineTo(endX, cy + 30);
        path.lineTo(endX, cy + 45);
        path.lineTo(startX, cy + 45);
        path.close();
        canvas.drawPath(path, paintBody);

        // Wheels
        canvas.drawCircle(Offset(startX + 70, cy + 45), 24, paintGlass);
        canvas.drawCircle(Offset(endX - 70, cy + 45), 24, paintGlass);

        // Side windows
        final winPath = Path();
        winPath.moveTo(startX + 165, cy - 36);
        winPath.lineTo(endX - 95, cy - 36);
        winPath.lineTo(endX - 55, cy + 5);
        winPath.lineTo(startX + 120, cy + 5);
        winPath.close();
        canvas.drawPath(winPath, paintGlass);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rentdesk/main.dart';
import 'package:rentdesk/providers/app_state.dart';

void main() {
  testWidgets('RentDeskApp boots successfully on desktop screen', (WidgetTester tester) async {
    // Configure standard desktop viewport
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..loadInitialData(),
        child: const RentDeskApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RentDesk'), findsWidgets);
    expect(find.text('Pusat Operasional Rental Armada'), findsOneWidget);
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ficct_primer_parcial_si2_diagramador_movil/main.dart';

void main() {
  testWidgets('dashboard renders main sections', (WidgetTester tester) async {
    await tester.pumpWidget(const TallerAcbApp());

    expect(find.text('Taller ACB Asistencia'), findsOneWidget);
    expect(find.text('Resumen general'), findsOneWidget);
    expect(find.text('Acciones rápidas'), findsOneWidget);
    expect(find.text('Solicitudes recientes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Talleres disponibles'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Talleres disponibles'), findsOneWidget);
  });
}

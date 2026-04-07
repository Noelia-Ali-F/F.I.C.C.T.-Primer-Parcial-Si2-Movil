import 'package:flutter_test/flutter_test.dart';

import 'package:ficct_primer_parcial_si2_diagramador_movil/app.dart';

void main() {
  testWidgets('welcome screen opens login flow', (WidgetTester tester) async {
    await tester.pumpWidget(const TallerAcbApp());

    expect(find.text('BIENVENIDO'), findsOneWidget);
    expect(find.text('Accede a tu cuenta'), findsOneWidget);
    expect(find.text('INICIAR SESION'), findsOneWidget);

    await tester.ensureVisible(find.text('INICIAR SESION'));
    await tester.tap(find.text('INICIAR SESION'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Conecta con talleres cercanos mediante IA'), findsOneWidget);
    expect(find.text('Accesos de prueba'), findsOneWidget);
  });
}

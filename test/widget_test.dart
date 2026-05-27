import 'package:flutter/material.dart';
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

    expect(
        find.text('Conecta con talleres cercanos mediante IA'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });

  testWidgets('login opens otp recovery and resets password',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TallerAcbApp());

    await tester.ensureVisible(find.text('INICIAR SESION'));
    await tester.tap(find.text('INICIAR SESION'));
    await tester.pumpAndSettle();

    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Correo electrónico'),
      'cliente@emergencias.bo',
    );
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Verificación OTP'), findsOneWidget);
    expect(find.text('Ingresa tu número de celular'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '71234567');
    await tester.pump();
    expect(find.text('Se enviará el código a +591 71234567'), findsOneWidget);
    await tester.ensureVisible(find.text('OBTENER OTP'));
    await tester.tap(find.text('OBTENER OTP'));
    await tester.pumpAndSettle();

    expect(find.text('OTP Verification'), findsOneWidget);

    await tester.ensureVisible(find.text('VERIFY & PROCEED'));
    await tester.tap(find.text('VERIFY & PROCEED'));
    await tester.pumpAndSettle();

    expect(find.text('Restablecer contraseña'), findsOneWidget);
    expect(find.text('Guardar nueva contraseña'), findsOneWidget);
  });
}

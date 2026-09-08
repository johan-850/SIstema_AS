// Validadores de formulario (login, alta de cajero, productos).
// Lógica pura: no necesita Supabase ni bindings de Flutter.

import 'package:flutter_test/flutter_test.dart';
import 'package:abarroteria_pro/core/constants/app_constants.dart';
import 'package:abarroteria_pro/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rechaza vacío y solo espacios', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });

    test('rechaza formatos inválidos', () {
      expect(Validators.email('sin-arroba.com'), isNotNull);
      expect(Validators.email('sin@dominio'), isNotNull);
      expect(Validators.email('dos@@arrobas.com'), isNotNull);
    });

    test('acepta un correo válido, ignorando espacios alrededor', () {
      expect(Validators.email('admin@abarroteria.com'), isNull);
      expect(Validators.email('  admin@abarroteria.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rechaza vacío', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('rechaza una contraseña más corta que el mínimo', () {
      final corta = 'a' * (AppConstants.minPasswordLength - 1);
      expect(Validators.password(corta), isNotNull);
    });

    test('acepta exactamente el mínimo', () {
      final justa = 'a' * AppConstants.minPasswordLength;
      expect(Validators.password(justa), isNull);
    });

    test('no recorta espacios: son caracteres válidos en una contraseña', () {
      expect(Validators.password('      '), isNull);
    });
  });

  group('Validators.requiredText', () {
    test('rechaza vacío y solo espacios', () {
      expect(Validators.requiredText(null), isNotNull);
      expect(Validators.requiredText('   '), isNotNull);
    });

    test('nombra el campo en el mensaje de error', () {
      expect(Validators.requiredText('', fieldName: 'El precio'),
          contains('El precio'));
    });

    test('acepta texto no vacío', () {
      expect(Validators.requiredText('algo'), isNull);
    });
  });

  group('Validators.name', () {
    test('rechaza vacío', () {
      expect(Validators.name(''), isNotNull);
    });

    test('acepta exactamente el máximo y rechaza uno más', () {
      expect(Validators.name('a' * AppConstants.maxNameLength), isNull);
      expect(Validators.name('a' * (AppConstants.maxNameLength + 1)), isNotNull);
    });

    test('acepta un nombre normal', () {
      expect(Validators.name('Juan Pérez'), isNull);
    });
  });
}

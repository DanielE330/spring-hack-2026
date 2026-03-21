import 'package:flutter_test/flutter_test.dart';
import 'package:entry_point/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for missing @', () {
      expect(Validators.email('userexample.com'), isNotNull);
    });

    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('secret123'), isNull);
    });

    test('returns error when too short', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('returns error for empty', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Validators.name', () {
    test('returns null for valid name', () {
      expect(Validators.name('Ivan'), isNull);
    });

    test('returns error for single char', () {
      expect(Validators.name('I'), isNotNull);
    });

    test('returns error for null', () {
      expect(Validators.name(null), isNotNull);
    });
  });

  group('Validators.required', () {
    test('returns null when field has value', () {
      expect(Validators.required('value', 'Field'), isNull);
    });

    test('returns error when field is empty', () {
      expect(Validators.required('', 'Field'), isNotNull);
    });
  });
}

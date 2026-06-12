import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/onboarding/first_spark.dart';

void main() {
  group('sparkCategoryFor', () {
    test('maps each motivation to its category', () {
      expect(sparkCategoryFor('animals'), 'why_vegan');
      expect(sparkCategoryFor('planet'), 'facts');
      expect(sparkCategoryFor('health'), 'quick_tips');
    });

    test('curious, unset, or unknown fall back to why_vegan', () {
      expect(sparkCategoryFor('curious'), 'why_vegan');
      expect(sparkCategoryFor(null), 'why_vegan');
      expect(sparkCategoryFor('something_else'), 'why_vegan');
    });
  });
}

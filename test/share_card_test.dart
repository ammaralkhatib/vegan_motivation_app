import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/db/database.dart' show Quote;
import 'package:vegan_motivation_app/features/quotes/share_card.dart';

Quote quoteWith(String body) => Quote(
      id: 1,
      body: body,
      author: null,
      categoryId: 'why_vegan',
      isFavorite: false,
      favoritedAt: null,
      shownCount: 0,
    );

void main() {
  for (final (label, body) in [
    ('short', 'Eat plants.'),
    (
      'long',
      'A very long quote that keeps going and going to make absolutely sure '
          'the card layout never overflows its fixed 360 by 450 design size, '
          'even with multiple wrapped lines of generous serif text on screen.',
    ),
  ]) {
    testWidgets('share card lays out without overflow ($label quote)',
        (tester) async {
      for (final style in ShareCardStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: ShareCard(quote: quoteWith(body), style: style),
            ),
          ),
        );
        expect(tester.takeException(), isNull,
            reason: 'style=$style, $label quote must not overflow');
      }
    });
  }
}

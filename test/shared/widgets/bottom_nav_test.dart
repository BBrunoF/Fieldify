import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/shared/widgets/bottom_nav.dart';

import '../../test_helpers.dart';

void main() {
  testWidgets(
    'BottomNav hides jobs when requested and keeps semantic indexes',
    (tester) async {
      var tappedIndex = -1;

      await pumpTestApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(),
          child: BottomNav(
            selected: 0,
            showJobs: false,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      );

      expect(find.text('Jobs'), findsNothing);
      expect(find.byKey(const Key('bottomNavItem_home')), findsOneWidget);
      expect(find.byKey(const Key('bottomNavItem_messages')), findsOneWidget);
      expect(find.byKey(const Key('bottomNavItem_profile')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bottomNavItem_messages')));

      expect(tappedIndex, 2);
    },
  );
}

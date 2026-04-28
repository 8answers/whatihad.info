import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:what_i_had/main.dart';

void main() {
  testWidgets('renders first screen with centered logo', (tester) async {
    await tester.pumpWidget(const WhatIHadApp());

    expect(find.byType(FirstScreen), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('navigates to loading screen after splash', (tester) async {
    await tester.pumpWidget(const WhatIHadApp());

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });

  testWidgets('fills loading circle then navigates to terms screen', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIHadApp());

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}

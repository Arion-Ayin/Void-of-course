import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lioluna/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 기본 타이틀이 보이는지 확인
    expect(find.text('Studio Saan'), findsOneWidget); // 예시 텍스트
  });
}

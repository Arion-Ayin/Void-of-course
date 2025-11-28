import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';
import 'package:lioluna/services/astro_calculator.dart';

void main() {
  test('Moon Sign Calculation Repro', () async {
    await Sweph.init();
    final calculator = AstroCalculator();

    // Date: 2025-11-30
    // Expected Event: Moon enters Aries at ~10:05 AM

    // Case A: Start of day (00:00)
    final dateA = DateTime(2025, 11, 30, 0, 0);
    final timesA = calculator.getMoonSignTimes(dateA);
    final signA = calculator.getMoonSignName(dateA);

    print('Case A (00:00): Moon Sign: $signA');
    print('Case A (00:00): Sign Start: ${timesA['start']}');
    print('Case A (00:00): Sign End:   ${timesA['end']}');

    // Case B: Afternoon (13:32)
    final dateB = DateTime(2025, 11, 30, 13, 32);
    final timesB = calculator.getMoonSignTimes(dateB);
    final signB = calculator.getMoonSignName(dateB);

    print('Case B (13:32): Moon Sign: $signB');
    print('Case B (13:32): Sign Start: ${timesB['start']}');
    print('Case B (13:32): Sign End:   ${timesB['end']}');

    // Assertions to confirm the issue
    // Case A should show the transition on 11/30
    expect(timesA['end']?.day, 30);
    expect(timesA['end']?.hour, 10);

    // Case B currently shows the NEXT transition (12/02) because 13:32 > 10:05
    // This confirms that if we pass 13:32, we miss the event.
    expect(timesB['end']?.month, 12);
    expect(timesB['end']?.day, 2);
  });
}

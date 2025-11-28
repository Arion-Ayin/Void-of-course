import 'package:sweph/sweph.dart';
import 'lib/services/astro_calculator.dart';

void main() async {
  await Sweph.init();
  final calculator = AstroCalculator();

  // Scenario:
  // Date: 2025-11-30
  // Event: Moon enters Aries at roughly 10:05 AM (based on user report)

  // Case A: Start of day
  final dateA = DateTime(2025, 11, 30, 0, 0);
  final timesA = calculator.getMoonSignTimes(dateA);
  print('Case A (00:00): Moon Sign: ${calculator.getMoonSignName(dateA)}');
  print('Case A (00:00): Sign Start: ${timesA['start']}');
  print('Case A (00:00): Sign End:   ${timesA['end']}');

  // Case B: Afternoon (simulating current time 13:32 projected to that day)
  final dateB = DateTime(2025, 11, 30, 13, 32);
  final timesB = calculator.getMoonSignTimes(dateB);
  print('\nCase B (13:32): Moon Sign: ${calculator.getMoonSignName(dateB)}');
  print('Case B (13:32): Sign Start: ${timesB['start']}');
  print('Case B (13:32): Sign End:   ${timesB['end']}');
}

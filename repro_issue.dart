import 'package:sweph/sweph.dart';
import 'lib/services/astro_calculator.dart';

void main() async {
  await Sweph.init();
  final calculator = AstroCalculator();

  // Test getMoonPhaseTimes
  final testDate = DateTime.now();
  final phaseTimes = calculator.getMoonPhaseTimes(testDate);
  final phaseInfo = calculator.getMoonPhaseInfo(testDate);
  
  print('Test Date: $testDate');
  print('Current Moon Phase: ${phaseInfo['phaseName']}');
  print('Phase Start: ${phaseTimes['start']}');
  print('Phase End: ${phaseTimes['end']}');
  print('Next Phase: ${calculator.findNextPhase(testDate)}');
}

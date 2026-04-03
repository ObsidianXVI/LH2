import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/operations/scenario_evaluator.dart';

void main() {
  final evaluator = ScenarioEvaluator();

  group('ScenarioEvaluator', () {
    test('matches when focus level is equal or higher', () {
      const required = ContextRequirement(
        focusLevel: 2.0,
        contiguousMinutesNeeded: 0,
        resourceTags: {},
      );
      const actualHigh = ActualContext(
        focusLevel: 3.0,
        contiguousMinutesAvailable: 0,
        resourceTags: {},
      );
      const actualLow = ActualContext(
        focusLevel: 1.0,
        contiguousMinutesAvailable: 0,
        resourceTags: {},
      );

      expect(evaluator.matches(actualHigh, required), isTrue);
      expect(evaluator.matches(actualLow, required), isFalse);
    });

    test('matches when minutes available is equal or higher', () {
      const required = ContextRequirement(
        focusLevel: 0,
        contiguousMinutesNeeded: 30,
        resourceTags: {},
      );
      const actualHigh = ActualContext(
        focusLevel: 0,
        contiguousMinutesAvailable: 45,
        resourceTags: {},
      );
      const actualLow = ActualContext(
        focusLevel: 0,
        contiguousMinutesAvailable: 15,
        resourceTags: {},
      );

      expect(evaluator.matches(actualHigh, required), isTrue);
      expect(evaluator.matches(actualLow, required), isFalse);
    });

    test('matches when all required resource tags are present', () {
      const required = ContextRequirement(
        focusLevel: 0,
        contiguousMinutesNeeded: 0,
        resourceTags: {'wifi': true, 'laptop': true},
      );
      const actualMatch = ActualContext(
        focusLevel: 0,
        contiguousMinutesAvailable: 0,
        resourceTags: {'wifi': true, 'laptop': true, 'desk': true},
      );
      const actualMissing = ActualContext(
        focusLevel: 0,
        contiguousMinutesAvailable: 0,
        resourceTags: {'wifi': true},
      );

      expect(evaluator.matches(actualMatch, required), isTrue);
      expect(evaluator.matches(actualMissing, required), isFalse);
    });
  });
}

import 'package:lh2_stub/lh2_stub.dart';

class ScenarioEvaluator {
  bool matches(ActualContext actual, ContextRequirement required) {
    // focusLevel: ActualContext.focusLevel >= ContextRequirement.focusLevel
    if (actual.focusLevel != null && actual.focusLevel! < required.focusLevel) {
      return false;
    }

    // contiguousMinutesAvailable >= contiguousMinutesNeeded
    if (actual.contiguousMinutesAvailable != null &&
        actual.contiguousMinutesAvailable! < required.contiguousMinutesNeeded) {
      return false;
    }

    // for each resourceTag in requirement: must match actualContext.resourceTags
    for (final entry in required.resourceTags.entries) {
      final tagName = entry.key;
      final isRequired = entry.value;

      if (isRequired) {
        final hasResource = actual.resourceTags[tagName] ?? false;
        if (!hasResource) {
          return false;
        }
      }
    }

    return true;
  }
}

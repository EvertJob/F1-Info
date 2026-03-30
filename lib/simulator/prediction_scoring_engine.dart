import 'package:f1/simulator/hub_prediction_scoring.dart';
import 'package:f1/simulator/simulator_models.dart';

/// Builds a fixed-size classification: index `i` is the driver who finished P(i+1), or null.
List<String?> classificationFromRows(
  List<SimulatorResultRowLite> rows,
  List<SimulatorDriverRef> roster,
) =>
    hubClassificationSlots(rows, roster);

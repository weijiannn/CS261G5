import 'runway_exception.dart';

/// Use when there is dual assignage to a runway.
class RunwayOccupiedException extends RunwayException {
  RunwayOccupiedException(super.id, [super.cause]);
}
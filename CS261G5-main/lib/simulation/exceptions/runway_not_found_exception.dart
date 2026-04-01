import 'runway_exception.dart';

class RunwayNotFoundException extends RunwayException {
  RunwayNotFoundException(super.id, [super.cause]);
}
import 'dart:math';

double toRadian(
  double degrees, {
  bool boundTo2Pi = false,
  bool boundToPi = false,
}) =>
    asRadian(
      degrees * pi / 180,
      boundTo2Pi: boundTo2Pi,
      boundToPi: boundToPi,
    );

double asRadian(
  double radians, {
  bool boundTo2Pi = false,
  bool boundToPi = false,
}) {
  if (boundTo2Pi) {
    radians = radians % (pi * 2);
    if (radians < 0) {
      radians += (pi * 2);
    }
  } else if (boundToPi) {
    radians = radians % (pi * 2);
    if (radians.abs() > pi) {
      radians = radians.sign * (radians.abs() - (pi * 2));
    }
  }

  return radians;
}

double toDegree(
  double radians, {
  bool boundTo360 = false,
}) =>
    asDegree(
      radians * 180 / pi,
      boundTo360: boundTo360,
    );

double asDegree(
  double degrees, {
  bool boundTo360 = false,
}) {
  if (boundTo360) {
    degrees = degrees % 360;
    if (degrees < 0) {
      degrees += 360;
    }
  }

  return degrees;
}

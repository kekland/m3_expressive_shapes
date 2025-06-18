part of '_shapes.dart';

/*
 * Copyright 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Changes to the source code: a 1-1 Dart port of the original Kotlin code.

class Cubic {
  const Cubic({required this.points});

  factory Cubic.straightLine(Offset a, Offset b) {
    return Cubic(points: [a, Offset.lerp(a, b, 1.0 / 3.0)!, Offset.lerp(a, b, 2.0 / 3.0)!, b]);
  }

  factory Cubic.circularArc(Offset center, Offset a, Offset b) {
    final p0d = _directionVector(a - center);
    final p1d = _directionVector(b - center);
    final rotatedP0 = _rotate90(p0d);
    final rotatedP1 = _rotate90(p1d);
    final clockwise = _dotProduct(rotatedP0, b - center) >= 0;
    final cosa = _dotProduct(p0d, p1d);
    if (cosa > 0.999) return Cubic.straightLine(a, b);

    var k = (a - center).distance * 4 / 3;
    k *= sqrt(2 * (1 - cosa)) - sqrt(1 - cosa * cosa);
    k /= (1 - cosa);
    k *= clockwise ? 1 : -1;

    return Cubic(points: [a, a + rotatedP0 * k, b - rotatedP1 * k, b]);
  }

  factory Cubic.empty(Offset p) {
    return Cubic(points: [p, p, p, p]);
  }

  final List<Offset> points;

  double get _anchor0X => points[0].dx;
  double get _anchor0Y => points[0].dy;
  double get _control0X => points[1].dx;
  double get _control0Y => points[1].dy;
  double get _control1X => points[2].dx;
  double get _control1Y => points[2].dy;
  double get _anchor1X => points[3].dx;
  double get _anchor1Y => points[3].dy;

  Offset _pointOnCurve(double t) {
    final u = 1 - t;

    return Offset(
      _anchor0X * (u * u * u) + _control0X * (3 * t * u * u) + _control1X * (3 * t * t * u) + _anchor1X * (t * t * t),
      _anchor0Y * (u * u * u) + _control0Y * (3 * t * u * u) + _control1Y * (3 * t * t * u) + _anchor1Y * (t * t * t),
    );
  }

  bool _zeroLength() {
    return (_anchor0X - _anchor1X).abs() < _distanceEpsilon && (_anchor0Y - _anchor1Y).abs() < _distanceEpsilon;
  }

  bool _convexTo(Cubic next) {
    final prevVertex = Offset(_anchor0X, _anchor0Y);
    final currVertex = Offset(_anchor1X, _anchor1Y);
    final nextVertex = Offset(next._anchor1X, next._anchor1Y);
    return _convex(prevVertex, currVertex, nextVertex);
  }

  bool _zeroIsh(double v) => v.abs() < _distanceEpsilon;

  Rect calculateBounds({bool approximate = false}) {
    if (_zeroLength()) {
      return Rect.fromLTRB(_anchor0X, _anchor0Y, _anchor0X, _anchor0Y);
    }

    var minX = min(_anchor0X, _anchor1X);
    var minY = min(_anchor0Y, _anchor1Y);
    var maxX = max(_anchor0X, _anchor1X);
    var maxY = max(_anchor0Y, _anchor1Y);

    if (approximate) {
      return Rect.fromLTRB(
        min(minX, min(_control0X, _control1X)),
        min(minY, min(_control0Y, _control1Y)),
        max(maxX, max(_control0X, _control1X)),
        max(maxY, max(_control0Y, _control1Y)),
      );
    }

    final xa = -_anchor0X + 3 * _control0X - 3 * _control1X + _anchor1X;
    final xb = 2 * _anchor0X - 4 * _control0X + 2 * _control1X;
    final xc = -_anchor0X + _control0X;

    if (_zeroIsh(xa)) {
      if (xb != 0.0) {
        final t = 2 * xc / (-2 * xb);
        if (t >= 0.0 && t <= 1.0) {
          final it = _pointOnCurve(t).dx;
          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }
      }
    } else {
      final xs = xb * xb - 4 * xa * xc;
      if (xs >= 0.0) {
        final t1 = (-xb + sqrt(xs)) / (2 * xa);
        if (t1 >= 0.0 && t1 <= 1.0) {
          final it = _pointOnCurve(t1).dx;
          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }

        final t2 = (-xb - sqrt(xs)) / (2 * xa);
        if (t2 >= 0.0 && t2 <= 1.0) {
          final it = _pointOnCurve(t2).dx;
          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }
      }
    }

    final ya = -_anchor0Y + 3 * _control0Y - 3 * _control1Y + _anchor1Y;
    final yb = 2 * _anchor0Y - 4 * _control0Y + 2 * _control1Y;
    final yc = -_anchor0Y + _control0Y;

    if (_zeroIsh(ya)) {
      if (yb != 0.0) {
        final t = 2 * yc / (-2 * yb);
        if (t >= 0.0 && t <= 1.0) {
          final it = _pointOnCurve(t).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }
      }
    } else {
      final ys = yb * yb - 4 * ya * yc;
      if (ys >= 0.0) {
        final t1 = (-yb + sqrt(ys)) / (2 * ya);
        if (t1 >= 0.0 && t1 <= 1.0) {
          final it = _pointOnCurve(t1).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }

        final t2 = (-yb - sqrt(ys)) / (2 * ya);
        if (t2 >= 0.0 && t2 <= 1.0) {
          final it = _pointOnCurve(t2).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  (Cubic, Cubic) split(double t) {
    final u = 1 - t;
    final pointOnCurve = _pointOnCurve(t);

    final cubic1 = Cubic(
      points: [
        Offset(_anchor0X, _anchor0Y),
        Offset(_anchor0X * u + _control0X * t, _anchor0Y * u + _control0Y * t),
        Offset(
          _anchor0X * (u * u) + _control0X * (2 * u * t) + _control1X * (t * t),
          _anchor0Y * (u * u) + _control0Y * (2 * u * t) + _control1Y * (t * t),
        ),
        pointOnCurve,
      ],
    );

    final cubic2 = Cubic(
      points: [
        pointOnCurve,
        Offset(
          _control0X * (u * u) + _control1X * (2 * u * t) + _anchor1X * (t * t),
          _control0Y * (u * u) + _control1Y * (2 * u * t) + _anchor1Y * (t * t),
        ),
        Offset(_control1X * u + _anchor1X * t, _control1Y * u + _anchor1Y * t),
        Offset(_anchor1X, _anchor1Y),
      ],
    );

    return (cubic1, cubic2);
  }

  Cubic reverse() {
    return Cubic(
      points: [
        Offset(_anchor1X, _anchor1Y),
        Offset(_control1X, _control1Y),
        Offset(_control0X, _control0Y),
        Offset(_anchor0X, _anchor0Y),
      ],
    );
  }

  Cubic operator +(Cubic other) {
    return Cubic(
      points: [
        points[0] + other.points[0],
        points[1] + other.points[1],
        points[2] + other.points[2],
        points[3] + other.points[3],
      ],
    );
  }

  Cubic operator *(double scale) {
    return Cubic(points: [points[0] * scale, points[1] * scale, points[2] * scale, points[3] * scale]);
  }

  Cubic operator /(double scale) {
    return this * (1 / scale);
  }

  @override
  String toString() {
    return 'Cubic(${points.map((p) => '(${p.dx}, ${p.dy})').join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Cubic) return false;
    return points[0] == other.points[0] &&
        points[1] == other.points[1] &&
        points[2] == other.points[2] &&
        points[3] == other.points[3];
  }

  @override
  int get hashCode => Object.hash(points[0], points[1], points[2], points[3]);

  Cubic transformed(PointTransformer transformer) {
    return Cubic(points: points.map(transformer).toList());
  }
}

class MutableCubic extends Cubic {
  MutableCubic({required super.points});
  MutableCubic.empty() : super(points: [Offset.zero, Offset.zero, Offset.zero, Offset.zero]);

  void transform(PointTransformer transformer) {
    for (var i = 0; i < points.length; i++) {
      points[i] = transformer(points[i]);
    }
  }

  void interpolate(Cubic c1, Cubic c2, double progress) {
    for (var i = 0; i < points.length; i++) {
      points[i] = Offset.lerp(c1.points[i], c2.points[i], progress)!;
    }
  }
}

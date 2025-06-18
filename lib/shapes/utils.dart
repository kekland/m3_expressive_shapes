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

const _distanceEpsilon = 1e-4;
const _angleEpsilon = 1e-6;

bool _clockwise(Offset p, Offset other) {
  return p.dx * other.dy - p.dy * other.dx > 0.0;
}

bool _convex(Offset previous, Offset current, Offset next) {
  return _clockwise(current - previous, next - current);
}

Offset _directionVector(Offset p) {
  final d = p.distance;
  return p.scale(1 / d, 1 / d);
}

Offset _rotate90(Offset p) {
  return Offset(-p.dy, p.dx);
}

double _dotProduct(Offset a, Offset b) {
  return a.dx * b.dx + a.dy * b.dy;
}

Offset _radialToCartesian(double radius, double angleRadians, Offset center) {
  return Offset(cos(angleRadians) * radius + center.dx, sin(angleRadians) * radius + center.dy);
}

double _positiveModulo(double n, double m) {
  return (n % m + m) % m;
}

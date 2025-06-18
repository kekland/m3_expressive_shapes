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

class DoubleMapper {
  DoubleMapper({required List<(double, double)> mappings}) {
    sourceValues = <double>[];
    targetValues = <double>[];

    for (var i = 0; i < mappings.length; i++) {
      sourceValues.add(mappings[i].$1);
      targetValues.add(mappings[i].$2);
    }

    _validateProgress(sourceValues);
    _validateProgress(targetValues);
  }

  static final identity = DoubleMapper(mappings: [(0.0, 0.0), (0.5, 0.5)]);

  late final List<double> sourceValues;
  late final List<double> targetValues;

  double map(double x) => _linearMap(sourceValues, targetValues, x);
  double mapBack(double x) => _linearMap(targetValues, sourceValues, x);
}

bool _progressInRange(double progress, double progressFrom, double progressTo) {
  if (progressTo >= progressFrom) {
    return progress >= progressFrom && progress <= progressTo;
  } else {
    return progress >= progressFrom || progress <= progressTo;
  }
}

double _linearMap(List<double> xValues, List<double> yValues, double x) {
  assert(x >= 0.0 && x < 1.0, 'Invalid progress: $x');
  final segmentStartIndex = xValues.indexed
      .firstWhere((v) => _progressInRange(x, xValues[v.$1], xValues[(v.$1 + 1) % xValues.length]))
      .$1;

  final segmentEndIndex = (segmentStartIndex + 1) % xValues.length;
  final segmentSizeX = _positiveModulo(xValues[segmentEndIndex] - xValues[segmentStartIndex], 1.0);

  final segmentSizeY = _positiveModulo(yValues[segmentEndIndex] - yValues[segmentStartIndex], 1.0);

  final positionInSegment = segmentSizeX < 0.001
      ? 0.5
      : _positiveModulo(x - xValues[segmentStartIndex], 1.0) / segmentSizeX;

  return _positiveModulo(yValues[segmentStartIndex] + segmentSizeY * positionInSegment, 1.0);
}

void _validateProgress(List<double> p) {
  var prev = p.last;
  var wraps = 0;
  for (var i = 0; i < p.length; i++) {
    final curr = p[i];
    assert(curr >= 0.0 && curr < 1.0, 'FloatMapping - Progress outside of range: $p');

    assert(_progressDistance(curr, prev) > _distanceEpsilon, 'FloatMapping - Progress repeats a value: $p');

    if (curr < prev) {
      wraps++;
      assert(wraps <= 1, 'FloatMapping - Progress wraps more than once: $p');
    }

    prev = curr;
  }
}

double _progressDistance(double p1, double p2) => min((p1 - p2).abs(), 1.0 - (p1 - p2).abs());

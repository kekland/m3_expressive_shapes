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

class Morph {
  Morph({required this.start, required this.end}) {
    _morphMatch = _match(start, end);
  }

  final RoundedPolygon start;
  final RoundedPolygon end;

  late final List<(Cubic, Cubic)> _morphMatch;

  Rect calculateBounds({bool approximate = true}) {
    final s = start.calculateBounds(approximate: approximate);
    final e = end.calculateBounds(approximate: approximate);
    return Rect.fromLTRB(min(s.left, e.left), min(s.top, e.top), max(s.right, e.right), max(s.bottom, e.bottom));
  }

  Rect calculateMaxBounds() {
    final s = start.calculateMaxBounds();
    final e = end.calculateMaxBounds();
    return Rect.fromLTRB(min(s.left, e.left), min(s.top, e.top), max(s.right, e.right), max(s.bottom, e.bottom));
  }

  List<Cubic> asCubics(double progress) {
    final ret = <Cubic>[];
    Cubic? firstCubic;
    Cubic? lastCubic;

    for (var i = 0; i < _morphMatch.length; i++) {
      final cubic = Cubic(
        points: [
          Offset.lerp(_morphMatch[i].$1.points[0], _morphMatch[i].$2.points[0], progress)!,
          Offset.lerp(_morphMatch[i].$1.points[1], _morphMatch[i].$2.points[1], progress)!,
          Offset.lerp(_morphMatch[i].$1.points[2], _morphMatch[i].$2.points[2], progress)!,
          Offset.lerp(_morphMatch[i].$1.points[3], _morphMatch[i].$2.points[3], progress)!,
        ],
      );

      firstCubic ??= cubic;
      if (lastCubic != null) ret.add(lastCubic);
      lastCubic = cubic;
    }

    if (lastCubic != null && firstCubic != null) {
      ret.add(Cubic(points: [lastCubic.points[0], lastCubic.points[1], lastCubic.points[2], firstCubic.points[0]]));
    }

    return ret;
  }

  void forEachCubic(double progress, MutableCubic cubic, void Function(MutableCubic) callback) {
    for (var i = 0; i < _morphMatch.length; i++) {
      cubic.interpolate(_morphMatch[i].$1, _morphMatch[i].$2, progress);
      callback(cubic);
    }
  }

  static List<(Cubic, Cubic)> _match(RoundedPolygon p1, RoundedPolygon p2) {
    final measuredPolygon1 = MeasuredPolygon.measurePolygon(LengthMeasurer.instance, p1);
    final measuredPolygon2 = MeasuredPolygon.measurePolygon(LengthMeasurer.instance, p2);

    final features1 = measuredPolygon1.features;
    final features2 = measuredPolygon2.features;

    final doubleMapper = featureMapper(features1, features2);

    final polygon2CutPoint = doubleMapper.map(0.0);

    final bs1 = measuredPolygon1;
    final bs2 = measuredPolygon2.cutAndShift(polygon2CutPoint);

    final ret = <(Cubic, Cubic)>[];

    var i1 = 0;
    var i2 = 0;
    var b1 = bs1.getOrNull(i1++);
    var b2 = bs2.getOrNull(i2++);

    while (b1 != null && b2 != null) {
      final b1a = i1 == bs1.length ? 1.0 : b1.endOutlineProgress;
      final b2a = i2 == bs2.length
          ? 1.0
          : doubleMapper.mapBack(_positiveModulo(b2.endOutlineProgress + polygon2CutPoint, 1.0));

      final minb = min(b1a, b2a);
      final (seg1, newb1) = b1a > minb + _angleEpsilon ? b1.cutAtProgress(minb) : (b1, bs1.getOrNull(i1++));

      final (seg2, newb2) = b2a > minb + _angleEpsilon
          ? b2.cutAtProgress(_positiveModulo(doubleMapper.map(minb) - polygon2CutPoint, 1.0))
          : (b2, bs2.getOrNull(i2++));

      ret.add((seg1.cubic, seg2.cubic));
      b1 = newb1;
      b2 = newb2;
    }

    assert(b1 == null && b2 == null, 'Expected both polygon\'s cubic to be fully matched');
    return ret;
  }
}

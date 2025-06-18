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

class RoundedPolygon {
  RoundedPolygon({required this.features, required this.center}) {
    final cubics = <Cubic>[];

    Cubic? firstCubic;
    Cubic? lastCubic;
    List<Cubic>? firstFeatureSplitStart;
    List<Cubic>? firstFeatureSplitEnd;

    if (features.isNotEmpty && features.first.cubics.length == 3) {
      final centerCubic = features.first.cubics[1];
      final (start, end) = centerCubic.split(0.5);
      firstFeatureSplitStart = [features.first.cubics[0], start];
      firstFeatureSplitEnd = [end, features.first.cubics[2]];
    }

    for (var i = 0; i <= features.length; i++) {
      final List<Cubic> featureCubics;
      if (i == 0 && firstFeatureSplitEnd != null) {
        featureCubics = firstFeatureSplitEnd;
      } else if (i == features.length) {
        if (firstFeatureSplitStart != null) {
          featureCubics = firstFeatureSplitStart;
        } else {
          break;
        }
      } else {
        featureCubics = features[i].cubics;
      }

      for (var j = 0; j < featureCubics.length; j++) {
        final cubic = featureCubics[j];
        if (!cubic._zeroLength()) {
          if (lastCubic != null) cubics.add(lastCubic);
          lastCubic = cubic;
          firstCubic ??= cubic;
        } else {
          if (lastCubic != null) {
            lastCubic = Cubic(points: lastCubic.points.toList());
            lastCubic.points[3] = cubic.points[3];
          }
        }
      }
    }

    if (lastCubic != null && firstCubic != null) {
      cubics.add(Cubic(points: [lastCubic.points[0], lastCubic.points[1], lastCubic.points[2], firstCubic.points[0]]));
    } else {
      cubics.add(Cubic(points: [center, center, center, center]));
    }

    this.cubics = cubics;
  }

  factory RoundedPolygon.fromNumVertices(
    int numVertices, {
    double radius = 1.0,
    Offset center = Offset.zero,
    CornerRounding rounding = CornerRounding.unrounded,
    List<CornerRounding>? perVertexRounding,
  }) {
    return RoundedPolygon.fromVertices(
      _verticesFromNumVertices(numVertices, radius, center),
      rounding: rounding,
      perVertexRounding: perVertexRounding,
      center: center,
    );
  }

  factory RoundedPolygon.fromVertices(
    List<Offset> vertices, {
    CornerRounding rounding = CornerRounding.unrounded,
    List<CornerRounding>? perVertexRounding,
    Offset? center,
  }) {
    if (vertices.length < 3) {
      throw ArgumentError('Polygons must have at least 3 vertices');
    }

    if (perVertexRounding != null && perVertexRounding.length != vertices.length) {
      throw ArgumentError('perVertexRounding must have the same length as vertices');
    }

    final corners = <List<Cubic>>[];
    final n = vertices.length;
    final roundedCorners = <_RoundedCorner>[];
    for (var i = 0; i < n; i++) {
      final vtxRounding = perVertexRounding?[i] ?? rounding;
      final prevIndex = (i - 1 + n) % n;
      final nextIndex = (i + 1) % n;
      roundedCorners.add(
        _RoundedCorner(p0: vertices[prevIndex], p1: vertices[i], p2: vertices[nextIndex], rounding: vtxRounding),
      );
    }

    final cutAdjusts = List.generate(n, (i) {
      final expectedRoundCut = roundedCorners[i].expectedRoundCut + roundedCorners[(i + 1) % n].expectedRoundCut;

      final expectedCut = roundedCorners[i].expectedCut + roundedCorners[(i + 1) % n].expectedCut;

      final vtx = vertices[i];
      final nextVtx = vertices[(i + 1) % n];
      final sideSize = (vtx - nextVtx).distance;

      if (expectedRoundCut > sideSize) {
        return (sideSize / expectedRoundCut, 0.0);
      } else if (expectedCut > sideSize) {
        return (1.0, (sideSize - expectedRoundCut) / (expectedCut - expectedRoundCut));
      } else {
        return (1.0, 1.0);
      }
    });

    for (var i = 0; i < n; i++) {
      final allowedCuts = <double>[];
      for (var delta = 0; delta <= 1; delta++) {
        final (roundCutRatio, cutRatio) = cutAdjusts[(i + n - 1 + delta) % n];
        allowedCuts.add(
          roundedCorners[i].expectedRoundCut * roundCutRatio +
              (roundedCorners[i].expectedCut - roundedCorners[i].expectedRoundCut) * cutRatio,
        );
      }

      corners.add(roundedCorners[i].getCubics(allowedCuts[0], allowedCuts[1]));
    }

    final features = <Feature>[];
    for (var i = 0; i < n; i++) {
      final prevVtxIndex = (i - 1 + n) % n;
      final nextVtxIndex = (i + 1) % n;
      final currVertex = vertices[i];
      final prevVertex = vertices[prevVtxIndex];
      final nextVertex = vertices[nextVtxIndex];
      final convex = _convex(prevVertex, currVertex, nextVertex);
      features.add(_FeatureCorner(cubics: corners[i], convex: convex));
      features.add(
        _FeatureEdge(cubics: [Cubic.straightLine(corners[i].last.points[3], corners[nextVtxIndex].first.points[0])]),
      );
    }

    return RoundedPolygon(features: features, center: center ?? _calculateCenter(vertices));
  }

  factory RoundedPolygon.fromFeatures(List<Feature> features, {Offset? center}) {
    assert(features.length >= 2, 'Polygons must have at least 2 features');

    final vertices = <Offset>[];
    for (final f in features) {
      for (final c in f.cubics) {
        vertices.add(c.points[0]);
      }
    }

    return RoundedPolygon(features: features, center: center ?? _calculateCenter(vertices));
  }

  final List<Feature> features;
  final Offset center;
  late final List<Cubic> cubics;

  RoundedPolygon transformed(PointTransformer transformer) {
    return RoundedPolygon(
      features: features.map((f) => f.transformed(transformer)).toList(growable: false),
      center: transformer(center),
    );
  }

  RoundedPolygon normalized() {
    final bounds = calculateBounds();
    final width = bounds.width;
    final height = bounds.height;
    final side = bounds.longestSide;

    final offsetX = (side - width) / 2 - bounds.left;
    final offsetY = (side - height) / 2 - bounds.top;
    return transformed((p) => Offset((p.dx + offsetX) / side, (p.dy + offsetY) / side));
  }

  Rect calculateMaxBounds() {
    var maxDistSqr = 0.0;
    for (final c in cubics) {
      final anchorDistance = (c.points[0] - center).distanceSquared;
      final middlePoint = c._pointOnCurve(0.5);
      final middleDistance = (middlePoint - center).distanceSquared;
      maxDistSqr = max(maxDistSqr, max(anchorDistance, middleDistance));
    }

    final distance = sqrt(maxDistSqr);
    return Rect.fromCircle(center: center, radius: distance);
  }

  Rect calculateBounds({bool approximate = true}) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final c in cubics) {
      final cubicBounds = c.calculateBounds(approximate: approximate);
      minX = min(minX, cubicBounds.left);
      minY = min(minY, cubicBounds.top);
      maxX = max(maxX, cubicBounds.right);
      maxY = max(maxY, cubicBounds.bottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  String toString() {
    return 'RoundedPolygon(center: $center, features: $features, cubics: $cubics)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is RoundedPolygon && other.center == center && listEquals(other.features, features);
  }

  @override
  int get hashCode {
    return Object.hash(center, Object.hashAll(features));
  }
}

Offset _calculateCenter(List<Offset> vertices) {
  double sumX = 0.0;
  double sumY = 0.0;
  for (final v in vertices) {
    sumX += v.dx;
    sumY += v.dy;
  }
  return Offset(sumX / vertices.length, sumY / vertices.length);
}

List<Offset> _verticesFromNumVertices(int numVertices, double radius, Offset center) {
  final result = <Offset>[];

  for (var i = 0; i < numVertices; i++) {
    final vertex = _radialToCartesian(radius, pi / numVertices * 2 * i, center);
    result.add(vertex);
  }

  return result;
}

class _RoundedCorner {
  _RoundedCorner({required this.p0, required this.p1, required this.p2, required this.rounding}) {
    final v01 = p0 - p1;
    final v21 = p2 - p1;
    final d01 = v01.distance;
    final d21 = v21.distance;

    if (d01 > 0.0 && d21 > 0.0) {
      d1 = v01 / d01;
      d2 = v21 / d21;
      cornerRadius = rounding?.radius ?? 0.0;
      smoothing = rounding?.smoothing ?? 0.0;

      cosAngle = _dotProduct(d1, d2);
      sinAngle = sqrt(1 - cosAngle * cosAngle);

      expectedRoundCut = sinAngle > 1e-3 ? cornerRadius * (cosAngle + 1) / sinAngle : 0.0;
    } else {
      d1 = Offset.zero;
      d2 = Offset.zero;
      cornerRadius = 0.0;
      smoothing = 0.0;
      cosAngle = 0.0;
      sinAngle = 0.0;
      expectedRoundCut = 0.0;
    }
  }

  final Offset p0;
  final Offset p1;
  final Offset p2;
  final CornerRounding? rounding;

  late final Offset d1;
  late final Offset d2;
  late final double cornerRadius;
  late final double smoothing;
  late final double cosAngle;
  late final double sinAngle;
  late final double expectedRoundCut;

  double get expectedCut => ((1 + smoothing) * expectedRoundCut);
  Offset center = Offset.zero;

  List<Cubic> getCubics(double allowedCut0, double? _allowedCut1) {
    final allowedCut1 = _allowedCut1 ?? allowedCut0;
    final allowedCut = min(allowedCut0, allowedCut1);

    if (expectedRoundCut < _distanceEpsilon || expectedCut < _distanceEpsilon) {
      center = p1;
      return [Cubic.straightLine(p1, p1)];
    }

    final actualRoundCut = min(allowedCut, expectedRoundCut);
    final actualSmoothing0 = calculateActualSmoothingValue(allowedCut0);
    final actualSmoothing1 = calculateActualSmoothingValue(allowedCut1);

    final actualR = cornerRadius * actualRoundCut / expectedRoundCut;
    final centerDistance = sqrt(actualR * actualR + actualRoundCut * actualRoundCut);

    center = p1 + _directionVector((d1 + d2) / 2.0) * centerDistance;

    final circleIntersection0 = p1 + d1 * actualRoundCut;
    final circleIntersection2 = p1 + d2 * actualRoundCut;

    final flanking0 = computeFlankingCurve(
      actualRoundCut,
      actualSmoothing0,
      p1,
      p0,
      circleIntersection0,
      circleIntersection2,
      center,
      actualR,
    );

    final flanking2 = computeFlankingCurve(
      actualRoundCut,
      actualSmoothing1,
      p1,
      p2,
      circleIntersection2,
      circleIntersection0,
      center,
      actualR,
    ).reverse();

    return [flanking0, Cubic.circularArc(center, flanking0.points[3], flanking2.points[0]), flanking2];
  }

  double calculateActualSmoothingValue(double allowedCut) {
    if (allowedCut > expectedCut) {
      return smoothing;
    } else if (allowedCut > expectedRoundCut) {
      return smoothing * (allowedCut - expectedRoundCut) / (expectedCut - expectedRoundCut);
    } else {
      return 0.0;
    }
  }

  Cubic computeFlankingCurve(
    double actualRoundCut,
    double actualSmoothingValues,
    Offset corner,
    Offset sideStart,
    Offset circleSegmentIntersection,
    Offset otherCircleSegmentIntersection,
    Offset circleCenter,
    double actualR,
  ) {
    final sideDirection = _directionVector(sideStart - corner);
    final curveStart = corner + sideDirection * actualRoundCut * (1 + actualSmoothingValues);

    final p = Offset.lerp(
      circleSegmentIntersection,
      (circleSegmentIntersection + otherCircleSegmentIntersection) / 2,
      actualSmoothingValues,
    )!;

    final curveEnd = circleCenter + _directionVector(p - circleCenter) * actualR;
    final circleTangent = _rotate90(curveEnd - circleCenter);
    final anchorEnd = lineIntersection(sideStart, sideDirection, curveEnd, circleTangent) ?? circleSegmentIntersection;

    final anchorStart = (curveStart + anchorEnd * 2.0) / 3.0;
    return Cubic(points: [curveStart, anchorStart, anchorEnd, curveEnd]);
  }

  Offset? lineIntersection(Offset p0, Offset d0, Offset p1, Offset d1) {
    final rotatedD1 = _rotate90(d1);
    final den = _dotProduct(d0, rotatedD1);
    if (den.abs() < _distanceEpsilon) return null;

    final n = _dotProduct((p1 - p0), rotatedD1);
    if (den.abs() < _distanceEpsilon * n.abs()) return null;

    final k = n / den;
    return p0 + d0 * k;
  }
}

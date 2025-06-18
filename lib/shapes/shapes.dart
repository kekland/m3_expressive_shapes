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

extension RoundedPolygonShapes on RoundedPolygon {
  static RoundedPolygon circle({int numVertices = 8, double radius = 1.0, Offset center = Offset.zero}) {
    if (numVertices < 3) throw ArgumentError('Circle must have at least three vertices');

    final theta = pi / numVertices;
    final polygonRadius = radius / cos(theta);

    return RoundedPolygon.fromNumVertices(
      numVertices,
      rounding: CornerRounding(radius),
      radius: polygonRadius,
      center: center,
    );
  }

  static RoundedPolygon rectangle({
    double width = 2.0,
    double height = 2.0,
    CornerRounding rounding = CornerRounding.unrounded,
    List<CornerRounding>? perVertexRounding,
    Offset center = Offset.zero,
  }) {
    final left = center.dx - width / 2;
    final top = center.dy - height / 2;
    final right = center.dx + width / 2;
    final bottom = center.dy + height / 2;

    return RoundedPolygon.fromVertices(
      [Offset(right, bottom), Offset(left, bottom), Offset(left, top), Offset(right, top)],
      rounding: rounding,
      perVertexRounding: perVertexRounding,
      center: center,
    );
  }

  static RoundedPolygon star({
    required int numVerticesPerRadius,
    double radius = 1.0,
    double innerRadius = 0.5,
    CornerRounding rounding = CornerRounding.unrounded,
    CornerRounding? innerRounding,
    List<CornerRounding>? perVertexRounding,
    Offset center = Offset.zero,
  }) {
    if (radius <= 0.0 || innerRadius <= 0.0) {
      throw ArgumentError('Star radii must both be greater than 0');
    }

    if (innerRadius >= radius) {
      throw ArgumentError('innerRadius must be less than radius');
    }

    var pvRounding = perVertexRounding;
    if (pvRounding == null && innerRounding != null) {
      pvRounding = List.filled(numVerticesPerRadius * 2, innerRounding, growable: false);
      for (var i = 0; i < pvRounding.length; i += 2) {
        pvRounding[i] = rounding;
        pvRounding[i + 1] = innerRounding;
      }
    }

    return RoundedPolygon.fromVertices(
      _starVerticesFromNumVerts(numVerticesPerRadius, radius, innerRadius, center),
      rounding: rounding,
      perVertexRounding: pvRounding,
      center: center,
    );
  }

  static RoundedPolygon pill({
    double width = 2.0,
    double height = 1.0,
    double smoothing = 0.0,
    Offset center = Offset.zero,
  }) {
    if (width <= 0.0 || height <= 0.0) {
      throw ArgumentError('Pill width and height must both be greater than 0');
    }

    final wHalf = width / 2;
    final hHalf = height / 2;

    return RoundedPolygon.fromVertices(
      [
        Offset(wHalf + center.dx, hHalf + center.dy),
        Offset(-wHalf + center.dx, hHalf + center.dy),
        Offset(-wHalf + center.dx, -hHalf + center.dy),
        Offset(wHalf + center.dx, -hHalf + center.dy),
      ],
      rounding: CornerRounding(min(wHalf, hHalf), smoothing),
      center: center,
    );
  }

  static RoundedPolygon pillStar({
    double width = 2.0,
    double height = 1.0,
    int numVerticesPerRadius = 8,
    double innerRadiusRatio = 0.5,
    CornerRounding rounding = CornerRounding.unrounded,
    CornerRounding? innerRounding,
    List<CornerRounding>? perVertexRounding,
    double vertexSpacing = 0.5,
    double startLocation = 0.0,
    Offset center = Offset.zero,
  }) {
    if (width <= 0.0 || height <= 0.0) {
      throw ArgumentError('Pill star width and height must both be greater than 0');
    }

    if (innerRadiusRatio <= 0.0 || innerRadiusRatio >= 1.0) {
      throw ArgumentError('innerRadiusRatio must be between 0 and 1');
    }

    var pvRounding = perVertexRounding;
    if (pvRounding == null && innerRounding != null) {
      pvRounding = List.filled(numVerticesPerRadius * 2, innerRounding, growable: false);
      for (var i = 0; i < pvRounding.length; i += 2) {
        pvRounding[i] = rounding;
        pvRounding[i + 1] = innerRounding;
      }
    }

    return RoundedPolygon.fromVertices(
      _pillStarVerticesFromNumVerts(
        numVerticesPerRadius,
        width,
        height,
        innerRadiusRatio,
        vertexSpacing,
        startLocation,
        center,
      ),
      rounding: rounding,
      perVertexRounding: pvRounding,
      center: center,
    );
  }
}

List<Offset> _pillStarVerticesFromNumVerts(
  int numVerticesPerRadius,
  double width,
  double height,
  double innerRadius,
  double vertexSpacing,
  double startLocation,
  Offset center,
) {
  final endcapRadius = min(width, height);
  final vSegLen = (height - width).clamp(0.0, double.infinity);
  final hSegLen = (width - height).clamp(0.0, double.infinity);
  final vSegHalf = vSegLen / 2;
  final hSegHalf = hSegLen / 2;

  final circlePerimeter = 2 * pi * endcapRadius * lerpDouble(innerRadius, 1.0, vertexSpacing)!;
  final perimeter = 2 * hSegLen + 2 * vSegLen + circlePerimeter;

  final sections = List.filled(11, 0.0, growable: false);
  sections[0] = 0.0;
  sections[1] = vSegHalf;
  sections[2] = sections[1] + circlePerimeter / 4;
  sections[3] = sections[2] + hSegLen;
  sections[4] = sections[3] + circlePerimeter / 4;
  sections[5] = sections[4] + vSegLen;
  sections[6] = sections[5] + circlePerimeter / 4;
  sections[7] = sections[6] + hSegLen;
  sections[8] = sections[7] + circlePerimeter / 4;
  sections[9] = sections[8] + vSegHalf;
  sections[10] = perimeter;

  final tPerVertex = perimeter / (numVerticesPerRadius * 2);
  var inner = false;
  var currSecIndex = 0;
  var secStart = 0.0;
  var secEnd = sections[1];
  var t = startLocation * perimeter;

  final result = List.filled(numVerticesPerRadius * 2, Offset.zero, growable: false);
  var arrayIndex = 0;
  final rectBR = Offset(hSegHalf, vSegHalf);
  final rectBL = Offset(-hSegHalf, vSegHalf);
  final rectTL = Offset(-hSegHalf, -vSegHalf);
  final rectTR = Offset(hSegHalf, -vSegHalf);

  for (var i = 0; i < numVerticesPerRadius * 2; i++) {
    final boundedT = t % perimeter;
    if (boundedT < secStart) currSecIndex = 0;
    while (boundedT >= sections[(currSecIndex + 1) % sections.length]) {
      currSecIndex = (currSecIndex + 1) % sections.length;
      secStart = sections[currSecIndex];
      secEnd = sections[(currSecIndex + 1) % sections.length];
    }

    final tInSection = boundedT - secStart;
    final tProportion = tInSection / (secEnd - secStart);

    final currRadius = inner ? endcapRadius * innerRadius : endcapRadius;
    final vertex = switch (currSecIndex) {
      0 => Offset(currRadius, tProportion * vSegHalf),
      1 => _radialToCartesian(currRadius, tProportion * pi / 2, rectBR),
      2 => Offset(hSegHalf - tProportion * hSegLen, currRadius),
      3 => _radialToCartesian(currRadius, pi / 2 + (tProportion * pi / 2), rectBL),
      4 => Offset(-currRadius, vSegHalf - tProportion * vSegLen),
      5 => _radialToCartesian(currRadius, pi + (tProportion * pi / 2), rectTL),
      6 => Offset(-hSegHalf + tProportion * hSegLen, -currRadius),
      7 => _radialToCartesian(currRadius, pi * 1.5 + (tProportion * pi / 2), rectTR),
      _ => Offset(currRadius, -vSegHalf + tProportion * vSegHalf),
    };

    result[arrayIndex++] = vertex + center;
    t += tPerVertex;
    inner = !inner;
  }

  return result;
}

List<Offset> _starVerticesFromNumVerts(int numVerticesPerRadius, double radius, double innerRadius, Offset center) {
  final result = List.filled(numVerticesPerRadius * 2, Offset.zero, growable: false);
  var arrayIndex = 0;

  for (var i = 0; i < numVerticesPerRadius; i++) {
    final vertex = _radialToCartesian(radius, (pi / numVerticesPerRadius * 2 * i), center);
    result[arrayIndex++] = vertex;

    final innerVertex = _radialToCartesian(innerRadius, (pi / numVerticesPerRadius * (2 * i + 1)), center);
    result[arrayIndex++] = innerVertex;
  }

  return result;
}

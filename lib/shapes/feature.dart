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

abstract class Feature {
  const Feature({required this.cubics});

  static Feature _validated(Feature feature) {
    assert(feature.cubics.isNotEmpty, 'Features need at least one cubic.');
    assert(
      _isContinuous(feature),
      'Feature must be continuous, with the anchor points of all cubics matching the anchor points of the preceding and succeeding cubics',
    );

    return feature;
  }

  static bool _isContinuous(Feature feature) {
    var prevCubic = feature.cubics.first;

    for (var i = 1; i < feature.cubics.length; i++) {
      final cubic = feature.cubics[i];
      if ((cubic._anchor0X - prevCubic._anchor1X).abs() > _distanceEpsilon ||
          (cubic._anchor0Y - prevCubic._anchor1Y).abs() > _distanceEpsilon) {
        return false;
      }
      prevCubic = cubic;
    }

    return true;
  }

  factory Feature.buildIgnorableFeature(List<Cubic> cubics) {
    return _validated(_FeatureEdge(cubics: cubics));
  }

  factory Feature.buildEdge(List<Cubic> cubics) {
    return _validated(_FeatureEdge(cubics: cubics));
  }

  factory Feature.buildConvexCorner(List<Cubic> cubics) {
    return _validated(_FeatureCorner(cubics: cubics, convex: true));
  }

  factory Feature.buildConcaveCorner(List<Cubic> cubics) {
    return _validated(_FeatureCorner(cubics: cubics, convex: false));
  }

  final List<Cubic> cubics;

  Feature transformed(PointTransformer transformer);
  Feature reversed();

  bool get isIgnorableFeature;
  bool get isEdge;
  bool get isConvexCorner;
  bool get isConcaveCorner;

  @override
  String toString() {
    return 'Feature(${cubics.length} cubics, '
        'isIgnorableFeature: $isIgnorableFeature, '
        'isEdge: $isEdge, '
        'isConvexCorner: $isConvexCorner, '
        'isConcaveCorner: $isConcaveCorner)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Feature) return false;
    return listEquals(cubics, other.cubics) &&
        isIgnorableFeature == other.isIgnorableFeature &&
        isEdge == other.isEdge &&
        isConvexCorner == other.isConvexCorner &&
        isConcaveCorner == other.isConcaveCorner;
  }

  @override
  int get hashCode {
    return Object.hash(
      cubics,
      isIgnorableFeature,
      isEdge,
      isConvexCorner,
      isConcaveCorner,
    );
  }
}

class _FeatureEdge extends Feature {
  _FeatureEdge({required super.cubics});

  @override
  Feature transformed(PointTransformer transformer) {
    return _FeatureEdge(
      cubics: cubics.map((c) => c.transformed(transformer)).toList(),
    );
  }

  @override
  Feature reversed() {
    return _FeatureEdge(cubics: cubics.map((c) => c.reverse()).toList());
  }

  @override
  bool get isIgnorableFeature => true;

  @override
  bool get isEdge => true;

  @override
  bool get isConvexCorner => false;

  @override
  bool get isConcaveCorner => false;
}

class _FeatureCorner extends Feature {
  const _FeatureCorner({required super.cubics, required this.convex});

  final bool convex;

  @override
  Feature transformed(PointTransformer transformer) {
    return _FeatureCorner(
      cubics: cubics.map((c) => c.transformed(transformer)).toList(),
      convex: convex,
    );
  }

  @override
  Feature reversed() {
    return _FeatureCorner(
      cubics: cubics.map((c) => c.reverse()).toList(),
      convex: !convex,
    );
  }

  @override
  bool get isIgnorableFeature => false;

  @override
  bool get isEdge => false;

  @override
  bool get isConvexCorner => convex;

  @override
  bool get isConcaveCorner => !convex;
}

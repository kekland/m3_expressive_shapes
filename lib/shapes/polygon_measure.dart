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

class MeasuredPolygon {
  MeasuredPolygon._({required this.measurer, required this.cubics, required this.features});

  factory MeasuredPolygon._internal({
    required Measurer measurer,
    required List<Cubic> cubics,
    required List<ProgressableFeature> features,
    required List<double> outlineProgress,
  }) {
    assert(outlineProgress.length == cubics.length + 1, 'Outline progress size is expected to be the cubics size + 1');

    assert(outlineProgress.first == 0.0, 'First outline progress value is expected to be zero');
    assert(outlineProgress.last == 1.0, 'Last outline progress value is expected to be one');

    final measuredCubics = <MeasuredCubic>[];
    var startOutlineProgress = 0.0;

    for (var i = 0; i < cubics.length; i++) {
      if ((outlineProgress[i + 1] - outlineProgress[i]) > _distanceEpsilon) {
        measuredCubics.add(
          MeasuredCubic(
            measurer: measurer,
            cubic: cubics[i],
            startOutlineProgress: startOutlineProgress,
            endOutlineProgress: outlineProgress[i + 1],
          ),
        );

        startOutlineProgress = outlineProgress[i + 1];
      }
    }

    measuredCubics.last.updateProgressRange(endOutlineProgress: 1.0);
    return MeasuredPolygon._(measurer: measurer, cubics: measuredCubics, features: features);
  }

  factory MeasuredPolygon.measurePolygon(Measurer measurer, RoundedPolygon polygon) {
    final cubics = <Cubic>[];
    final featureToCubic = <(Feature, int)>[];

    for (var featureIndex = 0; featureIndex < polygon.features.length; featureIndex++) {
      final feature = polygon.features[featureIndex];
      for (var cubicIndex = 0; cubicIndex < feature.cubics.length; cubicIndex++) {
        if (feature is _FeatureCorner && cubicIndex == feature.cubics.length ~/ 2) {
          featureToCubic.add((feature, cubics.length));
        }

        cubics.add(feature.cubics[cubicIndex]);
      }
    }

    final measures = <double>[0.0];
    for (var i = 0; i < cubics.length; i++) {
      final measure = measures.last;
      final newM = measurer.measureCubic(cubics[i]);
      assert(newM >= 0.0, 'Measured cubic is expected to be greater or equal to zero');
      measures.add(measure + newM);
    }

    final totalMeasure = measures.last;
    final outlineProgress = <double>[];
    for (var i = 0; i < measures.length; i++) {
      outlineProgress.add(measures[i] / totalMeasure);
    }

    final features = <ProgressableFeature>[];
    for (var i = 0; i < featureToCubic.length; i++) {
      final ix = featureToCubic[i].$2;

      features.add(
        ProgressableFeature(
          progress: _positiveModulo((outlineProgress[ix] + outlineProgress[ix + 1]) / 2, 1.0),
          feature: featureToCubic[i].$1,
        ),
      );
    }

    return MeasuredPolygon._internal(
      measurer: measurer,
      cubics: cubics,
      features: features,
      outlineProgress: outlineProgress,
    );
  }

  final Measurer measurer;
  final List<MeasuredCubic> cubics;
  final List<ProgressableFeature> features;

  MeasuredPolygon cutAndShift(double cuttingPoint) {
    assert(cuttingPoint >= 0 && cuttingPoint <= 1, 'Cutting point is expected to be between 0 and 1');
    if (cuttingPoint < _distanceEpsilon) return this;

    final targetIndex = cubics.indexWhere(
      (c) => c.startOutlineProgress <= cuttingPoint && c.endOutlineProgress >= cuttingPoint,
    );
    final target = cubics[targetIndex];
    final (b1, b2) = target.cutAtProgress(cuttingPoint);
    final retCubics = <Cubic>[b2.cubic];
    for (var i = 1; i < cubics.length; i++) {
      retCubics.add(cubics[(i + targetIndex) % cubics.length].cubic);
    }
    retCubics.add(b1.cubic);

    final retOutlineProgress = <double>[];
    for (var i = 0; i < cubics.length + 2; i++) {
      if (i == 0) {
        retOutlineProgress.add(0.0);
      } else if (i == cubics.length + 1) {
        retOutlineProgress.add(1.0);
      } else {
        final cubicIndex = (targetIndex + i - 1) % cubics.length;
        retOutlineProgress.add(_positiveModulo(cubics[cubicIndex].endOutlineProgress - cuttingPoint, 1.0));
      }
    }

    final newFeatures = <ProgressableFeature>[];
    for (var i = 0; i < features.length; i++) {
      newFeatures.add(
        ProgressableFeature(
          progress: _positiveModulo(features[i].progress - cuttingPoint, 1.0),
          feature: features[i].feature,
        ),
      );
    }

    return MeasuredPolygon._internal(
      measurer: measurer,
      cubics: retCubics,
      features: newFeatures,
      outlineProgress: retOutlineProgress,
    );
  }

  int get length => cubics.length;
  MeasuredCubic operator [](int index) {
    assert(index >= 0 && index < cubics.length, 'Index out of bounds');
    return cubics[index];
  }

  MeasuredCubic? getOrNull(int i) {
    if (i < 0 || i >= cubics.length) return null;
    return cubics[i];
  }
}

class MeasuredCubic {
  MeasuredCubic({
    required this.measurer,
    required this.cubic,
    required this.startOutlineProgress,
    required this.endOutlineProgress,
  });

  final Measurer measurer;
  final Cubic cubic;
  double startOutlineProgress;
  double endOutlineProgress;

  late final measuredSize = measurer.measureCubic(cubic);

  void updateProgressRange({double? startOutlineProgress, double? endOutlineProgress}) {
    this.startOutlineProgress = startOutlineProgress ?? this.startOutlineProgress;
    this.endOutlineProgress = endOutlineProgress ?? this.endOutlineProgress;
    assert(
      this.endOutlineProgress >= this.startOutlineProgress,
      'endOutlineProgress is expected to be equal or greater than startOutlineProgress',
    );
  }

  (MeasuredCubic, MeasuredCubic) cutAtProgress(double cutOutlineProgress) {
    final boundedCutOutlineProgress = cutOutlineProgress.clamp(startOutlineProgress, endOutlineProgress);

    final outlineProgressSize = endOutlineProgress - startOutlineProgress;
    final progressFromStart = boundedCutOutlineProgress - startOutlineProgress;

    final relativeProgress = progressFromStart / outlineProgressSize;
    final t = measurer.findCubicCutPoint(cubic, relativeProgress * measuredSize);
    assert(t >= 0 && t <= 1, 'Cubic cut point is expected to be between 0 and 1');

    final (c1, c2) = cubic.split(t);
    return (
      MeasuredCubic(
        measurer: measurer,
        cubic: c1,
        startOutlineProgress: startOutlineProgress,
        endOutlineProgress: boundedCutOutlineProgress,
      ),
      MeasuredCubic(
        measurer: measurer,
        cubic: c2,
        startOutlineProgress: boundedCutOutlineProgress,
        endOutlineProgress: endOutlineProgress,
      ),
    );
  }
}

abstract class Measurer {
  double measureCubic(Cubic c);
  double findCubicCutPoint(Cubic c, double m);
}

class LengthMeasurer implements Measurer {
  const LengthMeasurer();

  static const segments = 3;
  static const instance = LengthMeasurer();

  @override
  double measureCubic(Cubic c) {
    return closestProgressTo(c, double.infinity).$2;
  }

  @override
  double findCubicCutPoint(Cubic c, double m) {
    return closestProgressTo(c, m).$1;
  }

  (double, double) closestProgressTo(Cubic c, double threshold) {
    var total = 0.0;
    var remainder = threshold;
    var prev = c.points[0];

    for (var i = 1; i <= segments; i++) {
      final progress = i / segments;
      final point = c._pointOnCurve(progress);
      final segment = (point - prev).distance;

      if (segment >= remainder) {
        return (progress - (1.0 - remainder / segment) / segments, threshold);
      }

      remainder -= segment;
      total += segment;
      prev = point;
    }

    return (1.0, total);
  }
}

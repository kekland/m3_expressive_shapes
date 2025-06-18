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

class ProgressableFeature {
  const ProgressableFeature({required this.progress, required this.feature});

  final double progress;
  final Feature feature;

  ProgressableFeature copyWith({double? progress, Feature? feature}) {
    return ProgressableFeature(progress: progress ?? this.progress, feature: feature ?? this.feature);
  }
}

DoubleMapper featureMapper(List<ProgressableFeature> features1, List<ProgressableFeature> features2) {
  final filteredFeatures1 = features1.indexed.where((x) => x.$2.feature is _FeatureCorner).map((v) => v.$2);
  final filteredFeatures2 = features2.indexed.where((x) => x.$2.feature is _FeatureCorner).map((v) => v.$2);

  final featureProgressMapping = _doMapping(filteredFeatures1, filteredFeatures2);
  return DoubleMapper(mappings: featureProgressMapping);
}

typedef DistanceVertex = (double, ProgressableFeature, ProgressableFeature);

List<(double, double)> _doMapping(Iterable<ProgressableFeature> features1, Iterable<ProgressableFeature> features2) {
  final distanceVertexList = <DistanceVertex>[];
  for (final f1 in features1) {
    for (final f2 in features2) {
      final d = _featureDistSquared(f1.feature, f2.feature);
      if (d != double.maxFinite) {
        distanceVertexList.add((d, f1, f2));
      }
    }
  }
  distanceVertexList.sort((a, b) => a.$1.compareTo(b.$1));
  if (distanceVertexList.isEmpty) return _identityMapping;
  if (distanceVertexList.length == 1) {
    final f = distanceVertexList.first;
    final f1 = f.$2.progress;
    final f2 = f.$3.progress;
    return [(f1, f2), ((f1 + 0.5) % 1.0, (f2 + 0.5) % 1.0)];
  }

  final helper = MappingHelper();
  for (final v in distanceVertexList) {
    helper.addMapping(v.$2, v.$3);
  }

  return helper.zip();
}

class MappingHelper {
  final _mapping1 = <double>[];
  final _mapping2 = <double>[];
  final _usedF1 = <ProgressableFeature>{};
  final _usedF2 = <ProgressableFeature>{};

  void addMapping(ProgressableFeature f1, ProgressableFeature f2) {
    if (_usedF1.contains(f1) || _usedF2.contains(f2)) return;

    final exists = binarySearch(_mapping1, f1.progress) != -1;
    assert(!exists, 'There can\'t be two features with the same progress');
    final insertionIndex = lowerBound(_mapping1, f1.progress);
    final n = _mapping1.length;

    if (n >= 1) {
      final i1 = (insertionIndex + n - 1) % n;
      final i2 = insertionIndex % n;
      final before1 = _mapping1[i1];
      final before2 = _mapping2[i1];
      final after1 = _mapping1[i2];
      final after2 = _mapping2[i2];

      if (_progressDistance(f1.progress, before1) < _distanceEpsilon ||
          _progressDistance(f1.progress, after1) < _distanceEpsilon ||
          _progressDistance(f2.progress, before2) < _distanceEpsilon ||
          _progressDistance(f2.progress, after2) < _distanceEpsilon) {
        return;
      }

      if (n > 1 && !_progressInRange(f2.progress, before2, after2)) return;
    }

    _mapping1.insert(insertionIndex, f1.progress);
    _mapping2.insert(insertionIndex, f2.progress);
    _usedF1.add(f1);
    _usedF2.add(f2);
  }

  List<(double, double)> zip() {
    final result = <(double, double)>[];
    for (var i = 0; i < _mapping1.length; i++) {
      result.add((_mapping1[i], _mapping2[i]));
    }
    return result;
  }
}

final _identityMapping = <(double, double)>[(0.0, 0.0), (0.5, 0.5)];

double _featureDistSquared(Feature f1, Feature f2) {
  if (f1 is _FeatureCorner && f2 is _FeatureCorner && f1.convex != f2.convex) {
    return double.maxFinite;
  }

  return (_featureRepresentativePoint(f1) - _featureRepresentativePoint(f2)).distanceSquared;
}

Offset _featureRepresentativePoint(Feature feature) {
  return (feature.cubics.first.points[0] + feature.cubics.last.points[3]) / 2.0;
}

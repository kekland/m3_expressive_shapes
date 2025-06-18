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

import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:m3_expressive_shapes/shapes/_shapes.dart';

class _PointNRound {
  _PointNRound(this.o, [this.rounding = CornerRounding.unrounded]);

  final Offset o;
  final CornerRounding rounding;
}

List<_PointNRound> _doRepeat(List<_PointNRound> points, int reps, Offset center, bool mirroring) {
  final ret = <_PointNRound>[];

  if (mirroring) {
    final angles = points.map((v) => _angleDegrees(v.o - center)).toList();
    final distances = points.map((v) => (v.o - center).distance).toList();
    final actualReps = reps * 2;
    final sectionAngle = 360.0 / actualReps;

    for (var r = 0; r < actualReps; r++) {
      for (var idx = 0; idx < points.length; idx++) {
        final i = r % 2 == 0 ? idx : points.length - 1 - idx;
        if (i > 0 || r % 2 == 0) {
          final adeg = sectionAngle * r + ((r % 2 == 0) ? angles[i] : sectionAngle - angles[i] + 2 * angles[0]);
          final a = _toRadians(adeg);
          final finalPoint = Offset(cos(a), sin(a)) * distances[i] + center;
          ret.add(_PointNRound(finalPoint, points[i].rounding));
        }
      }
    }
  } else {
    final np = points.length;
    for (var i = 0; i < np * reps; i++) {
      final point = _rotateDegrees(points[i % np].o, (i ~/ np) * 360.0 / reps, center: center);
      ret.add(_PointNRound(point, points[i % np].rounding));
    }
  }

  return ret;
}

Offset _rotateDegrees(Offset o, double angle, {Offset center = Offset.zero}) {
  final a = _toRadians(angle);
  final off = o - center;
  return Offset(off.dx * cos(a) - off.dy * sin(a), off.dx * sin(a) + off.dy * cos(a)) + center;
}

double _angleDegrees(Offset o) => atan2(o.dy, o.dx) * (180.0 / pi);
double _toRadians(double d) => d * (pi / 180.0);

RoundedPolygon _customPolygon(
  List<_PointNRound> pnr,
  int reps, {
  Offset center = const Offset(0.5, 0.5),
  bool mirroring = false,
}) {
  final actualPoints = _doRepeat(pnr, reps, center, mirroring);

  return RoundedPolygon.fromVertices(
    actualPoints.map((v) => v.o).toList(),
    perVertexRounding: actualPoints.map((v) => v.rounding).toList(),
    center: center,
  );
}

class _Generators {
  static final _cornerRound15 = CornerRounding(0.15);
  static final _cornerRound20 = CornerRounding(0.2);
  static final _cornerRound30 = CornerRounding(0.3);
  static final _cornerRound50 = CornerRounding(0.5);
  static final _cornerRound100 = CornerRounding(1);

  static final _rotateNeg45 = Matrix4.rotationZ(-45.0 * (pi / 180.0));
  static final _rotateNeg90 = Matrix4.rotationZ(-90.0 * (pi / 180.0));
  static final _rotateNeg135 = Matrix4.rotationZ(-135.0 * (pi / 180.0));

  static Offset Function(Offset) _matrixTransformer(Matrix4 m) {
    return (Offset v) => MatrixUtils.transformPoint(m, v);
  }

  static RoundedPolygon circle([int numVertices = 10]) {
    return RoundedPolygonShapes.circle(numVertices: numVertices);
  }

  static RoundedPolygon square() {
    return RoundedPolygonShapes.rectangle(width: 1.0, height: 1.0, rounding: _cornerRound30);
  }

  static RoundedPolygon slanted() {
    return _customPolygon([
      _PointNRound(Offset(0.926, 0.970), CornerRounding(0.189, 0.811)),
      _PointNRound(Offset(-0.021, 0.967), CornerRounding(0.187, 0.057)),
    ], 2);
  }

  static RoundedPolygon arch() {
    return RoundedPolygon.fromNumVertices(
      4,
      perVertexRounding: [_cornerRound100, _cornerRound100, _cornerRound20, _cornerRound20],
    ).transformed(_matrixTransformer(_rotateNeg135));
  }

  static RoundedPolygon fan() {
    return _customPolygon([
      _PointNRound(Offset(1.004, 1.000), CornerRounding(0.148, 0.417)),
      _PointNRound(Offset(0.000, 1.000), CornerRounding(0.151)),
      _PointNRound(Offset(0.000, -0.003), CornerRounding(0.148)),
      _PointNRound(Offset(0.978, 0.020), CornerRounding(0.803)),
    ], 1);
  }

  static RoundedPolygon arrow() {
    return _customPolygon([
      _PointNRound(Offset(0.500, 0.892), CornerRounding(0.313)),
      _PointNRound(Offset(-0.216, 1.050), CornerRounding(0.207)),
      _PointNRound(Offset(0.499, -0.160), CornerRounding(0.215, 1.000)),
      _PointNRound(Offset(1.225, 1.060), CornerRounding(0.211)),
    ], 1);
  }

  static RoundedPolygon semiCircle() {
    return RoundedPolygonShapes.rectangle(
      width: 1.6,
      height: 1.0,
      perVertexRounding: [_cornerRound20, _cornerRound20, _cornerRound100, _cornerRound100],
    );
  }

  static RoundedPolygon oval() {
    return RoundedPolygonShapes.circle()
        .transformed((p) => Offset(p.dx, p.dy * 0.64))
        .transformed((p) => MatrixUtils.transformPoint(_rotateNeg45, p));
  }

  static RoundedPolygon pill() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.961, 0.039), CornerRounding(0.426)),
        _PointNRound(Offset(1.001, 0.428)),
        _PointNRound(Offset(1.000, 0.609), CornerRounding(1.000)),
      ],
      2,
      mirroring: true,
    );
  }

  static RoundedPolygon triangle() {
    return RoundedPolygon.fromNumVertices(
      3,
      rounding: _cornerRound20,
    ).transformed((p) => MatrixUtils.transformPoint(_rotateNeg90, p));
  }

  static RoundedPolygon diamond() {
    return _customPolygon([
      _PointNRound(Offset(0.500, 1.096), CornerRounding(0.151, 0.524)),
      _PointNRound(Offset(0.040, 0.500), CornerRounding(0.159)),
    ], 2);
  }

  static RoundedPolygon clamShell() {
    return _customPolygon([
      _PointNRound(Offset(0.171, 0.841), CornerRounding(0.159)),
      _PointNRound(Offset(-0.020, 0.500), CornerRounding(0.140)),
      _PointNRound(Offset(0.170, 0.159), CornerRounding(0.159)),
    ], 2);
  }

  static RoundedPolygon pentagon() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.500, -0.009), CornerRounding(0.172)),
        _PointNRound(Offset(1.030, 0.365), CornerRounding(0.164)),
        _PointNRound(Offset(0.828, 0.970), CornerRounding(0.169)),
      ],
      1,
      mirroring: true,
    );
  }

  static RoundedPolygon gem() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.499, 1.023), CornerRounding(0.241, 0.778)),
        _PointNRound(Offset(-0.005, 0.792), CornerRounding(0.208)),
        _PointNRound(Offset(0.073, 0.258), CornerRounding(0.228)),
        _PointNRound(Offset(0.433, -0.000), CornerRounding(0.491)),
      ],
      1,
      mirroring: true,
    );
  }

  static RoundedPolygon sunny() {
    return RoundedPolygonShapes.star(numVerticesPerRadius: 8, innerRadius: 0.8, rounding: _cornerRound15);
  }

  static RoundedPolygon verySunny() {
    return _customPolygon([
      _PointNRound(Offset(0.5, 1.080), CornerRounding(0.085)),
      _PointNRound(Offset(0.358, 0.843), CornerRounding(0.085)),
    ], 8);
  }

  static RoundedPolygon cookie4() {
    return _customPolygon(
      [
        _PointNRound(Offset(1.237, 1.236), CornerRounding(0.258)),
        _PointNRound(Offset(0.500, 0.918), CornerRounding(0.233)),
      ],
      4,
      mirroring: true,
    );
  }

  static RoundedPolygon cookie6() {
    return _customPolygon([
      _PointNRound(Offset(0.723, 0.884), CornerRounding(0.394)),
      _PointNRound(Offset(0.500, 1.099), CornerRounding(0.398)),
    ], 6);
  }

  static RoundedPolygon cookie7() {
    return RoundedPolygonShapes.star(
      numVerticesPerRadius: 7,
      innerRadius: 0.75,
      rounding: _cornerRound50,
    ).transformed((p) => MatrixUtils.transformPoint(_rotateNeg90, p));
  }

  static RoundedPolygon cookie9() {
    return RoundedPolygonShapes.star(
      numVerticesPerRadius: 9,
      innerRadius: 0.8,
      rounding: _cornerRound50,
    ).transformed((p) => MatrixUtils.transformPoint(_rotateNeg90, p));
  }

  static RoundedPolygon ghostish() {
    return _customPolygon(
      [
        // Not sure why! this seems to be a bug. If the point is set to
        // (0.5, 0.0), as in the official code, then the shape is malformed when morphing to arch.
        // TODO: investigate.
        _PointNRound(Offset(0.500, 0.001), CornerRounding(1.000)),
        _PointNRound(Offset(1.000, 0.000), CornerRounding(1.000)),
        _PointNRound(Offset(1.000, 1.140), CornerRounding(0.254, 0.106)),
        _PointNRound(Offset(0.575, 0.906), CornerRounding(0.253)),
      ],
      1,
      mirroring: true,
    );
  }

  static RoundedPolygon clover4() {
    return _customPolygon(
      [_PointNRound(Offset(0.500, 0.074)), _PointNRound(Offset(0.725, -0.099), CornerRounding(0.476))],
      4,
      mirroring: true,
    );
  }

  static RoundedPolygon clover8() {
    return _customPolygon([
      _PointNRound(Offset(0.5, 0.036)),
      _PointNRound(Offset(0.758, -0.101), CornerRounding(0.209)),
    ], 8);
  }

  static RoundedPolygon cookie12() {
    return RoundedPolygonShapes.star(
      numVerticesPerRadius: 12,
      innerRadius: 0.8,
      rounding: _cornerRound50,
    ).transformed((v) => MatrixUtils.transformPoint(_rotateNeg90, v));
  }

  static RoundedPolygon burst() {
    return _customPolygon([
      _PointNRound(Offset(0.500, -0.006), CornerRounding(0.006)),
      _PointNRound(Offset(0.592, 0.158), CornerRounding(0.006)),
    ], 12);
  }

  static RoundedPolygon softBurst() {
    return _customPolygon([
      _PointNRound(Offset(0.193, 0.277), CornerRounding(0.053)),
      _PointNRound(Offset(0.176, 0.055), CornerRounding(0.053)),
    ], 10);
  }

  static RoundedPolygon boom() {
    return _customPolygon([
      _PointNRound(Offset(0.457, 0.296), CornerRounding(0.007)),
      _PointNRound(Offset(0.500, -0.051), CornerRounding(0.007)),
    ], 15);
  }

  static RoundedPolygon softBoom() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.733, 0.454)),
        _PointNRound(Offset(0.839, 0.437), CornerRounding(0.532)),
        _PointNRound(Offset(0.949, 0.449), CornerRounding(0.439, 1.000)),
        _PointNRound(Offset(0.998, 0.478), CornerRounding(0.174)),
      ],
      16,
      mirroring: true,
    );
  }

  static RoundedPolygon flower() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.370, 0.187)),
        _PointNRound(Offset(0.416, 0.049), CornerRounding(0.381)),
        _PointNRound(Offset(0.479, 0.001), CornerRounding(0.095)),
      ],
      8,
      mirroring: true,
    );
  }

  static RoundedPolygon puffy() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.500, 0.053)),
        _PointNRound(Offset(0.545, -0.040), CornerRounding(0.405)),
        _PointNRound(Offset(0.670, -0.035), CornerRounding(0.426)),
        _PointNRound(Offset(0.717, 0.066), CornerRounding(0.574)),
        _PointNRound(Offset(0.722, 0.128)),
        _PointNRound(Offset(0.777, 0.002), CornerRounding(0.360)),
        _PointNRound(Offset(0.914, 0.149), CornerRounding(0.660)),
        _PointNRound(Offset(0.926, 0.289), CornerRounding(0.660)),
        _PointNRound(Offset(0.881, 0.346)),
        _PointNRound(Offset(0.940, 0.344), CornerRounding(0.126)),
        _PointNRound(Offset(1.003, 0.437), CornerRounding(0.255)),
      ],
      2,
      mirroring: true,
    ).transformed((p) => Offset(p.dx, p.dy * 0.742));
  }

  static RoundedPolygon puffyDiamond() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.870, 0.130), CornerRounding(0.146)),
        _PointNRound(Offset(0.818, 0.357)),
        _PointNRound(Offset(1.000, 0.332), CornerRounding(0.853)),
      ],
      4,
      mirroring: true,
    );
  }

  static RoundedPolygon pixelCircle() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.500, 0.000)),
        _PointNRound(Offset(0.704, 0.000)),
        _PointNRound(Offset(0.704, 0.065)),
        _PointNRound(Offset(0.843, 0.065)),
        _PointNRound(Offset(0.843, 0.148)),
        _PointNRound(Offset(0.926, 0.148)),
        _PointNRound(Offset(0.926, 0.296)),
        _PointNRound(Offset(1.000, 0.296)),
      ],
      2,
      mirroring: true,
    );
  }

  static RoundedPolygon pixelTriangle() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.110, 0.500)),
        _PointNRound(Offset(0.113, 0.000)),
        _PointNRound(Offset(0.287, 0.000)),
        _PointNRound(Offset(0.287, 0.087)),
        _PointNRound(Offset(0.421, 0.087)),
        _PointNRound(Offset(0.421, 0.170)),
        _PointNRound(Offset(0.560, 0.170)),
        _PointNRound(Offset(0.560, 0.265)),
        _PointNRound(Offset(0.674, 0.265)),
        _PointNRound(Offset(0.675, 0.344)),
        _PointNRound(Offset(0.789, 0.344)),
        _PointNRound(Offset(0.789, 0.439)),
        _PointNRound(Offset(0.888, 0.439)),
      ],
      1,
      mirroring: true,
    );
  }

  static RoundedPolygon bun() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.796, 0.500)),
        _PointNRound(Offset(0.853, 0.518), CornerRounding(1.0)),
        _PointNRound(Offset(0.992, 0.631), CornerRounding(1.0)),
        _PointNRound(Offset(0.968, 1.000), CornerRounding(1.0)),
      ],
      2,
      mirroring: true,
    );
  }

  static RoundedPolygon heart() {
    return _customPolygon(
      [
        _PointNRound(Offset(0.500, 0.268), CornerRounding(0.016)),
        _PointNRound(Offset(0.792, -0.066), CornerRounding(0.958)),
        _PointNRound(Offset(1.064, 0.276), CornerRounding(1.000)),
        _PointNRound(Offset(0.501, 0.946), CornerRounding(0.129)),
      ],
      1,
      mirroring: true,
    );
  }
}

class MaterialShapes {
  static RoundedPolygon? _circle;
  static RoundedPolygon get circle => _circle ??= _Generators.circle().normalized();

  static RoundedPolygon? _square;
  static RoundedPolygon get square => _square ??= _Generators.square().normalized();

  static RoundedPolygon? _slanted;
  static RoundedPolygon get slanted => _slanted ??= _Generators.slanted().normalized();

  static RoundedPolygon? _arch;
  static RoundedPolygon get arch => _arch ??= _Generators.arch().normalized();

  static RoundedPolygon? _fan;
  static RoundedPolygon get fan => _fan ??= _Generators.fan().normalized();

  static RoundedPolygon? _arrow;
  static RoundedPolygon get arrow => _arrow ??= _Generators.arrow().normalized();

  static RoundedPolygon? _semiCircle;
  static RoundedPolygon get semiCircle => _semiCircle ??= _Generators.semiCircle().normalized();

  static RoundedPolygon? _oval;
  static RoundedPolygon get oval => _oval ??= _Generators.oval().normalized();

  static RoundedPolygon? _pill;
  static RoundedPolygon get pill => _pill ??= _Generators.pill().normalized();

  static RoundedPolygon? _triangle;
  static RoundedPolygon get triangle => _triangle ??= _Generators.triangle().normalized();

  static RoundedPolygon? _diamond;
  static RoundedPolygon get diamond => _diamond ??= _Generators.diamond().normalized();

  static RoundedPolygon? _clamShell;
  static RoundedPolygon get clamShell => _clamShell ??= _Generators.clamShell().normalized();

  static RoundedPolygon? _pentagon;
  static RoundedPolygon get pentagon => _pentagon ??= _Generators.pentagon().normalized();

  static RoundedPolygon? _gem;
  static RoundedPolygon get gem => _gem ??= _Generators.gem().normalized();

  static RoundedPolygon? _sunny;
  static RoundedPolygon get sunny => _sunny ??= _Generators.sunny().normalized();

  static RoundedPolygon? _verySunny;
  static RoundedPolygon get verySunny => _verySunny ??= _Generators.verySunny().normalized();

  static RoundedPolygon? _cookie4;
  static RoundedPolygon get cookie4 => _cookie4 ??= _Generators.cookie4().normalized();

  static RoundedPolygon? _cookie6;
  static RoundedPolygon get cookie6 => _cookie6 ??= _Generators.cookie6().normalized();

  static RoundedPolygon? _cookie7;
  static RoundedPolygon get cookie7 => _cookie7 ??= _Generators.cookie7().normalized();

  static RoundedPolygon? _cookie9;
  static RoundedPolygon get cookie9 => _cookie9 ??= _Generators.cookie9().normalized();

  static RoundedPolygon? _cookie12;
  static RoundedPolygon get cookie12 => _cookie12 ??= _Generators.cookie12().normalized();

  static RoundedPolygon? _ghostish;
  static RoundedPolygon get ghostish => _ghostish ??= _Generators.ghostish().normalized();

  static RoundedPolygon? _clover4;
  static RoundedPolygon get clover4 => _clover4 ??= _Generators.clover4().normalized();

  static RoundedPolygon? _clover8;
  static RoundedPolygon get clover8 => _clover8 ??= _Generators.clover8().normalized();

  static RoundedPolygon? _burst;
  static RoundedPolygon get burst => _burst ??= _Generators.burst().normalized();

  static RoundedPolygon? _softBurst;
  static RoundedPolygon get softBurst => _softBurst ??= _Generators.softBurst().normalized();

  static RoundedPolygon? _boom;
  static RoundedPolygon get boom => _boom ??= _Generators.boom().normalized();

  static RoundedPolygon? _softBoom;
  static RoundedPolygon get softBoom => _softBoom ??= _Generators.softBoom().normalized();

  static RoundedPolygon? _flower;
  static RoundedPolygon get flower => _flower ??= _Generators.flower().normalized();

  static RoundedPolygon? _puffy;
  static RoundedPolygon get puffy => _puffy ??= _Generators.puffy().normalized();

  static RoundedPolygon? _puffyDiamond;
  static RoundedPolygon get puffyDiamond => _puffyDiamond ??= _Generators.puffyDiamond().normalized();

  static RoundedPolygon? _pixelCircle;
  static RoundedPolygon get pixelCircle => _pixelCircle ??= _Generators.pixelCircle().normalized();

  static RoundedPolygon? _pixelTriangle;
  static RoundedPolygon get pixelTriangle => _pixelTriangle ??= _Generators.pixelTriangle().normalized();

  static RoundedPolygon? _bun;
  static RoundedPolygon get bun => _bun ??= _Generators.bun().normalized();

  static RoundedPolygon? _heart;
  static RoundedPolygon get heart => _heart ??= _Generators.heart().normalized();

  static List<RoundedPolygon> get values {
    return [
      circle,
      square,
      slanted,
      arch,
      fan,
      arrow,
      semiCircle,
      oval,
      pill,
      triangle,
      diamond,
      clamShell,
      pentagon,
      gem,
      sunny,
      verySunny,
      cookie4,
      cookie6,
      cookie7,
      cookie9,
      cookie12,
      ghostish,
      clover4,
      clover8,
      burst,
      softBurst,
      boom,
      softBoom,
      flower,
      puffy,
      puffyDiamond,
      pixelCircle,
      pixelTriangle,
      bun,
      heart,
    ];
  }
}

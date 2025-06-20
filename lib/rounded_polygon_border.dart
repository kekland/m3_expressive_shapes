import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Cubic;
import 'package:m3_expressive_shapes/rounded_polygon_to_path.dart';
import 'package:m3_expressive_shapes/shapes/_shapes.dart';

class RoundedPolygonBorder extends ShapeBorder {
  RoundedPolygonBorder({required this.polygon}) : cubics = polygon!.cubics;
  const RoundedPolygonBorder.cubics(this.cubics, this.polygon);

  final RoundedPolygon? polygon;
  final List<Cubic> cubics;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final path = roundedPolygonToPath(cubics, rect);
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => getInnerPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return RoundedPolygonBorder.cubics(cubics, polygon);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RoundedPolygonBorder && a.polygon != null) {
      final morph = Morph(start: a.polygon!, end: polygon!);
      return RoundedPolygonBorder.cubics(morph.asCubics(t), polygon);
    }

    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RoundedPolygonBorder && b.polygon != null) {
      final morph = Morph(start: polygon!, end: b.polygon!);
      return RoundedPolygonBorder.cubics(morph.asCubics(t), polygon);
    }

    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoundedPolygonBorder) return false;

    return polygon == other.polygon && listEquals(cubics, other.cubics);
  }

  @override
  int get hashCode {
    return Object.hash(polygon, Object.hashAll(cubics));
  }
}

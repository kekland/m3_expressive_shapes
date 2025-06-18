import 'package:flutter/widgets.dart' hide Cubic;
import 'package:m3_expressive_shapes/shapes/_shapes.dart';

Path cubicsListToPath(List<Cubic> cubics) {
  final path = Path();
  if (cubics.isEmpty) return path;

  final p0 = cubics.first.points[0];
  path.moveTo(p0.dx, p0.dy);
  for (final cubic in cubics) {
    final c0 = cubic.points[1];
    final c1 = cubic.points[2];
    final p1 = cubic.points[3];
    path.cubicTo(c0.dx, c0.dy, c1.dx, c1.dy, p1.dx, p1.dy);
    // path.lineTo(cubic.points[3].dx, cubic.points[3].dy);
  }

  return path;
}

Path roundedPolygonToPath(List<Cubic> cubics, Rect rect) {
  final path = cubicsListToPath(cubics);
  final bounds = Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);

  final fittedSizes = applyBoxFit(BoxFit.contain, bounds.size, rect.size);
  final outputSubrect = Alignment.center.inscribe(fittedSizes.destination, rect);

  final transform = Matrix4.identity()
    ..translate(outputSubrect.left, outputSubrect.top)
    ..scale(outputSubrect.width / bounds.width, outputSubrect.height / bounds.height)
    ..translate(-bounds.left, -bounds.top);

  return path.transform(transform.storage);
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:m3_expressive_shapes/shapes/material_shapes.dart';
import 'package:m3_expressive_shapes/rounded_polygon_border.dart';
import 'package:m3_expressive_shapes/shapes/_shapes.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
      ),
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _shapes = <RoundedPolygon>[];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    final shapeCount = MaterialShapes.values.length;
    for (var i = 0; i < 100; i++) {
      final shapeIndex = _random.nextInt(shapeCount);
      final shape = MaterialShapes.values[shapeIndex];
      _shapes.add(shape);
    }
  }

  void shuffle() {
    final shapeCount = MaterialShapes.values.length;
    for (var i = 0; i < 100; i++) {
      final shapeIndex = _random.nextInt(shapeCount);
      final shape = MaterialShapes.values[shapeIndex];
      _shapes[i] = shape;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('M3 Expressive Shapes Test')),
      floatingActionButton: FloatingActionButton(onPressed: shuffle, child: const Icon(Icons.shuffle)),
      body: Center(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < 100; i++)
              AnimatedContainer(
                key: Key('shape_$i'),
                duration: const Duration(milliseconds: 500),
                curve: ElasticOutCurve(0.85),
                width: 100.0,
                height: 100.0,
                decoration: ShapeDecoration(
                  shape: RoundedPolygonBorder(polygon: _shapes[i]),
                  color: Colors.primaries[i % Colors.primaries.length],
                ),
              ),
            // for (var i = 0; i < 100; i++)
            //   Material(
            //     key: Key('shape_$i'),
            //     color: Colors.primaries[i % Colors.primaries.length],
            //     shape: RoundedPolygonBorder(polygon: _shapes[i]),
            //     clipBehavior: Clip.antiAlias,
            //     child: InkWell(
            //       onTap: () {},
            //       splashFactory: InkSparkle.splashFactory,
            //       child: SizedBox(width: 100.0, height: 100.0),
            //     ),
            //   ),
            // Container(
            //   width: 100.0,
            //   height: 100.0,
            //   decoration: ShapeDecoration(
            //     shape: MorphPolygonBorder(
            //       morph: Morph(start: MaterialShapes.ghostish, end: MaterialShapes.arch),
            //       progress: 1.0,
            //     ),
            //     color: Colors.blue,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class DebugMorphPainter extends CustomPainter {
  DebugMorphPainter(this.morph, this.progress);

  final Morph morph;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cubics = morph.asCubics(progress);
    final path = Path();
    if (cubics.isEmpty) return;

    final bounds = morph.calculateBounds();
    final fittedSizes = applyBoxFit(BoxFit.contain, bounds.size, size);
    final outputSubrect = Alignment.center.inscribe(
      fittedSizes.destination,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final transform = Matrix4.identity()
      ..translate(outputSubrect.left, outputSubrect.top)
      ..scale(outputSubrect.width / bounds.width, outputSubrect.height / bounds.height)
      ..translate(-bounds.left, -bounds.top);

    canvas.transform(transform.storage);

    for (var i = 0; i < cubics.length; i++) {
      // if (i != 15) continue;
      final cubic = cubics[i];
      final path = Path()
        ..moveTo(cubic.points[0].dx, cubic.points[0].dy)
        ..cubicTo(
          cubic.points[1].dx,
          cubic.points[1].dy,
          cubic.points[2].dx,
          cubic.points[2].dy,
          cubic.points[3].dx,
          cubic.points[3].dy,
        );

      final color = Colors.primaries[i % Colors.primaries.length];
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05
          ..color = color,
      );
    }

    canvas.drawPath(path.transform(transform.storage), Paint()..color = Colors.red.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

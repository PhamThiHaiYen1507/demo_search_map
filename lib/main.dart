import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final columns = (size.width / 4).floor();
    final rows = (size.height / 4).floor();
    return Scaffold(
      body: InteractiveViewer(
          minScale: 1.1,
          maxScale: 5,
          child: Stack(
            children: [
              Image.asset('assets/map.png'),
              GestureDetector(
                onTapDown: (details) {
                  print(Offset(
                      (details.localPosition.dx / 4).floor().toDouble(),
                      (details.localPosition.dy / 4).floor().toDouble()));
                },
                child: Column(
                  children: List.generate(
                      rows,
                      (row) => Row(
                            children: List.generate(
                                columns,
                                (column) => Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 0.1, color: Colors.red),
                                      ),
                                    )),
                          )),
                ),
              )
            ],
          )),
    );
  }
}

// class GridPainter extends CustomPainter {
//   final BuildContext ctx;

//   GridPainter(this.ctx);
//   @override
//   void paint(Canvas canvasA, Size size) {
//     TouchyCanvas canvas = TouchyCanvas(ctx, canvasA);

//     double y = 0;
//     final Paint paint = Paint();
//     paint.style = PaintingStyle.stroke;
//     paint.strokeWidth = 0.2;
//     paint.color = Colors.red.withOpacity(0.2);
//     for (var i = 0; i < 250; i++) {
//       double x = 0;
//       for (var j = 0; j < 500; j++) {
//         canvas.drawRect(
//           Rect.fromLTWH(x, y, 4, 4),
//           paint,
//           onTapDown: (details) {
//             // print(Offset(i.toDouble(), j.toDouble()));
//             print(i);
//           },
//         );
//         x += 4;
//       }
//       y += 4;
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

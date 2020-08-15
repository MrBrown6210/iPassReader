import 'package:flutter/material.dart';
import 'screens/screens.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF3EBACC),
        accentColor: Color(0xFFD8ECF1),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Color(0xFFF0F2F5),
      ),
      home: HomeScreen(),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);
//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   List<ScanResult> xresults = [];

//   void _incrementCounter() {
//     setState(() {
//       FlutterBlue flutterBlue = FlutterBlue.instance;
//       flutterBlue.startScan(timeout: Duration(seconds: 4));
//       flutterBlue.scanResults.listen((results) {
//         setState(() {
//           xresults = results;
//         });
//         for (ScanResult r in results) {
//           print('${r.toString()}');
//         }
//       });
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: ListView.builder(
//           padding: const EdgeInsets.all(8),
//           itemCount: xresults.length,
//           scrollDirection: Axis.vertical,
//           shrinkWrap: true,
//           physics: BouncingScrollPhysics(),
//           itemBuilder: (BuildContext context, int index) {
//             return Container(
//               padding: const EdgeInsets.all(3),
//               color: Colors.red[200],
//               child: Row(
//                 children: [
//                   Column(
//                     children: [
//                       Container(child: Text('${xresults[index].device.id}', textAlign: TextAlign.left,), padding: const EdgeInsets.all(5), alignment: Alignment.centerLeft,),
//                       Container(child: Text('${xresults[index].device.name}', textAlign: TextAlign.left,), alignment: Alignment.centerLeft),
//                       Container(child: Text('${xresults[index].advertisementData.txPowerLevel}', textAlign: TextAlign.left,), alignment: Alignment.centerLeft),
//                       Container(child: Text('${xresults[index].advertisementData.serviceData}')),
//                       FlatButton(onPressed: () {
//                         print(xresults[index].toString());
//                         Navigator.push(context, MaterialPageRoute(builder: (context) => SecondRoute(scanResult: xresults[index],)));
//                       }, child: Text("Connect"))
//                     ],
//                   ),
//                 ]
//               ),
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }

//   Widget titleSection = Container(
//     padding: const EdgeInsets.all(32),
//     child: Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.only(bottom: 18),
//                 child: Text(
//                   'WOWOWOW',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold
//                   ),
//                 ),
//               ),
//               Text("testja"),
//             ],
//           ),
//         )
//       ]
//     ),
//   );
// }

// class SecondRoute extends StatelessWidget {
//   final ScanResult scanResult;

//   const SecondRoute({Key key, @required this.scanResult}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Second Route"),
//       ),
//       body: Container(
//         padding: const EdgeInsets.all(15),
//         child: Align(
//           alignment: Alignment.centerLeft,
//           child: Column(
//             children: [
//               Text("${scanResult.device.name}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, foreground: Paint())),
//               Text("${scanResult.device.id}", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),),
//               FlatButton(onPressed: () async {
//                 await scanResult.device.connect();
//                 List<BluetoothService> services = await scanResult.device.discoverServices();
//                 services.forEach((service) {
//                   service.characteristics.forEach((element) async {
//                     // print(element.properties.toString());
//                     List<int> x = await element.read();
//                     print(x);
//                     print(utf8.decode(x));
//                   });
//                 });
//               }, child: Text("Connect")),
//             ],
//           ),
//         ),
//         // child: RaisedButton(
//         //   onPressed: () {
//         //     print(scanResult.device.name);
//         //     Navigator.pop(context);
//         //   },
//         //   child: Text('Go back!'),
//         // ),
//       ),
//     );
//   }
// }

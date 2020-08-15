import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hello_world/screens/screens.dart';
import 'package:hello_world/widgets/circle_button.dart';

import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {

  FlutterBlue blue = FlutterBlue.instance;
  List<ScanResult> list = [];

  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    blue.scanResults.listen((event) {
      List<ScanResult> listResult = [];
      for (var e in event) {
        if (e.device.name.startsWith('iPass'))
          listResult.add(e);
      }
      setState(() {
        list = listResult;
        // print(list);
      });
      // for (ScanResult r in event) {
      //   print('${r.toString()}');
      // }
    });
    scan();
    // testHttp();
  }

  void scan() async {
    setState(() {
      isScanning = true;
    });
    await blue.startScan(timeout: Duration(seconds: 4));
    setState(() {
      isScanning = false;
    });
    // setState(() async {
    //   isScanning = true;
    //   isScanning = false;
    // });
  }

  void testHttp() async {
    List<Data> x = [
      Data(id: "id", timestamp: 2000, stayInMilliSecond: 15000),
      Data(id: "idx", timestamp: 2000, stayInMilliSecond: 15000)
    ];
    var res = await http.post(
      'http://128.199.205.55:3030/records',
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      // body: json.encode({
      //   'device': "xxx",
      //   'data': [
      //     {
      //       "id": x.id,
      //       "timestamp": x.timestamp,
      //       "stayInMilliSecond": x.stayInMilliSecond
      //     },
      //   ]
      // }),
      body: json.encode({
        'device': "xxx",
        'data': x.map((e) {
          return {
            "id": e.id,
            "stayInMilliSecond": e.stayInMilliSecond,
            "timestamp": e.timestamp
          };
        }).toList()
      }),
    )
    // .then((value) {
    //   print('aaaa ${value.statusCode}');
    //   print('aaaa ${value.body}');
    // })
    .catchError((onError) {
      print(onError.toString());
    });
    print(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            title: Text(
              'iPass',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.2,
              )
            ),
            pinned: true,
            centerTitle: false,
            // floating: true,
            actions: [
              CircleButton(icon: isScanning ? Icons.panorama_fish_eye_outlined : Icons.search, iconSize: 30, onPressed: () {
                if (isScanning) return;
                print('search'); scan(); 
              })
            ],
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.yellow,
                  ),
                  child: ListTile(
                    title: Text(list[index].device.name),
                    subtitle: Text(list[index].device.id.toString()),
                    trailing: Text('View'),
                    onTap: () {
                      List<List<int>> x = [];
                      list[index].advertisementData.manufacturerData.forEach((key, value) {
                        x.add(value);
                        print(value);
                        Uint8List a = Uint8List.fromList(value);
                        print((a[0] << 8) + a[1]);
                      });
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceScreen(result: list[index])));
                      // print(list[index].advertisementData.manufacturerData.map((key, value) => value)); print(utf8.decode([2]));
                    },
                  ),
                );
              },
              childCount: list.length,
            )
          ),
          // StreamBuilder<List<BluetoothDevice>>(
          //   stream: Stream.periodic(Duration(seconds: 2)).asyncMap((_) => FlutterBlue.instance.connectedDevices),
          //   initialData: [],
          //   builder: (c, snapshot) {
          //     if (snapshot.hasData) {
          //       return SliverList(
          //         delegate: SliverChildBuilderDelegate(
          //           (context, index) {
          //             return ListTile(title: Text(snapshot.data[index].name));
          //           },
          //           childCount: snapshot.data.length,
          //         ),
          //       );
          //     }
          //     return Text('no');
          //   }
          // )
        ],
      ),
    );
  }
}
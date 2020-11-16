// import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hello_world/screens/screens.dart';
import 'package:hello_world/widgets/circle_button.dart';

// import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {

  FlutterBlue blue = FlutterBlue.instance;
  List<ScanResult> list = [];

  bool isScanning = false;

  bool isConnectingDevice = false;
  int connectingIndex = -1;

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
    // scan();
    // testHttp();
  }

  void scan() async {
    if (isScanning) return;
    if (isConnectingDevice) return;
    setState(() {
      isScanning = true;
    });
    await blue.startScan(timeout: Duration(seconds: 20));
    setState(() {
      isScanning = false;
    });
    // setState(() async {
    //   isScanning = true;
    //   isScanning = false;
    // });
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
              }),
              CircleButton(icon: Icons.add_link, iconSize: 30, onPressed: () async {
                print("dio");
                try {
                  var dio = Dio();
                  var res = await dio.post(
                    "http://192.168.1.105:3030/tracks/multiple",
                    data: {
                      "items": [
                        {
                          'stay': 12000,
                          'owner': 't1',
                          'found': 't2',
                          'timestamp': 1598939356
                        },
                        {
                          'stay': 12000,
                          'owner': 't2',
                          'found': 't3',
                          'timestamp': 1598939356
                        },
                      ]
                    }
                  );
                  print('test $res');
                } on DioError catch(e) {
                  if (e.response != null) {
                    print(e.response.data);
                  }
                  print('error: ${e.message}');
                }
                // var url = "http://128.199.205.55:3030/recordsxad";
                // var res = await http.post(
                //   url,
                //   headers: <String, String>{
                //     'Content-Type': 'application/json',
                //   },
                //   body: json.encode({
                //     'owner': 'x'
                //   })
                // ).catchError((onError) { print('error: ${onError.toString()}'); });
                // print('res $res');
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
                    trailing: Text(index == connectingIndex ? 'Connecting' : 'View'),
                    onTap: () async {

                      if (isConnectingDevice) return;

                      setState(() {
                        isConnectingDevice = true;
                        connectingIndex = index;
                      });

                      List<List<int>> x = [];
                      list[index].advertisementData.manufacturerData.forEach((key, value) {
                        x.add(value);
                        print(value);
                        Uint8List a = Uint8List.fromList(value);
                        print((a[0] << 8) + a[1]);
                        // TODO: Find Beacon UUID
                      });

                      try {
                        print('connecting');
                        list[index].device.connect(timeout: Duration(seconds: 20));
                        await list[index].device.state.firstWhere((s) => s == BluetoothDeviceState.connected).timeout(Duration(seconds: 20));
                        // await list[index].device.state.firstWhere(((state) => state == BluetoothDeviceState.connected));
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceScreen(result: list[index])));
                      } on Exception catch (exception) {
                        print('exception $exception');
                      } catch (error) {
                        print('error: $error');
                      } finally {
                        setState(() {
                          isConnectingDevice = false;
                          connectingIndex = -1;
                        });
                        print('finally');
                      }
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
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
// import 'package:flutter_blue/gen/flutterblue.pbserver.dart';
import 'package:hello_world/models/models.dart';
import 'package:hello_world/widgets/circle_button.dart';
import 'package:http/http.dart' as http;

String rowDataUUID = "00002ad1-0000-1000-8000-00805f9b34fb";
String timeUUID = "00002a0f-0000-1000-8000-00805f9b34fb";
String commandUUID = "00002b26-0000-1000-8000-00805f9b34fb";

List<Data> dataToRowDataList(String rawData) {
  List<Data> ds = [];
  return ds;
}

class DeviceScreen extends StatefulWidget {
  final ScanResult result;

  const DeviceScreen({Key key, this.result}) : super(key: key);

  @override
  _DeviceScreen createState() => _DeviceScreen();
}

class Data {
  final String id;
  final int timestamp;
  final int stayInMilliSecond;

  const Data({
    this.id,
    this.timestamp,
    this.stayInMilliSecond,
  });
}

class _DeviceScreen extends State<DeviceScreen> {

  List<BluetoothService> xservices = [];
  List<IPass> characteristicsData = [];

  bool isDataEnable = false;
  List<Data> datas = [];

  bool isDateEnable = false;
  int date = 0;
  BluetoothCharacteristic characteristicTime;

  bool isCommandEnable = false;
  BluetoothCharacteristic characteristicCommand;

  bool isUploading = false;

  final commandTextFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // widget.result.device.connect(timeout: Duration(seconds: 4)).then((_) {
      refreshData();
    // });
  }

  String startFlag = 'START';
  String endFlag = 'END';
  String rowData = '';

  Future<void> updateRowData(BluetoothCharacteristic characteristic) async {
    List<int> data =  await characteristic.read();
    String rawData = utf8.decode(data);
    print('rawData: $rawData');
    if (rawData == startFlag) {
      rowData = '';
      setState(() {
        rawData = '';
      });
      await updateRowData(characteristic);
      return;
    }

    if (rawData == endFlag) {
      List<Data> records = recordsFromRowData(rowData);
      print('records: ${records.toString()}');
      setState(() {
        isDataEnable = true;
        datas = records;
      });
      return;
    }

    rowData += rawData;

    await updateRowData(characteristic);
  }

  List<Data> recordsFromRowData(String rowData) {
    List<String> splits = rowData.split(";");
    List<Data> ds = [];
    for (var split in splits) {
      // split.indexOf('@');
      if (split == "") {
        continue;
      }
      String uuid = split.substring(split.indexOf('@') + 1, split.indexOf(':'));
      int timeStay = int.tryParse(split.substring(split.indexOf(':') + 1, split.indexOf('?')));
      int timeEnd = int.tryParse(split.substring(split.indexOf('?') + 1, split.length));
      // print('time $timeEnd');
      // print('timex ${split.substring(split.indexOf('?') + 1, split.length)}}');
      if (timeEnd == null || timeStay == null) continue;
      Data data = Data(id: uuid, timestamp: timeEnd, stayInMilliSecond: timeStay * 1000);
      print('data::: ${data.stayInMilliSecond}');
      ds.add(data);
    }
    return ds;
  }

  void refreshData() async {
    List<BluetoothService> services = await widget.result.device.discoverServices();
    List<IPass> _characteristicsData = [];
    for (var service in services) {
      print('x ${service.characteristics.map((e) => e.uuid.toString())}');
      for (var characteristic in service.characteristics) {

        if (characteristic == null) {
          continue;
        }

        if (characteristic.uuid.toString() == rowDataUUID) {
          updateRowData(characteristic);
        }

        if (characteristic.uuid.toString() == timeUUID) {
          List<int> data =  await characteristic.read();
          String rawData = utf8.decode(data);
          var dateData = int.tryParse(rawData);
          if (dateData != null) {
            setState(() {
              characteristicTime = characteristic;
              isDateEnable = true;
              date = dateData;
            });
          }
        }

        if (characteristic.uuid.toString() == commandUUID) {
          setState(() {
            characteristicCommand = characteristic;
            isCommandEnable = true;
          });
        }
      }
    }
    // services.forEach((service) async => service.characteristics.forEach((characteristic) async {
    // }));
    setState(() {
      // print('setState');
      xservices = services;
      characteristicsData = _characteristicsData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await widget.result.device.disconnect();
        print('disconnected');
        Navigator.pop(context);
        return Future.value(false);
      },
      child: GestureDetector(
        onTap: () {
          dismissKeyboard(context);
        },
        onPanDown: (x) {
          print(x);
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                brightness: Brightness.light,
                backgroundColor: Colors.white,
                title: Text(widget.result.device.name),
                pinned: true,
                actions: [
                  CircleButton(icon: Icons.refresh, iconSize: 28, onPressed: () {
                    refreshData();
                  })
                ],
              ),
              if (isDateEnable) SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(width: 2, color: Colors.orange)
                  ),
                  margin: const EdgeInsets.all(8),
                  padding: EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Time in Device',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${convertTimestampToDate(new DateTime.fromMillisecondsSinceEpoch(date * 1000))}'),
                        ],
                      ),
                      CircleButton(icon: Icons.upload_file, iconSize: 22, onPressed: () {
                        String timestamp = (DateTime.now().millisecondsSinceEpoch/1000).toString();
                        print(timestamp);
                        List<int> x = utf8.encode(timestamp);
                        print(x);
                        characteristicTime.write(x);
                        refreshData();
                      }),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(width: 2, color: Colors.orange)
                  ),
                  child: Column(
                    children: [
                      TextField(
                        // obscureText: true,
                        controller: commandTextFieldController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Command',
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlineButton(
                          child: Text('Send'),
                          onPressed: () {
                            var text = commandTextFieldController.text;
                            print('$text');
                            commandTextFieldController.clear();
                            characteristicCommand.write(utf8.encode(text));
                            refreshData();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    'Records',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: datas.map((data) {
                      return BoxList(data: data);
                    }).toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: double.infinity,
                  padding: EdgeInsets.all(4),
                  child: OutlineButton(
                    child: isUploading ? Text('UPLOADING') : Text('UPLOAD TO SERVER'),
                    onPressed: () async {
                      if (isUploading) return;
                      setState(() {
                        isUploading = true;
                      });

                      var url = "http://128.199.205.55:3030/records";
                      var res = await http.post(
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json',
                        },
                        body: json.encode({
                          'device': widget.result.device.name,
                          'data': datas.map((data) {
                            return {
                              "id": data.id,
                              "stayInMilliSecond": data.stayInMilliSecond,
                              "timestamp": data.timestamp
                            };
                          }).toList()
                        })
                      ).catchError((onError) {print(onError); isUploading = false;});
                      setState(() {
                        isUploading = false;
                      });
                      print(res.statusCode);
                      print(res.body);
                    },
                  ),  
                )
              )
              // SliverPadding(
              //   padding: const EdgeInsets.all(6),
              //   sliver: SliverToBoxAdapter(
              //     child: Container(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Text('test'),
              //           Text('test'),
              //           Text('test'),
              //           Text('test'),
              //           xservices[0].characteristics[0].serviceUuid
              //         ],
              //       )
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void dismissKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  @override
  void dispose() {
    commandTextFieldController.dispose();
    super.dispose();
  }
  
}


class XXX extends StatelessWidget {
  final List<BluetoothCharacteristic> characteristics;

  const XXX({Key key, this.characteristics}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: characteristics.map((e) => Text(e.toString())).toList(),
    );
  }
}

String convertTimestampToDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}

class BoxList extends StatelessWidget {

  final Data data;

  String convertTimestampToTime(int timestamp) {
    int seconds = timestamp ~/ 1000;
    int hour = seconds~/3600;
    int minute = (seconds%3600)~/60;
    int second = seconds%60;
    return '$hour h. $minute min. $second s.';
  }

  const BoxList({Key key, this.data}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(width: 2, color: Colors.blue)
      ),
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          Text(
            '${data.id}',
            style: TextStyle(
              fontWeight: FontWeight.bold
            ),
          ),
          Text(
            'อยู่ในระยะเป็นเวลา ${convertTimestampToTime(data.stayInMilliSecond)}'
          ),
          Text(
            'ออกไปเมื่อ ${convertTimestampToDate(new DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000))}'
          ),
        ],
      ),
    );
  }
}

class CarJson {
  String OptionID;
  CarJson(this.OptionID);
  Map<String, dynamic> TojsonData() {
    var map = new Map<String, dynamic>();
    map["OptionID"] = OptionID;
    return map;
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
// import 'package:flutter_blue/gen/flutterblue.pbserver.dart';
import 'package:hello_world/models/models.dart';
import 'package:hello_world/widgets/circle_button.dart';

String rowDataUUID = "00002ad1-0000-1000-8000-00805f9b34fb";
String identifyUUID = "00002ac3-0000-1000-8000-00805f9b34fb";
String timeUUID = "00002a0f-0000-1000-8000-00805f9b34fb";
String commandUUID = "00002b26-0000-1000-8000-00805f9b34fb";
String debugUUID = "00002b26-0000-1000-8000-xxxxxxxxxxx";

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
  final int leaveAt;
  final int stayInMilliSecond;

  const Data({
    this.id,
    this.leaveAt,
    this.stayInMilliSecond,
  });
}

class _DeviceScreen extends State<DeviceScreen> {

  bool isProduction = false;

  List<BluetoothService> xservices = [];
  List<IPass> characteristicsData = [];

  bool isDataEnable = false;
  List<Data> datas = [];
  String recordStatus = '';

  bool isDateEnable = false;
  int date = 0;
  BluetoothCharacteristic characteristicTime;

  bool isCommandEnable = false;
  BluetoothCharacteristic characteristicCommand;

  bool isUploading = false;

  String uuid = "";

  String debugStr = "";

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
  StreamSubscription<dynamic> subscription;

  Future<void> updateRowData(BluetoothCharacteristic characteristic) async {
    print("request more data");
    List<int> data =  await characteristic.read();
    String rawData = utf8.decode(data);
    print('rawData: $rawData');
    setState(() {
      recordStatus = rawData;
    });
    if (rawData == startFlag) {
      rowData = '';
      setState(() {
        rawData = '';
      });
      var future = new Future.delayed(const Duration(seconds: 10));
      subscription = future.asStream().listen((event) {
        print('Timeout! create list now');
        updateRecordsFromRowData();
      });
      await updateRowData(characteristic);
      return;
    }

    if (rawData == endFlag) {
      updateRecordsFromRowData();
      subscription.cancel();
      return;
    }

    rowData += rawData;

    subscription.cancel();
    var future = new Future.delayed(const Duration(seconds: 10));
    subscription = future.asStream().listen((event) {
      print('Timeout! create list now');
      updateRecordsFromRowData();
    });
    await updateRowData(characteristic);
  }

  void updateRecordsFromRowData() {
    List<Data> records = recordsFromRowData(rowData);
    setState(() {
      isDataEnable = true;
      datas = records;
    });
  }

  List<Data> recordsFromRowData(String rowData) {
    List<String> splits = rowData.split(";");
    List<Data> ds = [];
    for (var split in splits) {
      // split.indexOf('@');
      if (split == "") {
        continue;
      }

      print(split);

      RegExp exp = new RegExp(r"\@([\S]{4}):([0-9]+)\?([0-9]+)");
      RegExpMatch match = exp.firstMatch(split);
      if (match == null) continue;
      print("1--${match.group(0)}");
      print("2--${match.group(1)}");
      print("3--${match.group(2)}");
      print("4--${match.group(3)}");

      String uuid = match.group(1);
      int stayTime = int.tryParse(match.group(2));
      int endTime = int.tryParse(match.group(3));

      if (stayTime == null || endTime == null || uuid == null) continue;
      Data data = Data(id: uuid, leaveAt: endTime, stayInMilliSecond: stayTime * 1000);
      print('data::: ${data.stayInMilliSecond}');
      ds.add(data);
    }
    return ds;
  }

  void refreshData() async {
    List<BluetoothService> services = await widget.result.device.discoverServices();
    print('i ${widget.result.advertisementData.toString()}');
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

        if (characteristic.uuid.toString() == identifyUUID) {
          List<int> rawData =  await characteristic.read();
          String data = utf8.decode(rawData);
          uuid = data;
        }

        if (characteristic.uuid.toString() == timeUUID) {
          List<int> rawData =  await characteristic.read();
          String data = utf8.decode(rawData);
          var dateData = int.tryParse(data);
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

        if (characteristic.uuid.toString() == debugUUID) {
          if (!characteristic.isNotifying) {
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              String data = utf8.decode(value);
              setState(() {
                debugStr += "$data\n";
              });
            });
          }
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

                      try {
                        var dio = Dio();
                        var res = await dio.post(
                          "http://64.225.38.121:3030/tracks/multiple",
                          data: {
                            "items": datas.map((data) {
                              return {
                                'stay': data.stayInMilliSecond,
                                'owner': uuid.substring(uuid.length - 4).toLowerCase(),
                                'found': data.id,
                                'leave_at': data.leaveAt
                              };
                            }).toList()
                          }
                        );
                        print('result: ${res.data}');
                        // characteristicCommand.write(utf8.encode("clear"));
                        refreshData();
                      } on DioError catch (e) {
                        if (e.response != null) {
                          print(e.response.data);
                        }
                        print('error: ${e.message}');
                      } finally {
                        setState(() {
                          isUploading = false;
                        });
                      }
                    },
                  ),  
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    'Records $recordStatus',
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
                  child: Text(debugStr),
                )
              )
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


// class XXX extends StatelessWidget {
//   final List<BluetoothCharacteristic> characteristics;

//   const XXX({Key key, this.characteristics}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: characteristics.map((e) => Text(e.toString())).toList(),
//     );
//   }
// }

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
            'ออกไปเมื่อ ${convertTimestampToDate(new DateTime.fromMillisecondsSinceEpoch(data.leaveAt * 1000))}'
          ),
        ],
      ),
    );
  }
}

// class CarJson {
//   String OptionID;
//   CarJson(this.OptionID);
//   Map<String, dynamic> TojsonData() {
//     var map = new Map<String, dynamic>();
//     map["OptionID"] = OptionID;
//     return map;
//   }
// }
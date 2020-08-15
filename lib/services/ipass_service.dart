

import 'package:flutter_blue/flutter_blue.dart';

class IPassService {
  FlutterBlue blue = FlutterBlue.instance;
  x() {
    blue.startScan(timeout: Duration(seconds: 4));
  }
}
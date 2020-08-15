import 'package:flutter_blue/flutter_blue.dart';

class IPass {
  final List<int> data;
  final BluetoothCharacteristic characteristic;
  const IPass({
    this.data,
    this.characteristic
  });
}
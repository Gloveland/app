/*

import 'package:flutter_blue/flutter_blue.dart';

/// Wrapper for the bluetooth class.
class BluetoothWrapper {
  const BluetoothWrapper();

  Future<BluetoothDevice?> scanGlove(String uuid) async {
    List<BluetoothDevice> devices = await FlutterBlue.instance.connectedDevices;
    for (BluetoothDevice device in devices) {
      if (device.id.toString() == uuid) {
        return device;
      }
    }
    return null;
  }


}
*/


/// Class containing the specifications for the communication via BLE such as
/// the service and characteristic UUIDs.
class BluetoothSpecification {

  /// Identifier of the glove.
  static const String deviceName = "RightHandSmartGlove";

  /// Service for reading measurements from the gloves
  static const String MEASUREMENTS_SERVICE_UUID = "7056f14b-02df-4dd8-86fd-0261c7b15c86";

  /// Characteristic for reading measurements from the gloves
  static const String MEASUREMENTS_CHARACTERISTIC_UUID = "47e62e53-e278-494d-a3f8-ac00973ae0af";

}


/// Class containing the specifications for the communication via BLE such as
/// the service and characteristic UUIDs.
class BluetoothSpecification {
  /// Identifier of the glove.
  static const String deviceName = "RightHandSmartGlove";

  /// Service for reading measurements or retrieving interpretations from the gloves.
  static const String LSA_GLOVE_SERVICE_UUID = "7056f14b-02df-4dd8-86fd-0261c7b15c86";

  /// Characteristic for sending control commands to the gloves.
  static const String CONTROLLER_CHARACTERISTIC_UUID =
      "30b7db16-4567-42c5-acc4-2b0270c1e14d";

  /// Characteristic for reading measurements from the gloves.
  static const String DATA_COLLECTION_CHARACTERISTIC_UUID =
      "47e62e53-e278-494d-a3f8-ac00973ae0af";

  /// Characteristic for receiving interpretations from the gloves.
  static const String INTERPRETATION_CHARACTERISTIC_UUID =
      "079b8e74-101b-11ec-82a8-0242ac130003";

  /// Commands expected by the gloves.

  /// Start data collection command.
  ///
  /// This command will trigger the measurement readings from the IMU sensors
  /// and its subsequent transmission via BLE notifications using the
  /// DATA_COLLECTION_CHARACTERISTIC.
  ///
  /// Running this command while another task is being currently executed will
  /// cause the ongoing task to be stopped in order to start the data
  /// collection.
  static const String START_DATA_COLLECTION = "startdc";

  /// Start interpretations command.
  ///
  /// This command will trigger the interpretations in the gloves. Those
  /// interpretations along with their probabilities will be transferred via
  /// BLE notifications over the INTERPRETATION_CHARACTERISTIC.
  ///
  /// Running this command while another task is being currently executed will
  /// cause the ongoing task to be stopped in order to start the
  /// interpretations.
  static const String START_INTERPRETATIONS = "startint";

  /// Stop running command.
  ///
  /// This command will stop either the data collection task or the
  /// interpretations task on the device if one of them is being run
  static const String STOP_ONGOING_TASK = "stop";

  /// MTU to request
  static int mtu = 512;
}

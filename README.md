# lsa_gloves

A new Flutter application.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

esta rama funciona con este codigo de arduino

/*
    Video: https://www.youtube.com/watch?v=oCMOYS71NIU
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleNotify.cpp
    Ported to Arduino ESP32 by Evandro Copercini

   Create a BLE server that, once we receive a connection, will send periodic notifications.
   The service advertises itself as: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
   Has a characteristic of: 6E400002-B5A3-F393-E0A9-E50E24DCCA9E - used for receiving data with "WRITE"
   Has a characteristic of: 6E400003-B5A3-F393-E0A9-E50E24DCCA9E - used to send data with  "NOTIFY"

   The design of creating the BLE server is:
   1. Create a BLE Server
   2. Create a BLE Service
   3. Create a BLE Characteristic on the Service
   4. Create a BLE Descriptor on the characteristic
   5. Start the service.
   6. Start advertising.

   In this example rxValue is the data received (only accessible inside that function).
   And txValue is the data to be sent, in this example just a byte incremented every second.
*/
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer *pServer = NULL;
BLECharacteristic * pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
float m[9] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
char glove_measurement_buffer[256];
uint8_t data[13] = "Hola soy jaz";
int counter = 0;
int num = 0;
int data_size;

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART service UUID
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"


class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("device connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("device disconected");
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.println("*********");
        Serial.print("Received Value: ");
        for (int i = 0; i < rxValue.length(); i++)
          Serial.print(rxValue[i]);

        Serial.println();
        Serial.println("*********");
      }
    }
};


void setup() {
  Serial.begin(115200);

  // Create the BLE Device
  BLEDevice::init("UART Service");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pTxCharacteristic = pService->createCharacteristic(
										CHARACTERISTIC_UUID_TX,
										BLECharacteristic::PROPERTY_NOTIFY
									);

  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic * pRxCharacteristic = pService->createCharacteristic(
											 CHARACTERISTIC_UUID_RX,
											BLECharacteristic::PROPERTY_WRITE
										);

  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}



void loop() {


    if (deviceConnected) {

        data_size =  toString(glove_measurement_buffer, 'P');
        pTxCharacteristic->setValue(glove_measurement_buffer);
        pTxCharacteristic->notify();

        data_size =  toString(glove_measurement_buffer, 'R');
        pTxCharacteristic->setValue(glove_measurement_buffer);
        pTxCharacteristic->notify();

        data_size =  toString(glove_measurement_buffer, 'M');
        pTxCharacteristic->setValue(glove_measurement_buffer);
        pTxCharacteristic->notify();

        data_size =  toString(glove_measurement_buffer, 'I');
        pTxCharacteristic->setValue(glove_measurement_buffer);
        pTxCharacteristic->notify();

        data_size = toString(glove_measurement_buffer, 'T');
        pTxCharacteristic->setValue(glove_measurement_buffer);
        pTxCharacteristic->notify();

        char delimiter[] = "/n";
        pTxCharacteristic->setValue(delimiter);
        pTxCharacteristic->notify();

        delay(1000);
	}

    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
		// do stuff here on connecting
        oldDeviceConnected = deviceConnected;
    }
}


int toString(char buffer[],char finger){
    m[0] = num;
    m[1] = num + 0.1;
    m[2] = num + 0.2;
    m[3] = num + 0.3;
    m[4] = num + 0.4;
    m[5] = num + 0.5;
    m[6] = num + 0.6;
    m[7] = num + 0.7;
    m[8] = -num + 0.8;
    num = num + 1;

    /*
    const int buffer_size = 1 + snprintf(NULL, 0, "%c,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
    finger,m[0], m[1], m[2],m[3], m[3], m[5],m[6],m[7],m[8]);
    Serial.print("  buffer_size: ");Serial.print(buffer_size);
    assert(buffer_size > 0);
    char buf[buffer_size];
    */
    int size_written =  sprintf(buffer, "%d,%c,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
    counter, finger,m[0], m[1], m[2],m[3], m[3], m[5],m[6],m[7],m[8]);
    counter++;
    assert(size_written < 256);
    Serial.print("  size_written: ");Serial.print(size_written);
    Serial.println("  sending value via bluetooth: "+ String(buffer));
}
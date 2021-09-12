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

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer *pServer = NULL;
BLECharacteristic * pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
float m[9] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
char glove_measurement_buffer[512];
uint8_t data[13] = "Hola soy jaz";
int counter = 0;
int num = 0;
int data_size;

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART service UUID
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

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}



void loop() {
    if (deviceConnected) {
        int size_written =  sprintf(glove_measurement_buffer, "%d\nP%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\nR%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\nM%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\nI%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\nT%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f;",
        counter,
        m[0], m[1], m[2], m[3], m[3], m[5], m[6], m[7], m[8],
        m[0], m[1], m[2], m[3], m[3], m[5], m[6], m[7], m[8],
        m[0], m[1], m[2], m[3], m[3], m[5], m[6], m[7], m[8],
        m[0], m[1], m[2], m[3], m[3], m[5], m[6], m[7], m[8],
        m[0], m[1], m[2], m[3], m[3], m[5], m[6], m[7], m[8]);
        counter++;
        m[0] = num;
        m[1] = - num - 0.1;
        m[2] = - num - 0.2;
        m[3] = - num - 0.3;
        m[4] = - num - 0.4;
        m[5] = - num - 0.5;
        m[6] = - num - 0.6;
        m[7] = - num - 0.7;
        m[8] = - num - 0.8;
        num = num + 1;
        if(size_written > 512){
           Serial.print("Error size is bigger than 512!!");
        }
        Serial.print("  size_written: "); Serial.println(size_written);
        Serial.println(String(glove_measurement_buffer));
        Serial.println();
        pTxCharacteristic->setValue(glove_measurement_buffer);
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

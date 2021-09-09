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
uint8_t glove_measurement_buffer[sizeof(float)*45];
uint8_t data[13] = "Hola soy jaz";

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

        Serial.print("sending message: [");

        uint8_t * pinky_buffer = glove_measurement_buffer;
        toByteArray(pinky_buffer, 0);

        uint8_t * ring_buffer = glove_measurement_buffer + 9*(sizeof(float));
        toByteArray(ring_buffer, 1);

        uint8_t * middle_buffer = glove_measurement_buffer + 18*(sizeof(float));
        toByteArray(middle_buffer, 2);

        uint8_t * index_buffer = glove_measurement_buffer + 27*(sizeof(float));
        toByteArray(index_buffer, 3);

        uint8_t * thumb_buffer = glove_measurement_buffer + 36*(sizeof(float));
        toByteArray(thumb_buffer, 4);

        pTxCharacteristic->setValue(glove_measurement_buffer, 45*sizeof(float));
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


void toByteArray(uint8_t buffer[], int num){
    memcpy(buffer, &m[0], sizeof(float));
    m[0] = num;
    Serial.print(m[0]);Serial.print(",");

    memcpy(buffer + 1*sizeof(float), &m[1], sizeof(float));
    m[1] = num + 0.1;
    Serial.print(m[1]);Serial.print(",");

    memcpy(buffer + 2*sizeof(float), &m[2], sizeof(float));
    m[2] = num + 0.2;
    Serial.print(m[2]);Serial.print(",");

    memcpy(buffer + 3*sizeof(float), &m[3], sizeof(float));
    m[3] = num + 0.3;
    Serial.print(m[3]);Serial.print(",");

    memcpy(buffer + 4*sizeof(float), &m[4], sizeof(float));
    m[4] = num + 0.4;
    Serial.print(m[4]);Serial.print(",");

    memcpy(buffer + 5*sizeof(float), &m[5], sizeof(float));
    m[5] = num + 0.5;
    Serial.print(m[5]);Serial.print(",");

    memcpy(buffer + 6*sizeof(float), &m[6], sizeof(float));
    m[6] = num + 0.6;
    Serial.print(m[6]);Serial.print(",");

    memcpy(buffer + 7*sizeof(float), &m[7], sizeof(float));
    m[7] = num + 0.7;
    Serial.print(m[7]);Serial.print(",");

    memcpy(buffer + 8*sizeof(float), &m[8], sizeof(float));
    m[8] = num + 0.8;
    Serial.print(m[8]);Serial.println("]");

}
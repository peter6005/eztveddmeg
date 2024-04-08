#include <WiFi.h>
#include <HTTPClient.h>

// WiFi network settings
const char* ssid = "eztveddmeg";
const char* password = "password";

// The URL of the server to which requests are sent
const char* serverUrl = "http://lopert.ddns.net:3000/additembybarcode";

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  delay(100);

  // Connect to the WiFi network
  connectToWiFi();
}

void loop() {
  // If there is input available from the serial monitor
  if (Serial.available()) {
    // Read from the serial monitor
    String barcode = Serial.readString();
    barcode.trim();
    // If a valid barcode is received
    if (barcode.length() > 0) {
      Serial.println("Barcode read: " + barcode);
      // Send request to the server
      sendRequest(barcode);
    }
  }
}

// Connect to the WiFi network
void connectToWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  // Wait for connection to the WiFi network
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }

  Serial.println("\nConnected to WiFi");
}

// Send request to the server
void sendRequest(String barcode) {
  HTTPClient http;

  // Send request to the server URL
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");

  // Prepare request body in JSON format
  String requestBody = "{\"barcode\": \"" + barcode + "\"}";

  // Send POST request to the server
  int httpResponseCode = http.POST(requestBody);

  // If the request was successful
  if (httpResponseCode > 0) {
    // Receive response from the server
    String response = http.getString();
    Serial.println("Response: " + response);
  } else {
    // If the request failed
    Serial.print("Error on sending POST request: ");
    Serial.println(httpResponseCode);
  }

  // Close the request
  http.end();
}

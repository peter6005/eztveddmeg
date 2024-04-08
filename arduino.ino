#include <usbhid.h>
#include <usbhub.h>
#include <hiduniversal.h>
#include <hidboot.h>
#include <SPI.h>

// Array to store keyboard input
byte keyboard[256], counter;
char symbol;

// Custom parser class to handle keyboard input
class MyParser : public HIDReportParser {
public:
  MyParser();
  void Parse(USBHID *hid, bool is_rpt_id, byte len, byte *buf);
protected:
  virtual void OnScanFinished();
};

MyParser::MyParser() {}

void MyParser::Parse(USBHID *hid, bool is_rpt_id, byte len, byte *buf) {
  // Iterate through the input buffer
  for (int i = 0; i <= 7; i++) {
    // If a key is pressed
    if (buf[i] != 0) {
      // Store the key in the keyboard array
      keyboard[counter++] = buf[i];
    }
    // If the Enter key is pressed
    if (buf[i] == UHS_HID_BOOT_KEY_ENTER) {
      // Call the OnScanFinished method to process the input
      OnScanFinished();
      counter = 0;
    }
  }
}

void MyParser::OnScanFinished() {
  // Iterate through the stored keyboard input
  for (int i = 0; i < counter; i++) {
    // If the Enter key is encountered, stop processing
    if (keyboard[i] == 0x28) { break; }

    // If the key is a printable character
    if (keyboard[i] >= 0x04 && keyboard[i] < 0x28) {
      // Convert HID key code to ASCII character
      if (keyboard[i] == 0x27) {
        symbol = 0x30;  // Handle special case for single quote
      } else {
        symbol = keyboard[i] + 0x13;  // Convert HID key code to ASCII
      }

      // Print the character
      Serial.print(symbol);
    }
  }

  // Print newline character to signify end of input
  Serial.println();
}

// USB objects
USB Usb;
USBHub Hub(&Usb);
HIDUniversal Hid(&Usb);
MyParser Parser;

void setup() {
  Serial.begin(115200);
  Serial.println("Start");

  // Initialize USB
  if (Usb.Init() == -1) { Serial.println("USB did not start."); }

  delay(200);

  // Set custom parser for HID device
  Hid.SetReportParser(0, &Parser);

  counter = 0;
}

void loop() {
  // Handle USB tasks
  Usb.Task();
}

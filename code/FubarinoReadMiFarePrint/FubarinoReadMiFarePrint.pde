/**************************************************************************/
/*! 
 @file     readMifare.pde
 @author   Adafruit Industries
 	@license  BSD (see license.txt)
 
 This example will wait for any ISO14443A card or tag, and
 depending on the size of the UID will attempt to read from it.
 
 If the card has a 4-byte UID it is probably a Mifare
 Classic card, and the following steps are taken:
 
 - Authenticate block 4 (the first block of Sector 1) using
 the default KEYA of 0XFF 0XFF 0XFF 0XFF 0XFF 0XFF
 - If authentication succeeds, we can then read any of the
 4 blocks in that sector (though only block 4 is read here)
 	 
 If the card has a 7-byte UID it is probably a Mifare
 Ultralight card, and the 4 byte pages can be read directly.
 Page 4 is read by default since this is the first 'general-
 purpose' page on the tags.
 
 
 This is an example sketch for the Adafruit PN532 NFC/RFID breakout boards
 This library works with the Adafruit NFC breakout 
 ----> https://www.adafruit.com/products/364
 
 Check out the links above for our tutorials and wiring diagrams 
 These chips use SPI to communicate, 4 required to interface
 
 Adafruit invests time and resources providing this open source code, 
 please support Adafruit and open-source hardware by purchasing 
 products from Adafruit!
 
 */
/**************************************************************************/

#include <Adafruit_PN532.h>
#include <Adafruit_Thermal.h>

//Images
#include "tinyrp.h"
#include "chart.h"

//Fubarino Pinout
#define SCK  (24)
#define MOSI (26)
#define SS   (27)
#define MISO (25)

Adafruit_Thermal printer(&Serial1);
Adafruit_PN532 nfc(SCK, MISO, MOSI, SS);

void setup(void) {
  Serial.begin(9600);
  Serial.println("Hello!");

  nfc.begin();
  printer.begin();

  uint32_t versiondata = nfc.getFirmwareVersion();
  if (! versiondata) {
    Serial.print("Didn't find PN53x board");
    while (1); // halt
  }
  // Got ok data, print it out!
  Serial.print("Found chip PN5"); 
  Serial.println((versiondata>>24) & 0xFF, HEX); 
  Serial.print("Firmware ver. "); 
  Serial.print((versiondata>>16) & 0xFF, DEC); 
  Serial.print('.'); 
  Serial.println((versiondata>>8) & 0xFF, DEC);

  // configure board to read RFID tags
  nfc.SAMConfig();

  Serial.println("Waiting for an ISO14443A Card ...");
}


void loop(void) {
  uint8_t success;
  uint8_t uid[] = { 
    0, 0, 0, 0, 0, 0, 0       };  // Buffer to store the returned UID
  uint8_t uidLength;                        // Length of the UID (4 or 7 bytes depending on ISO14443A card type)

  // Wait for an ISO14443A type cards (Mifare, etc.).  When one is found
  // 'uid' will be populated with the UID, and uidLength will indicate
  // if the uid is 4 bytes (Mifare Classic) or 7 bytes (Mifare Ultralight)
  success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength);

  if (success) {
    Serial.println("Print started");
    printer.printBitmap(chart_width, chart_height, chart_data);
        delay(3000);
    printer.println("!!!!");
    printer.println("Thank You for using");
    printer.println("Morse's Autotelegrapher");
    printer.println("For more of these Fantastic Invetions");
    printer.println("please visit: Fubar Labs");
    printer.println("http://fubarlabs.org");
    printer.printBitmap(tinyrp_width, tinyrp_height, tinyrp_data);

    printer.feed(1);
    printer.feed(2);

    delay(3000);
    /*
    printer.printBitmap(tinyrp_width, tinyrp_height, tinyrp_data);
     // Print the 135x135 pixel QR code in chart.h
     printer.printBitmap(chart_width, chart_height, chart_data);
     printer.feed(1);
     printer.feed(2);
     
     printer.sleep();      // Tell printer to sleep
     printer.wake();       // MUST call wake() before printing again, even if reset
     printer.setDefault(); // Restore printer to defaults
     */
    Serial.println("Print End");

    // Display some basic information about the card
    Serial.println("Found an ISO14443A card");
    Serial.print("  UID Length: ");
    Serial.print(uidLength, DEC);
    Serial.println(" bytes");
    Serial.print("  UID Value: ");
    nfc.PrintHex(uid, uidLength);
    Serial.println("");

    if (uidLength == 4)
    {
      // We probably have a Mifare Classic card ... 
      Serial.println("Seems to be a Mifare Classic card (4 byte UID)");

      // Now we need to try to authenticate it for read/write access
      // Try with the factory default KeyA: 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF
      Serial.println("Trying to authenticate block 4 with default KEYA value");
      uint8_t keya[6] = { 
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF                   };

      // Start with block 4 (the first block of sector 1) since sector 0
      // contains the manufacturer data and it's probably better just
      // to leave it alone unless you know what you're doing
      //This is authenticating the sector starting at block 8
      //  success = nfc.mifareclassic_AuthenticateBlock(uid, uidLength, 4, 0, keya);
      //This is authenticating the sector starting at block 8, for loop is incremented by 4.
      //The length of the block is 4 so it read 8-11
      //success = nfc.mifareclassic_AuthenticateBlock(uid, uidLength, 8, 0, keya);
      //1024 is 1k card
      for (int ii = 4; ii < 8; ii+=4)
      {
        success = nfc.mifareclassic_AuthenticateBlock(uid, uidLength, ii, 0, keya);
        if (success)
        {
          Serial.println("Sector 1 (Blocks 4..7) has been authenticated");
          uint8_t data[16];

          // If you want to write something to block 4 to test with, uncomment
          // the following line and this text should be read back in a minute
          //  data = {  'a', 'd', 'a', 'f', 'r', 'u', 'i', 't', '.', 'c', 'o', 'm', 0, 0, 0, 0          };
          // success = nfc.mifareclassic_WriteDataBlock (4, data);
          //success = nfc.mifareclassic_WriteDataBlock (8, data);

          // Try to read the contents of block 4
          for (int jj = ii; jj < 4+ii ; jj++)
          {
            success = nfc.mifareclassic_ReadDataBlock(jj, data);

            if (success)
            {
              // Data seems to have been read ... spit it out
              Serial.println("Reading Block:");
              Serial.println(jj);
              nfc.PrintHexChar(data, 16);
              Serial.println("");

              // Wait a bit before reading the card again
              delay(1000);
            }
            else
            {
              Serial.println("Ooops ... unable to read the requested block.  Try another key?");
            }

          }
        }
        else
        {
          Serial.println("Ooops ... authentication failed: Try another key?");
        }
      }
    }

    if (uidLength == 7)
    {
      // We probably have a Mifare Ultralight card ...
      Serial.println("Seems to be a Mifare Ultralight tag (7 byte UID)");

      // Try to read the first general-purpose user page (#4)
      Serial.println("Reading page 4");
      uint8_t data[32];
      success = nfc.mifareultralight_ReadPage (4, data);
      if (success)
      {
        // Data seems to have been read ... spit it out
        nfc.PrintHexChar(data, 4);
        Serial.println("");

        // Wait a bit before reading the card again
        delay(500);
      }
      else
      {
        Serial.println("Ooops ... unable to read the requested page!?");
      }
    }
  }
}





/*************************************************************************
  This is an Arduino library for the Adafruit Thermal Printer.
  Pick one up at --> http://www.adafruit.com/products/597
  These printers use TTL serial to communicate, 2 pins are required.

  Adafruit invests time and resources providing this open source code.
  Please support Adafruit and open-source hardware by purchasing products
  from Adafruit!

  Written by Limor Fried/Ladyada for Adafruit Industries.
  MIT license, all text above must be included in any redistribution.
 *************************************************************************/

// If you're using Arduino 1.0 uncomment the next line:
#include "SoftwareSerial.h"
// If you're using Arduino 23 or earlier, uncomment the next line:
//#include "NewSoftSerial.h"

#include "Adafruit_Thermal.h"
//#include "robotpromise.h"
//#include "tinyrp.h"
#include "tinyrp.h"
#include "chart.h"
//#include <avr/pgmspace.h>

int printer_RX_Pin = 5;  // This is the green wire
int printer_TX_Pin = 6;  // This is the yellow wire

//Adafruit_Thermal printer(printer_RX_Pin, printer_TX_Pin);
Adafruit_Thermal printer(&Serial0);

void setup(){
  Serial.begin(9600);
  pinMode(7, OUTPUT); digitalWrite(7, LOW); // To also work w/IoTP printer
  printer.begin();



  // Test inverse on & off
  printer.inverseOn();
  printer.println("Inverse ON");
  printer.inverseOff();

  // Test character double-height on & off
  printer.doubleHeightOn();
  printer.println("Thank You for using");
  printer.println(" Morse's Autotelegrapher");
  printer.doubleHeightOff();

  printer.justify('L');
  printer.println("For more of these Fantastic Invetions");
  printer.println("please visit: Fubar Labs");
  printer.println("http://fubarlabs.org");

  // Print the 75x75 pixel logo in adalogo.h
 // printer.printBitmap(adalogo_width, adalogo_height, adalogo_data);
  printer.printBitmap(tinyrp_width, tinyrp_height, tinyrp_data);
  // Print the 135x135 pixel QR code in chart.h
  printer.printBitmap(chart_width, chart_height, chart_data);
  printer.feed(1);
  printer.feed(2);

  printer.sleep();      // Tell printer to sleep
  printer.wake();       // MUST call wake() before printing again, even if reset
  printer.setDefault(); // Restore printer to defaults
}

void loop() {
}

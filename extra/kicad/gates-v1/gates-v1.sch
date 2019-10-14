EESchema Schematic File Version 4
LIBS:gates-v1-cache
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L power:+3V3 #PWR03
U 1 1 5BF5F4FC
P 1800 1900
F 0 "#PWR03" H 1800 1750 50  0001 C CNN
F 1 "+3V3" H 1800 2050 50  0000 C CNN
F 2 "" H 1800 1900 50  0001 C CNN
F 3 "" H 1800 1900 50  0001 C CNN
	1    1800 1900
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG01
U 1 1 5BF5F5C5
P 1450 3400
F 0 "#FLG01" H 1450 3475 50  0001 C CNN
F 1 "PWR_FLAG" V 1450 3528 50  0000 L CNN
F 2 "" H 1450 3400 50  0001 C CNN
F 3 "~" H 1450 3400 50  0001 C CNN
	1    1450 3400
	0    -1   -1   0   
$EndComp
$Comp
L power:PWR_FLAG #FLG02
U 1 1 5BF5F603
P 1450 3500
F 0 "#FLG02" H 1450 3575 50  0001 C CNN
F 1 "PWR_FLAG" V 1450 3628 50  0000 L CNN
F 2 "" H 1450 3500 50  0001 C CNN
F 3 "~" H 1450 3500 50  0001 C CNN
	1    1450 3500
	0    -1   -1   0   
$EndComp
$Comp
L Connector_Generic:Conn_01x06 J7
U 1 1 5BF5F845
P 4050 1250
F 0 "J7" H 3969 725 50  0000 C CNN
F 1 "ESP-12/A" H 3969 816 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x06_P2.54mm_Vertical" H 4050 1250 50  0001 C CNN
F 3 "~" H 4050 1250 50  0001 C CNN
	1    4050 1250
	1    0    0    1   
$EndComp
$Comp
L Connector_Generic:Conn_01x06 J8
U 1 1 5BF5F98D
P 4550 1250
F 0 "J8" H 4470 725 50  0000 C CNN
F 1 "ESP-12/B" H 4470 816 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x06_P2.54mm_Vertical" H 4550 1250 50  0001 C CNN
F 3 "~" H 4550 1250 50  0001 C CNN
	1    4550 1250
	-1   0    0    1   
$EndComp
$Comp
L power:+3V3 #PWR014
U 1 1 5BF6A7A6
P 3850 1450
F 0 "#PWR014" H 3850 1300 50  0001 C CNN
F 1 "+3V3" V 3865 1578 50  0000 L CNN
F 2 "" H 3850 1450 50  0001 C CNN
F 3 "" H 3850 1450 50  0001 C CNN
	1    3850 1450
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR020
U 1 1 5BF6A859
P 4750 1450
F 0 "#PWR020" H 4750 1200 50  0001 C CNN
F 1 "GND" H 4755 1277 50  0000 C CNN
F 2 "" H 4750 1450 50  0001 C CNN
F 3 "" H 4750 1450 50  0001 C CNN
	1    4750 1450
	1    0    0    -1  
$EndComp
Text GLabel 3850 1350 0    50   Input ~ 0
MOSI
Text GLabel 3850 1250 0    50   Input ~ 0
MISO
Text GLabel 3850 1150 0    50   Input ~ 0
SCK
Text GLabel 3850 1050 0    50   Input ~ 0
GPIO16
Text GLabel 4750 1350 2    50   Input ~ 0
HCS
Text GLabel 4750 1050 2    50   Input ~ 0
GPIO4
Text GLabel 4750 950  2    50   Input ~ 0
GPIO5
$Comp
L power:GND #PWR015
U 1 1 5BF6F398
P 3850 1650
F 0 "#PWR015" H 3850 1400 50  0001 C CNN
F 1 "GND" H 3855 1477 50  0000 C CNN
F 2 "" H 3850 1650 50  0001 C CNN
F 3 "" H 3850 1650 50  0001 C CNN
	1    3850 1650
	1    0    0    -1  
$EndComp
$Comp
L Device:CP_Small C1
U 1 1 5BF6F8C0
P 3850 1550
F 0 "C1" H 3938 1596 50  0000 L CNN
F 1 "10uF" H 3938 1505 50  0000 L CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-3216-18_Kemet-A_Pad1.58x1.35mm_HandSolder" H 3850 1550 50  0001 C CNN
F 3 "~" H 3850 1550 50  0001 C CNN
	1    3850 1550
	1    0    0    -1  
$EndComp
Connection ~ 3850 1450
NoConn ~ 3850 950 
$Comp
L Connector_Generic:Conn_01x02 J1
U 1 1 5D94B8F5
P 1650 3500
F 0 "J1" H 1570 3175 50  0000 C CNN
F 1 "9V" H 1570 3266 50  0000 C CNN
F 2 "TerminalBlock:TerminalBlock_bornier-2_P5.08mm" H 1650 3500 50  0001 C CNN
F 3 "~" H 1650 3500 50  0001 C CNN
	1    1650 3500
	1    0    0    1   
$EndComp
$Comp
L power:+9V #PWR0101
U 1 1 5D94CBC9
P 1450 3400
F 0 "#PWR0101" H 1450 3250 50  0001 C CNN
F 1 "+9V" H 1465 3573 50  0000 C CNN
F 2 "" H 1450 3400 50  0001 C CNN
F 3 "" H 1450 3400 50  0001 C CNN
	1    1450 3400
	1    0    0    -1  
$EndComp
Connection ~ 1450 3400
$Comp
L MCU_Microchip_ATtiny:ATtiny13A-SSU U2
U 1 1 5D94E3BA
P 6300 1350
F 0 "U2" H 5770 1396 50  0000 R CNN
F 1 "ATtiny13A-SSU" H 5770 1305 50  0000 R CNN
F 2 "Package_SO:SOIC-8_3.9x4.9mm_P1.27mm" H 6300 1350 50  0001 C CIN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/doc8126.pdf" H 6300 1350 50  0001 C CNN
	1    6300 1350
	1    0    0    -1  
$EndComp
$Comp
L power:+3V3 #PWR0103
U 1 1 5D965A48
P 2400 1900
F 0 "#PWR0103" H 2400 1750 50  0001 C CNN
F 1 "+3V3" H 2400 2050 50  0000 C CNN
F 2 "" H 2400 1900 50  0001 C CNN
F 3 "" H 2400 1900 50  0001 C CNN
	1    2400 1900
	1    0    0    -1  
$EndComp
$Comp
L Device:CP_Small C4
U 1 1 5D965EB5
P 2400 2000
F 0 "C4" H 2488 2046 50  0000 L CNN
F 1 "470uF" H 2488 1955 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D8.0mm_P3.80mm" H 2400 2000 50  0001 C CNN
F 3 "~" H 2400 2000 50  0001 C CNN
	1    2400 2000
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 5D966568
P 2400 2100
F 0 "#PWR0104" H 2400 1850 50  0001 C CNN
F 1 "GND" H 2405 1927 50  0000 C CNN
F 2 "" H 2400 2100 50  0001 C CNN
F 3 "" H 2400 2100 50  0001 C CNN
	1    2400 2100
	1    0    0    -1  
$EndComp
Text GLabel 6900 1350 2    50   Input ~ 0
GPIO5
$Comp
L Connector_Generic:Conn_01x04 J10
U 1 1 5D968AF5
P 3850 2300
F 0 "J10" H 3768 2617 50  0000 C CNN
F 1 "MTR_A" H 3768 2526 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x04_P2.54mm_Vertical" H 3850 2300 50  0001 C CNN
F 3 "~" H 3850 2300 50  0001 C CNN
	1    3850 2300
	-1   0    0    -1  
$EndComp
Text GLabel 3300 2200 0    50   Input ~ 0
MTR_IN_1
Text GLabel 3300 2300 0    50   Input ~ 0
MTR_IN_2
$Comp
L Connector_Generic:Conn_01x04 J9
U 1 1 5D9688F4
P 3500 2300
F 0 "J9" H 3450 2600 50  0000 L CNN
F 1 "MTR_IN" H 3300 2500 50  0000 L CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x04_P2.54mm_Vertical" H 3500 2300 50  0001 C CNN
F 3 "~" H 3500 2300 50  0001 C CNN
	1    3500 2300
	1    0    0    -1  
$EndComp
NoConn ~ 3300 2400
NoConn ~ 3300 2500
NoConn ~ 4050 2400
NoConn ~ 4050 2500
Text GLabel 4050 2200 2    50   Input ~ 0
MTR+
Text GLabel 4050 2300 2    50   Input ~ 0
MTR-
Text GLabel 6900 1050 2    50   Input ~ 0
MTR_IN_1
Text GLabel 6900 1150 2    50   Input ~ 0
MTR_IN_2
$Comp
L power:+3V3 #PWR0105
U 1 1 5D96AE29
P 6300 750
F 0 "#PWR0105" H 6300 600 50  0001 C CNN
F 1 "+3V3" H 6300 900 50  0000 C CNN
F 2 "" H 6300 750 50  0001 C CNN
F 3 "" H 6300 750 50  0001 C CNN
	1    6300 750 
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0106
U 1 1 5D96B3AF
P 6300 1950
F 0 "#PWR0106" H 6300 1700 50  0001 C CNN
F 1 "GND" H 6305 1777 50  0000 C CNN
F 2 "" H 6300 1950 50  0001 C CNN
F 3 "" H 6300 1950 50  0001 C CNN
	1    6300 1950
	1    0    0    -1  
$EndComp
Text GLabel 6900 1250 2    50   Input ~ 0
BUZZER
Text GLabel 6900 1450 2    50   Input ~ 0
DOOR_SW
$Comp
L Connector_Generic:Conn_01x02 J3
U 1 1 5D96BCE9
P 2050 2800
F 0 "J3" H 1970 2475 50  0000 C CNN
F 1 "MTR_PWR" H 1970 2566 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x02_P2.54mm_Vertical" H 2050 2800 50  0001 C CNN
F 3 "~" H 2050 2800 50  0001 C CNN
	1    2050 2800
	1    0    0    1   
$EndComp
$Comp
L power:GND #PWR0107
U 1 1 5D96C55C
P 1450 3500
F 0 "#PWR0107" H 1450 3250 50  0001 C CNN
F 1 "GND" H 1455 3327 50  0000 C CNN
F 2 "" H 1450 3500 50  0001 C CNN
F 3 "" H 1450 3500 50  0001 C CNN
	1    1450 3500
	1    0    0    -1  
$EndComp
Connection ~ 1450 3500
$Comp
L power:GND #PWR0108
U 1 1 5D96C9E6
P 1850 2800
F 0 "#PWR0108" H 1850 2550 50  0001 C CNN
F 1 "GND" H 1855 2627 50  0000 C CNN
F 2 "" H 1850 2800 50  0001 C CNN
F 3 "" H 1850 2800 50  0001 C CNN
	1    1850 2800
	1    0    0    -1  
$EndComp
$Comp
L power:+9V #PWR0109
U 1 1 5D96CCD7
P 1850 2700
F 0 "#PWR0109" H 1850 2550 50  0001 C CNN
F 1 "+9V" H 1865 2873 50  0000 C CNN
F 2 "" H 1850 2700 50  0001 C CNN
F 3 "" H 1850 2700 50  0001 C CNN
	1    1850 2700
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x02 J2
U 1 1 5D96EBAE
P 1650 3900
F 0 "J2" H 1650 4100 50  0000 C CNN
F 1 "MTR" H 1650 4000 50  0000 C CNN
F 2 "TerminalBlock:TerminalBlock_bornier-2_P5.08mm" H 1650 3900 50  0001 C CNN
F 3 "~" H 1650 3900 50  0001 C CNN
	1    1650 3900
	1    0    0    -1  
$EndComp
Text GLabel 1450 3900 0    50   Input ~ 0
MTR+
Text GLabel 1450 4000 0    50   Input ~ 0
MTR-
$Comp
L Device:Buzzer BZ1
U 1 1 5D973576
P 8250 1350
F 0 "BZ1" H 8402 1379 50  0000 L CNN
F 1 "Buzzer" H 8402 1288 50  0000 L CNN
F 2 "Buzzer_Beeper:Buzzer_12x9.5RM7.6" V 8225 1450 50  0001 C CNN
F 3 "~" V 8225 1450 50  0001 C CNN
	1    8250 1350
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0111
U 1 1 5D9769E6
P 8150 1450
F 0 "#PWR0111" H 8150 1200 50  0001 C CNN
F 1 "GND" H 8155 1277 50  0000 C CNN
F 2 "" H 8150 1450 50  0001 C CNN
F 3 "" H 8150 1450 50  0001 C CNN
	1    8150 1450
	1    0    0    -1  
$EndComp
Text GLabel 8150 1250 0    50   Input ~ 0
BUZZER
$Comp
L Connector_Generic:Conn_01x02 J5
U 1 1 5D976CD0
P 2500 3500
F 0 "J5" H 2500 3200 50  0000 C CNN
F 1 "DOOR_SW" H 2500 3300 50  0000 C CNN
F 2 "TerminalBlock:TerminalBlock_bornier-2_P5.08mm" H 2500 3500 50  0001 C CNN
F 3 "~" H 2500 3500 50  0001 C CNN
	1    2500 3500
	1    0    0    1   
$EndComp
Text GLabel 2300 3400 0    50   Input ~ 0
DOOR_SW
$Comp
L power:GND #PWR0112
U 1 1 5D978273
P 2300 3500
F 0 "#PWR0112" H 2300 3250 50  0001 C CNN
F 1 "GND" H 2305 3327 50  0000 C CNN
F 2 "" H 2300 3500 50  0001 C CNN
F 3 "" H 2300 3500 50  0001 C CNN
	1    2300 3500
	1    0    0    -1  
$EndComp
NoConn ~ 4750 1250
$Comp
L Connector_Generic:Conn_01x03 J6
U 1 1 5D9C1E7B
P 1600 2000
F 0 "J6" H 1650 1650 50  0000 C CNN
F 1 "DC-DC" H 1650 1750 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x03_P2.54mm_Vertical" H 1600 2000 50  0001 C CNN
F 3 "~" H 1600 2000 50  0001 C CNN
	1    1600 2000
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0113
U 1 1 5D9C31F2
P 2000 2000
F 0 "#PWR0113" H 2000 1750 50  0001 C CNN
F 1 "GND" H 2005 1827 50  0000 C CNN
F 2 "" H 2000 2000 50  0001 C CNN
F 3 "" H 2000 2000 50  0001 C CNN
	1    2000 2000
	1    0    0    -1  
$EndComp
Wire Wire Line
	1800 2000 2000 2000
$Comp
L power:+9V #PWR0114
U 1 1 5D9C3BA3
P 1800 2100
F 0 "#PWR0114" H 1800 1950 50  0001 C CNN
F 1 "+9V" H 1815 2273 50  0000 C CNN
F 2 "" H 1800 2100 50  0001 C CNN
F 3 "" H 1800 2100 50  0001 C CNN
	1    1800 2100
	-1   0    0    1   
$EndComp
$Comp
L Device:R_Small R1
U 1 1 5D9DCAA0
P 4850 1150
F 0 "R1" V 4654 1150 50  0000 C CNN
F 1 "R_Small" V 4745 1150 50  0000 C CNN
F 2 "Resistor_SMD:R_1206_3216Metric" H 4850 1150 50  0001 C CNN
F 3 "~" H 4850 1150 50  0001 C CNN
	1    4850 1150
	0    1    1    0   
$EndComp
Wire Wire Line
	4950 1150 5150 1150
$Comp
L power:+3V3 #PWR0115
U 1 1 5D9DD96F
P 5150 1150
F 0 "#PWR0115" H 5150 1000 50  0001 C CNN
F 1 "+3V3" H 5150 1300 50  0000 C CNN
F 2 "" H 5150 1150 50  0001 C CNN
F 3 "" H 5150 1150 50  0001 C CNN
	1    5150 1150
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x04 J11
U 1 1 5D94C648
P 7050 2150
F 0 "J11" H 6968 2467 50  0000 C CNN
F 1 "Conn_01x04" H 6968 2376 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 7050 2150 50  0001 C CNN
F 3 "~" H 7050 2150 50  0001 C CNN
	1    7050 2150
	-1   0    0    -1  
$EndComp
Text GLabel 6900 1550 2    50   Input ~ 0
RESET
Text GLabel 7250 2350 2    50   Input ~ 0
RESET
Text GLabel 7250 2150 2    50   Input ~ 0
MTR_IN_2
Text GLabel 7250 2050 2    50   Input ~ 0
MTR_IN_1
Text GLabel 7250 2250 2    50   Input ~ 0
BUZZER
$Comp
L power:+3V3 #PWR0110
U 1 1 5D9D80A5
P 1800 1000
F 0 "#PWR0110" H 1800 850 50  0001 C CNN
F 1 "+3V3" H 1800 1150 50  0000 C CNN
F 2 "" H 1800 1000 50  0001 C CNN
F 3 "" H 1800 1000 50  0001 C CNN
	1    1800 1000
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x04_Odd_Even J4
U 1 1 5D98DED4
P 1500 1100
F 0 "J4" H 1550 1417 50  0000 C CNN
F 1 "SPEAKER_UNIT" H 1550 1326 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x04_P2.54mm_Vertical" H 1500 1100 50  0001 C CNN
F 3 "~" H 1500 1100 50  0001 C CNN
	1    1500 1100
	1    0    0    -1  
$EndComp
Text GLabel 1800 1100 2    50   Input ~ 0
HCS
Text GLabel 1800 1200 2    50   Input ~ 0
GPIO4
$Comp
L power:GND #PWR013
U 1 1 5BF74B94
P 1800 1300
F 0 "#PWR013" H 1800 1050 50  0001 C CNN
F 1 "GND" H 1805 1127 50  0000 C CNN
F 2 "" H 1800 1300 50  0001 C CNN
F 3 "" H 1800 1300 50  0001 C CNN
	1    1800 1300
	1    0    0    -1  
$EndComp
Text GLabel 1300 1300 0    50   Input ~ 0
GPIO16
Text GLabel 1300 1200 0    50   Input ~ 0
SCK
Text GLabel 1300 1100 0    50   Input ~ 0
MISO
Text GLabel 1300 1000 0    50   Input ~ 0
MOSI
$EndSCHEMATC

# EcoWatt: IoT Based Energy Monitoring and Controlling System

## Project Title

EcoWatt: IoT Energy Monitoring and Controlling System

## Problem & Solution

### Problem
Many households lack awareness of how much electricity individual appliances consume. As a result, users find it difficult to identify energy wastage, monitor electricity usage, and make informed decisions that can help reduce electricity costs.

### Solution
EcoWatt is an Internet of Things (IoT)-based smart energy monitoring and controlling system developed to help users monitor the electricity consumption of individual appliances in real time. The system uses an ESP32 microcontroller together with voltage and current sensors to measure electrical parameters. The collected data is transmitted over Wi-Fi to a mobile application, where users can view live voltage, current, power consumption, energy usage history, and analytics. This helps users understand their electricity usage and make better energy management decisions.

## Technologies Used

### Hardware
- ESP32 Development Board
- ZMPT101B Voltage Sensor
- SCT-013 Current Sensor
- OLED Display
- Breadboard
- Jumper Wires
- Extension Cable
- Flat Iron (Test Appliance)

### Software
- Flutter
- Firebase
- Arduino IDE
- Visual Studio Code
- Git
- GitHub

## Setup Instructions

### Software Installation

1. Clone the repository.

```bash
git clone https://github.com/Yvonne-prog/EcoWatt.git
```

2. Open the project folder.

```bash
cd EcoWatt
```

3. Install all Flutter dependencies.

```bash
flutter pub get
```

4. Connect an Android device or start an Android emulator.

5. Run the application.

```bash
flutter run
```

### Hardware Setup

1. Connect the ZMPT101B voltage sensor to the ESP32.
2. Connect the SCT-013 current sensor to the ESP32.
3. Connect the OLED display to the ESP32.
4. Upload the ESP32 program using Arduino IDE.
5. Connect the ESP32 and the mobile phone to the same Wi-Fi network.
6. Power the ESP32.
7. Open the EcoWatt mobile application to monitor electricity usage in real time.

## Features

- User authentication
- Real-time voltage monitoring
- Real-time current monitoring
- Power consumption monitoring
- Live electricity usage dashboard
- Energy usage analytics
- Appliance monitoring
- OLED display for live readings
- Wi-Fi communication between hardware and mobile application
- Firebase integration for data storage


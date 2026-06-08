# fpga-uart-control
# FPGA UART Frequency & PWM Control System (DE10-Nano)

## Overview

This project demonstrates UART-based communication between a PC and an Intel DE10-Nano FPGA board for real-time digital signal control and monitoring. The system is designed to validate FPGA-to-PC and PC-to-FPGA communication using frequency control switches and pulse-width-controlled PWM generation.

The project does not involve motor control. Instead, it focuses on digital signal generation, UART communication, and real-time visualization through a Python-based interface.

---

## Key Features

* Real-time frequency selection using FPGA onboard switches
* UART transmission of selected frequency to PC GUI
* Python GUI for monitoring FPGA frequency output
* User-defined PWM pulse width generation from PC
* FPGA GPIO output pulse generation with microsecond precision
* Serial terminal view for debugging and verification

---

## System Functionality

### 1. Frequency Control (FPGA → PC)

The DE10-Nano board uses onboard slide switches to select output frequency:

| Switch | Frequency |
| ------ | --------- |
| SW1    | 100 Hz    |
| SW2    | 200 Hz    |
| SW3    | 300 Hz    |
| SW4    | 400 Hz    |

* The selected frequency is processed inside the FPGA.
* The frequency value is transmitted to the PC via UART.
* The Python GUI displays the current active frequency in real time.

---

### 2. PWM Pulse Width Control (PC → FPGA)

The Python GUI allows the user to input a desired pulse width in microseconds.

Example:

* Input: `2`
* Output: FPGA generates a HIGH pulse of **2 microseconds** on a GPIO pin.

This enables precise testing of timing accuracy and FPGA pulse generation capability.

---

## Hardware Setup

### FPGA Platform

* Intel DE10-Nano (Cyclone V SoC FPGA)

### UART Interface

* DSD TECH SH-U09C USB-to-TTL Serial Adapter
* FTDI FT232RL USB-UART Bridge

### Connections

| FT232RL | DE10-Nano |
| ------- | --------- |
| TXD     | FPGA RX   |
| RXD     | FPGA TX   |
| GND     | GND       |

---

### FPGA GPIO Output

* One GPIO pin configured as PWM output
* Pulse width controlled by UART command from PC

---

### Data Flow

```
FPGA Switches → Frequency Selector → UART TX → PC GUI Display
```

```
PC GUI → UART TX → FPGA → Pulse Width Generator → GPIO Output Pulse
```

---

## FPGA Design 

### 1. Switch Frequency Decoder

* Reads FPGA onboard switches
* Maps switch combination to frequency values (100–400 Hz)

---

### 2. UART Transmitter

* Sends frequency data to PC in real time
* Format: ASCII or encoded integer stream

---

### 3. UART Receiver

* Receives pulse width values from PC GUI
* Parses numeric input (microseconds)

---

### 4. PWM / Pulse Generator

* Generates precise HIGH pulse based on received pulse width
* Output is driven on FPGA GPIO pin

---

## Python GUI

The GUI provides:

* Real-time frequency display from FPGA
* Input box for pulse width (in microseconds)
* Send button to transmit pulse width to FPGA
* Serial monitor window for debugging UART data

### GUI Features

* Live frequency update display
* UART communication via pyserial
* Simple control interface for FPGA testing
* Optional serial console view

---

## Development Tools

### FPGA Design

* Intel Quartus Prime
* ModelSim / QuestaSim

### Software

* Python 3.15
* Visual Studio Code

## Use Case

This system is designed as a **hardware-software co-design test platform** for:

* UART communication validation
* FPGA timing accuracy testing
* Digital signal generation experiments
* Embedded system interface development

## Results

* Stable UART communication between DE10-Nano and PC
* Accurate frequency selection via FPGA switches
* Verified microsecond-level pulse generation on GPIO
* Successful real-time GUI interaction with FPGA hardware

## Author

Varsha Sri
FPGA Engineer | Embedded Systems Engineer


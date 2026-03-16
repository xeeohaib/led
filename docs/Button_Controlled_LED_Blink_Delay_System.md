# Button-Controlled LED Blink Delay System on ZC702 FPGA

## Table of Contents

1. [Introduction](#1-introduction)
2. [Hardware Used](#2-hardware-used)
3. [System Architecture](#3-system-architecture)
4. [Flow Diagram](#4-flow-diagram)
5. [Implementation Steps (Vivado)](#5-implementation-steps-vivado)
6. [Pin Constraints Example (XDC)](#6-pin-constraints-example-xdc)

---

## 1. Introduction

### What Is an FPGA?

A **Field-Programmable Gate Array (FPGA)** is a semiconductor device containing an
array of configurable logic blocks (CLBs), programmable interconnects, and I/O
blocks. Unlike a fixed-function ASIC, an FPGA can be reprogrammed after
manufacturing to implement virtually any digital circuit. This makes FPGAs ideal
for prototyping, embedded control, signal processing, and educational projects.

### The Xilinx ZC702 Evaluation Board

The **ZC702** is a Xilinx evaluation board built around the **Zynq-7000 SoC
(xc7z020clg484-1)**. It combines a dual-core ARM Cortex-A9 processing system
(PS) with Artix-7 class programmable logic (PL) in a single device. Key
features include:

* 200 MHz differential system clock available on the PL side
* Multiple GPIO headers including the **J63 Pmod-compatible connector**
* Gigabit Ethernet, USB, HDMI, and FMC expansion connectors
* On-board JTAG for programming and debug via Vivado Hardware Manager

The ZC702 User Guide (**UG850**) and the board schematics provide full pin
mapping details for all connectors and peripherals.

### Purpose of This Project

This project demonstrates **basic FPGA I/O control using GPIO and timing
logic**. An LED connected to the J63 header blinks continuously, and a push
button on the same header allows the user to increase the blink delay at
runtime. The design uses fundamental digital building blocks — clock division,
counters, and debounce logic — implemented entirely in **Verilog HDL** and
deployed with **Xilinx Vivado**.

---

## 2. Hardware Used

### Components

| Component   | Board Pin | FPGA Package Pin (typical) | Description                              |
|-------------|-----------|---------------------------|------------------------------------------|
| LED         | J63 Pin 1 | E15                       | Output — blinking LED                    |
| Push Button | J63 Pin 2 | D15                       | Input — control for delay increment      |
| System Clock| Y9 / Y8   | Y9 (P), Y8 (N)           | 200 MHz LVDS differential clock          |
| Reset       | CPU_RESET  | A15                       | Active-high system reset                 |

### Pin-Mapping Reference

The pin assignments above are derived from the **ZC702 Evaluation Board User
Guide (UG850)**, specifically:

* **Table 1-26** — Pmod connector J63 pin-to-FPGA mapping
* **Board schematics** — Section covering the J63 GPIO header

> **Important:** Always cross-check pin assignments against the version of the
> UG850 document and schematics that match your board revision. The PACKAGE_PIN
> values (E15, D15) shown here are representative and must be verified for your
> specific board revision.

### J63 Connector Pinout

The J63 connector is a standard 12-pin Pmod-compatible header. The relevant
pins for this project are:

```
 J63 Pmod Header (top view)
 ┌───────────────────────┐
 │  Pin 6   Pin 5  Pin 4 │  (top row — power / ground)
 │  GND     GND    VCC   │
 │                       │
 │  Pin 3   Pin 2  Pin 1 │  (bottom row — I/O signals)
 │  GPIO    BTN    LED   │
 └───────────────────────┘
```

* **Pin 1 (LED)** → FPGA I/O bank, LVCMOS25, active-high output
* **Pin 2 (BTN)** → FPGA I/O bank, LVCMOS25, active-high input from external push button with pull-down resistor

Refer to the ZC702 schematics for the exact schematic net names and FPGA ball
assignments.

---

## 3. System Architecture

### Digital Logic Components

The design consists of four key components:

| Component           | Description                                                     |
|---------------------|-----------------------------------------------------------------|
| **Clock Divider / Blink Counter** | Counts system clock cycles up to the current delay limit and toggles the LED |
| **Delay Counter Register**        | Stores the current blink half-period (in clock cycles); incremented by button presses |
| **Button Debounce Logic**         | Filters mechanical switch bounce; outputs a single clean pulse per press |
| **LED Toggle Logic**              | Inverts the LED output each time the blink counter reaches the delay limit |

### Block Diagram

```
                 ┌─────────────────────────────────────────────────┐
                 │              led_blink_delay (top)              │
                 │                                                 │
  clk ──────────┤►  ┌────────────────┐    ┌────────────────────┐  │
                 │   │  Blink Counter │    │  Delay Limit Reg   │  │
                 │   │                │◄───┤  (100 ms – 2000 ms)│  │
                 │   │  count → match │    │                    │  │
                 │   └───────┬────────┘    └────────▲───────────┘  │
                 │           │ toggle               │ +100 ms      │
                 │           ▼                      │              │
  led ◄──────────┤    ┌──────────────┐    ┌─────────┴──────────┐   │
                 │    │  LED Toggle  │    │  Debounce Module   │   │
                 │    │  (flip-flop) │    │  (10 ms filter)    │   │
                 │    └──────────────┘    └─────────▲──────────┘   │
                 │                                  │              │
  btn ───────────┤──────────────────────────────────┘              │
                 │                                                 │
  rst ───────────┤► (async reset to all registers)                 │
                 └─────────────────────────────────────────────────┘
```

**Signal flow:**

1. **Clock (`clk`)** drives the blink counter and all synchronous logic.
2. **Blink Counter** counts from 0 up to `delay_limit − 1`, then resets and
   toggles the LED.
3. **Button (`btn`)** passes through the **Debounce Module**, which filters
   bounce and produces a single-cycle pulse.
4. Each debounced pulse increments the **Delay Limit Register** by 100 ms
   worth of clock cycles (20,000,000 cycles at 200 MHz), up to the 2000 ms
   maximum (400,000,000 cycles).
5. **Reset (`rst`)** asynchronously resets all registers to their initial
   values (delay = 100 ms, counter = 0, LED = off).

---

## 4. Flow Diagram

```
                          ┌───────────┐
                          │   START   │
                          └─────┬─────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │ Initialize           │
                     │  delay = 100 ms      │
                     │  counter = 0         │
                     │  LED = OFF           │
                     └──────────┬──────────┘
                                │
                ┌───────────────▼───────────────┐
                │                               │
                │  ┌─────────────────────────┐  │
                │  │ Increment blink counter │  │
                │  └────────────┬────────────┘  │
                │               │               │
                │               ▼               │
                │  ┌─────────────────────────┐  │
                │  │ counter ≥ delay limit?  │  │
                │  └─────┬──────────┬────────┘  │
                │     NO │          │ YES       │
                │        │          ▼           │
                │        │  ┌─────────────┐     │
                │        │  │ Toggle LED  │     │
                │        │  │ Reset cntr  │     │
                │        │  └──────┬──────┘     │
                │        │         │            │
                │        ▼         ▼            │
                │  ┌─────────────────────────┐  │
                │  │  Button pressed?        │  │
                │  └─────┬──────────┬────────┘  │
                │     NO │          │ YES       │
                │        │          ▼           │
                │        │  ┌──────────────┐    │
                │        │  │ delay < 2 s? │    │
                │        │  └──┬────────┬──┘    │
                │        │  NO │     YES│       │
                │        │    │        ▼       │
                │        │    │ ┌───────────┐  │
                │        │    │ │delay+=100ms│  │
                │        │    │ └─────┬─────┘  │
                │        │    │       │        │
                │        ▼    ▼       ▼        │
                │  ┌─────────────────────────┐  │
                │  │    Continue loop         │  │
                │  └─────────────────────────┘  │
                │               │               │
                └───────────────┘               │
                                                │
                         (loops forever)
```

---

## 5. Implementation Steps (Vivado)

Follow these steps to build, synthesize, and deploy the design on the ZC702:

1. **Open Vivado** — Launch Xilinx Vivado (2020.2 or later recommended).

2. **Create a new RTL project** — Select *File → Project → New...*; choose
   **RTL Project** and check *Do not specify sources at this time* (sources
   will be added next).

3. **Select the ZC702 board** — In the *Default Part* step, switch to the
   **Boards** tab and select **ZC702 Evaluation Board**. This sets the target
   device to **xc7z020clg484-1**.

4. **Add Verilog source files** — In the *Sources* panel, click *Add Sources →
   Add or create design sources* and add:
   * `src/led_blink_delay.v` (top-level module)
   * `src/debounce.v` (button debounce sub-module)

5. **Write / review LED blinking logic** — The top-level module
   (`led_blink_delay`) contains a blink counter that counts clock cycles and
   toggles the LED when the counter reaches the configurable delay limit.

6. **Add button input logic** — The same top-level module reads the `btn`
   input and, on each debounced press, increments the delay limit register by
   100 ms worth of clock cycles.

7. **Implement debounce module** — The `debounce` module filters mechanical
   switch bounce by requiring the button input to be stable for ≈ 10 ms before
   registering a change.

8. **Create XDC constraints file** — In the *Sources* panel, click *Add Sources
   → Add or create constraints* and add `constraints/zc702_pins.xdc`.

9. **Assign pins in the XDC file:**
   * LED → J63 Pin 1 (`PACKAGE_PIN E15`)
   * Button → J63 Pin 2 (`PACKAGE_PIN D15`)
   * Clock → Y9 with LVDS I/O standard
   * Reset → A15 with LVCMOS25 I/O standard

10. **Run Synthesis** — Click *Run Synthesis* in the Flow Navigator. Fix any
    errors or warnings before proceeding.

11. **Run Implementation** — Click *Run Implementation* to place and route the
    design.

12. **Generate Bitstream** — Click *Generate Bitstream* to produce the `.bit`
    file.

13. **Program FPGA using Hardware Manager** — Open *Hardware Manager → Open
    Target → Auto Connect*, then *Program Device* with the generated bitstream.

---

## 6. Pin Constraints Example (XDC)

The complete constraints file is located at
[`constraints/zc702_pins.xdc`](../constraints/zc702_pins.xdc). Below is the
key content:

```tcl
## System Clock — 200 MHz LVDS
set_property PACKAGE_PIN Y9   [get_ports clk]
set_property IOSTANDARD LVDS  [get_ports clk]
create_clock -period 5.000 -name sys_clk [get_ports clk]

## Reset
set_property PACKAGE_PIN A15  [get_ports rst]
set_property IOSTANDARD LVCMOS25 [get_ports rst]

## LED Output — J63 Pin 1
set_property PACKAGE_PIN E15  [get_ports led]
set_property IOSTANDARD LVCMOS25 [get_ports led]

## Push Button Input — J63 Pin 2
set_property PACKAGE_PIN D15  [get_ports btn]
set_property IOSTANDARD LVCMOS25 [get_ports btn]
```

### Key Notes

* **`PACKAGE_PIN`** — Maps a Verilog port to a physical FPGA ball (pad). The
  values above (E15, D15, Y9, A15) are typical for the ZC702 J63 header and
  must be verified against the board schematics for your revision.
* **`IOSTANDARD`** — Specifies the electrical I/O standard. The J63 header
  bank on the ZC702 typically uses **LVCMOS25** (2.5 V logic). The system clock
  uses **LVDS** (Low-Voltage Differential Signaling).
* **`create_clock`** — Informs the Vivado timing engine about the clock
  frequency so that it can perform accurate timing analysis during
  implementation.

> **Tip:** If Vivado reports an *unconstrained clock* or *I/O standard
> conflict*, double-check that the IOSTANDARD matches the voltage bank where
> the pin resides. Refer to UG850 for bank voltage assignments.

## =============================================================================
## ZC702 Pin Constraints — Button-Controlled LED Blink Delay System
## =============================================================================
## Target device : xc7z020clg484-1 (Xilinx ZC702 Evaluation Board)
## Reference     : UG850 — ZC702 Evaluation Board User Guide
## =============================================================================

## -----------------------------------------------------------------------------
## System Clock — 200 MHz differential clock on PL side
## ZC702 provides a 200 MHz LVDS clock on pins Y9 (P) / Y8 (N).
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN Y9   [get_ports clk]
set_property IOSTANDARD LVDS  [get_ports clk]

## Create a 200 MHz (5 ns period) clock constraint
create_clock -period 5.000 -name sys_clk [get_ports clk]

## -----------------------------------------------------------------------------
## Reset — active-high reset input
## Connected to an available GPIO or the board CPU_RESET push button.
## Use an appropriate pin for your board setup.
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN A15  [get_ports rst]
set_property IOSTANDARD LVCMOS25 [get_ports rst]

## -----------------------------------------------------------------------------
## LED Output — J63 Pin 1
## Connected to the J63 Pmod-compatible header Pin 1 on the ZC702.
## Typical mapping: J63 Pin 1 → FPGA package pin E15.
## Verify the exact PACKAGE_PIN using UG850 Table 1-26 or board schematics.
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN E15  [get_ports led]
set_property IOSTANDARD LVCMOS25 [get_ports led]

## -----------------------------------------------------------------------------
## Push Button Input — J63 Pin 2
## Connected to the J63 Pmod-compatible header Pin 2 on the ZC702.
## Typical mapping: J63 Pin 2 → FPGA package pin D15.
## Verify the exact PACKAGE_PIN using UG850 Table 1-26 or board schematics.
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN D15  [get_ports btn]
set_property IOSTANDARD LVCMOS25 [get_ports btn]

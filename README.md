# Button-Controlled LED Blink Delay System on ZC702 FPGA

An FPGA project implemented in **Verilog HDL** targeting the **Xilinx ZC702
evaluation board (xc7z020clg484-1)**. An LED blinks continuously and a push
button increases the blink delay by 100 ms per press, up to a maximum of
2 seconds.

## Repository Structure

```
├── constraints/
│   └── zc702_pins.xdc            # Xilinx Design Constraints (pin assignments)
├── docs/
│   └── Button_Controlled_LED_Blink_Delay_System.md   # Full project document
├── src/
│   ├── led_blink_delay.v         # Top-level module
│   ├── debounce.v                # Button debounce sub-module
│   └── tb_led_blink_delay.v      # Simulation testbench
├── .gitignore
└── README.md
```

## Quick Start

1. Open **Xilinx Vivado** and create a new RTL project targeting the ZC702
   board.
2. Add the Verilog sources from `src/` and the constraints from
   `constraints/`.
3. Run Synthesis → Implementation → Generate Bitstream.
4. Program the FPGA via Hardware Manager.

See the [full project document](docs/Button_Controlled_LED_Blink_Delay_System.md)
for detailed instructions, block diagrams, and flow charts.

## Simulation

A testbench (`src/tb_led_blink_delay.v`) is provided for behavioral
simulation with a reduced clock frequency for fast execution:

```bash
# Using Icarus Verilog
iverilog -o tb_led_blink_delay src/led_blink_delay.v src/debounce.v src/tb_led_blink_delay.v
vvp tb_led_blink_delay
```

## License

This project is provided for educational purposes.
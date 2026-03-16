`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// Module: led_blink_delay
// Description: Top-level module for the Button-Controlled LED Blink Delay
//              System on the Xilinx ZC702 evaluation board.
//
//   - LED on J63 Pin 1 blinks continuously.
//   - Push button on J63 Pin 2 increases the blink half-period by 100 ms
//     per press, up to a maximum of 2000 ms.
//   - System clock is 200 MHz (ZC702 default differential clock).
//
// Parameters:
//   CLK_FREQ_HZ   - System clock frequency (default 200 MHz).
//   DELAY_STEP_MS - Delay increment per button press in ms (default 100).
//   MAX_DELAY_MS  - Maximum allowed delay in ms (default 2000).
//   INIT_DELAY_MS - Initial blink half-period in ms (default 100).
//-----------------------------------------------------------------------------
module led_blink_delay #(
    parameter CLK_FREQ_HZ   = 200_000_000,
    parameter DELAY_STEP_MS = 100,
    parameter MAX_DELAY_MS  = 2000,
    parameter INIT_DELAY_MS = 100
)(
    input  wire clk,
    input  wire rst,
    input  wire btn,       // Push button input (active-high)
    output reg  led        // LED output
);

    // -----------------------------------------------------------------------
    // Derived constants
    // -----------------------------------------------------------------------
    localparam integer CYCLES_PER_MS    = CLK_FREQ_HZ / 1000;
    localparam integer STEP_CYCLES      = DELAY_STEP_MS * CYCLES_PER_MS;
    localparam integer MAX_DELAY_CYCLES = MAX_DELAY_MS  * CYCLES_PER_MS;
    localparam integer INIT_CYCLES      = INIT_DELAY_MS * CYCLES_PER_MS;

    // Counter width must accommodate the maximum delay value
    localparam CNT_WIDTH = $clog2(MAX_DELAY_CYCLES + 1);

    // -----------------------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------------------
    reg  [CNT_WIDTH-1:0] blink_counter;
    reg  [CNT_WIDTH-1:0] delay_limit;
    wire                  btn_pulse;

    // -----------------------------------------------------------------------
    // Button debounce (10 ms debounce window at CLK_FREQ_HZ)
    // -----------------------------------------------------------------------
    debounce #(
        .DEBOUNCE_LIMIT(CLK_FREQ_HZ / 100)   // 10 ms
    ) u_debounce (
        .clk      (clk),
        .rst      (rst),
        .btn_in   (btn),
        .btn_pulse(btn_pulse)
    );

    // -----------------------------------------------------------------------
    // Delay-limit register: increases by STEP_CYCLES on each press,
    //                       capped at MAX_DELAY_CYCLES.
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_limit <= INIT_CYCLES[CNT_WIDTH-1:0];
        end else if (btn_pulse) begin
            if (delay_limit + STEP_CYCLES <= MAX_DELAY_CYCLES)
                delay_limit <= delay_limit + STEP_CYCLES;
            // else: already at max — do nothing
        end
    end

    // -----------------------------------------------------------------------
    // Blink counter and LED toggle
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blink_counter <= {CNT_WIDTH{1'b0}};
            led           <= 1'b0;
        end else begin
            if (blink_counter >= delay_limit - 1) begin
                blink_counter <= {CNT_WIDTH{1'b0}};
                led           <= ~led;
            end else begin
                blink_counter <= blink_counter + 1'b1;
            end
        end
    end

endmodule

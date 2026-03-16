`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// Module: debounce
// Description: Debounces a mechanical push-button input.
//              Requires the input to be stable for DEBOUNCE_LIMIT clock cycles
//              before updating the output. Generates a single-cycle pulse on
//              the rising edge of the debounced signal.
//
// Parameters:
//   DEBOUNCE_LIMIT - Number of clock cycles the input must be stable.
//                    Default 1_000_000 (~5 ms at 200 MHz, ~10 ms at 100 MHz).
//-----------------------------------------------------------------------------
module debounce #(
    parameter DEBOUNCE_LIMIT = 1_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,      // Raw button input (active-high)
    output reg  btn_pulse    // Single-cycle pulse on debounced rising edge
);

    // Width of the counter needed to hold DEBOUNCE_LIMIT
    localparam CNT_WIDTH = $clog2(DEBOUNCE_LIMIT + 1);

    reg [CNT_WIDTH-1:0] count;
    reg                  btn_stable;  // Last stable (debounced) value

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count      <= {CNT_WIDTH{1'b0}};
            btn_stable <= 1'b0;
            btn_pulse  <= 1'b0;
        end else begin
            btn_pulse <= 1'b0;  // Default: no pulse

            if (btn_in != btn_stable) begin
                // Input differs from stable value — start counting
                if (count == DEBOUNCE_LIMIT - 1) begin
                    btn_stable <= btn_in;
                    count      <= {CNT_WIDTH{1'b0}};
                    // Generate pulse only on rising edge (0 → 1)
                    if (btn_in == 1'b1)
                        btn_pulse <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end else begin
                count <= {CNT_WIDTH{1'b0}};
            end
        end
    end

endmodule

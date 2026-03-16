`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// Testbench: tb_led_blink_delay
// Description: Verifies the led_blink_delay top-level module with a reduced
//              clock frequency so that simulation completes quickly.
//-----------------------------------------------------------------------------
module tb_led_blink_delay;

    // Use a much smaller clock frequency for simulation speed.
    // 1 kHz clock ⇒ 1 ms per cycle, so 100-ms delay = 100 cycles.
    localparam CLK_FREQ_HZ   = 1_000;
    localparam DELAY_STEP_MS = 100;
    localparam MAX_DELAY_MS  = 2000;
    localparam INIT_DELAY_MS = 100;

    // 1 kHz ⇒ 500 us half-period = 500_000 ns
    localparam HALF_PERIOD = 500_000;

    reg  clk;
    reg  rst;
    reg  btn;
    wire led;

    // Instantiate the DUT with reduced parameters
    led_blink_delay #(
        .CLK_FREQ_HZ   (CLK_FREQ_HZ),
        .DELAY_STEP_MS (DELAY_STEP_MS),
        .MAX_DELAY_MS   (MAX_DELAY_MS),
        .INIT_DELAY_MS  (INIT_DELAY_MS)
    ) uut (
        .clk (clk),
        .rst (rst),
        .btn (btn),
        .led (led)
    );

    // Clock generation
    initial clk = 0;
    always #(HALF_PERIOD) clk = ~clk;

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    initial begin
        // --- Reset ---
        rst = 1;
        btn = 0;
        #(HALF_PERIOD * 4);
        rst = 0;

        // --- Wait for a few LED toggles at the initial 100-ms delay ---
        // 100 ms at 1 kHz = 100 cycles ⇒ 100 full clock periods
        #(HALF_PERIOD * 2 * 100 * 3); // ~3 toggles

        // --- Press button once (increase delay to 200 ms) ---
        btn = 1;
        #(HALF_PERIOD * 2 * 20);  // Hold for 20 cycles (well past debounce)
        btn = 0;
        #(HALF_PERIOD * 2 * 250); // Observe at new delay

        // --- Press button enough times to reach max (2000 ms) ---
        repeat (20) begin
            #(HALF_PERIOD * 2 * 30);
            btn = 1;
            #(HALF_PERIOD * 2 * 20);
            btn = 0;
        end

        // --- Observe LED at max delay ---
        #(HALF_PERIOD * 2 * 2500);

        // --- Press again — delay should NOT increase beyond 2000 ms ---
        btn = 1;
        #(HALF_PERIOD * 2 * 20);
        btn = 0;
        #(HALF_PERIOD * 2 * 2500);

        $display("TB: Simulation complete.");
        $finish;
    end

    // Optional: dump waveform
    initial begin
        $dumpfile("tb_led_blink_delay.vcd");
        $dumpvars(0, tb_led_blink_delay);
    end

endmodule

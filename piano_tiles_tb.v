`timescale 1ns / 1ps

module piano_tiles_tb;

    // Inputs
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;

    // Outputs
    wire [9:0] LEDR;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    // Instantiate the Unit Under Test (UUT)
    piano_tiles dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    // Clock generation - 50MHz (20ns period)
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        KEY = 4'b1111;  // Keys are active low (not pressed)
        SW = 10'b0000000000;  // Reset active

        // Display test start
        $display("=== Piano Tiles Testbench Started ===");
        $display("Time: %0t", $time);

        // Hold reset for 100ns
        #100;

        // Release reset
        SW[0] = 1'b1;
        $display("Time: %0t - Reset released, game started", $time);

        // Let the game run for a while
        #10000;

        // Simulate key press on column 1 (KEY[3])
        $display("Time: %0t - Pressing KEY[3] (Column 1)", $time);
        KEY[3] = 1'b0;  // Press key
        #200;
        KEY[3] = 1'b1;  // Release key

        // Wait
        #5000;

        // Simulate key press on column 2 (KEY[2])
        $display("Time: %0t - Pressing KEY[2] (Column 2)", $time);
        KEY[2] = 1'b0;
        #200;
        KEY[2] = 1'b1;

        // Wait
        #5000;

        // Simulate key press on column 3 (KEY[1])
        $display("Time: %0t - Pressing KEY[1] (Column 3)", $time);
        KEY[1] = 1'b0;
        #200;
        KEY[1] = 1'b1;

        // Wait
        #5000;

        // Simulate key press on column 4 (KEY[0])
        $display("Time: %0t - Pressing KEY[0] (Column 4)", $time);
        KEY[0] = 1'b0;
        #200;
        KEY[0] = 1'b1;

        // Let it run more
        #10000;

        // Test reset functionality
        $display("Time: %0t - Asserting reset", $time);
        SW[0] = 1'b0;
        #500;
        SW[0] = 1'b1;
        $display("Time: %0t - Reset released again", $time);

        // Continue running
        #10000;

        // End simulation
        $display("Time: %0t - Testbench completed", $time);
        $display("=== Piano Tiles Testbench Finished ===");
        $stop;
    end

    // Monitor important state changes
    always @(posedge CLOCK_50) begin
        // Monitor column states
        if (dut.col1.state == 3'd4)
            $display("Time: %0t - Column 1: Clearing tile", $time);
        if (dut.col2.state == 3'd4)
            $display("Time: %0t - Column 2: Clearing tile", $time);
        if (dut.col3.state == 3'd4)
            $display("Time: %0t - Column 3: Clearing tile", $time);
        if (dut.col4.state == 3'd4)
            $display("Time: %0t - Column 4: Clearing tile", $time);
    end

endmodule

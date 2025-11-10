// Simplified stub models for Altera primitives (for simulation only)
// These are minimal implementations to allow testbench to run without full Quartus libraries

`timescale 1ns / 1ps

// Simplified altpll model
module altpll (
    inclk,
    clk,
    c0,
    locked
);

    parameter intended_device_family = "Cyclone II";
    parameter lpm_type = "altpll";
    parameter clk0_divide_by = 1;
    parameter clk0_duty_cycle = 50;
    parameter clk0_multiply_by = 1;
    parameter clk0_phase_shift = "0";
    parameter compensate_clock = "CLK0";
    parameter inclk0_input_frequency = 20000;
    parameter operation_mode = "NORMAL";
    parameter pll_type = "AUTO";
    parameter primary_clock = "INCLK0";

    input [1:0] inclk;
    output [5:0] clk;
    output c0;
    output locked;

    reg c0_reg;
    reg [5:0] clk_reg;
    reg locked_reg;

    assign c0 = c0_reg;
    assign clk = clk_reg;
    assign locked = locked_reg;

    // Simple clock generation based on multiply/divide
    initial begin
        c0_reg = 0;
        clk_reg = 6'b000000;
        locked_reg = 0;
        #100 locked_reg = 1; // Lock after 100ns
    end

    // Generate output clock
    real input_period;
    real output_period;

    initial begin
        input_period = inclk0_input_frequency / 1000.0; // Convert to ns
        output_period = (input_period * clk0_divide_by) / clk0_multiply_by;

        // Wait for lock
        #100;

        // Generate clock
        forever begin
            #(output_period/2) begin
                c0_reg = ~c0_reg;
                clk_reg[0] = ~clk_reg[0];
            end
        end
    end

endmodule

// Simplified altsyncram model
module altsyncram (
    wren_a,
    wren_b,
    clock0,
    clock1,
    clocken0,
    clocken1,
    address_a,
    address_b,
    data_a,
    q_b,
    // Legacy ports for compatibility
    wrclock,
    rdclock,
    data,
    wraddress,
    rdaddress,
    wren,
    rden,
    q
);

    parameter intended_device_family = "Cyclone II";
    parameter lpm_type = "altsyncram";
    parameter operation_mode = "DUAL_PORT";
    parameter width_a = 8;
    parameter widthad_a = 10;
    parameter numwords_a = 1024;
    parameter width_b = 8;
    parameter widthad_b = 10;
    parameter numwords_b = 1024;
    parameter address_reg_b = "CLOCK1";
    parameter outdata_reg_b = "UNREGISTERED";
    parameter rdcontrol_reg_b = "CLOCK1";
    parameter ram_block_type = "AUTO";
    parameter clock_enable_input_a = "BYPASS";
    parameter clock_enable_input_b = "BYPASS";
    parameter clock_enable_output_b = "BYPASS";
    parameter power_up_uninitialized = "FALSE";
    parameter init_file = "UNUSED";

    input wren_a;
    input wren_b;
    input clock0;
    input clock1;
    input clocken0;
    input clocken1;
    input [widthad_a-1:0] address_a;
    input [widthad_b-1:0] address_b;
    input [width_a-1:0] data_a;
    output reg [width_b-1:0] q_b;

    // Legacy ports
    input wrclock;
    input rdclock;
    input [width_a-1:0] data;
    input [widthad_a-1:0] wraddress;
    input [widthad_b-1:0] rdaddress;
    input wren;
    input rden;
    output reg [width_b-1:0] q;

    // Memory array
    reg [width_a-1:0] mem [0:numwords_a-1];

    // Initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < numwords_a; i = i + 1) begin
            mem[i] = 0;
        end
        q = 0;
        q_b = 0;
    end

    // Determine actual control signals (support both port naming styles)
    wire write_clock = (clock0 !== 1'bz) ? clock0 : wrclock;
    wire read_clock = (clock1 !== 1'bz) ? clock1 : rdclock;
    wire write_enable = (wren_a !== 1'bz) ? wren_a : wren;
    wire read_enable = (clocken1 !== 1'bz) ? clocken1 : rden;
    wire [widthad_a-1:0] write_addr = (address_a !== {widthad_a{1'bz}}) ? address_a : wraddress;
    wire [widthad_b-1:0] read_addr = (address_b !== {widthad_b{1'bz}}) ? address_b : rdaddress;
    wire [width_a-1:0] write_data = (data_a !== {width_a{1'bz}}) ? data_a : data;

    // Write port
    always @(posedge write_clock) begin
        if (write_enable) begin
            mem[write_addr] <= write_data;
        end
    end

    // Read port (support both q and q_b outputs)
    always @(posedge read_clock) begin
        if (read_enable) begin
            q <= mem[read_addr];
            q_b <= mem[read_addr];
        end
    end

endmodule

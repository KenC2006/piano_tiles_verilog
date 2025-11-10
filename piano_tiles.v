`default_nettype none

module piano_tiles(CLOCK_50, KEY, SW, LEDR, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

	input wire CLOCK_50;
	input wire [3:0] KEY;
	input wire [9:0] SW;
	output wire [9:0] LEDR;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;

	// VGA stuff
    reg [2:0] color;
    reg [9:0] X;
    reg [8:0] Y;
    reg write = 1;
    // Decides which column gets the VGA
    reg [1:0] vga_turn;

    // States for each column 
    localparam DRAW_RECT = 3'd0;
    localparam ERASE_TOP = 3'd1;
    localparam DRAW_BOTTOM = 3'd2;
    localparam DELAY = 3'd3;
    localparam CLEAR_TILE = 3'd4;

    // Column output wires
    wire [9:0] X1, X2, X3, X4;
    wire [8:0] Y1, Y2, Y3, Y4;
    wire [2:0] state1, state2, state3, state4;
    wire [8:0] start_y1, start_y2, start_y3, start_y4;
    wire [8:0] end_y1, end_y2, end_y3, end_y4;

    assign LEDR = 10'd0;

    //  cycles through columns
    always @(posedge CLOCK_50) begin
        if (!SW[0]) begin
            vga_turn <= 2'd0;
        end else begin
            vga_turn <= vga_turn + 2'd1;
        end
    end

    // sets vars for column to use VGA
    always @(*) begin
        // Normal piano tiles mode
        case (vga_turn)
            2'd0: begin
                X = X1;
                Y = Y1;
                if (state1 == ERASE_TOP || state1 == CLEAR_TILE) begin
                    color = 3'b000;
                end else begin
                    color = 3'b111;
                end
            end
            2'd1: begin
                X = X2;
                Y = Y2;
                if (state2 == ERASE_TOP || state2 == CLEAR_TILE) begin
                    color = 3'b000;
                end else begin
                    color = 3'b111;
                end
            end
            2'd2: begin
                X = X3;
                Y = Y3;
                if (state3 == ERASE_TOP || state3 == CLEAR_TILE) begin
                    color = 3'b000;
                end else begin
                    color = 3'b111;
                end
            end
            2'd3: begin
                X = X4;
                Y = Y4;
                if (state4 == ERASE_TOP || state4 == CLEAR_TILE) begin
                    color = 3'b000;
                end else begin
                    color = 3'b111;
                end
            end
        endcase
    end
    

    // Column 1
    column #(10'd0, 10'd160, 9'd0, 9'd120) col1 (CLOCK_50, !SW[0], vga_turn, 2'd0, KEY[3], X1, Y1, state1, start_y1, end_y1);

    // Column 2
    column #(10'd161, 10'd320, 9'd0, 9'd120) col2 (CLOCK_50, !SW[0], vga_turn, 2'd1, KEY[2], X2, Y2, state2, start_y2, end_y2);

    // Column 3
    column #(10'd321, 10'd480, 9'd0, 9'd120) col3 (CLOCK_50, !SW[0], vga_turn, 2'd2, KEY[1], X3, Y3, state3, start_y3, end_y3);

    // Column 4
    column #(10'd481, 10'd640, 9'd0, 9'd120) col4 (CLOCK_50, !SW[0], vga_turn, 2'd3, KEY[0], X4, Y4, state4, start_y4, end_y4);

    vga_adapter VGA (
        .resetn(SW[0]),
        .clock(CLOCK_50),
        .color(color),
        .x(X),
        .y(Y),
        .write(write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "640x480";
	defparam VGA.COLOR_DEPTH = 3;

endmodule

module column #(
    parameter START_X = 10'd0,
    parameter END_X = 10'd160,
    parameter INITIAL_START_Y = 9'd0,
    parameter INITIAL_END_Y = 9'd120
)(
    input wire clk,
    input wire reset,
    input wire [1:0] vga_turn,
    input wire [1:0] my_id,
    input wire key_pressed,

    output reg [9:0] X,
    output reg [8:0] Y,
    output reg [2:0] state,
    output reg [8:0] start_y,
    output reg [8:0] end_y
);

    // States
    localparam DRAW_RECT = 3'd0;
    localparam ERASE_TOP = 3'd1;
    localparam DRAW_BOTTOM = 3'd2;
    localparam DELAY = 3'd3;
    localparam CLEAR_TILE = 3'd4;

    reg [8:0] old_end_y;
    reg [25:0] delay_counter;
    reg key_prev;

    always @(posedge clk) begin
        if (reset) begin
            // Reset column
            state <= DRAW_RECT;
            X <= START_X;
            Y <= INITIAL_START_Y;
            start_y <= INITIAL_START_Y;
            end_y <= INITIAL_END_Y;
            delay_counter <= 26'd0;
            key_prev <= 0;
        end else begin
            key_prev <= key_pressed;

            if (key_pressed && !key_prev) begin
                old_end_y <= end_y;
                state <= CLEAR_TILE;
                X <= START_X;
                Y <= start_y;
            end else begin
                case (state)
                    DRAW_RECT: begin
                        if (vga_turn == my_id) begin
                            if (X < END_X) begin
                                X <= X + 10'd1;
                            end else begin
                                X <= START_X;
                                if (Y < end_y) begin
                                    Y <= Y + 9'd1;
                                end else begin
                                    state <= ERASE_TOP;
                                    X <= START_X;
                                end
                            end
                        end
                    end

                    ERASE_TOP: begin
                        if (vga_turn == my_id) begin
                            Y <= start_y;
                            if (X < END_X) begin
                                X <= X + 10'd1;
                            end else begin
                                state <= DRAW_BOTTOM;
                                X <= START_X;
                            end
                        end
                    end

                    DRAW_BOTTOM: begin
                        if (vga_turn == my_id) begin
                            Y <= end_y + 9'd1;
                            if (X < END_X) begin
                                X <= X + 10'd1;
                            end else begin
                                start_y <= start_y + 9'd1;
                                end_y <= end_y + 9'd1;
                                state <= DELAY;
                                delay_counter <= 26'd0;
                            end
                        end
                    end

                    DELAY: begin
                        if (delay_counter < 26'd5) begin
                            delay_counter <= delay_counter + 26'd1;
                        end else begin
                            state <= ERASE_TOP;
                            X <= START_X;
                            Y <= start_y;
                        end
                    end

                    CLEAR_TILE: begin
                        if (vga_turn == my_id) begin
                            if (X < END_X) begin
                                X <= X + 10'd1;
                            end else begin
                                X <= START_X;
                                if (Y < old_end_y) begin
                                    Y <= Y + 9'd1;
                                end else begin
                                    start_y <= INITIAL_START_Y;
                                    end_y <= INITIAL_END_Y;
                                    Y <= INITIAL_START_Y;
                                    X <= START_X;
                                    state <= DRAW_RECT;
                                end
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule



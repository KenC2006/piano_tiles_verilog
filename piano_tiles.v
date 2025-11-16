`default_nettype none

module piano_tiles(CLOCK_50, KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX4, HEX5, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    input wire CLOCK_50;
    input wire [3:0] KEY;
    input wire [9:0] SW;
    output wire [9:0] LEDR;
    output wire [6:0] HEX0;
    output wire [6:0] HEX1;
	 output wire [6:0] HEX2;
	 output wire [6:0] HEX4;
    output wire [6:0] HEX5;
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
    // Decides which column gets its turn with the VGA
    reg [1:0] vga_turn;

    // States for each column
    localparam DRAW_RECT = 3'd0;
    localparam ERASE_TOP = 3'd1;
    localparam DRAW_BOTTOM = 3'd2;
    localparam DELAY = 3'd3;
    localparam CLEAR_TILE = 3'd4;
    localparam IDLE = 3'd5;

    // Column output wires
    wire [9:0] X1, X2, X3, X4;
    wire [8:0] Y1, Y2, Y3, Y4;
    wire [2:0] state1, state2, state3, state4;
    wire [8:0] start_y1, start_y2, start_y3, start_y4;
    wire [8:0] end_y1, end_y2, end_y3, end_y4;
    wire hit_success1, hit_success2, hit_success3, hit_success4;
	 wire miss1, miss2, miss3, miss4;
	 
	 wire Resetn = SW[0]; //active high reset
	 
	 
	 wire [1:0] scrollspeed = SW[2:1];
	 
	 always @(*) begin
		if (!SW[0]) begin
			HEX2_reg = 7'b1111111;
		end else begin
		case (scrollspeed)
			2'b00: HEX2_reg = 7'b1111001;
			2'b01: HEX2_reg = 7'b0100100;
			2'b11: HEX2_reg = 7'b0110000;
			default: HEX2_reg = 7'b1111111;  // blank
		endcase
	end
	end
	 
	 reg [1:0] speed_setting;
	
	always @(posedge CLOCK_50) begin
		if (!SW[0]) begin
			speed_setting <= speed_setting;
		end else begin
			speed_setting <= scrollspeed;
		end
	end
		
	 

    // Random number generator (LFSR) - wider for more independence
    reg [31:0] lfsr;

    always @(posedge CLOCK_50) begin
        if (!SW[0]) begin
            lfsr <= 32'hACE1BEAD; 
        end else begin
            // 32-bit LFSR with taps at positions 32, 22, 2, 1
            lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        end
    end

    // Score tracking
    reg [7:0] score = 8'd0;
	 
	 // Combo
	 reg [7:0] combo = 8'd0;


    assign LEDR = 10'd0;

    reg [6:0] HEX0_reg;
    reg [6:0] HEX1_reg;

    assign HEX0 = HEX0_reg;
    assign HEX1 = HEX1_reg;
	 
	 reg [6:0] HEX4_reg;
    reg [6:0] HEX5_reg;

    assign HEX4 = HEX4_reg;
    assign HEX5 = HEX5_reg;
	 reg [6:0] HEX2_reg;
	assign HEX2 = HEX2_reg;

	
	wire [3:0] ones_digit = score % 10;
	wire [3:0] tens_digit = score / 10;
	wire [3:0] combo_ones_digit = combo % 10;
	wire [3:0] combo_tens_digit = combo / 10;

	always @(*) begin
		if (!SW[0]) begin
			HEX0_reg = 7'b1111111;
			HEX1_reg = 7'b1111111;
		end else begin
		case (ones_digit)
			4'd0: HEX0_reg = 7'b1000000;
			4'd1: HEX0_reg = 7'b1111001;
			4'd2: HEX0_reg = 7'b0100100;
			4'd3: HEX0_reg = 7'b0110000;
			4'd4: HEX0_reg = 7'b0011001;
			4'd5: HEX0_reg = 7'b0010010;
			4'd6: HEX0_reg = 7'b0000010;
			4'd7: HEX0_reg = 7'b1111000;
			4'd8: HEX0_reg = 7'b0000000;
			4'd9: HEX0_reg = 7'b0010000;
			default: HEX0_reg = 7'b1111111;  // blank
		endcase
		 
		case (tens_digit)
			4'd0: HEX1_reg = 7'b1000000;
			4'd1: HEX1_reg = 7'b1111001;
			4'd2: HEX1_reg = 7'b0100100;
			4'd3: HEX1_reg = 7'b0110000;
			4'd4: HEX1_reg = 7'b0011001;
			4'd5: HEX1_reg = 7'b0010010;
			4'd6: HEX1_reg = 7'b0000010;
			4'd7: HEX1_reg = 7'b1111000;
			4'd8: HEX1_reg = 7'b0000000;
			4'd9: HEX1_reg = 7'b0010000;
			default: HEX1_reg = 7'b1111111;
		endcase
		end
	end

	 
	//draw combo on SW[9:8]
	always @(*) begin
		if (!SW[0]) begin
			HEX4_reg = 7'b1111111;
			HEX5_reg = 7'b1111111;
		end else begin
		case (combo_ones_digit)
			4'd0: HEX4_reg = 7'b1000000;
			4'd1: HEX4_reg = 7'b1111001;
			4'd2: HEX4_reg = 7'b0100100;
			4'd3: HEX4_reg = 7'b0110000;
			4'd4: HEX4_reg = 7'b0011001;
			4'd5: HEX4_reg = 7'b0010010;
			4'd6: HEX4_reg = 7'b0000010;
			4'd7: HEX4_reg = 7'b1111000;
			4'd8: HEX4_reg = 7'b0000000;
			4'd9: HEX4_reg = 7'b0010000;
			default: HEX4_reg = 7'b1111111;  // blank
		endcase
		  
		case (combo_tens_digit)
			4'd0: HEX5_reg = 7'b1000000;
			4'd1: HEX5_reg = 7'b1111001;
			4'd2: HEX5_reg = 7'b0100100;
			4'd3: HEX5_reg = 7'b0110000;
			4'd4: HEX5_reg = 7'b0011001;
			4'd5: HEX5_reg = 7'b0010010;
			4'd6: HEX5_reg = 7'b0000010;
			4'd7: HEX5_reg = 7'b1111000;
			4'd8: HEX5_reg = 7'b0000000;
			4'd9: HEX5_reg = 7'b0010000;
			default: HEX5_reg = 7'b1111111;
		endcase
		end
	end

	//combo logic
	
	
	
	wire miss = miss1 || miss2 || miss3 || miss4; 
	always @(posedge CLOCK_50) begin
		if (!SW[0]) begin
			combo <= 0;
		end else if (hit_success1 || hit_success2 || hit_success3 || hit_success4) begin
			combo <= combo + 1;
		end else if (miss)
			combo <= 0;
	end
    // Score update logic
    always @(posedge CLOCK_50) begin
        if (!SW[0]) begin
            score <= 8'd0;
        end else if (hit_success1 || hit_success2 || hit_success3 || hit_success4) begin
            score <= score + 1;
        end
    end

    //  cycles through columns
    always @(posedge CLOCK_50) begin
        if (!SW[0]) begin
            vga_turn <= 2'd0;
        end else begin
            vga_turn <= vga_turn + 1;
        end
    end

    localparam HIT_TOP = 9'd360;
    localparam HIT_BOTTOM = 9'd500;

    // sets vars for column to use VGA
    always @(posedge CLOCK_50) begin
        if (!SW[0]) begin
            X <= 10'd0;
            Y <= 9'd0;
            color <= 3'b000;
        end else begin
            case (vga_turn)
                2'd0: begin
                    X <= X1;
                    Y <= Y1;
                    if (state1 == ERASE_TOP || state1 == CLEAR_TILE || state1 == IDLE) begin
                        color <= 3'b000;
                    end else if ((end_y1 >= HIT_TOP) && (start_y1 <= HIT_BOTTOM)) begin
                        color <= 3'b010;
                    end else begin
                        color <= 3'b111;
                    end
                end
                2'd1: begin
                    X <= X2;
                    Y <= Y2;
                    if (state2 == ERASE_TOP || state2 == CLEAR_TILE || state2 == IDLE) begin
                        color <= 3'b000;
                    end else if ((end_y2 >= HIT_TOP) && (start_y2 <= HIT_BOTTOM)) begin
                        color <= 3'b010;
                    end else begin
                        color <= 3'b111;
                    end
                end
                2'd2: begin
                    X <= X3;
                    Y <= Y3;
                    if (state3 == ERASE_TOP || state3 == CLEAR_TILE || state3 == IDLE) begin
                        color <= 3'b000;
                    end else if ((end_y3 >= HIT_TOP) && (start_y3 <= HIT_BOTTOM)) begin
                        color <= 3'b010;
                    end else begin
                        color <= 3'b111;
                    end
                end
                2'd3: begin
                    X <= X4;
                    Y <= Y4;
                    if (state4 == ERASE_TOP || state4 == CLEAR_TILE || state4 == IDLE) begin
                        color <= 3'b000;
                    end else if ((end_y4 >= HIT_TOP) && (start_y4 <= HIT_BOTTOM)) begin
                        color <= 3'b010;
                    end else begin
                        color <= 3'b111;
                    end
                end
            endcase
        end
    end

	 
	 wire pause = !SW[0]; //stop notes falling when SW[0] is off
	 
    // Column 1 - use bits 7:0 for more randomness
    column #(10'd0, 10'd160, 9'd0, 9'd120) col1 (CLOCK_50, pause, vga_turn, 2'd0, KEY[3], lfsr[7:0], X1, Y1, state1, start_y1, end_y1, hit_success1, miss1, speed_setting);

    // Column 2 - use bits 15:8 (separated from col1)
    column #(10'd160, 10'd320, 9'd0, 9'd120) col2 (CLOCK_50, pause, vga_turn, 2'd1, KEY[2], lfsr[15:8], X2, Y2, state2, start_y2, end_y2, hit_success2, miss2, speed_setting);

    // Column 3 - use bits 23:16 (separated)
    column #(10'd320, 10'd480, 9'd0, 9'd120) col3 (CLOCK_50, pause, vga_turn, 2'd2, KEY[1], lfsr[23:16], X3, Y3, state3, start_y3, end_y3, hit_success3, miss3, speed_setting);

    // Column 4 - use bits 31:24 (separated)
    column #(10'd480, 10'd640, 9'd0, 9'd120) col4 (CLOCK_50, pause, vga_turn, 2'd3, KEY[0], lfsr[31:24], X4, Y4, state4, start_y4, end_y4, hit_success4, miss4, speed_setting);

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

module column #(parameter START_X = 10'd0, parameter END_X = 10'd160, parameter INITIAL_START_Y = 9'd0, parameter INITIAL_END_Y = 9'd120)
    (input wire clk, input wire reset, input wire [1:0] vga_turn, input wire [1:0] my_id, input wire pressed, input wire [7:0] random_bits, output reg [9:0] X, output reg [8:0] Y, output reg [2:0] state, output reg [8:0] start_y, output reg [8:0] end_y, output reg hit_success, output reg miss, input wire [1:0] speed_setting);
    // States
    localparam DRAW_RECT = 3'd0;
    localparam ERASE_TOP = 3'd1;
    localparam DRAW_BOTTOM = 3'd2;
    localparam DELAY = 3'd3;
    localparam CLEAR_TILE = 3'd4;
    localparam IDLE = 3'd5;

    // Hit zone
    localparam HIT_TOP = 9'd360;
    localparam HIT_BOTTOM = 9'd500;

    reg [8:0] old_start_y;
    reg [8:0] old_end_y;
    reg [25:0] delay_counter;
    reg lastPress;
    reg [27:0] idle_counter;
    reg [27:0] random_threshold;
	 reg [25:0] scroll_speed_delay;

	 


			
    always @(posedge clk) begin
        if (reset) begin
            // Reset column - start in IDLE state
            state <= IDLE;
            X <= START_X;
            Y <= INITIAL_START_Y;
            start_y <= INITIAL_START_Y;
            end_y <= INITIAL_END_Y;
            delay_counter <= 26'd0;
            lastPress <= 0;
            hit_success <= 0;
				miss <= 0;
            idle_counter <= 28'd0;
        end else begin
            lastPress <= pressed;
            hit_success <= 0;
				miss <= 0;

            if (pressed && !lastPress && (end_y >= HIT_TOP) && (end_y <= HIT_BOTTOM)) begin
                old_start_y <= start_y;
                old_end_y <= end_y;
                state <= CLEAR_TILE;
                X <= START_X;
                Y <= start_y;
                hit_success <= 1;

            end else begin
                case (state)
                    DRAW_RECT: begin
                        if (vga_turn == my_id) begin
                            if (X < END_X) begin
                                X <= X + 1;
                            end else begin
                                X <= START_X;
                                if (Y < end_y) begin
                                    Y <= Y + 1;
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
                                X <= X + 1;
                            end else begin
                                state <= DRAW_BOTTOM;
                                X <= START_X;
                            end
                        end
                    end

                    DRAW_BOTTOM: begin
                        if (vga_turn == my_id) begin
                            Y <= end_y + 1;
                            if (X < END_X) begin
                                X <= X + 1;
                            end else begin
                                start_y <= start_y + 1;
                                end_y <= end_y + 1;

                                // Check for miss and tile passed hitzone
                                if (end_y + 1 > HIT_BOTTOM) begin
                                    old_start_y <= start_y + 1;
                                    old_end_y <= end_y + 1;
                                    state <= CLEAR_TILE;
                                    X <= START_X;
                                    Y <= start_y + 1;
												miss <= 1;
                                end else begin
                                    state <= DELAY;
                                    delay_counter <= 26'd0;
                                end
                            end
                        end
                    end

                    DELAY: begin
						
								case(speed_setting)
									2'b00: scroll_speed_delay = 26'd200000;
									2'b01: scroll_speed_delay = 26'd100000;
									2'b11: scroll_speed_delay = 26'd50000;
									default: scroll_speed_delay = 26'd200000;
								endcase
								
                        if (delay_counter < scroll_speed_delay) begin
                            delay_counter <= delay_counter + 1;
                        end else begin
                            state <= ERASE_TOP;
                            X <= START_X;
                            Y <= start_y;
                        end
                    end

                    CLEAR_TILE: begin
                        if (vga_turn == my_id) begin
                            if (X < END_X) begin
                                X <= X + 1;
                            end else begin
                                X <= START_X;
                                if (Y < old_end_y) begin
                                    Y <= Y + 1;
                                end else begin
                                    start_y <= INITIAL_START_Y;
                                    end_y <= INITIAL_END_Y;
                                    Y <= INITIAL_START_Y;
                                    X <= START_X;
                                    state <= IDLE;
                                    idle_counter <= 28'd0;
                                    // New random threshold when entering IDLE
                                    random_threshold <= {random_bits, 17'd0};
                                end
                            end
                        end
                    end

                    IDLE: begin
                        // Wait for random delay before starting to fall
                        if (vga_turn == my_id) begin
                            if (idle_counter >= random_threshold) begin
                                state <= DRAW_RECT;
                                X <= START_X;
                                Y <= INITIAL_START_Y;
                            end else begin
                                idle_counter <= idle_counter + 1;
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule

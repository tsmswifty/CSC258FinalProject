module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input	  CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	// Use SW[0] to enable the Delay/Frame counter so that the output will be 1 for these.
	input   [3:0]   KEY;

	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [9:0] LEDR;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn = 1'b1;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
	wire load_x = 1'b1;
	wire load_y = 1'b1;
	wire load_c = 1'b1;
	wire [7:0] out_x;
	wire [6:0] out_y;
	wire [4:0] count;
	wire [7:0] xcount;
	wire [6:0] ycount;
	wire writeEnAlt;
	wire signal;
	wire drawSignal;

	wire [2:0] color_in;
	wire erase, draw;

	// assign writeEn = drawSignal;
	TimeCounter tc(
			.count_enable(SW[0]), 
			.clk(CLOCK_50), 
			.reset_n(KEY[0]), 
			.display(signal), //1 tick
			.erase(erase),
			.draw(draw)
			);
	XCounter xc(
			.count_enable(SW[0]), 
			.clk(signal), 
			.reset_n(KEY[0]),
			.xDisplay(xcount)
			);
   	YCounter yc(
			.count_enable(SW[0]), //not implemented yet
			.clk(signal), 
			.reset_n(KEY[0]),
			.yDisplay(ycount)
			);
	// output from the counter
	datapath d0(
			.clk(CLOCK_50),
			.dataxin(xcount),
			.datayin(ycount),
			.colorin(color_in),
			.ld_x(load_x),
			.ld_y(load_y),
			.ld_c(load_c),
			.resetn(KEY[0]),
			.out_x(out_x),
			.out_y(out_y),
			.out_c(colour)
			);
	// PixelCounter counter(
	// 		.enable(writeEn),
	// 		.clk(CLOCK_50),
	// 		.drawSignal(drawSignal),
	// 		.signal(signal),
	// 		.display(count),
	// 		);
	squareFSM square0(
			.clock50(CLOCK_50), 
			.erase(erase), 
			.draw(draw),
			.color_input(SW[9:7]),
			.display(count),
			.color_output(color_in)
	);
	assign x = out_x + count[1:0];
	assign y = out_y + count[3:2];
	// control c0(
	// 		.clk(CLOCK_50),
	// 		.resetn(KEY[0]),
	// 		.go(drawSignal),
	// 		.ld_x(load_x), 
	// 		.ld_y(load_y), 
	// 		.ld_c(load_c), 
	// 		.plot(writeEnAlt), //changed
	// 		.enable_xc(signal_xc),
	// 		.enable_yc(signal_yc)
	// 		);

	//register to display clock speed
	reg [9:0] clock_counter = 1'b0;
	reg [3:0] writeIndicator = 1'b0;
	always@(posedge signal)
	begin
		clock_counter <= clock_counter + 1'b1;
		writeIndicator <= writeEn + writeIndicator;
	end
	assign LEDR[9:0] = clock_counter;
	hex_decoder hexzero(.hex_digit(writeIndicator), .segments(HEX0));
	hex_decoder hexfive(.hex_digit(x[7:4]), .segments(HEX5));
	hex_decoder hexfour(.hex_digit(x[3:0]), .segments(HEX4));
	hex_decoder hexthree(.hex_digit(y[6:4]), .segments(HEX3));
	hex_decoder hextwo(.hex_digit(y[3:0]), .segments(HEX2));
	hex_decoder hexone(.hex_digit(colour), .segments(HEX1));


endmodule

//outputs the coordinates needed for drawing a square
module PixelCounter(clk, reset, display);
	input clk;
	input reset;
	output reg [4:0] display;

	always @(posedge clk) 
	begin
		if (reset)
			display <= 5'b10000;
		if (display != 1'b0)
			display <= display - 1'b1;
	end
endmodule

module combine(input enable, input clk,input[2:0]colorin,input reset,input go,output [7:0]out_x,output [6:0]out_y,output [2:0]c,output writeEn);
	wire load_x,load_y,load_c;
	wire signal_xc;
	wire signal_yc;
	wire [7:0]xcount;
	wire [6:0]ycount;
	wire [3:0] count;
	wire signal;
	TimeCounter tc(.count_enable(enable), .clk(clk), .reset_n(reset), .display(signal));
	control c0(.clk(clk),.resetn(reset),.go(signal),.ld_x(load_x), .ld_y(load_y), .ld_c(load_c), .plot(writeEn),.enable_xc(signal_xc),.enable_yc(signal_yc));
	XCounter xc(.count_enable(enable), .clk(signal_xc), .reset_n(reset),.xDisplay(xcount));
   YCounter yc(.count_enable(enable), .clk(signal_yc), .reset_n(reset),.yDisplay(ycount));
	datapath d0(.clk(clk),.dataxin(xcount),.datayin(ycount),.colorin(colorin),.ld_x(load_x),.ld_y(load_y),.ld_c(load_c),.resetn(reset),
	.out_x(out_x),.out_y(out_y),.out_c(c));
endmodule

//module that primarily interacts with vga
module datapath(clk,dataxin, datayin, colorin, ld_x, ld_y, ld_c, resetn, out_x, out_y, out_c);
	input clk;
	// 8bits for coordinate load to register x
	input [7:0]dataxin;
	// 7 bits for coordinate load to register x
	input [6:0]datayin;
	// 3 bits for color load to register c
	input [2:0]colorin;
	// reset signal
	input resetn;
	// enable x register
	input ld_x;
	// enable y register
	input ld_y;
	// enable c register
	input ld_c;
	output reg [7:0]out_x;
	output reg [6:0]out_y;
	output reg [2:0]out_c;
	always @ (posedge clk) begin
		//reset
		if (!resetn) begin
			out_x <= 8'd0;
			out_y <= 7'd0;
		end
		else begin
			// if (ld_x)
				out_x <= dataxin;
			// if (ld_y)
				out_y <= datayin;
			// if (ld_c)
				out_c <= colorin;
		end
	end

endmodule

module squareFSM(input clock50, input erase, input draw, input [2:0] color_input, output reg [4:0] display, output reg [2:0] color_output);
	reg [4:0] erase_clock;
	reg [4:0] draw_clock;
	reg reset;
	//PixelCounter p0(.clk(clock50), .reset(reset), .display(display));
	always@(posedge clock50)
	begin
		
		if (erase) begin
			erase_clock <= 5'b10000; //gives us 16 ticks
			display <= 1'b0;
			reset <= 1'b1;
		end
		if (draw) begin
			draw_clock <= 5'b10000; //gives us 16 ticks
			display <= 1'b0;
			reset <= 1'b1;
		end
		if (erase_clock != 1'b0) begin
			//draw black over current coordinates
			//we have 16 ticks
			reset <= 1'b0;
			color_output <= 3'b0;
			display <= display + 1'b1;
			erase_clock <= erase_clock - 1'b1;
		end
		if (draw_clock != 1'b0) begin
			//draw color over current coordinates
			reset <= 1'b0;
			display <= display + 1'b1;
			color_output <= color_input;
			draw_clock <= draw_clock - 1'b1;
		end
	end
endmodule
			


// module control(
// 	input clk,
// 	input resetn,
// 	input go,
// 	output reg  ld_x, ld_y, ld_c, plot,enable_xc,enable_yc
// );

// 	reg [2:0] current_state, next_state;

// 	localparam  S_ERASE = 3'd0,
// 	S_DRAW   = 3'd1;

// 	// Next state logic aka our state table
// 	always@(posedge clk)
// 		begin: state_table
// 			case (current_state)
// 				S_ERASE: next_state = go ? S_DRAW : S_ERASE; 
// 				S_DRAW: next_state = go ? S_DRAW : S_ERASE; 
// 				default:     next_state = S_ERASE;
// 			endcase
// 		end // state_table
// 	// Output logic aka all of our datapath control signals
// 	always @(posedge clk)
// 		begin: enable_signals
// 			// ld_x = 1'b0;
// 			// ld_y = 1'b0;
// 			// ld_c = 1'b0;
// 			// plot = 1'b0;
// 			// enable_xc = 1'b0;
// 			// enable_yc = 1'b0;
// 			case (current_state)
// 				S_ERASE: begin
// 					//this should not be enabled, as we are going to draw over the previous shape with black
// 					//plot = 1'b0;
// 					enable_xc = 1'b0;
// 					enable_yc = 1'b0;
// 					// ld_c <= 1'b0;
// 				end
// 				S_DRAW: begin
// 					plot = 1'b1;
// 					ld_x = 1'b1;
// 			      	ld_y = 1'b1;
// 			      	ld_c = 1'b1;
// 					enable_xc = 1'b1;
// 					enable_yc = 1'b1;
// 				end
// 				// default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
// 			endcase
// 		end // enable_signals

// 	// current_state registers
// 	always@(posedge clk)
// 		begin: state_FFs
// 			if(!resetn)
// 				current_state <= S_ERASE;
// 			else
// 				current_state <= next_state;
// 		end // state_FFS
// endmodule

module XCounter(count_enable, clk, reset_n,xDisplay);
	input clk;
	input reset_n;
	input count_enable;
	output reg [7:0] xDisplay;
	reg direction; //0 = left, 1 = right
	reg [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk) 
	begin
		if(reset_n == 1'b0) begin
			xDisplay <= 1'b0;
			direction <= 1'b0;
			end
		else if (xDisplay == 1'b0)
			direction <= 1'b1; //reached left, has to go right
		else if (xDisplay == (8'd160 - square_size)) //subtract square size to determine true boundary of x
			direction <= 1'b0; //reached rightmost area, has to go left

		if (direction == 1'b0)
			xDisplay <= xDisplay - 1'b1; //going left
		else if (direction == 1'b1)
			xDisplay <= xDisplay + 1'b1; //going right
	end
endmodule

module YCounter(count_enable, clk, reset_n,yDisplay);
	input clk;
	input reset_n;
	input count_enable;
	output reg [6:0]yDisplay;
	reg direction; //0 = down, 1 = up: note to go up is to decrease y
	reg [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk) 
	begin
		if (reset_n == 1'b0) begin
			yDisplay <= 1'b0; //initialize to 0
			direction <= 1'b0;
			end
		else if (yDisplay == 1'b0)
			direction <= 1'b0; //reached top of screen; has to go down.
		else if (yDisplay == (7'd120 - square_size)) //subtract square size to determine true boundary of y
			direction <= 1'b1; //reached bottom of screen; has to go up.

		if (direction == 1'b0)
			yDisplay <= yDisplay + 1'b1; //going down
		else if (direction == 1'b1)
			yDisplay <= yDisplay - 1'b1; //going up
	end
endmodule

//should run at 1/60th of a second
module TimeCounter(count_enable, clk, reset_n, display, erase, draw);
	input count_enable;
	input clk;
	input reset_n;
	output display;
	output erase;
	output draw;
	reg [19:0] q;
	// wire [23:0] value = 24'd12500000;
	//wire [23:0] value = 24'd5;
	wire [19:0] value = 20'd1000000; //1-60th of a second - maybe try 1/50
	always @(posedge clk) 
	begin
		if(reset_n == 1'b0) 
			q <= 1'b0; 
		else if (q == 1'b0)
			q <= value;
		else
			q <= q - 1'b1; 
		end
	//note: the reason why the square was not drawing itself properly is because it was only able to draw one or two pixels before display went to 0, thus disabling drawing.
	assign erase = (20'd600000 <= q & q <= 20'd601000) ? 1 : 0; //goes high around 400000 ticks before increment - decreasing gap seems to decrease speed
	assign display = (q == 20'd590000) ? 1 : 0; //this only goes high every 1/60th of a second for 1/50M of a second - increment when this is high
	assign draw = (20'd100000 <= q & q <= 20'd200000) ? 1 : 0; //goes high 100 ticks after increment
endmodule

//what is this for?
module FrequencyCounter(enable,clk,display);
	input enable;
	input clk;
	output [3:0]display; 
	reg [3:0]display;
	always @(posedge clk) 
		begin
		if(display == 4'b1111) 
		display <= 0;
		else if (enable == 1'b1)
		display <= display + 1'b1; 
		end
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

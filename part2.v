module part2
	(
	CLOCK_50, //	On Board 50 MHz
	// Your inputs and outputs here
	KEY,
	SW,
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK, //	VGA Clock
	VGA_HS, //	VGA H_SYNC
	VGA_VS, //	VGA V_SYNC
	VGA_BLANK_N, //	VGA BLANK
	VGA_SYNC_N, //	VGA SYNC
	VGA_R, //	VGA Red[9:0]
	VGA_G, //	VGA Green[9:0]
	VGA_B //	VGA Blue[9:0]
);

	input	  CLOCK_50; //	50 MHz
	input   [9:0]   SW;
	// Use SW[0] to enable the Delay/Frame counter so that the output will be 1 for these.
	input   [3:0]   KEY;
	//KEY[0] is active low reset

	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [9:0] LEDR;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK; //	VGA Clock
	output			VGA_HS; //	VGA H_SYNC
	output			VGA_VS; //	VGA V_SYNC
	output			VGA_BLANK_N; //	VGA BLANK
	output			VGA_SYNC_N; //	VGA SYNC
	output	[9:0]	VGA_R; //	VGA Red[9:0]
	output	[9:0]	VGA_G; //	VGA Green[9:0]
	output	[9:0]	VGA_B; //	VGA Blue[9:0]

	wire resetn;
	assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	// Notice that we need 8 bits for x input and 7 bits for y input
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	reg writeEn;

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
	wire [4:0] paddleount;
	wire [7:0] xcount; //for border
	wire [6:0] ycount;
	wire [2:0] colour_count;
	wire [7:0] xCounter; //for counter
	wire [6:0] yCounter;
	wire [2:0] colour_counter;
	wire [7:0] x_in;
	wire [6:0] y_in;
	wire [2:0] colour_in;
	wire signal;
	wire bounce;// 1 for hit ; 0 for not hit
	
	assign x_in = (pause == 1'b0) ? xCounter : xcount;
	assign y_in = (pause == 1'b0) ? yCounter : ycount;
	assign colour_in = (pause == 1'b0) ? colour_counter : colour_count;
	
	wire erase, draw;
	wire pause;
	wire systemPause; //only triggered by system
	
	assign pause = (!systemPause | SW[3]);
	
	reg clock_25;
	always@(posedge CLOCK_50) begin
		clock_25 <= ~clock_25;
	end

	drawBorder draw0(.x(xcount), .y(ycount), .clk(clock_25), .colour(colour_count), .done(systemPause));
	TimeCounter tc(
		.count_enable(SW[0]),
		.clk(CLOCK_50),
		.reset_n(KEY[0]),
		.difficulty(SW[1:0]),
		.display(signal), //1 tick
		.erase(erase),
		.draw(draw),
		.pause(pause)
	);
	XCounter xc(
		.count_enable(SW[0]),
		.clk(signal),
		.reset_n(KEY[0]),
		.paddle_hit(bounce),
		.xDisplay(xCounter)
	);
	YCounter yc(
		.count_enable(SW[0]), //not implemented yet
		.clk(signal),
		.reset_n(KEY[0]),
		.yDisplay(yCounter)
	);
	// output from the counter
	datapath d0(
		.clk(CLOCK_50),
		.dataxin(x_in),
		.datayin(y_in),
		.colorin(colour_in),
		.ld_x(load_x),
		.ld_y(load_y),
		.ld_c(load_c),
		.resetn(KEY[0]),
		.out_x(out_x),
		.out_y(out_y),
		.out_c(colour)
	);

	squareFSM square0(
		.clock50(CLOCK_50),
		.erase(erase),
		.draw(draw),
		.color_input(SW[9:7]),
		.display(count),
		.color_output(colour_counter)
	);
	paddleFSM paddle0(
	    .clock50(CLOCK_50),
		 .erase(erase),
		 .draw(draw),
		 .display(paddleCount)
	);
	
	assign x = (pause == 1'b0) ? out_x + count[1:0] : out_x;
	assign y = (pause == 1'b0) ? out_y + count[3:2] : out_y;

	reg [4:0] drawTimer;
	always@(posedge CLOCK_50) begin
		if (erase | draw | !systemPause) begin
			drawTimer <= 5'b10001; //this has to be equal to squareFSM counter
		end
		
		if (drawTimer != 1'b0) begin
			writeEn <= 1'b1;
			drawTimer <= drawTimer - 1'b1;
		end else
			writeEn <= 1'b0;
	end

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
	hex_decoder hexone(.hex_digit(pause), .segments(HEX1));


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

module drawBorder(x, y, clk, colour, done);
 	input clk;
 	output reg [7:0] x;
 	output reg [6:0] y;
 	output reg [2:0] colour;
 	output reg done = 1'b0;
 	
 	//draw left border
 	always @(posedge clk)
 	begin
 		colour <= 3'b111;
 		if (x == 8'd159 & y == 7'd119 & !done) begin//we only run this at the start so that the last pixel is drawn
 			done <= 1'b1;
			x <= 8'd80; //starting coordinates
			y <= 7'd60;
		end
 		else if (!done) begin
 			if (x == 1'b0) begin
 				if (y == 7'd119) begin
 					x <= x + 1'b1;
 					y <= 1'b0;
 				end else begin
 					//y != 120, x == 1'b0
 					y <= y + 1'b1;
 				end
 			end else if (x == 8'd159) begin
	 			if (y != 7'd119) begin
	 					//assuming y is at 0 when starting the final right border
	 					//we want to start drawing down
	 					y <= y + 1'b1;
	 				end
	 		end else if (x < 8'd159) begin
	 			//middle part, only draw top and bottom
	 			//draw current pixel then either jump down or top and right
	 			//we start at x = 1, y = 0
	 			if (y == 1'b0)
	 				y <= 7'd119;
	 			else begin
	 				//y = 119
	 				y <= 1'b0;
	 				x <= x + 1'b1;
	 			end
	 		end
	 	end
 	end
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
//Based on erase or draw input on every active clock edge
module squareFSM(input clock50, input erase, input draw, input [2:0] color_input, output reg [4:0] display, output reg [2:0] color_output);
	reg [4:0] erase_clock;
	reg [4:0] draw_clock;
	//PixelCounter p0(.clk(clock50), .reset(reset), .display(display));
	always@(posedge clock50)
	begin

		if (erase == 1'b1) begin
			erase_clock <= 5'b10001; //gives us 16 ticks
			display <= 1'b0;
		end
		if (draw == 1'b1) begin
			draw_clock <= 5'b10001; //gives us 16 ticks
			display <= 1'b0;
		end
		if (erase_clock != 1'b0) begin
			//draw black over current coordinates
			//we have 16 ticks
			display <= display + 1'b1;
			color_output <= 3'b0;
			erase_clock <= erase_clock - 1'b1;
		end
		if (draw_clock != 1'b0) begin
			//draw color over current coordinates
			display <= display + 1'b1;
			color_output <= color_input;
			draw_clock <= draw_clock - 1'b1;
		end
	end
endmodule

//Based on erase or draw input on every active clock edge
//Set the paddle to be white as default color 
module paddleFSM(input clock50, input erase, input draw, output reg [4:0] display);
	reg [4:0] erase_clock;
	reg [4:0] draw_clock;
	always@(posedge clock50)
	begin

		if (erase == 1'b1) begin
			erase_clock <= 5'b10001; //gives us 16 ticks
			display <= 1'b0;
		end
		if (draw == 1'b1) begin
			draw_clock <= 5'b10001; //gives us 16 ticks
			display <= 1'b0;
		end
		if (erase_clock != 1'b0) begin
			//draw black over current coordinates
			//we have 16 ticks
			display <= display + 1'b1;
			erase_clock <= erase_clock - 1'b1;
		end
		if (draw_clock != 1'b0) begin
			//draw color over current coordinates
			display <= display + 1'b1;
			draw_clock <= draw_clock - 1'b1;
		end
	end
endmodule

//TODO WRITE LOGIC that check paddle_hit
// compare the x and y coordinate of the square and paddle;
// produce 1 when hits; 0 when not;
// should be checked all the time?

module XCounter(count_enable, clk, reset_n,paddle_hit,xDisplay);
	input clk;
	input reset_n;
	input count_enable;//TODO: use count_enable to activate counter
	input paddle_hit;// when the object hits the paddle,paddle_hit is 1 
	output reg [7:0] xDisplay;
	reg direction; //0 = left, 1 = right:note to go right is to increase x
	reg [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk)
	begin
	   // reset position and diretion
		if(reset_n == 1'b0) begin
			xDisplay <= 1'b1;
			direction <= 1'b0;
		end
		if (paddle_hit == 1)
		   direction <= ~direction;
		// go to right if hits left wall
		else if (xDisplay == 2'd2)
			direction <= 1'b1; //reached left, has to go right
		// go to left if hits right wall
		else if (xDisplay == (8'd160 - square_size - 2'd2)) //subtract square size AND BORDER SIZE to determine true boundary of x
			direction <= 1'b0; //reached rightmost area, has to go left
			
		if (direction == 1'b0)
			xDisplay <= xDisplay - 1'b1; //going left
		else
			xDisplay <= xDisplay + 1'b1; //going right	
		end
endmodule

module YCounter(count_enable, clk, reset_n,yDisplay);
	input clk;
	input reset_n;
	input count_enable;//TODO: use count_enable to activate counter
	output reg [6:0]yDisplay;
	reg direction; //0 = down, 1 = up: note to go up is to decrease y
	reg [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk)
	begin
	   // reset position and diretion
		if (reset_n == 1'b0) begin
			yDisplay <= 2'd2; //initialize to 0
			direction <= 1'b0;
		end
		// go down if hits upper wall
	   // TODO: check the condition of hitting upper walls	
		else if (yDisplay == 2'd2)
			direction <= 1'b0; //reached top of screen; has to go down.
		// go up if hits lower wall
	   // TODO: check the condition of hitting lower walls	
		else if (yDisplay == (7'd120 - square_size - 2'd2)) //subtract square size to determine true boundary of y
			direction <= 1'b1; //reached bottom of screen; has to go up.
		
		if (direction == 1'b0)
			yDisplay <= yDisplay + 1'b1; //going down
		else
			yDisplay <= yDisplay - 1'b1; //going up
		
	end
endmodule

//should run at 1/60th of a second
module TimeCounter(count_enable, clk, reset_n, difficulty, display, erase, draw, pause);
	input count_enable;
	input clk;
	input reset_n;
	input [1:0] difficulty;
	input pause;
	output reg display;
	output reg erase;
	output reg draw;
	reg [19:0] q;
	// wire [23:0] value = 24'd12500000;
	//wire [23:0] value = 24'd5;
	wire [19:0] value = 20'd200000 + 20'd211111 * difficulty; //1-60th of a second - maybe try 1/50
	always @(posedge clk)
	begin
	if(reset_n == 1'b0) begin
		q <= 1'b0;
		display <= 1'b0;
		draw <= 1'b0;
		erase <= 1'b0;
	end else begin
		if (q < value & !pause) begin
			q <= q + 1'b1;
			if (q == 20'd30000 - 20'd18) //(20'd499980 < q & q < 20'd500000)
					erase <= 1'b1;
			else if (q == 20'd30000) //these three values should have small offset (18)
					display <= 1'b1;
			else if (q == 20'd30000 + 20'd18) //(20'd510000 < q & q < 20'd510020)
					draw <= 1'b1;
			else begin
					erase <= 1'b0;
					draw <= 1'b0;
					display <= 1'b0;
				end
			end else begin
				q <= 1'b0;
			end
		end 
	end
	//assigning these values outside of the @loop might be unstable
	//note: the reason why the square was not drawing itself properly is because it was only able to draw one or two pixels before display went to 0, thus disabling drawing.
//	assign erase = (q == 20'd601000 | q == 20'd600900) ? 1 : 0; //goes high around 400000 ticks before increment - decreasing gap seems to decrease speed
//	assign display = (q == 20'd590000) ? 1 : 0; //this only goes high every 1/60th of a second for 1/50M of a second - increment when this is high
//	assign draw = (q == 20'd200000 | q == 20'd201000) ? 1 : 0; //goes high 100 ticks after increment
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

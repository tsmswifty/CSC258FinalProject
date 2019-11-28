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
	// HEX2,HEX1,HEX0 will display the score for the right-hand side player;
	// Add 1 to the right hand side score if the ball touches the left wall
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	// HEX5,HEXR4,HEX3 will display the score for the left-hand side player;
	// Add 1 to the left  hand side score if the ball touches the right wall

	
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
	wire lhitPulse;// 1 if the object hits the left wall
	wire rhitPulse;// 1 if the object hits the right wall
	wire [11:0]lscore; //score for the left hand player
	wire [11:0]rscore; //score for the right hand player
	
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

//	drawBorder draw0(.x(xcount), .y(ycount), .clk(clock_25), .colour(colour_count), .done(systemPause));
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
		.xDisplay(xCounter),
		.lhitPulse(lhitPulse),
		.rhitPulse(rhitPulse)
	);
	
	YCounter yc(
		.count_enable(SW[0]), //not implemented yet
		.clk(signal),
		.reset_n(KEY[0]),
		.yDisplay(yCounter)
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
	
//	assign x = (pause == 1'b0) ? out_x + count[1:0] : out_x;
//	assign y = (pause == 1'b0) ? out_y + count[3:2] : out_y;

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
	
	// HEXO,HEX1,HEX2 displays the right hand player score
	hex_decoder hexzero(.hex_digit(rscore[3:0]),.segments(HEX0));
	hex_decoder hexone(.hex_digit(rscore[7:4]),.segments(HEX1));
	hex_decoder hextwo(.hex_digit(rscore[11:7]),.segments(HEX2));
	
	// HEX3,HEX4,HEX5 displays the left hand player score
	hex_decoder hexthree(.hex_digit(lscore[3:0]),.segments(HEX3));
	hex_decoder hexfour(.hex_digit(lscore[7:4]),.segments(HEX4));
	hex_decoder hexfive(.hex_digit(lscore[11:7]),.segments(HEX5));
	
	wire [6:0] ylpaddle; // the left paddle
	wire [6:0] yrpaddle; // the right paddle
	//TODO: Hook up after finish drawing paddle,
	
	LeftScoreDetector lDetect(
	.enable(SW[9]),
	.lhit(lhitPulse),
	.lpaddle(ylpaddle),
	.yobject(yCounter),
	.lsignal(lsignal));
	
	RightScoreDetector rDetect(
	.enable(SW[9]),
	.rhit(rhitPulse),
	.rpaddle(yrpaddle),
	.yobject(yCounter),
	.rsignal(rsignal));
	
	LeftScoreCounter lScore(.enable(SW[9]),.reset(resetn),.rsignal(rsignal),.lscore(lscore));
	RightScoreCounter rScore(.enable(SW[9]),.reset(resetn),.lsignal(lsignal),.lscore(rscore));

endmodule

// update and count the score for the left hand side user
module LeftScoreCounter(enable,reset,rsignal,lscore);
	input rsignal;// update signal, clk is 1 when object hits the right wall
	input reset;
	output reg [11:0] lscore;
	always @(posedge rsignal)
	begin
		if(reset == 1'b0)
			lscore <= 0;
		else if (enable == 1'b1)
			lscore <= lscore + 1'b1;
	end
endmodule


// update and count the score for the right hand side user
module RightScoreCounter(enable,reset,lsignal,rscore);
	input lsignal;// update signal, clk is 1 when object hits the left wall
	input reset;
	output reg [11:0] rscore;
	always @(posedge lsignal)
	begin
		if(reset == 1'b0)
			rscore <= 0;
		else if (enable == 1'b1)
			rscore <= rscore + 1'b1;
	end
endmodule

// Check and update if the object hits the left paddle
// Generate pulse 1 if object hits the left paddle
// Generate pulse o if object does not hit the left paddle
// lpaddle should be the top y coordinate of the left paddle
// we hardcode the length of the paddle to be 40 pxl

module LeftScoreDetector(enable,lhit,lpaddle,yobject,lsignal);
	input lhit;// update signal, lhit is 1 when object hits the left wall
	input [6:0]lpaddle;// ycoordinate of the left paddle
	input [6:0] yobject;// ycoordinate of the object
	output reg lsignal;// output 1 if the left paddle missed the object
	always @(posedge lhit)
	begin
		if (enable == 1'b1)
		   begin 
			if (lpaddle <= yobject && yobject <= lpaddle + 6'd40) 
			lsignal<= 1'b1;
			else 
			lsignal<= 1'b0;
			end 
		else
		   lsignal = 1'b0;
	end
endmodule

// Check and update if the object hits the right paddle
// Generate pulse 1 if object hits the right paddle
// Generate pulse o if object does not hit the right paddle
// rpaddle should be the top y coordinate of the right paddle
// we hardcode the length of the paddle to be 40 pxl

module RightScoreDetector(enable,rhit,rpaddle,yobject,rsignal);
	input rhit;// update signal, rhit is 1 when object hits the right wall
	input [6:0]rpaddle;// ycoordinate of the righgt paddle
	input [6:0]yobject;// ycoordinate of the object
	output reg rsignal;// output 1 if the right paddle missed the object
	always @(posedge rhit)
	begin
		if (enable == 1'b1)
		   begin 
			if (rpaddle <= yobject && yobject <= rpaddle + 6'd40) 
			rsignal<= 1'b1;
			else 
			rsignal<= 1'b0;
			end 
		else
		   rsignal = 1'b0;
	end
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



//module that primarily interacts with vga
module datapathFSM(
	input clock,
	//draw/erase signals from ratedivider
	input eraseIn, //generated by ratedivider
	input drawIn, //generated by ratedivider
	//square inputs
	input [7:0] Xin, //X determined by Xcounter
	input [6:0] Yin, //Y determined by Ycounter
	//left paddle inputs
	input [7:0] leftPaddleXin,
	input [6:0] leftPaddleYin,
	//right paddle inputs
	input [7:0] rightPaddleXin,
	input [6:0] rightPaddleYin,
	input resetn, //key0, active low, as pressing key results in 0
	input [2:0] colorSwitch, //switches determine color - optional
	output reg [7:0] Xout,
	output reg [6:0] Yout,
	output reg [2:0] colour
	);
	
	//states 
	reg [3:0] current_state, next_state;
	
	localparam 	S_DRAW_BORDER = 4'd0,
				S_INIT_OBJ = 4'd1,
				S_DRAW_SQUARE = 4'd2,
				S_DRAW_LEFT_PADDLE = 4'd3,
				S_DRAW_RIGHT_PADDLE = 4'd4,
				S_WAIT_ERASE = 4'd5,
				S_ERASE_SQUARE = 4'd6,
				S_ERASE_LEFT_PADDLE = 4'd7,
				S_ERASE_RIGHT_PADDLE = 4'd8,
				S_WAIT_DRAW = 4'd9,
				S_RESET_COUNTERS = 4'd10;
	
	//counters	
	reg [9:0] borderCount = 10'd600; //should be 560, added 40 for error
	reg [4:0] squareCount = 5'd18; //should be 16, added 2 for error
	reg [6:0] LpaddleCount = 7'd100; //allocated 100 for paddles, maybe have them be 2x16?
	reg [6:0] RpaddleCount = 7'd100;
	reg [4:0] eraseSquareCount = 5'd18; //should be 16, added 2 for error
	reg [6:0] LerasePaddleCount = 7'd100; //allocated 100 for paddles, maybe have them be 2x16?
	reg [6:0] RerasePaddleCount = 7'd100;
	
	//switches - might not need these
	reg drawBorder, initObj, drawSquare, drawPaddles, eraseSquare, erasePaddles;
	
	//counters
	always@(posedge clock) 
	begin
		if(~resetn) begin
			borderCount <= 10'd600; 
			squareCount <= 5'd18; 
			LpaddleCount <= 7'd100; 
			RpaddleCount <= 7'd100;
			eraseSquareCount <= 5'd18; 
			LerasePaddleCount <= 7'd100; 
			RerasePaddleCount <= 7'd100; 
		end
	else begin
		if (current_state == S_DRAW_BORDER & borderCount != 1'b0)
			borderCount <= borderCount - 1'b1;
		else if (current_state == S_DRAW_SQUARE & squareCount != 1'b0)
			squareCount <= squareCount - 1'b1;
		else if (current_state == S_DRAW_LEFT_PADDLE & LpaddleCount != 1'b0)
			LpaddleCount <= LpaddleCount - 1'b1;
		else if (current_state == S_DRAW_RIGHT_PADDLE & RpaddleCount != 1'b0)
			RpaddleCount <= RpaddleCount - 1'b1;
		else if (current_state == S_ERASE_SQUARE & eraseSquareCount != 1'b0)
			eraseSquareCount <= eraseSquareCount - 1'b1;
		else if (current_state == S_ERASE_LEFT_PADDLE & LerasePaddleCount != 1'b0)
			LerasePaddleCount <= LerasePaddleCount - 1'b1;
		else if (current_state == S_ERASE_RIGHT_PADDLE & RerasePaddleCount != 1'b0)
			RerasePaddleCount <= RerasePaddleCount - 1'b1;
		else if (current_state == S_RESET_COUNTERS) begin
			borderCount <= 10'd600; 
			squareCount <= 5'd18; 
			LpaddleCount <= 7'd100; 
			RpaddleCount <= 7'd100;
			eraseSquareCount <= 5'd18; 
			LerasePaddleCount <= 7'd100; 
			RerasePaddleCount <= 7'd100; 
			end
		end
	end
	
	//FSM
	always@(posedge clock) //can be always@* but idk
	begin: state_table
		case (current_state) 
			S_DRAW_BORDER: next_state = (borderCount == 1'b0) ? S_INIT_OBJ : S_DRAW_BORDER;
			S_INIT_OBJ: next_state = S_DRAW_SQUARE;
			S_DRAW_SQUARE: next_state = (squareCount == 1'b0) ? S_DRAW_LEFT_PADDLE : S_DRAW_SQUARE;
			S_DRAW_LEFT_PADDLE: next_state = (LpaddleCount == 1'b0) ? S_DRAW_RIGHT_PADDLE : S_DRAW_LEFT_PADDLE;
			S_DRAW_RIGHT_PADDLE: next_state = (RpaddleCount == 1'b0) ? S_WAIT_ERASE : S_DRAW_RIGHT_PADDLE;
			S_WAIT_ERASE: next_state = (eraseIn == 1'b1) ? S_ERASE_SQUARE : S_WAIT_ERASE;
			S_ERASE_SQUARE: next_state = (eraseSquareCount == 1'b0) ? S_ERASE_PADDLE : S_ERASE_SQUARE;
			S_ERASE_LEFT_PADDLE: next_state = (LerasePaddleCount == 1'b0) ? S_ERASE_RIGHT_PADDLE : S_ERASE_LEFT_PADDLE;
			S_ERASE_RIGHT_PADDLE: next_state = (RerasePaddleCount == 1'b0) ? S_WAIT_DRAW : S_ERASE_RIGHT_PADDLE;
			S_WAIT_DRAW: next_state = (drawIn == 1'b1) ? S_RESET_COUNTERS : S_WAIT_DRAW;
			S_RESET_COUNTERS: next_state = S_DRAW_SQUARE;
			default: next_state = S_DRAW_BORDER;
		endcase
	end
	
	//draw the border
	reg [7:0] borderX;
	reg [6:0] borderY;
	drawBorder m0(.enable(current_state == S_DRAW_BORDER), .x(borderX), .y(borderY), .clk(clock)); //cannot use counter count to determine whether active
	
	//draw/erase the square
	reg [4:0] squareAdd;
	reg resetSquare = 1'b1; //note resetn is not negated here as resetSquare is active low
	squareFSM m1(.clock(clock), .reset(resetSquare | resetn), .enable(current_state == S_DRAW_SQUARE | current_state == S_ERASE_SQUARE), .display(squareAdd));
	
	//draw/erase the left paddle
	reg [4:0] LpaddleX;
	reg [4:0] LpaddleY;
	reg resetLeftPaddle = 1'b1;
	paddleFSM m2(.clock(clock), .reset(reset), .enable(resetLeftPaddle | resetn), .paddleX(LpaddleX), .paddleY(LpaddleY));
	
	
	//draw/erase the right paddle
	reg resetRightPaddle = 1'b1;
	reg [4:0] RpaddleX;
	reg [4:0] RpaddleY;
	paddleFSM m3(.clock(clock), .reset(reset), .enable(resetRightPaddle | resetn), .paddleX(RpaddleX), .paddleY(RpaddleY));
	
	//datapath control
	always@(posedge clock)
		begin
			case(current_state)
				S_DRAW_BORDER: begin
					colour <= 3'b111; //white color for borders
					Xout <= borderX;
					Yout <= borderY;
				end
				S_INIT_OBJ: begin
					//do stuff
				end
				S_DRAW_SQUARE: begin
					color <= 3'b111;
					resetSquare = 1'b0;
					Xout <= Xin + squareAdd[1:0];
					Yout <= Yin + squareAdd[3:2];
				end
				S_DRAW_LEFT_PADDLE: begin
					//freeze square counter
					resetSquare <= 1'b1;
					resetLeftPaddle <= 1'b0;
					color <= 3'b111;
					Xout <= leftPaddleXin + LpaddleX;
					Yout <= leftPaddleYin + LpaddleY;
				end
				S_DRAW_RIGHT_PADDLE: begin
					color <= 3'b111; //change for customization if you want
					resetLeftPaddle <= 1'b1;
					resetRightPaddle <= 1'b0;
					Xout <= rightPaddleXin + RpaddleX;
					Yout <= rightPaddleYin + RpaddleY;
				end
				S_ERASE_SQUARE: begin
					color <= 1'b0;
					resetRightPaddle <= 1'b1;
					resetSquare <= 1'b0;
					Xout <= Xin + squareAdd[1:0];
					Yout <= Yin + squareAdd[3:2];
				end
				S_ERASE_LEFT_PADDLE: begin
					color <= 3'b0;
					resetSquare <= 1'b1;
					resetLeftPaddle <= 1'b0;
					Xout <= leftPaddleXin + LpaddleX;
					Yout <= leftPaddleYin + LpaddleY;
				end
				S_ERASE_RIGHT_PADDLE: begin
					color <= 3'b0;
					resetLeftPaddle <= 1'b1;
					resetRightPaddle <= 1'b0;
					Xout <= rightPaddleXin + RpaddleX;
					Yout <= rightPaddleYin + RpaddleY;
				end
				S_RESET_COUNTERS: begin
					resetRightPaddle <= 1'b1;
					//borderCount <= 10'd600; 
					squareCount <= 5'd18; 
					LpaddleCount <= 7'd100; 
					RpaddleCount <= 7'd100;
					eraseSquareCount <= 5'd18; 
					LerasePaddleCount <= 7'd100; 
					RerasePaddleCount <= 7'd100; 
				end
				//default: something
			endcase
		end
endmodule
	
module drawBorder(enable, x, y, clk);
	input clk;
	input enable;
 	output reg [7:0] x;
 	output reg [6:0] y;
 	
 	//draw left border
 	always @(posedge clk)
 	begin
 		if (x == 8'd159 & y == 7'd119) begin//we only run this at the start so that the last pixel is drawn
			x <= 8'd80; //starting coordinates
			y <= 7'd60;
		end
 		else if (enable) begin
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

//Based on erase or draw input on every active clock edge
module squareFSM(input clock, input reset, input enable, output reg [4:0] display);
	reg [4:0] draw_clock;
	always@(posedge clock)
	begin
		if (reset) begin
			draw_clock <= 5'b10001; //gives us 16 ticks
			display <= 1'b0;
		end
		else if (draw_clock != 1'b0 & enable == 1'b1) begin
			//draw color over current coordinates
			display <= display + 1'b1;
			draw_clock <= draw_clock - 1'b1;
		end
	end
endmodule

//Based on erase or draw input on every active clock edge
//Set the paddle to be white as default color 
module paddleFSM(input clock, input enable, input reset, output reg [4:0] paddleX, output reg [4:0] paddleY);
	reg [6:0] draw_clock; //goes from 0 to 81 - some wiggle room left for error
	
	always@(posedge clock) begin
		if (reset) begin
			draw_clock <= 7'd81;
			paddleX <= 1'b0;
			paddleY <= 1'b0;
		end
		else begin
			if(paddleY == 5'd39) begin
				if (paddleX != 1'd1) begin
					paddleX <= 1'd1;
					paddleY <= 1'd0;
					end
				end //do nothing otherwise, as we are done
			else begin
				paddleY <= paddleY + 1'b1;
			end
		end
	end
	
endmodule
			
					

module XCounter(count_enable, clk, reset_n,xDisplay,lhitPulse,rhitPulse);
	input clk;
	input reset_n;
	input count_enable;//TODO: use count_enable to activate counter
	output reg lhitPulse;// When the object hits the left side of the wall,lhitPulse is 1,otherwise it is 0
	output reg rhitPulse;// When the object hits the right side of the wall,rhitPulse is 1,otherwise it is 0
	output reg [7:0] xDisplay;
	reg direction; //0 = left, 1 = right:note to go right is to increase x
	reg [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk)
	begin
	   // reset position and diretion
		if(reset_n == 1'b0) begin
			xDisplay <= 1'b1;
			direction <= 1'b0;
			lhitPulse <= 1'b0;
			rhitPulse <= 1'b0;
		end
		
		// go to right if hits left wall
		else if (xDisplay == 2'd2)
		begin 
		   lhitPulse <= 1'b1; // hit the left wall, should have high pulse
			rhitPulse <= 1'b0;
			direction <= 1'b1; //reached left, has to go right
		end
		
		// go to left if hits right wall
		else if (xDisplay == (8'd160 - square_size - 2'd2)) //subtract square size AND BORDER SIZE to determine true boundary of x
		begin
		   rhitPulse <= 1'b1; // hit the right wall, should have high pulse
			lhitPulse <= 1'b0;
			direction <= 1'b0; //reached rightmost area, has to go left
		end 
		
		else 
		   lhitPulse <= 1'b0; // the object is in the middle, should have low pulse
		   rhitPulse <= 1'b0;
			
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
		if (reset_n == 1'b0) 
		begin
			yDisplay <= 2'd2; //initialize to 0
			direction <= 1'b0;
		end
		// go down if hits upper wall
		
		else if (yDisplay == 2'd2)
			direction <= 1'b0; //reached top of screen; has to go down.
		// go up if hits lower wall
		
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
			if (q == 20'd30000 - 20'd300) //(20'd499980 < q & q < 20'd500000) //adjust for erase time
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

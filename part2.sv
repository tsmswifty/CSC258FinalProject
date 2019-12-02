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
	VGA_B , //	VGA Blue[9:0]
	PS2_DAT,
	PS2_CLK
);

	input logic  CLOCK_50; //	50 MHz
	inout logic PS2_DAT;
	inout logic PS2_CLK;
	input logic [9:0]   SW;
	// Use SW[0] to enable the Delay/Frame counter so that the output will be 1 for these.
	input logic  [3:0]   KEY;

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

	output logic [9:0] LEDR;

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

	logic resetn;
	assign resetn = SW[2];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	// Notice that we need 8 bits for x input and 7 bits for y input
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	wire [2:0] colour;

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
	logic valid;
	logic makeBreak;
	logic [7:0] outCode;
	assign LEDR[0] = valid;
	assign LEDR[1] = makeBreak;
	//  assign LEDR[9:2] = outCode;
	keyboard_press_driver keytest(
		.CLOCK_50(CLOCK_50),
		.valid(valid),
		.makeBreak(makeBreak),
		.outCode(outCode),
		.PS2_DAT(PS2_DAT),
		.PS2_CLK(PS2_CLK),
		.reset(~resetn)
	);


	wire lhitPulse; // 1 if the object hits the left wall
	wire rhitPulse; // 1 if the object hits the right wall
	wire [7:0]lscore; //score for the left hand player
	wire [7:0]rscore; //score for the right hand player
	wire [7:0]strike;

	//timecounter signals for FSM
	wire erase, draw, signal;

	//ball position
	wire [7:0] xCounter;
	wire [6:0] yCounter;


	wire [7:0] leftPaddleXpos, rightPaddleXpos;

	assign leftPaddleXpos = 8'd12;
	assign rightPaddleXpos = 8'd147;

	wire enableCounter;

	//	drawBorder draw0(.x(xcount), .y(ycount), .clk(clock_25), .colour(colour_count), .done(systemPause));
	TimeCounter tc(
		.count_enable(SW[6]),
		.clk(CLOCK_50),
		.reset_n(resetn),
		.difficulty(SW[1:0]),
		.display(signal), //1 tick
		.erase(erase),
		.draw(draw),
		.pause(pause)
	);
	XCounter xc(
		.count_enable(SW[6]),
		.clk(signal),
		.reset_n(resetn),
		.xDisplay(xCounter),
		.lhitPulse(lhitPulse),
		.rhitPulse(rhitPulse)
	);

	YCounter yc(
		.count_enable(SW[6]), //not implemented yet
		.clk(signal),
		.reset_n(resetn),
		.yDisplay(yCounter)
	);

	wire [6:0] ylpaddle; // the left paddle
	wire [6:0] yrpaddle; // the right paddle
	wire lup;
	wire ldown;
	wire rup;
	wire rdown;
	lKeyBoardDetector lDetect(.outCode(outCode),.makeCode(makeBreak),.lupCondition(lup),.ldownCondition(ldown));
	rKeyBoardDetector rDetect(.outCode(outCode),.makeCode(makeBreak),.rupCondition(rup),.rdownCondition(rdown));
	YPaddle yleftPaddle(
		.clk(signal),
		.reset_n(resetn),
		.moveEnable(SW[3]),
		.up(lup),
		.down(ldown),
		.ypDisplay(ylpaddle)
	);

	YPaddle yrightPaddle(
		.clk(signal),
		.reset_n(resetn),
		.moveEnable(SW[3]),
		.up(rup),
		.down(rdown),
		.ypDisplay(yrpaddle)
	);

	//TODO: Temporialy set KEY1,KEY2 to control left paddle; set sw[2],sw[3] to control right paddle
	// In milestone 3 , hook up keyboard so that we can control from the keyboard

	LeftScoreDetector lDetecter(
		.enable(SW[6]),
		.lhit(lhitPulse),
		.lpaddle(ylpaddle),
		.yobject(yCounter),
		.lsignal(lsignal));

	RightScoreDetector rDetecter(
		.enable(SW[6]),
		.rhit(rhitPulse),
		.rpaddle(yrpaddle),
		.yobject(yCounter),
		.rsignal(rsignal));

	LeftScoreCounter lScore(.enable(SW[6]),.reset(resetn),.rsignal(rsignal),.lscore(lscore));
	RightScoreCounter rScore(.enable(SW[6]),.reset(resetn),.lsignal(lsignal),.rscore(rscore));
	StrikeDetector strikeDetect(.enable(SW[6]), .reset(resetn), .rsignal(rsignal),.lsignal(lsignal),.hit(lhitPulse || rhitPulse),.strike(stikes));

	datapathFSM fsm0(
		.clock(CLOCK_50),
		//draw/erase signals from ratedivider
		.eraseIn(erase), //generated by ratedivider
		.drawIn(draw), //generated by ratedivider
		//square inputs
		.Xin(xCounter), //X determined by Xcounter
		.Yin(yCounter), //Y determined by Ycounter
		//left paddle inputs
		.leftPaddleXin(leftPaddleXpos),
		.leftPaddleYin(ylpaddle),
		//right paddle inputs
		.rightPaddleXin(rightPaddleXpos),
		.rightPaddleYin(yrpaddle),
		.resetn(resetn), //key0, active low, as pressing key results in 0
		.colorSwitch(SW[9:7]), //switches determine color - optional
		.enableCounter(enableCounter),
		.Xout(x),
		.Yout(y),
		.colour(colour),
		.writeEn(writeEn)
	);



	//register to display clock speed
	logic [9:0] clock_counter = 1'b0;
	logic [3:0] writeIndicator = 1'b0;
	always@(posedge signal)
	begin
		clock_counter <= clock_counter + 1'b1;
		writeIndicator <= writeEn + writeIndicator;
	end
	//assign LEDR[9:0] = clock_counter;

	// HEXO,HEX1,HEX2 displays the right hand player score
	hex_decoder hexzero(.hex_digit(rscore[3:0]),.segments(HEX0));
	hex_decoder hexone(.hex_digit(rscore[7:4]),.segments(HEX1));
	hex_decoder hextwo(.hex_digit(strike[3:0]),.segments(HEX2));

	// HEX3,HEX4,HEX5 displays the left hand player score
	hex_decoder hexthree(.hex_digit(strike[7:4]),.segments(HEX3));
	hex_decoder hexfour(.hex_digit(lscore[3:0]),.segments(HEX4));
	hex_decoder hexfive(.hex_digit(lscore[7:4]),.segments(HEX5));
endmodule

module testRightScore(input enable, input reset, input lhitPulse,input [6:0] ylpaddle, input [6:0]yCounter, output [7:0] rightscore);
	LeftScoreDetector lDetect(
		.enable(enable),
		.lhit(lhitPulse),
		.lpaddle(ylpaddle),
		.yobject(yCounter),
		.lsignal(lsignal));
	RightScoreCounter rScore(.enable(enable),.reset(reset),.lsignal(lsignal),.rscore(rightscore));
endmodule

module testLeftScore(input enable, input reset, input rhitPulse,input [6:0] yrpaddle, input [6:0]yCounter, output [7:0] leftscore);
	RightScoreDetector rDetect(
		.enable(enable),
		.rhit(rhitPulse),
		.rpaddle(yrpaddle),
		.yobject(yCounter),
		.rsignal(rsignal));
	LeftScoreCounter rScore(.enable(enable),.reset(reset),.rsignal(rsignal),.lscore(leftscore));
endmodule

module testStrike(input enable, input reset, input lhitPulse,input [6:0] ylpaddle,input rhitPulse,input [6:0] yrpaddle,  input [6:0]yCounter,output logic [7:0]strikes);
	LeftScoreDetector lDetect(
		.enable(enable),
		.lhit(lhitPulse),
		.lpaddle(ylpaddle),
		.yobject(yCounter),
		.lsignal(lsignal));

	RightScoreDetector rDetect(
		.enable(enable),
		.rhit(rhitPulse),
		.rpaddle(ylpaddle),
		.yobject(yCounter),
		.rsignal(rsignal));

	StrikeDetector strikeDetect(.enable(enable), .reset(reset), .rsignal(rsignal),.lsignal(lsignal),.hit(lhitPulse || rhitPulse),.strike(stikes));
endmodule

module testControl(input signal, input reset, input enable, input lup, input ldown, input rup, input rdown, output [6:0] ylpaddle,output [6:0] yrpaddle);
	YPaddle yleftPaddle(
		.clk(signal),
		.reset_n(reset),
		.moveEnable(enable),
		.up(lup),
		.down(ldown),
		.ypDisplay(ylpaddle)
	);

	YPaddle yrightPaddle(
		.clk(signal),
		.reset_n(reset),
		.moveEnable(enable),
		.up(rup),
		.down(rdown),
		.ypDisplay(yrpaddle)
	);

endmodule

module StrikeDetector(enable, reset,  rsignal, lsignal, hit,strike);
	input enable;
	input reset;
	input rsignal;
	input lsignal;
	input hit;
	output logic [7:0]strike;
	always @(posedge hit)
	begin
		if (reset == 1'b0 || (rsignal == 1'b1 || lsignal == 1'b1)|| strike== 8'b11111111)
			strike <= 8'b00000000;
		else if (enable == 1'b1)
			strike <= strike + 8'b00000001;
	end
endmodule

// update and count the score for the left hand side user
module LeftScoreCounter(input enable,input reset,input rsignal,output logic [7:0] lscore=0);
	// update signal, clk is 1 when object hits the right wall

	always @(posedge rsignal)
	begin
		if(reset == 1'b0 || lscore == 8'b11111111)
			lscore <= 0;
		else if (enable == 1'b1)
			lscore <= lscore + 1'b1;
	end
endmodule

// update and count the score for the right hand side user
module RightScoreCounter(input enable,input reset,input lsignal,output logic [7:0] rscore=0);
	// update signal, clk is 1 when object hits the left wall

	always @(posedge lsignal)
	begin
		if(reset == 1'b0 || rscore == 8'b11111111)
			rscore <= 0;
		else if (enable == 1'b1)
			rscore <= rscore + 1'b1;
	end
endmodule

// Check and update if the object hits the left paddle
// Generate pulse 1 if object hits the left paddle
// Generate pulse o if object does not hit the left paddle
// lpaddle should be the top y coordinate of the left paddle
// we hardcode the length of the paddle to be 20 pxl

module LeftScoreDetector(enable,lhit,lpaddle,yobject,lsignal);
	input enable; //TODO: implement this
	input lhit; // update signal, lhit is 1 when object hits the left wall
	input [6:0]lpaddle; // ycoordinate of the left paddle
	input [6:0] yobject; // ycoordinate of the object
	output logic lsignal; // output 1 if the left paddle missed the object
	always @(lhit)
	begin
		if (enable == 1'b1)
			begin
				if (lpaddle - 6'd10 <= yobject  && yobject <= lpaddle + 6'd30)
					lsignal <= 1'b0;
				else
					begin
						if (lhit)
							lsignal <= 1'b1;
						else
							lsignal <= 1'b0;
					end
			end
	end

endmodule

// Check and update if the object hits the right paddle
// Generate pulse 1 if object hits the right paddle
// Generate pulse o if object does not hit the right paddle
// rpaddle should be the top y coordinate of the right paddle
// we hardcode the length of the paddle to be 20 pxl

module RightScoreDetector(enable,rhit,rpaddle,yobject,rsignal);
	input enable; //TODO: implement this
	input rhit; // update signal, rhit is 1 when object hits the right wall
	input [6:0]rpaddle; // ycoordinate of the righgt paddle
	input [6:0]yobject; // ycoordinate of the object
	output logic rsignal; // output 1 if the right paddle missed the object
	always @(rhit)
	begin
		if (enable == 1'b1)
			begin
				if (rpaddle - 6'd10 <= yobject  && yobject <= rpaddle + 6'd30)
					rsignal <= 1'b0;
				else
					begin
						if (rhit)
							rsignal <= 1'b1;
						else
							rsignal <= 1'b0;
					end
			end
	end
endmodule

//outputs the coordinates needed for drawing a square
module PixelCounter(clk, reset, display);
	input clk;
	input reset;
	output logic [4:0] display;

	always @(posedge clk)
	begin
		if (reset)
			display <= 5'b10000;
		if (display != 1'b0)
			display <= display - 1'b1;
	end
endmodule
module lKeyBoardDetector(input [7:0] outCode, input makeCode,output logic lupCondition = 0, output logic ldownCondition=0);

	always@(*)
	begin
		case({outCode,makeCode})
			9'b000101011: begin
				lupCondition <= 1 ;
				ldownCondition<=0;
			end
			9'b000101010: begin
				lupCondition <= 0 ;
				ldownCondition<=0;
			end
			9'b000111001: begin
				lupCondition <= 0;
				ldownCondition<= 1;
			end
			9'b000111000: begin
				lupCondition <= 0;
				ldownCondition<= 0;
			end
			//  9'b000111011: begin 
			//	              lupCondition <= lupCondition ; 
			//					  ldownCondition<= ldownCondition;
			//					  end
			//	9'b000111010: begin 
			//	              lupCondition <= lupCondition ; 
			//					  ldownCondition<= ldownCondition;
			//					  end
			//	9'b000110111: begin 
			//	              lupCondition <= lupCondition ; 
			//					  ldownCondition<= ldownCondition;
			//					  end
			//	9'b000110110: begin 
			//	              lupCondition <= lupCondition ; 
			//					  ldownCondition<= ldownCondition;
			//					  end
			default:      begin
				lupCondition <= lupCondition ;
				ldownCondition<= ldownCondition;
			end
		endcase
	end
endmodule

module rKeyBoardDetector(input [7:0] outCode, input makeCode,output logic rupCondition=0, output logic rdownCondition=0);
	always@(*)
	begin
		case({outCode,makeCode})
			9'b000111011: begin
				rupCondition <= 1 ;
				rdownCondition<=0;
			end
			9'b000111010: begin
				rupCondition <= 0 ;
				rdownCondition<=0;
			end
			9'b000110111: begin
				rupCondition <= 0;
				rdownCondition<= 1;
			end
			9'b000110110: begin
				rupCondition <= 0;
				rdownCondition<= 0;
			end
			default:      begin
				rupCondition <= rupCondition;
				rdownCondition<= rdownCondition;
			end
		endcase
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
	output logic enableCounter,
	output logic [7:0] Xout,
	output logic [6:0] Yout,
	output logic [2:0] colour,
	output logic writeEn
);

	//states 
	logic [3:0] current_state, next_state;

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
	S_RESET_COUNTERS = 4'd10,
	S_RESET_STATE = 4'd11; //the state you transition to when you click reset

	//counters	
	logic [14:0] resetCount = 15'd19500; //should be 19200 (160x120), added 300 for error
	logic [9:0] borderCount = 10'd600; //should be 560, added 40 for error
	logic [4:0] squareCount = 5'd18; //should be 16, added 2 for error
	logic [6:0] LpaddleCount = 7'd100; //allocated 100 for paddles, maybe have them be 2x16?
	logic [6:0] RpaddleCount = 7'd100;
	logic [4:0] eraseSquareCount = 5'd18; //should be 16, added 2 for error
	logic [6:0] LerasePaddleCount = 7'd100; //allocated 100 for paddles, maybe have them be 2x16?
	logic [6:0] RerasePaddleCount = 7'd100;

	//switches - might not need these
	//	logic drawBorder, initObj, drawSquare, drawPaddles, eraseSquare, erasePaddles;

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
			resetCount <= 15'd19500;
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
			else if (current_state == S_RESET_STATE & resetCount != 1'b0)
				resetCount <= resetCount - 1'b1;
			else if (current_state == S_RESET_COUNTERS) begin
				borderCount <= 10'd600;
				squareCount <= 5'd18;
				LpaddleCount <= 7'd100;
				RpaddleCount <= 7'd100;
				eraseSquareCount <= 5'd18;
				LerasePaddleCount <= 7'd100;
				RerasePaddleCount <= 7'd100;
				resetCount <= 15'd19500;
			end
		end
	end

	//FSM
	always@(posedge clock) //can be always@* but idk
	begin: state_table
		case (current_state)
			S_RESET_STATE: next_state = (resetCount == 1'b0) ? S_DRAW_BORDER : S_RESET_STATE;
			S_DRAW_BORDER: next_state = (borderCount == 1'b0) ? S_INIT_OBJ : S_DRAW_BORDER;
			S_INIT_OBJ: next_state = S_DRAW_SQUARE;
			S_DRAW_SQUARE: next_state = (squareCount == 1'b0) ? S_DRAW_LEFT_PADDLE : S_DRAW_SQUARE;
			S_DRAW_LEFT_PADDLE: next_state = (LpaddleCount == 1'b0) ? S_DRAW_RIGHT_PADDLE : S_DRAW_LEFT_PADDLE;
			S_DRAW_RIGHT_PADDLE: next_state = (RpaddleCount == 1'b0) ? S_WAIT_ERASE : S_DRAW_RIGHT_PADDLE;
			S_WAIT_ERASE: next_state = (eraseIn == 1'b1) ? S_ERASE_SQUARE : S_WAIT_ERASE;
			S_ERASE_SQUARE: next_state = (eraseSquareCount == 1'b0) ? S_ERASE_LEFT_PADDLE : S_ERASE_SQUARE;
			S_ERASE_LEFT_PADDLE: next_state = (LerasePaddleCount == 1'b0) ? S_ERASE_RIGHT_PADDLE : S_ERASE_LEFT_PADDLE;
			S_ERASE_RIGHT_PADDLE: next_state = (RerasePaddleCount == 1'b0) ? S_WAIT_DRAW : S_ERASE_RIGHT_PADDLE;
			S_WAIT_DRAW: next_state = (drawIn == 1'b1) ? S_RESET_COUNTERS : S_WAIT_DRAW;
			S_RESET_COUNTERS: next_state = S_DRAW_SQUARE;
			default: next_state = S_RESET_STATE;
		endcase
	end

	//update states
	always@(posedge clock) begin
		if(~resetn)
			current_state <= S_RESET_STATE;
		else
			current_state <= next_state;
	end

	//draw the border
	wire [7:0] borderX;
	wire [6:0] borderY;
	drawBorder m0(.enable(current_state == S_DRAW_BORDER), .x(borderX), .y(borderY), .clk(clock)); //cannot use counter count to determine whether active

	//draw/erase the square
	wire [4:0] squareAdd;
	logic resetSquare; //note resetn is not negated here as resetSquare is active low
	squareFSM m1(.clock(clock), .reset(resetSquare | ~resetn), .enable(current_state == S_DRAW_SQUARE | current_state == S_ERASE_SQUARE), .display(squareAdd));

	//draw/erase the left paddle
	wire [5:0] LpaddleX;
	wire [5:0] LpaddleY;
	logic resetLeftPaddle;
	paddleFSM m2(.clock(clock), .reset(resetLeftPaddle | ~resetn), .enable(current_state == S_DRAW_LEFT_PADDLE | current_state == S_ERASE_LEFT_PADDLE), .paddleX(LpaddleX), .paddleY(LpaddleY));


	//draw/erase the right paddle
	logic resetRightPaddle;
	wire [5:0] RpaddleX;
	wire [5:0] RpaddleY;
	paddleFSM m3(.clock(clock), .reset(resetRightPaddle | ~resetn), .enable(current_state == S_DRAW_RIGHT_PADDLE | current_state == S_ERASE_RIGHT_PADDLE), .paddleX(RpaddleX), .paddleY(RpaddleY));

	//erase the entire screen (draw black)
	logic resetErase;
	wire [7:0] eraseX;
	wire [6:0] eraseY;
	//note resetn does not trigger reset
	eraseAll m4(.clock(clock), .reset(resetErase), .enable(current_state == S_ERASE_STATE), .eraseX(eraseX), .eraseY(eraseY));

	//datapath control
	always@(posedge clock)
	begin
		case(current_state)
			S_RESET_STATE: begin
				writeEn <= 1'b1;
				resetSquare <= 1'b1;
				resetLeftPaddle <= 1'b1;
				resetRightPaddle <= 1'b1;
				resetErase <= 1'b0;

				colour <= 1'b0;
				Xout <= eraseX;
				Yout <= eraseY;
			end
			S_DRAW_BORDER: begin
				writeEn <= 1'b1;

				resetSquare <= 1'b1;
				resetLeftPaddle <= 1'b1;
				resetRightPaddle <= 1'b1;
				resetErase <= 1'b1;

				enableCounter <= 1'b0;

				colour <= colorSwitch; //white color for borders
				Xout <= borderX;
				Yout <= borderY;
			end
			S_INIT_OBJ: begin
				enableCounter <= 1'b1;
				writeEn <= 1'b0;
				//do stuff
			end
			S_DRAW_SQUARE: begin

				writeEn <= 1'b1;
				colour <= colorSwitch;
				resetSquare <= 1'b0;
				Xout <= Xin + squareAdd[1:0];
				Yout <= Yin + squareAdd[3:2];
			end
			S_DRAW_LEFT_PADDLE: begin
				writeEn <= 1'b1;
				//freeze square counter
				resetSquare <= 1'b1;
				resetLeftPaddle <= 1'b0;
				colour <= colorSwitch;
				Xout <= leftPaddleXin + LpaddleX;
				Yout <= leftPaddleYin + LpaddleY;
			end
			S_DRAW_RIGHT_PADDLE: begin
				writeEn <= 1'b1;
				colour <= colorSwitch; //change for customization if you want
				resetLeftPaddle <= 1'b1;
				resetRightPaddle <= 1'b0;
				Xout <= rightPaddleXin + RpaddleX;
				Yout <= rightPaddleYin + RpaddleY;
			end
			S_WAIT_ERASE: begin
				writeEn <= 1'b0;
			end
			S_ERASE_SQUARE: begin
				writeEn <= 1'b1;
				colour <= 1'b0;
				resetRightPaddle <= 1'b1;
				resetSquare <= 1'b0;
				Xout <= Xin + squareAdd[1:0];
				Yout <= Yin + squareAdd[3:2];
			end
			S_ERASE_LEFT_PADDLE: begin
				writeEn <= 1'b1;
				colour <= 3'b0;
				resetSquare <= 1'b1;
				resetLeftPaddle <= 1'b0;
				Xout <= leftPaddleXin + LpaddleX;
				Yout <= leftPaddleYin + LpaddleY;
			end
			S_ERASE_RIGHT_PADDLE: begin
				writeEn <= 1'b1;
				colour <= 3'b0;
				resetLeftPaddle <= 1'b1;
				resetRightPaddle <= 1'b0;
				Xout <= rightPaddleXin + RpaddleX;
				Yout <= rightPaddleYin + RpaddleY;
			end
			S_WAIT_DRAW: begin
				resetRightPaddle <= 1'b1;
				writeEn <= 1'b0;
			end
			S_RESET_COUNTERS: begin
				//					writeEn <= 1'b0;
				resetRightPaddle <= 1'b1;
				//					//borderCount <= 10'd600; 
				//					squareCount <= 5'd18; 
				//					LpaddleCount <= 7'd100; 
				//					RpaddleCount <= 7'd100;
				//					eraseSquareCount <= 5'd18; 
				//					LerasePaddleCount <= 7'd100; 
				//					RerasePaddleCount <= 7'd100; 
			end
			//				//default: something
		endcase
	end
endmodule

module drawBorder(enable, x, y, clk);
	input clk;
	input enable;
	output logic [7:0] x;
	output logic [6:0] y;

	//draw left border
	always @(posedge clk)
	begin
		if (x == 8'd159 & y == 7'd119) begin //we only run this at the start so that the last pixel is drawn
			x <= 1'd0; //starting coordinates
			y <= 1'd0;
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
module squareFSM(input clock, input reset, input enable, output logic [4:0] display);
	always@(posedge clock)
	begin
		if (reset) begin
			display <= 1'b0;
		end
		else if (enable) begin
			//draw color over current coordinates
			display <= display + 1'b1;
		end
	end
endmodule

//Based on erase or draw input on every active clock edge
//Set the paddle to be white as default color 
module paddleFSM(input clock, input enable, input reset, output logic [5:0] paddleX, output logic [5:0] paddleY);

	always@(posedge clock) begin
		if (reset) begin
			paddleX <= 1'b0;
			paddleY <= 1'b0;
		end
		else if (enable) begin
			if(paddleY < 6'd20) begin //adjust here for paddle size
				paddleY <= paddleY + 1'b1;
			end
			else begin
				if(paddleX == 1'd0) begin
					paddleX <= 1'b1;
					paddleY <= 1'b0;
				end
			end
		end
	end

endmodule

module eraseAll(input clock, input enable, input reset, output logic [7:0] eraseX, output logic [6:0] eraseY);

	always@(posedge clock) begin
		if (reset) begin
			eraseX <= 1'b0;
			eraseY <= 1'b0;
		end
		else if (enable) begin
			if(eraseY < 7'd120) begin //adjust here for paddle size
				eraseY <= eraseY + 1'b1;
			end
			else begin
				if(eraseX < 8'd160) begin
					eraseX <= eraseX + 1'b1;
					eraseY <= 1'b0;
				end
			end
		end
	end
endmodule

module XCounter(count_enable, clk, reset_n,xDisplay,lhitPulse,rhitPulse);
	input clk;
	input reset_n;
	input count_enable; //TODO: use count_enable to activate counter
	output logic lhitPulse; // When the object hits the left side of the wall,lhitPulse is 1,otherwise it is 0
	output logic rhitPulse; // When the object hits the right side of the wall,rhitPulse is 1,otherwise it is 0
	output logic [7:0] xDisplay;
	logic direction; //0 = left, 1 = right:note to go right is to increase x
	logic [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk)
	begin
		// reset position and diretion
		if(reset_n == 1'b0) begin
			xDisplay <= 8'd50;
			direction <= 1'b0;
			lhitPulse <= 1'b0;
			rhitPulse <= 1'b0;
		end

		// go to right if hits left wall
		else if (xDisplay == 8'd14) //CURRENT OFFSET: 22: 20 for paddles and 2 for border
			begin
				lhitPulse <= 1'b1; // hit the left wall, should have high pulse
				rhitPulse <= 1'b0;
				direction <= 1'b1; //reached left, has to go right
			end
			// go to left if hits right wall
		else if (xDisplay >= (8'd160 - square_size - 8'd14)) //subtract square size AND BORDER SIZE to determine true boundary of x
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
	input count_enable; //TODO: use count_enable to activate counter
	output logic [6:0]yDisplay;
	logic direction; //0 = down, 1 = up: note to go up is to decrease y
	logic [3:0] square_size = 4'd4; //size of edge of square
	always @(posedge clk)
	begin
		// reset position and diretion
		if (reset_n == 1'b0)
			begin
				yDisplay <= 7'd50; //initialize to 0
				direction <= 1'b0;
			end
			// go down if hits upper wall

		else if (yDisplay <= 2'd2)
			direction <= 1'b0; //reached top of screen; has to go down.
			// go up if hits lower wall

		else if (yDisplay >= (7'd120 - square_size - 2'd2)) //subtract square size to determine true boundary of y
			direction <= 1'b1; //reached bottom of screen; has to go up.

		if (direction == 1'b0)
			yDisplay <= yDisplay + 1'b1; //going down
		else
			yDisplay <= yDisplay - 1'b1; //going up

	end
endmodule

module YPaddle(clk, reset_n,moveEnable,up,down,ypDisplay);
	input clk;
	input reset_n;
	input moveEnable;
	input up;
	input down;
	output logic [6:0]ypDisplay;
	logic [5:0] paddle_size = 6'd20; //size of edge of square
	always @(posedge clk)
	begin
		// reset position and diretion
		if (reset_n == 1'b0)
			begin
				ypDisplay <= 7'd50; //initialize to 50
			end

		if (moveEnable)
			begin
				if (up == 1'b0 && down == 1'b1)
					begin
						if (ypDisplay < (7'd120 - paddle_size - 2'd2))
							ypDisplay <= ypDisplay + 1'b1; //going down
					end
				else if (up == 1'b1 && down == 1'b0)
					begin
						if (ypDisplay > 2'd2)
							ypDisplay <= ypDisplay - 1'b1; //going up
					end
			end

	end
endmodule

//should run at 1/60th of a second
module TimeCounter(count_enable, clk, reset_n, difficulty, display, erase, draw, pause);
	input count_enable;
	input clk;
	input reset_n;
	input [1:0] difficulty;
	input pause;
	output logic display;
	output logic erase;
	output logic draw;
	logic [19:0] q;
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
				if (20'd29000 < q & q < 20'd29500) //(20'd499980 < q & q < 20'd500000) //adjust for erase time
					erase <= 1'b1;
				else if (q == 20'd30000) //the two values above and below should hold so that the drawing/erasing can occur
					display <= 1'b1;
				else if (20'd30100 < q & q < 20'd30600) //(20'd510000 < q & q < 20'd510020)
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

module hex_decoder(hex_digit, segments);
	input [3:0] hex_digit;
	output logic [6:0] segments;

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

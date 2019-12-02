module DE1_SoC (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW, PS2_DAT, PS2_CLK);

	input logic CLOCK_50; 
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY; 
	input logic [9:0] SW;
	inout logic PS2_DAT, PS2_CLK;
	
	logic reset;
	logic valid;
	logic makeBreak;
	logic [7:0] outCode;

	// Show signals on LEDRs so we can see what is happening.
	assign LEDR = {valid, makeBreak, outCode};
	
	keyboard_press_driver keytest(
		.CLOCK_50(CLOCK_50), 
		.valid(valid), 
		.makeBreak(makeBreak),
		.outCode(outCode),
		.PS2_DAT(PS2_DAT), 
		.PS2_CLK(PS2_CLK), 
		.reset(~KEY[0])
);

endmodule

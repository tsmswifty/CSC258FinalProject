// CREDIT: 
// John Loomis (http://www.johnloomis.org/)
// http://www.johnloomis.org/digitallab/ps2lab1/ps2lab1.html

module oneshot(output reg pulse_out, input trigger_in, input clk);
reg delay;

always @ (posedge clk)
begin
	if (trigger_in && !delay) pulse_out <= 1'b1;
	else pulse_out <= 1'b0;
	delay <= trigger_in;
end 
endmodule

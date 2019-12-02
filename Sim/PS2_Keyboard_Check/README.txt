README

This Quartus project is provided to allow EE271 Students to test keyboards to determine
if they are PS2 compatible and will work with the DE1-SoC board.

To test a mouse:
1) Compile provided project
2) Program the FPGA
3) Plug in the keyboard
4) Press KEY0 to send the reset signal to the keyboard
5) Press keyboard buttons 
	a) if your keyboard works, you will see the scan codes and make/break codes of the 
	   letters you are pressing appear on the LEDs
	b) if you do not see any LEDs your keyboard is likely not PS2 compatible
6) If you want to test an additional keyboard, plug in the new keyboard and press KEY0 to reset 
   the system, and repeat from Step 5.
	
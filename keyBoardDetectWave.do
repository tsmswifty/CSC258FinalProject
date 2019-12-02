# Set the working dir, where all compiled Verilog goes.
vlib work
vlog -timescale 1ns/1ns  part2.sv
vsim -L altera_mf_ver lKeyBoardDetector
log {/*}
add wave {/*}

force {outCode} 00000000;
force {makeCode} 0;
run 5ns
force {outCode} 00010101;
force {makeCode} 1;
run 5ns
force {outCode} 00011101;
force {makeCode} 1;
run 5ns
force {outCode} 00011101;
force {makeCode} 0;
run 5ns
force {outCode} 00010101;
force {makeCode} 0;
run 5ns
force {outCode} 00011100;
force {makeCode} 1;
run 5ns
force {outCode} 00011100;
force {makeCode} 0;
run 5ns




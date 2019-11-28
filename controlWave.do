# Set the working dir, where all compiled Verilog goes.
vlib work
vlog -timescale 1ns/1ns  part2.v
vsim -L altera_mf_ver testControl
log {/*}
add wave {/*}

force {signal} 0 0,1 5 -r 10;
force {reset} 0;
run 5ns
force {reset} 1;
force  {enable} 1;
force {lup} 0;
force {ldown} 1;
force {rup} 0;
force {rdown} 1;
run 400ns
force {lup} 1;
force {ldown} 0;
run 300ns



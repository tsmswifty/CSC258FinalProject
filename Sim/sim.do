# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns part2.v

# Load simulation using mux as the top level simulation module.
vsim part2
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {CLOCK_50} 1 0, 0 1 -r 2
force {SW[9]} 1
force {SW[8]} 1
force {SW[7]} 1
force {KEY[0]} 0 1, 1 2
run 2000000ns
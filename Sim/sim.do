# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns part2.sv

# Load simulation using mux as the top level simulation module.
vsim part2
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {SW[2]} 0 0, 1 10
force {CLOCK_50} 0 0, 1 1 -repeat 1
force {SW[9]} 1 1
force {SW[7]} 1 1
force {SW[6]} 1 1
force {SW[5]} 1 1
force {SW[4]} 1 1
force {SW[3]} 1 1
force {SW[8]} 1 1
force {SW[1]} 1 1

run 20000ns
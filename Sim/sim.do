# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns part2.v

# Load simulation using mux as the top level simulation module.
vsim datapathFSM
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force resetn 0 0, 1 10
force clock 0 0, 1 1 -repeat 1
force eraseIn 0 0, 1 1500, 0 1502 -repeat 3000
force drawIn 0 0, 1 2000, 0 2002 -repeat 3000
force Xin 10#10 0
force Yin 10#20 0
force leftPaddleXin 10#50 0
force leftPaddleYin 10#60 0
force rightPaddleXin 10#30 0
force rightPaddleYin 10#40 0

run 20000ns
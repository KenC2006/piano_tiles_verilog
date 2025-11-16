# Simple ModelSim TCL script for piano_tiles testbench
# Uses stub models for Altera primitives (no Quartus installation needed)

# Clean and create libraries
if {[file exists work]} {
    vdel -lib work -all
}
if {[file exists altera_mf]} {
    vdel -lib altera_mf -all
}

vlib work
vlib altera_mf
vmap altera_mf altera_mf

# Compile Altera stub models
echo "Compiling Altera primitive stubs..."
vlog -work altera_mf altera_stubs.v

# Compile design files
echo "Compiling design files..."
vlog -work work vga_pll.v
vlog -work work vga_controller.v
vlog -work work vga_address_translator.v
vlog -work work vga_adapter.v
vlog -work work piano_tiles.v
vlog -work work piano_tiles_tb.v

# Start simulation
echo "Starting simulation..."
vsim -t ps -L altera_mf -lib work piano_tiles_tb

# Add waves to waveform window
echo "Adding signals to waveform..."
add wave -divider "Clock and Reset"
add wave sim:/piano_tiles_tb/CLOCK_50
add wave sim:/piano_tiles_tb/SW
add wave -hex sim:/piano_tiles_tb/KEY

add wave -divider "Score"
add wave -unsigned sim:/piano_tiles_tb/dut/score
add wave -binary sim:/piano_tiles_tb/dut/HEX0
add wave -binary sim:/piano_tiles_tb/dut/HEX1

# Run simulation
echo "Running simulation..."
run 50us

# Zoom to fit waveform
wave zoom full

echo "Simulation complete. View waveform for results."

yosys read_verilog -sv main.sv
yosys read_verilog -sv uart_rx.sv
yosys read_verilog -sv uart_tx.sv
yosys read_verilog -sv i2c.v
yosys read_verilog -sv bh1750_i2c.v
yosys read_verilog -sv i2c_control.sv
yosys read_verilog -sv fifo.sv

yosys synth_ecp5 -json ./build/out.json -abc9

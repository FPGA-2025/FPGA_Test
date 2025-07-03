yosys read_verilog -sv main.sv
yosys read_verilog -sv uart_rx.sv
yosys read_verilog -sv uart_tx.sv

yosys synth_ecp5 -json ./build/out.json -abc9

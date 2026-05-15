iverilog -o pe_tb \
    synth/processing_element_synth.v \
    lib/primitives.v \
    lib/sky130_fd_sc_hd.v \
    tb/tb_processing_element_gate.v
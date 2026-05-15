# ============================================================
# Clock Definition
# ============================================================

create_clock \
    -name pe_clk \
    -period 10.0 \
    [get_ports clk]

# ============================================================
# Clock Uncertainty
# Models jitter/skew margins
# ============================================================

set_clock_uncertainty 0.2 [get_clocks pe_clk]

# ============================================================
# Input Delays
# Relative to clock
# ============================================================

set_input_delay 1.0 \
    -clock pe_clk \
    [remove_from_collection [all_inputs] [get_ports clk]]

# ============================================================
# Output Delays
# ============================================================

set_output_delay 1.0 \
    -clock pe_clk \
    [all_outputs]

# ============================================================
# Driving Cell Assumptions
# Helps synthesis estimate transition behavior
# ============================================================

set_driving_cell \
    -lib_cell sky130_fd_sc_hd__buf_2 \
    [remove_from_collection [all_inputs] [get_ports clk]]

# ============================================================
# Output Load Assumptions
# ============================================================

set_load 0.05 [all_outputs]

# ============================================================
# Optional Max Fanout Constraint
# ============================================================

set_max_fanout 8 [current_design]
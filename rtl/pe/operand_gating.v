`timescale 1ns / 1ps

module operand_gating #(
    parameter DATA_WIDTH = 8
)(
    input wire signed [DATA_WIDTH-1:0] activation,
    input wire signed [DATA_WIDTH-1:0] weight,

    output wire mac_enable
);
    assign mac_enable = (activation != 0) && (weight != 0);
endmodule

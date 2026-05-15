`timescale 1ns / 1ps

module systolic_array #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire clk,
    input  wire rst_n,

    input  wire pe_enable,
    input  wire valid_in,

    // Activation inputs (rows)
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] activation_in,

    // Weight inputs (columns)
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] weight_in,

    // Final outputs
    output wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] result_out,

    output wire valid_out
);
    wire signed [DATA_WIDTH-1:0] activation_bus [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
    wire signed [DATA_WIDTH-1:0] weight_bus [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
    wire signed [ACC_WIDTH-1:0] psum_bus [0:ARRAY_SIZE-1][0:ARRAY_SIZE];

    wire valid_bus [0:ARRAY_SIZE][0:ARRAY_SIZE];

    genvar i, j;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            assign activation_bus[0][i] = activation_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign weight_bus[i][0] = weight_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign psum_bus[i][0] = 0;
            assign valid_bus[0][i] = valid_in;
        end
    endgenerate

    /* Processing Elements */
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : ROW_GEN
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : COL_GEN
                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .pe_enable(pe_enable),
                    .activation_in(activation_bus[i][j]),
                    .weight_in(weight_bus[i][j]),
                    .psum_in(psum_bus[i][j]),
                    .valid_in(valid_bus[i][j]),
                    .activation_out(activation_bus[i+1][j]),
                    .weight_out(weight_bus[i][j+1]),
                    .psum_out(psum_bus[i][j+1]),
                    .valid_out(valid_bus[i+1][j])
                );
            end
        end
    endgenerate

    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            assign result_out[
                (i+1)*ACC_WIDTH-1 -: ACC_WIDTH
            ] = psum_bus[i][ARRAY_SIZE];
        end
    endgenerate

    assign valid_out = valid_bus[ARRAY_SIZE][ARRAY_SIZE-1];
endmodule
`timescale 1ns / 1ps

module output_streaming #(
    parameter ARRAY_SIZE = 4,
    parameter ACC_WIDTH  = 32,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,

    input wire write_enable,
    input wire read_enable,

    /* INT32 systolic outputs */
    input wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] systolic_result,
 
    /* Streamed FIFO outputs */
    output wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] streamed_output,
    output wire [ARRAY_SIZE-1:0] fifo_empty,
    output wire [ARRAY_SIZE-1:0] fifo_full
);
    wire signed [ACC_WIDTH-1:0] fifo_out [0:ARRAY_SIZE-1];

    genvar i;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : OUTPUT_FIFO_GEN
            output_fifo #(
                .DATA_WIDTH(ACC_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH)
            ) u_output_fifo (
                .clk(clk),
                .rst_n(rst_n),
                .write_en(write_enable),
                .read_en(read_enable),
                .write_data(
                    systolic_result[(i+1)*ACC_WIDTH-1 -: ACC_WIDTH]
                ),
                .read_data(fifo_out[i]),
                .full(fifo_full[i]),
                .empty(fifo_empty[i])
            );

            assign streamed_output[
                (i+1)*ACC_WIDTH-1 -: ACC_WIDTH
            ] = fifo_out[i];
        end
    endgenerate
endmodule

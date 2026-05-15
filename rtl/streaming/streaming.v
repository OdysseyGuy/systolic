`timescale 1ns / 1ps

module streaming #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire stream_enable,

    input wire [DATA_WIDTH-1:0] activation_sram_data,
    input wire [DATA_WIDTH-1:0] weight_sram_data,

    output wire [ARRAY_SIZE*DATA_WIDTH-1:0] activation_stream,
    output wire [ARRAY_SIZE*DATA_WIDTH-1:0] weight_stream
);
    wire [DATA_WIDTH-1:0] activation_fifo_out [0:ARRAY_SIZE-1];
    wire [DATA_WIDTH-1:0] weight_fifo_out [0:ARRAY_SIZE-1];

    /* Activation FIFO */
    genvar i;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : ACT_FIFO_GEN
            activation_fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH)
            ) u_activation_fifo (
                .clk(clk),
                .rst_n(rst_n),

                .write_en(stream_enable),
                .write_data(activation_sram_data),

                .read_en(stream_enable),
                .read_data(activation_fifo_out[i]),

                .full(),
                .empty()
            );
            assign activation_stream[
                (i+1)*DATA_WIDTH-1 -: DATA_WIDTH
            ] = activation_fifo_out[i];
        end
    endgenerate

    /* Weight FIFO */
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : WT_FIFO_GEN
            weight_fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH)
            ) u_weight_fifo (
                .clk(clk),
                .rst_n(rst_n),

                .write_en(stream_enable),
                .write_data(weight_sram_data),

                .read_en(stream_enable),
                .read_data(weight_fifo_out[i]),

                .full(),
                .empty()
            );
            assign weight_stream[
                (i+1)*DATA_WIDTH-1 -: DATA_WIDTH
            ] = weight_fifo_out[i];
        end
    endgenerate
endmodule

`timescale 1ns / 1ps

module weight_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,

    /* write interface */
    input wire write_en,
    input wire [DATA_WIDTH-1:0] write_data,

    /* read interface */
    input wire read_en,
    output wire [DATA_WIDTH-1:0] read_data,

    /* fifo status */
    output wire full,
    output wire empty
)
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_data(write_data),
        .read_en(read_en),
        .read_data(read_data),
        .full(full),
        .empty(empty),
        .fifo_count()
    );
endmodule

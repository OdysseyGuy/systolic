`timescale 1ns / 1ps

module postprocess_pipeline #(
    parameter ARRAY_SIZE = 4,
    parameter ACC_WIDTH = 32,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10
)(
    input wire clk,
    input wire rst_n,

    input wire valid_in,
    input wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] streamed_output,

    /* Output SRAM Interface */
    output wire [ARRAY_SIZE-1:0] output_sram_we,
    output wire [ARRAY_SIZE*ADDR_WIDTH-1:0] output_sram_addr,
    output wire [ARRAY_SIZE*DATA_WIDTH-1:0] output_sram_data
);
    wire signed [DATA_WIDTH-1:0] requant_out [0:ARRAY_SIZE-1];
    wire requant_valid [0:ARRAY_SIZE-1];
    wire signed [DATA_WIDTH-1:0] relu_out [0:ARRAY_SIZE-1];

    genvar i;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : POST_PIPE
            /* Requantization */
            requant #(
                .IN_WIDTH(ACC_WIDTH),
                .OUT_WIDTH(DATA_WIDTH)
            ) u_requant (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(valid_in),
                .data_in(streamed_output[(i+1)*ACC_WIDTH-1 -: ACC_WIDTH]),
                .scale_factor(16'd256),
                .shift_amount(8'd8),
                .valid_out(requant_valid[i]),
                .data_out(requant_out[i])
            );

            /* ReLU */
            relu_unit #(
                .DATA_WIDTH(DATA_WIDTH)
            ) u_relu (
                .data_in(requant_out[i]),
                .data_out(relu_out[i])
            );

            /* Sparse-Aware Address Suppression */
            address_suppression #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) u_addr_suppress (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(requant_valid[i]),
                .data_in(relu_out[i]),
                .sram_we(output_sram_we[i]),
                .sram_addr(output_sram_addr[(i+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
                .sram_data(output_sram_data[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
                .suppressed_writes(),
                .successful_writes()
            );
        end
    endgenerate
endmodule

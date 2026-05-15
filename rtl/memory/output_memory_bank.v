`timescale 1ns / 1ps

module output_memory_bank #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10
)(
    input wire clk,

    /* SRAM interface */
    input wire [ARRAY_SIZE-1:0] output_sram_we,
    input wire [ARRAY_SIZE*ADDR_WIDTH-1:0] output_sram_addr,
    input wire [ARRAY_SIZE*DATA_WIDTH-1:0] output_sram_data
);
    genvar i;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : SRAM_BANK_GEN
            output_sram #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) u_output_sram (
                .clk(clk),
                .we(output_sram_we[i]),
                .addr(output_sram_addr[(i+1)*ADDR_WIDTH-1 -: ADDR_WIDTH]),
                .write_data(output_sram_data[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH]),
                .read_data()
            );
        end
    endgenerate
endmodule

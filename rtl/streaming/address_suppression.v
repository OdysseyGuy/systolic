/**
 * Sparse-Aware Output Write Suppression Unit
 *
 * Purpose:
 * - prevents unnecessary SRAM writes for zero outputs
 * - reduces SRAM switching activity
 * - reduces memory dynamic power
 * - preserves dense tensor addressing
 */

`timescale 1ns / 1ps

module address_suppression #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10
)(
    input  wire clk,
    input  wire rst_n,

    /* Input Stream */
    input  wire valid_in,
    input  wire signed [DATA_WIDTH-1:0] data_in,

    /* SRAM Interface */
    output reg sram_we,
    output reg [ADDR_WIDTH-1:0] sram_addr,
    output reg signed [DATA_WIDTH-1:0] sram_data,

    /* Statistics / Monitoring */
    output reg [31:0] suppressed_writes,
    output reg [31:0] successful_writes
);
    /* Zero Detection */
    wire nonzero_output;
    assign nonzero_output = (data_in != 0);

    /* Main Control Logic */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sram_we <= 1'b0;
            sram_addr <= 0;
            sram_data <= 0;
            suppressed_writes <= 0;
            successful_writes <= 0;
        end else begin
            sram_we <= 1'b0;
            if (valid_in) begin
                // ============================================
                // NONZERO OUTPUT
                // Perform SRAM write
                // ============================================
                if (nonzero_output) begin
                    sram_we <= 1'b1;
                    sram_data <= data_in;
                    successful_writes <= successful_writes + 1'b1;
                end
                // ============================================
                // ZERO OUTPUT
                // Suppress SRAM write
                // ============================================
                else begin
                    sram_we <= 1'b0;
                    suppressed_writes <= suppressed_writes + 1'b1;
                end

                // ============================================
                // IMPORTANT:
                // Address ALWAYS increments
                // to preserve logical tensor indexing
                // ============================================
                sram_addr <= sram_addr + 1'b1;
            end
        end
    end
endmodule

`timescale 1ns / 1ps

module output_sram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 1024
)(
    input wire clk,
    input wire cs,
    input wire we,

    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,

    output reg [DATA_WIDTH-1:0] read_data
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 0;
        end
    end

    always @(posedge clk) begin
        if (cs) begin
            if (we) begin
                mem[addr] <= write_data;
            end
            read_data <= mem[addr];
        end
    end
endmodule

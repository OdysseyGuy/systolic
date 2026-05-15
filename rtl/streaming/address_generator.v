`timescale 1ns / 1ps

module address_generator #(
    parameter ADDR_WIDTH = 10
)(
    input wire clk,
    input wire rst_n,
    input wire enable,

    output reg [ADDR_WIDTH-1:0] addr_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= 0;
        end else if (enable) begin
            addr_out <= addr_out + 1'b1;
        end
    end
endmodule

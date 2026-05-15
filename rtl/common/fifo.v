`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input wire clk,
    input wire rst_n,

    input wire write_en,
    input wire [DATA_WIDTH-1:0] write_data,

    input wire read_en,
    output reg [DATA_WIDTH-1:0] read_data,

    output wire full,
    output wire empty,
    output wire [ADDR_WIDTH:0] fifo_count
);
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;

    assign full = (count == FIFO_DEPTH);
    assign empty = (count == 0);
    assign fifo_count = count;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            read_data <= 0;

            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else begin
            if (write_en && !full && !(read_en && !empty)) begin
                /* write only */
                mem[wr_ptr] <= write_data;
                wr_ptr <= wr_ptr + 1'b1;
                count <= count + 1'b1;
            end else if (read_en && !empty && !(write_en && !full)) begin
                /* read only */
                read_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
                count <= count - 1'b1;
            end else if (write_en && !full && read_en && !empty) begin
                /* read + write */
                mem[wr_ptr] <= write_data;
                read_data <= mem[rd_ptr];
                wr_ptr <= wr_ptr + 1'b1;
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
endmodule

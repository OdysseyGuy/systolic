`timescale 1ns / 1ps

module requant #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8,
    parameter SCALE_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,

    /* Input stream */
    input wire valid_in,
    input wire signed [IN_WIDTH-1:0] data_in,

    /* Quantization parameters */
    input wire signed [SCALE_WIDTH-1:0] scale_factor,
    input wire [7:0] shift_amount,

    /* Output stream */
    output reg valid_out,
    output reg signed [OUT_WIDTH-1:0] data_out
);
    /* Internal Precision */
    localparam MULT_WIDTH = IN_WIDTH + SCALE_WIDTH;

    /* Internal Registers */ 
    reg signed [MULT_WIDTH-1:0] scaled_value;
    reg signed [MULT_WIDTH-1:0] shifted_value;
    reg signed [OUT_WIDTH-1:0] saturated_value;

    /* Saturation Limits */
    localparam signed [OUT_WIDTH-1:0] MAX_VAL = 127;
    localparam signed [OUT_WIDTH-1:0] MIN_VAL = -128;

    /* Main Requantization Pipeline */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scaled_value <= 0;
            shifted_value <= 0;
            saturated_value <= 0;

            data_out <= 0;
            valid_out <= 0;
        end
        else begin
            valid_out <= valid_in;
            if (valid_in) begin
                scaled_value <= data_in * scale_factor;
                shifted_value <= scaled_value >>> shift_amount;

                if (shifted_value > MAX_VAL) begin
                    saturated_value <= MAX_VAL;
                end else if (shifted_value < MIN_VAL) begin
                    saturated_value <= MIN_VAL;
                end else begin
                    saturated_value <= shifted_value[OUT_WIDTH-1:0];
                end
            end
        end
    end
endmodule

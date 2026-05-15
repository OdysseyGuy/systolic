`timescale 1ns / 1ps

module processing_element #(
    parameter DATA_WIDTH = 8,
    parameter PROD_WIDTH = 16,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire pe_enable,

    input wire signed [DATA_WIDTH-1:0] activation_in,
    input wire signed [DATA_WIDTH-1:0] weight_in,
    input wire signed [ACC_WIDTH-1:0] psum_in,
    input wire valid_in,

    output reg signed [DATA_WIDTH-1:0] activation_out,
    output reg signed [DATA_WIDTH-1:0] weight_out,
    output reg signed [ACC_WIDTH-1:0] psum_out,
    output reg valid_out
);
    wire mac_enable;

    reg signed [PROD_WIDTH-1:0] product;
    reg signed [ACC_WIDTH-1:0] accumulator;

    operand_gating #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_operand_gating (
        .activation(activation_in),
        .weight(weight_in),
        .mac_enable(mac_enable)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activation_out <= 0;
            weight_out <= 0;
            psum_out <= 0;
            valid_out <= 0;
            product <= 0;
            accumulator <= 0;
        end
        else begin
            if (pe_enable) begin
                activation_out <= activation_in;
                weight_out <= weight_in;
                valid_out <= valid_in;

                if (valid_in) begin
                    if (mac_enable) begin
                        product <= activation_in * weight_in;
                        accumulator <= psum_in + (activation_in * weight_in);
                        psum_out <= psum_in + (activation_in * weight_in);
                    end
                    else begin
                        /* zero skipping */
                        product <= 0;
                        accumulator <= psum_in;
                        psum_out <= psum_in;
                    end
                end
            end
        end
    end
endmodule

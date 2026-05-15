`timescale 1ns / 1ps

module skew_injector #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,

    /* FIFO Stream Inputs */
    input wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] activation_stream_in,
    input wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] weight_stream_in,

    /* Skewed Outputs Toward Systolic Array */
    output wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] activation_stream_out,
    output wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] weight_stream_out
);
    /* Delay Storage */
    integer i, j;

    /* Activation delay lines */
    reg signed [DATA_WIDTH-1:0] activation_delay [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
   
    /* Activation Skew Logic */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    activation_delay[i][j] <= 0;
                end
            end
        end else begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                activation_delay[i][0] <= activation_stream_in[
                    (i+1)*DATA_WIDTH-1 -: DATA_WIDTH
                ];
                for (j = 1; j < ARRAY_SIZE; j = j + 1) begin
                    activation_delay[i][j] <= activation_delay[i][j-1];
                end
            end
        end
    end

    /* Weight delay lines */
    reg signed [DATA_WIDTH-1:0] weight_delay [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    /* Weight Skew Logic */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    weight_delay[i][j] <= 0;
                end
            end
        end else begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                weight_delay[i][0] <= weight_stream_in[
                    (i+1)*DATA_WIDTH-1 -: DATA_WIDTH
                ];
                for (j = 1; j < ARRAY_SIZE; j = j + 1) begin
                    weight_delay[i][j] <= weight_delay[i][j-1];
                end
            end
        end
    end

    genvar k;
    generate
        for (k = 0; k < ARRAY_SIZE; k = k + 1) begin : OUTPUT_ASSIGN
            assign activation_stream_out[
                (k+1)*DATA_WIDTH-1 -: DATA_WIDTH
            ] = activation_delay[k][k];
            assign weight_stream_out[
                (k+1)*DATA_WIDTH-1 -: DATA_WIDTH
            ] = weight_delay[k][k];
        end
    endgenerate
endmodule

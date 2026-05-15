`timescale 1ns / 1ps

module systolic_top #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter FIFO_DEPTH = 16,
    parameter ADDR_WIDTH = 10
)(
    input wire clk,
    input wire rst_n,
    input wire start, /* Accelerator control */

    input wire activation_sram_we,
    input wire weight_sram_we,

    input wire [ADDR_WIDTH-1:0] activation_sram_wr_addr,
    input wire [ADDR_WIDTH-1:0] weight_sram_wr_addr,

    input wire signed [DATA_WIDTH-1:0] activation_sram_wr_data,
    input wire signed [DATA_WIDTH-1:0] weight_sram_wr_data,

    output wire done /* done status */
);
    /* Control Signals */
    wire stream_enable;
    wire compute_enable;

    /* Controller FSM */
    controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .stream_enable(stream_enable),
        .compute_enable(compute_enable),
        .done(done)
    );

    /* SRAM Address Generation */
    wire [ADDR_WIDTH-1:0] activation_rd_addr;
    wire [ADDR_WIDTH-1:0] weight_rd_addr;

    /* Activation Address Generator */
    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_activation_addr_gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(stream_enable),
        .addr_out(activation_rd_addr)
    );

    /* Weight Address Generator */
    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_activation_addr_gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(stream_enable),
        .addr_out(activation_rd_addr)
    );

    /* SRAM Outputs */
    wire signed [DATA_WIDTH-1:0] activation_sram_rd_data;
    wire signed [DATA_WIDTH-1:0] weight_sram_rd_data;

    /* Activation SRAM */
    activation_sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_activation_sram (
        .clk(clk),
        .we(activation_sram_we),
        .addr(
            activation_sram_we ?
            activation_sram_wr_addr :
            activation_rd_addr
        ),
        .write_data(activation_sram_wr_data),
        .read_data(activation_sram_rd_data)
    );

    /* Weight SRAM */
    weight_sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_weight_sram (
        .clk(clk),
        .we(weight_sram_we),
        .addr(
            weight_sram_we ?
            weight_sram_wr_addr :
            weight_rd_addr
        ),
        .write_data(weight_sram_wr_data),
        .read_data(weight_sram_rd_data)
    );

    /* Streaming Outputs */
    wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] activation_stream;
    wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] weight_stream;

    /* Weight and Activation streaming */
    streaming #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_streaming (
        .clk(clk),
        .rst_n(rst_n),
        .stream_enable(stream_enable),
        .activation_sram_data(activation_sram_rd_data),
        .weight_sram_data(weight_sram_rd_data),
        .activation_stream(activation_stream),
        .weight_stream(weight_stream)
    );

    /* Skewed Streams */
    wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] skewed_activation_stream;
    wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] skewed_weight_stream;

    /* Skew injector */
    skew_injector #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_skew_injector (
        .clk(clk),
        .rst_n(rst_n),
        .activation_stream_in(activation_stream),
        .weight_stream_in(weight_stream),
        .activation_stream_out(skewed_activation_stream),
        .weight_stream_out(skewed_weight_stream)
    );

    /* Systolic Outputs */
    wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] systolic_result;
    wire systolic_valid;

    /* Systolic Array */
    systolic #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_systolic (
        .clk(clk),
        .rst_n(rst_n),
        .pe_enable(compute_enable),
        .valid_in(stream_enable),
        .activation_in(skewed_activation_stream),
        .weight_in(skewed_weight_stream),
        .result_out(systolic_result),
        .valid_out(systolic_valid)
    );

    /* Output Stream */
    wire signed [ARRAY_SIZE*ACC_WIDTH-1:0] streamed_output;
    wire [ARRAY_SIZE-1:0] output_fifo_empty;
    wire [ARRAY_SIZE-1:0] output_fifo_full;

    output_streaming #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .ACC_WIDTH(ACC_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_output_streaming (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(systolic_valid),
        .read_enable(1'b1),
        .systolic_result(systolic_result),
        .streamed_output(streamed_output),
        .fifo_empty(output_fifo_empty),
        .fifo_full(output_fifo_full)
    );

    /* Post Process Pipeline */
    wire [ARRAY_SIZE-1:0] output_sram_we;
    wire [ARRAY_SIZE*ADDR_WIDTH-1:0] output_sram_addr;
    wire [ARRAY_SIZE*DATA_WIDTH-1:0] output_sram_data;

    postprocess_pipeline #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .ACC_WIDTH(ACC_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_postprocess_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(systolic_valid),
        .streamed_output(streamed_output),
        .output_sram_we(output_sram_we),
        .output_sram_addr(output_sram_addr),
        .output_sram_data(output_sram_data)
    );

    /* Output SRAM Bank */
    output_memory_bank #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_output_memory_bank (
        .clk(clk),
        .output_sram_we(output_sram_we),
        .output_sram_addr(output_sram_addr),
        .output_sram_data(output_sram_data)
    );
endmodule


`timescale 1ns / 1ps

module controller (
    input wire clk,
    input wire rst_n,
    input wire start,

    /* Control signals */
    output reg load_weights,
    output reg load_activations,
    output reg compute_enable,
    output reg writeback_enable,
    output reg done
);
    localparam IDLE = 3'd0;
    localparam LOAD_W = 3'd1;
    localparam LOAD_A = 3'd2;
    localparam COMPUTE = 3'd3;
    localparam WRITEBACK = 3'd4;
    localparam FINISHED = 3'd5;

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [7:0] cycle_counter;

    /* state updation */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    /* next state logic */
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD_W;
                end
            end
            LOAD_W: begin
                next_state = LOAD_A;
            end
            LOAD_A: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                if (cycle_counter == 20) begin
                    next_state = WRITEBACK;
                end
            end
            WRITEBACK: begin
                next_state = FINISHED;
            end
            FINISHED: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    /* output logic */
    always @(*) begin
        load_weights = 0;
        load_activations = 0;
        compute_enable = 0;
        writeback_enable = 0;
        done = 0;

        case (current_state)
            LOAD_W: begin
                load_weights = 1;
            end
            LOAD_A: begin
                load_activations = 1;
            end
            COMPUTE: begin
                compute_enable = 1;
            end
            WRITEBACK: begin
                writeback_enable = 1;
            end
            FINISHED: begin
                done = 1;
            end
        endcase
    end

    /* cycle counter */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 0;
        end else if (current_state == COMPUTE) begin
            cycle_counter <= cycle_counter + 1'b1;
        end else begin
            cycle_counter <= 0;
        end
    end
endmodule

`timescale 1ns / 1ps

module tb_processing_element_gate;
    // ============================================================
    // PARAMETERS
    // ============================================================

    parameter DATA_WIDTH = 8;
    parameter PROD_WIDTH = 16;
    parameter ACC_WIDTH  = 32;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    reg clk;
    reg rst_n;

    reg pe_enable;

    reg signed [DATA_WIDTH-1:0] activation_in;
    reg signed [DATA_WIDTH-1:0] weight_in;

    reg signed [ACC_WIDTH-1:0] psum_in;

    reg valid_in;

    wire signed [DATA_WIDTH-1:0] activation_out;
    wire signed [DATA_WIDTH-1:0] weight_out;

    wire signed [ACC_WIDTH-1:0] psum_out;

    wire valid_out;

    // ============================================================
    // DUT INSTANTIATION
    // NOTE:
    // Gate-level synthesized netlist has NO parameters anymore
    // ============================================================

    processing_element dut (
        .clk            (clk),
        .rst_n          (rst_n),

        .pe_enable      (pe_enable),

        .activation_in  (activation_in),
        .weight_in      (weight_in),

        .psum_in        (psum_in),

        .valid_in       (valid_in),

        .activation_out (activation_out),
        .weight_out     (weight_out),

        .psum_out       (psum_out),

        .valid_out      (valid_out)
    );

    // ============================================================
    // CLOCK GENERATION
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // TEST TASK
    // ============================================================

    task check_result;
        input integer expected;

        begin

            // Wait for synthesized logic to settle
            @(negedge clk);

            if (psum_out !== expected) begin

                $display(
                    "ERROR: Expected = %0d, Got = %0d at time %0t",
                    expected,
                    psum_out,
                    $time
                );

                $finish;
            end
            else begin
                $display(
                    "PASS: Expected = %0d, Got = %0d at time %0t",
                    expected,
                    psum_out,
                    $time
                );
            end
        end
    endtask

    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================

    initial begin
        // --------------------------------------------------------
        // VCD DUMP
        // --------------------------------------------------------
        $dumpfile("waves/tb_processing_element_gate.vcd");
        $dumpvars(0, tb_processing_element_gate);

        // --------------------------------------------------------
        // INITIALIZE
        // --------------------------------------------------------
        clk           = 0;
        rst_n         = 0;

        pe_enable     = 0;

        activation_in = 0;
        weight_in     = 0;

        psum_in       = 0;

        valid_in      = 0;

        // --------------------------------------------------------
        // LONG RESET FOR GATE-LEVEL SIM
        // --------------------------------------------------------

        #100;

        rst_n = 1;

        // Allow several clocks after reset
        repeat(5) @(posedge clk);

        // ========================================================
        // TEST 1
        // BASIC MAC
        // ========================================================

        @(posedge clk);

        pe_enable     <= 1;
        valid_in      <= 1;

        activation_in <= 2;
        weight_in     <= 3;

        psum_in       <= 4;

        @(posedge clk);

        check_result(10);

        // ========================================================
        // TEST 2
        // NEGATIVE MULTIPLICATION
        // ========================================================

        @(posedge clk);

        activation_in <= -2;
        weight_in     <= 5;

        psum_in       <= 20;

        @(posedge clk);

        check_result(10);

        // ========================================================
        // TEST 3
        // ZERO-SKIP OPERAND GATING
        // ========================================================

        @(posedge clk);

        activation_in <= 0;
        weight_in     <= 12;

        psum_in       <= 55;

        @(posedge clk);

        check_result(55);

        // ========================================================
        // TEST 4
        // NEGATIVE WEIGHT
        // ========================================================
        @(posedge clk);
        activation_in <= 7;
        weight_in     <= -3;

        psum_in       <= 100;

        @(posedge clk);
        check_result(79);

        // ========================================================
        // TEST 5
        // PE DISABLED
        // ========================================================
        @(posedge clk);
        pe_enable     <= 0;

        activation_in <= 8;
        weight_in     <= 8;

        psum_in       <= 999;

        @(posedge clk);
        @(negedge clk);
        if (psum_out !== 79) begin
            $display("ERROR: PE disable failed. psum_out changed.");
            $finish;
        end
        else begin
            $display("PASS: PE disable successful.");
        end

        // ========================================================
        // TEST 6
        // VALID LOW
        // ========================================================
        @(posedge clk);
        pe_enable     <= 1;

        valid_in      <= 0;

        activation_in <= 9;
        weight_in     <= 9;

        psum_in       <= 500;

        @(posedge clk);
        @(negedge clk);
        if (valid_out !== 0) begin
            $display("ERROR: valid_out incorrect.");
            $finish;
        end
        else begin
            $display("PASS: valid propagation correct.");
        end

        // ========================================================
        // TEST COMPLETE
        // ========================================================
        $display("========================================");
        $display("ALL GATE-LEVEL PE TESTS PASSED");
        $display("========================================");

        #50;
        $finish;
    end
endmodule

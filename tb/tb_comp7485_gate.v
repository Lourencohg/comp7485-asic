// ============================================================================
// File    : tb_comp7485_gate.v
// Design  : Gate-level testbench for the 7485 4-bit magnitude comparator
// Author  : Lourenco
//
// Description:
//   Self-checking, exhaustive testbench for the SYNTHESIZED netlist.
//   It is the Verilog twin of tb_comp7485.vhd: same 2048 vectors, same
//   reference model taken from the TI datasheet. Verilog is required here
//   because the netlist written by Fusion Compiler is Verilog.
//
//   Passing this test proves the netlist is functionally equivalent to the
//   RTL: with only 11 inputs, exhaustive simulation is a complete proof.
// ============================================================================
`timescale 1ns/1ps

module tb_comp7485_gate;

    // ---- Signals connected to the DUT pins ---------------------------------
    reg  [3:0] A, B;
    reg        i_AGB, i_AEB, i_ALB;
    wire       o_AGB, o_AEB, o_ALB;

    // Settle time for the combinational logic before checking
    localparam T_SETTLE = 10;

    integer a_val, b_val, c_val;
    integer n_tests, n_errors;

    // Bit order of the 3-bit vectors below: {AGB, ALB, AEB}
    reg [2:0] cascade;
    reg [2:0] expected;
    wire [2:0] obtained = {o_AGB, o_ALB, o_AEB};

    // ---- Device Under Test (the synthesized netlist) -----------------------
    comp7485 dut (
        .A     (A),
        .B     (B),
        .i_AGB (i_AGB),
        .i_AEB (i_AEB),
        .i_ALB (i_ALB),
        .o_AGB (o_AGB),
        .o_AEB (o_AEB),
        .o_ALB (o_ALB)
    );

    // ---- Stimulus + checking ------------------------------------------------
    initial begin
        $dumpfile("tb_comp7485_gate.vcd");
        $dumpvars(0, tb_comp7485_gate);

        n_tests  = 0;
        n_errors = 0;
        $display("Starting exhaustive gate-level test of comp7485 (2048 vectors)");

        for (a_val = 0; a_val < 16; a_val = a_val + 1) begin
            for (b_val = 0; b_val < 16; b_val = b_val + 1) begin
                for (c_val = 0; c_val < 8; c_val = c_val + 1) begin

                    // -- 1. Apply stimulus ------------------------------------
                    cascade = c_val[2:0];
                    A     = a_val[3:0];
                    B     = b_val[3:0];
                    i_AGB = cascade[2];
                    i_ALB = cascade[1];
                    i_AEB = cascade[0];

                    // -- 2. Reference model (datasheet, not the RTL equations) -
                    if (a_val > b_val)
                        expected = 3'b100;
                    else if (a_val < b_val)
                        expected = 3'b010;
                    else
                        case (cascade)                  // A = B: cascade table
                            3'b100:  expected = 3'b100; // prev A > B
                            3'b010:  expected = 3'b010; // prev A < B
                            3'b001,                     // i_AEB dominates
                            3'b011,
                            3'b101,
                            3'b111:  expected = 3'b001;
                            3'b110:  expected = 3'b000; // illegal
                            3'b000:  expected = 3'b110; // illegal
                        endcase

                    // -- 3. Wait and compare ----------------------------------
                    #T_SETTLE;
                    n_tests = n_tests + 1;

                    if (obtained !== expected) begin
                        n_errors = n_errors + 1;
                        $display("MISMATCH: A=%0d B=%0d cascade(AGB,ALB,AEB)=%b expected=%b obtained=%b",
                                 a_val, b_val, cascade, expected, obtained);
                    end
                end
            end
        end

        // -- 4. Final report ------------------------------------------------
        $display("Tests run: %0d   Errors: %0d", n_tests, n_errors);
        if (n_errors == 0)
            $display("GATE-LEVEL SIMULATION PASSED");
        else
            $display("GATE-LEVEL SIMULATION FAILED");

        $finish;
    end

endmodule

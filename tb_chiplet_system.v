`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// lat_monitor : counts clock cycles from 'start' until 'done_sig' is seen
// -----------------------------------------------------------------------------
module lat_monitor (
    input  wire clk, rst_n, start, done_sig,
    output reg [31:0] cycles,
    output reg        finished
);
    reg run;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin run <= 0; cycles <= 0; finished <= 0; end
        else if (start && !run && !finished) begin run <= 1; cycles <= 1; end
        else if (run && !finished) begin
            if (done_sig) begin finished <= 1; run <= 0; end
            else cycles <= cycles + 1;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// tb_chiplet_system : full system test, three systems run side by side
//   MONO : same design as ONE die (links are wires)
//   CHIP : three chiplets joined by serialized D2D links
//   ERR  : chiplet version with a bit error injected on the compute->I/O link
// -----------------------------------------------------------------------------
module tb_chiplet_system;
    reg clk = 0, rst_n = 0, start = 0;
    always #5 clk = ~clk;

    wire        done_m, done_c, done_e;
    wire [15:0] res_m, res_c, res_e;
    wire        rv_m, rv_c, rv_e;
    wire        ef_m, ef_c, ef_e;

    chiplet_system #(.BYPASS(1), .LAT(2)) MONO (.clk(clk), .rst_n(rst_n), .start(start),
        .inj_mem(1'b0), .inj_io(1'b0), .done(done_m), .result(res_m), .result_valid(rv_m), .err_flag(ef_m));
    chiplet_system #(.BYPASS(0), .LAT(2)) CHIP (.clk(clk), .rst_n(rst_n), .start(start),
        .inj_mem(1'b0), .inj_io(1'b0), .done(done_c), .result(res_c), .result_valid(rv_c), .err_flag(ef_c));
    chiplet_system #(.BYPASS(0), .LAT(2)) ERR  (.clk(clk), .rst_n(rst_n), .start(start),
        .inj_mem(1'b0), .inj_io(1'b1), .done(done_e), .result(res_e), .result_valid(rv_e), .err_flag(ef_e));

    wire [31:0] cyc_m, cyc_c;
    wire        fin_m, fin_c;
    lat_monitor MON_M (.clk(clk), .rst_n(rst_n), .start(start), .done_sig(rv_m), .cycles(cyc_m), .finished(fin_m));
    lat_monitor MON_C (.clk(clk), .rst_n(rst_n), .start(start), .done_sig(rv_c), .cycles(cyc_c), .finished(fin_c));

    integer errors = 0, wait_n;

    initial begin
        $dumpfile("tb_chiplet_system.vcd");
        $dumpvars(0, tb_chiplet_system);
        repeat (4) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);
        start = 1;                      // one-cycle start pulse
        @(negedge clk);
        start = 0;

        wait_n = 0;
        while (!(fin_m && fin_c) && wait_n < 500) begin @(negedge clk); wait_n = wait_n + 1; end
        repeat (200) @(negedge clk);    // give ERR system time (it must NOT finish)

        $display("==============================================");
        $display(" CHIPLET SYSTEM SIMULATION RESULTS");
        $display("==============================================");
        $display("Monolithic : result = %0d, latency = %0d cycles", res_m, cyc_m);
        $display("Chiplet    : result = %0d, latency = %0d cycles", res_c, cyc_c);
        $display("Chiplet overhead = %0d cycles (%0d %%)", cyc_c - cyc_m, ((cyc_c - cyc_m) * 100) / cyc_m);

        if (rv_m && res_m == 16'd100) $display("[PASS] monolithic result correct");
        else begin $display("[FAIL] monolithic result wrong"); errors = errors + 1; end

        if (rv_c && res_c == 16'd100) $display("[PASS] chiplet result correct (same as monolithic)");
        else begin $display("[FAIL] chiplet result wrong"); errors = errors + 1; end

        if (!ef_m && !ef_c) $display("[PASS] no link errors in normal operation");
        else begin $display("[FAIL] unexpected link error"); errors = errors + 1; end

        if (ef_e && !rv_e) $display("[PASS] injected link error detected, corrupted result NOT delivered");
        else begin $display("[FAIL] error scenario wrong (err_flag=%b, result_valid=%b)", ef_e, rv_e); errors = errors + 1; end

        if (errors == 0) $display("SYSTEM TEST: ALL TESTS PASSED");
        else             $display("SYSTEM TEST: %0d FAILURES", errors);
        $finish;
    end
endmodule

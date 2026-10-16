`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// tb_d2d_link : self-checking test of ONE die-to-die link
//   - sends 4 packets (must arrive unchanged)
//   - sends 1 packet with an injected bit error (must be detected and dropped)
//   - sends 1 more good packet (link must recover)
//   - measures link latency and back-to-back packet interval
// -----------------------------------------------------------------------------
module tb_d2d_link;
    reg         clk = 0, rst_n = 0;
    reg  [31:0] tx_pkt = 0;
    reg         tx_valid = 0, err_inject = 0;
    wire        tx_ready, rx_valid, rx_err;
    wire [31:0] rx_pkt;

    d2d_link #(.BYPASS(0), .LAT(2)) dut (.clk(clk), .rst_n(rst_n),
        .tx_pkt(tx_pkt), .tx_valid(tx_valid), .tx_ready(tx_ready), .err_inject(err_inject),
        .rx_pkt(rx_pkt), .rx_valid(rx_valid), .rx_err(rx_err));

    always #5 clk = ~clk;                       // 100 MHz

    // ---- free running cycle counter + capture of link outputs ----
    integer cyc = 0, t_acc = 0, t_acc_prev = 0, t_rx = 0;
    reg         got_valid = 0, got_err = 0;
    reg  [31:0] got_pkt = 0;
    integer     rx_count = 0;
    always @(posedge clk) begin
        cyc <= cyc + 1;
        if (tx_valid && tx_ready) begin t_acc_prev <= t_acc; t_acc <= cyc; end
        if (rx_valid) begin rx_count <= rx_count + 1; got_valid <= 1; got_pkt <= rx_pkt; t_rx <= cyc; end
        if (rx_err)   got_err <= 1;
    end

    integer errors = 0, link_latency = 0, interval = 0, n, rx_count_before;

    task send_and_check;
        input [31:0] p;
        input        inject;
        begin
            @(negedge clk);
            while (!tx_ready) @(negedge clk);
            got_valid = 0; got_err = 0;
            tx_pkt = p; tx_valid = 1; err_inject = inject;
            @(negedge clk);
            tx_valid = 0;
            n = 0;
            while (!got_valid && !got_err && n < 40) begin @(negedge clk); n = n + 1; end
            err_inject = 0;
            if (!inject) begin
                if (got_valid && !got_err && got_pkt == p)
                    $display("[PASS] packet %h delivered intact", p);
                else begin
                    $display("[FAIL] packet %h lost or corrupted (got %h)", p, got_pkt);
                    errors = errors + 1;
                end
            end else begin
                if (got_err && !got_valid)
                    $display("[PASS] injected error in packet %h detected, packet dropped", p);
                else begin
                    $display("[FAIL] injected error NOT detected");
                    errors = errors + 1;
                end
            end
        end
    endtask

    task send_only;                              // no wait for delivery (back-to-back)
        input [31:0] p;
        begin
            @(negedge clk);
            while (!tx_ready) @(negedge clk);
            tx_pkt = p; tx_valid = 1;
            @(negedge clk);
            tx_valid = 0;
        end
    endtask

    initial begin
        $dumpfile("tb_d2d_link.vcd");
        $dumpvars(0, tb_d2d_link);
        repeat (4) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);

        send_and_check(32'hA5A55A5A, 0);
        link_latency = t_rx - t_acc;
        send_and_check(32'h00000000, 0);
        send_and_check(32'hFFFFFFFF, 0);
        send_and_check(32'h12345678, 0);

        // back-to-back burst of 3 packets to measure link throughput
        rx_count_before = rx_count;
        send_only(32'h11111111);
        send_only(32'h22222222);
        send_only(32'h33333333);
        interval = t_acc - t_acc_prev;
        repeat (30) @(negedge clk);
        if (rx_count - rx_count_before == 3) $display("[PASS] burst of 3 back-to-back packets delivered");
        else begin $display("[FAIL] burst delivered %0d of 3", rx_count - rx_count_before); errors = errors + 1; end

        send_and_check(32'hDEADBEEF, 1);        // error injection
        send_and_check(32'hCAFEF00D, 0);        // recovery after error

        $display("----------------------------------------------");
        $display("Link latency (accept -> packet out) : %0d cycles", link_latency);
        $display("Back-to-back packet interval        : %0d cycles", interval);
        if (errors == 0) $display("D2D LINK TEST: ALL TESTS PASSED");
        else             $display("D2D LINK TEST: %0d FAILURES", errors);
        $finish;
    end
endmodule

// -----------------------------------------------------------------------------
// d2d_rx : Die-to-Die receiver (de-serializer + parity checker)
// Collects 4 flits, checks parity of each flit, and outputs the 32-bit packet.
// If any flit has a parity error the packet is dropped and rx_err pulses.
// -----------------------------------------------------------------------------
module d2d_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [8:0]  flit,
    input  wire        flit_valid,
    output reg  [31:0] pkt,
    output reg         pkt_valid,
    output reg         err
);
    reg [1:0]  cnt;
    reg [23:0] sreg;
    reg        bad;
    reg        bad_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 2'd0;
            sreg      <= 24'd0;
            bad       <= 1'b0;
            pkt       <= 32'd0;
            pkt_valid <= 1'b0;
            err       <= 1'b0;
        end else begin
            pkt_valid <= 1'b0;
            err       <= 1'b0;
            if (flit_valid) begin
                bad_n = bad | ((^flit[7:0]) != flit[8]);
                if (cnt == 2'd3) begin
                    if (bad_n) err <= 1'b1;
                    else begin
                        pkt       <= {sreg, flit[7:0]};
                        pkt_valid <= 1'b1;
                    end
                    cnt <= 2'd0;
                    bad <= 1'b0;
                end else begin
                    sreg <= {sreg[15:0], flit[7:0]};
                    cnt  <= cnt + 2'd1;
                    bad  <= bad_n;
                end
            end
        end
    end
endmodule

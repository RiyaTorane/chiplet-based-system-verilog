// -----------------------------------------------------------------------------
// d2d_tx : Die-to-Die transmitter (serializer)
// Takes one 32-bit packet and sends it as 4 flits of 8 bits (+1 parity bit).
// pkt_ready is low while a packet is being sent (stop-and-wait protocol).
// err_inject (test feature) corrupts bit 0 of the first flit AFTER parity is
// calculated, so the receiver must detect a parity error.
// -----------------------------------------------------------------------------
module d2d_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pkt,
    input  wire        pkt_valid,
    output wire        pkt_ready,
    input  wire        err_inject,
    output reg  [8:0]  flit,        // {parity, data[7:0]}
    output reg         flit_valid
);
    reg        busy;
    reg [1:0]  cnt;
    reg [31:0] sreg;

    wire [7:0] cur_byte = sreg[31:24];
    wire       cur_par  = ^cur_byte;                       // even-parity bit
    wire [7:0] flip     = (err_inject && cnt == 2'd0) ? 8'h01 : 8'h00;

    assign pkt_ready = ~busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy       <= 1'b0;
            cnt        <= 2'd0;
            sreg       <= 32'd0;
            flit       <= 9'd0;
            flit_valid <= 1'b0;
        end else begin
            flit_valid <= 1'b0;
            if (!busy) begin
                if (pkt_valid) begin
                    sreg <= pkt;
                    busy <= 1'b1;
                    cnt  <= 2'd0;
                end
            end else begin
                flit       <= {cur_par, cur_byte ^ flip};
                flit_valid <= 1'b1;
                sreg       <= {sreg[23:0], 8'h00};
                cnt        <= cnt + 2'd1;
                if (cnt == 2'd3) busy <= 1'b0;
            end
        end
    end
endmodule

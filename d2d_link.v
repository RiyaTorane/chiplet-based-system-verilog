// -----------------------------------------------------------------------------
// d2d_link : one-directional die-to-die link  (TX -> PHY -> RX)
// BYPASS = 1 : direct wires, used to model a MONOLITHIC (single-die) design
// BYPASS = 0 : serialized chiplet link with LAT cycles of PHY delay
// -----------------------------------------------------------------------------
module d2d_link #(parameter BYPASS = 0, parameter LAT = 2) (
    input  wire        clk,
    input  wire        rst_n,
    // transmit side (source chiplet)
    input  wire [31:0] tx_pkt,
    input  wire        tx_valid,
    output wire        tx_ready,
    input  wire        err_inject,
    // receive side (destination chiplet)
    output wire [31:0] rx_pkt,
    output wire        rx_valid,
    output wire        rx_err
);
    generate
        if (BYPASS) begin : g_bypass
            assign tx_ready = 1'b1;
            assign rx_pkt   = tx_pkt;
            assign rx_valid = tx_valid;
            assign rx_err   = 1'b0;
        end else begin : g_link
            wire [8:0] tx_flit, ph_flit;
            wire       tx_fv,   ph_fv;

            d2d_tx u_tx (.clk(clk), .rst_n(rst_n),
                         .pkt(tx_pkt), .pkt_valid(tx_valid), .pkt_ready(tx_ready),
                         .err_inject(err_inject),
                         .flit(tx_flit), .flit_valid(tx_fv));

            d2d_phy #(.LAT(LAT)) u_phy (.clk(clk), .rst_n(rst_n),
                         .d_in(tx_flit), .v_in(tx_fv),
                         .d_out(ph_flit), .v_out(ph_fv));

            d2d_rx u_rx (.clk(clk), .rst_n(rst_n),
                         .flit(ph_flit), .flit_valid(ph_fv),
                         .pkt(rx_pkt), .pkt_valid(rx_valid), .err(rx_err));
        end
    endgenerate
endmodule

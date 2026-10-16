// -----------------------------------------------------------------------------
// chiplet_system : top level  (Compute + Memory + I/O chiplets, 3 D2D links)
//   BYPASS = 1 -> same system built as ONE die (links become plain wires)
//   BYPASS = 0 -> three chiplets connected through serialized D2D links
// -----------------------------------------------------------------------------
module chiplet_system #(parameter BYPASS = 0, parameter LAT = 2) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        inj_mem,        // test: corrupt a flit on compute->memory link
    input  wire        inj_io,         // test: corrupt a flit on compute->I/O link
    output wire        done,
    output wire [15:0] result,
    output wire        result_valid,
    output reg         err_flag        // sticky: a link parity error was detected
);
    // compute -> memory (requests)
    wire [31:0] rq_tx_pkt, rq_rx_pkt;  wire rq_tx_valid, rq_tx_ready, rq_rx_valid, rq_err;
    // memory -> compute (responses)
    wire [31:0] rs_tx_pkt, rs_rx_pkt;  wire rs_tx_valid, rs_tx_ready, rs_rx_valid, rs_err;
    // compute -> I/O
    wire [31:0] io_tx_pkt, io_rx_pkt;  wire io_tx_valid, io_tx_ready, io_rx_valid, io_err;

    compute_chiplet u_cpu (.clk(clk), .rst_n(rst_n), .start(start),
        .mem_pkt(rq_tx_pkt), .mem_valid(rq_tx_valid), .mem_ready(rq_tx_ready),
        .rsp_pkt(rs_rx_pkt), .rsp_valid(rs_rx_valid),
        .io_pkt(io_tx_pkt), .io_valid(io_tx_valid), .io_ready(io_tx_ready),
        .done(done));

    memory_chiplet u_mem (.clk(clk), .rst_n(rst_n),
        .req_pkt(rq_rx_pkt), .req_valid(rq_rx_valid),
        .rsp_pkt(rs_tx_pkt), .rsp_valid(rs_tx_valid), .rsp_ready(rs_tx_ready));

    io_chiplet u_io (.clk(clk), .rst_n(rst_n),
        .pkt(io_rx_pkt), .pkt_valid(io_rx_valid),
        .result(result), .result_valid(result_valid));

    d2d_link #(.BYPASS(BYPASS), .LAT(LAT)) u_link_req (.clk(clk), .rst_n(rst_n),
        .tx_pkt(rq_tx_pkt), .tx_valid(rq_tx_valid), .tx_ready(rq_tx_ready), .err_inject(inj_mem),
        .rx_pkt(rq_rx_pkt), .rx_valid(rq_rx_valid), .rx_err(rq_err));

    d2d_link #(.BYPASS(BYPASS), .LAT(LAT)) u_link_rsp (.clk(clk), .rst_n(rst_n),
        .tx_pkt(rs_tx_pkt), .tx_valid(rs_tx_valid), .tx_ready(rs_tx_ready), .err_inject(1'b0),
        .rx_pkt(rs_rx_pkt), .rx_valid(rs_rx_valid), .rx_err(rs_err));

    d2d_link #(.BYPASS(BYPASS), .LAT(LAT)) u_link_io (.clk(clk), .rst_n(rst_n),
        .tx_pkt(io_tx_pkt), .tx_valid(io_tx_valid), .tx_ready(io_tx_ready), .err_inject(inj_io),
        .rx_pkt(io_rx_pkt), .rx_valid(io_rx_valid), .rx_err(io_err));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                          err_flag <= 1'b0;
        else if (rq_err | rs_err | io_err)   err_flag <= 1'b1;
    end
endmodule

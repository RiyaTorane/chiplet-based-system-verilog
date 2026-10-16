// -----------------------------------------------------------------------------
// io_chiplet : receives the final result and holds it (like an output port / LEDs)
// -----------------------------------------------------------------------------
module io_chiplet (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pkt,
    input  wire        pkt_valid,
    output reg  [15:0] result,
    output reg         result_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result       <= 16'd0;
            result_valid <= 1'b0;
        end else if (pkt_valid) begin
            result       <= pkt[15:0];
            result_valid <= 1'b1;
        end
    end
endmodule

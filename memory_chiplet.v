// -----------------------------------------------------------------------------
// memory_chiplet : 16 x 16-bit RAM with packet interface
// write packet -> store data;  read packet -> send response packet back
// -----------------------------------------------------------------------------
module memory_chiplet (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] req_pkt,
    input  wire        req_valid,
    output reg  [31:0] rsp_pkt,
    output reg         rsp_valid,
    input  wire        rsp_ready
);
    reg [15:0] mem [0:15];
    integer k;

    wire       wr   = req_pkt[31];
    wire [3:0] addr = req_pkt[27:24];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < 16; k = k + 1) mem[k] <= 16'd0;
            rsp_pkt   <= 32'd0;
            rsp_valid <= 1'b0;
        end else begin
            if (rsp_valid && rsp_ready) rsp_valid <= 1'b0;
            if (req_valid) begin
                if (wr) mem[addr] <= req_pkt[15:0];
                else begin
                    rsp_pkt   <= {16'h0000, mem[addr]};
                    rsp_valid <= 1'b1;
                end
            end
        end
    end
endmodule

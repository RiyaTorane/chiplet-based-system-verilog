// -----------------------------------------------------------------------------
// compute_chiplet : small FSM that behaves like a processor / traffic source
//   1. writes 10,20,30,40 into memory chiplet locations 0..3
//   2. reads the 4 locations back (one request at a time)
//   3. adds the values (sum = 100)
//   4. sends the sum to the I/O chiplet
// Packet format (32 bit):  [31]=write  [27:24]=address  [15:0]=data
// -----------------------------------------------------------------------------
module compute_chiplet (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    // request port -> memory chiplet
    output wire [31:0] mem_pkt,
    output wire        mem_valid,
    input  wire        mem_ready,
    // response port <- memory chiplet
    input  wire [31:0] rsp_pkt,
    input  wire        rsp_valid,
    // result port -> I/O chiplet
    output wire [31:0] io_pkt,
    output wire        io_valid,
    input  wire        io_ready,
    output wire        done
);
    localparam IDLE = 3'd0, WR_SEND = 3'd1, RD_SEND = 3'd2,
               RD_WAIT = 3'd3, IO_SEND = 3'd4, DONE = 3'd5;

    reg [2:0]  st;
    reg [2:0]  i;
    reg [15:0] sum;

    wire [15:0] wdata = ({13'd0, i} + 16'd1) * 16'd10;

    assign mem_valid = (st == WR_SEND) || (st == RD_SEND);
    assign mem_pkt   = (st == WR_SEND) ? {1'b1, 3'b000, 1'b0, i, 8'h00, wdata}
                                       : {1'b0, 3'b000, 1'b0, i, 8'h00, 16'h0000};
    assign io_valid  = (st == IO_SEND);
    assign io_pkt    = {16'h0000, sum};
    assign done      = (st == DONE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st  <= IDLE;
            i   <= 3'd0;
            sum <= 16'd0;
        end else begin
            case (st)
                IDLE: if (start) begin
                          i   <= 3'd0;
                          sum <= 16'd0;
                          st  <= WR_SEND;
                      end
                WR_SEND: if (mem_ready) begin
                          if (i == 3'd3) begin i <= 3'd0; st <= RD_SEND; end
                          else           i <= i + 3'd1;
                      end
                RD_SEND: if (mem_ready) st <= RD_WAIT;
                RD_WAIT: if (rsp_valid) begin
                          sum <= sum + rsp_pkt[15:0];
                          if (i == 3'd3) st <= IO_SEND;
                          else begin i <= i + 3'd1; st <= RD_SEND; end
                      end
                IO_SEND: if (io_ready) st <= DONE;
                default: st <= DONE;
            endcase
        end
    end
endmodule

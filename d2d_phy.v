// -----------------------------------------------------------------------------
// d2d_phy : models the wire / PHY delay between two chiplets (LAT clock cycles)
// LAT must be >= 1
// -----------------------------------------------------------------------------
module d2d_phy #(parameter LAT = 2) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [8:0] d_in,
    input  wire       v_in,
    output wire [8:0] d_out,
    output wire       v_out
);
    reg  [10*LAT-1:0] pipe;                  // each stage = {valid, flit[8:0]}
    wire [9:0]        stage_in = {v_in, d_in};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pipe <= {10*LAT{1'b0}};
        else        pipe <= (pipe << 10) | stage_in;
    end

    assign {v_out, d_out} = pipe[10*LAT-1 : 10*(LAT-1)];
endmodule

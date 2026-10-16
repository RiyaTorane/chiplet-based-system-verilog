# Chiplet-Based System in Verilog (Mini Project Demo)

Compute chiplet + Memory chiplet + I/O chiplet, connected by serialized
die-to-die (D2D) links with parity checking.
`BYPASS=1` builds the same system as a single die (for comparison).

## Files
| File | Purpose |
|---|---|
| d2d_tx.v / d2d_phy.v / d2d_rx.v / d2d_link.v | Die-to-die link (serializer, wire delay, de-serializer + parity check) |
| compute_chiplet.v | FSM: write 4 values, read back, add, send result |
| memory_chiplet.v | 16 x 16-bit RAM with packet interface |
| io_chiplet.v | Result register |
| chiplet_system.v | Top level |
| tb_d2d_link.v | Self-checking test of one link (incl. error injection) |
| tb_chiplet_system.v | Compares single-die vs chiplet, tests error detection |

## Run with Icarus Verilog + GTKWave
    ./run.sh
or manually:
    iverilog -o sim_link d2d_tx.v d2d_phy.v d2d_rx.v d2d_link.v tb_d2d_link.v && vvp sim_link
    iverilog -o sim_sys *.v   (exclude tb_d2d_link.v) && vvp sim_sys
    gtkwave tb_chiplet_system.vcd

## ModelSim / Vivado
Add all .v files (design + one testbench as top), run simulation, add signals to wave.

## Expected output (predicted from a cycle-accurate model; confirm on your simulator)
    Link latency (accept -> packet out) : 8 cycles
    Back-to-back packet interval        : 5 cycles
    Monolithic : result = 100, latency = 14 cycles
    Chiplet    : result = 100, latency = 102 cycles
    ALL TESTS PASSED

## Good signals to show in GTKWave
clk, start, u_cpu.st, rq_tx_valid, u_link_req.g_link.u_tx.flit, rq_rx_valid, rs_rx_valid, result, result_valid, err_flag

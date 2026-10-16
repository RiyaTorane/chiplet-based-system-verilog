#!/bin/bash
DES="d2d_tx.v d2d_phy.v d2d_rx.v d2d_link.v compute_chiplet.v memory_chiplet.v io_chiplet.v chiplet_system.v"
iverilog -o sim_link $DES tb_d2d_link.v     && vvp sim_link
iverilog -o sim_sys  $DES tb_chiplet_system.v && vvp sim_sys
echo "Open waveforms:  gtkwave tb_chiplet_system.vcd"

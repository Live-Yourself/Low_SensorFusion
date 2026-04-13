package soc_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "apb_seq_item.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"

  `include "apb_one_shot_seq.sv"

  `include "soc_scoreboard.sv"
  `include "cov_i2c.sv"
  `include "cov_udma.sv"
  `include "soc_cov.sv"
  `include "soc_env.sv"
  `include "base_test.sv"
  `include "smoke_apb_test.sv"
  `include "tc_i2c_basic_rw.sv"
  `include "tc_i2c_repeat_start.sv"
  `include "tc_udma_basic.sv"
  `include "tc_udma_len_boundary.sv"
endpackage

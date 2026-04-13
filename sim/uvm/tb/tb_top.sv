`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import soc_uvm_pkg::*;

  logic clk_sys;
  logic clk_aon;
  logic por_n;

  logic i2c0_scl_i, i2c0_sda_i;
  logic i2c0_scl_o, i2c0_sda_o;
  logic i2c1_scl_i, i2c1_sda_i;
  logic i2c1_scl_o, i2c1_sda_o;
  logic uart_rx_i, uart_tx_o;

  logic i2c0_scl_o_d, i2c0_sda_o_d;
  logic i2c1_scl_o_d, i2c1_sda_o_d;
  logic i2c0_bus_active, i2c1_bus_active;
  logic [3:0] i2c0_bit_mod9, i2c1_bit_mod9;
  logic i2c0_slave_ack_low, i2c1_slave_ack_low;

  apb_if apb_if0(.pclk(clk_sys), .presetn(por_n));

  initial begin
    string testname;
    testname = "smoke_apb_test";
    void'($value$plusargs("UVM_TESTNAME=%s", testname));
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_if0);
    run_test(testname);
  end

  sf_soc_top dut (
    .clk_sys     (clk_sys),
    .clk_aon     (clk_aon),
    .por_n       (por_n),
    .apb_psel    (apb_if0.psel),
    .apb_penable (apb_if0.penable),
    .apb_pwrite  (apb_if0.pwrite),
    .apb_paddr   (apb_if0.paddr),
    .apb_pwdata  (apb_if0.pwdata),
    .apb_prdata  (apb_if0.prdata),
    .apb_pready  (apb_if0.pready),
    .apb_pslverr (apb_if0.pslverr),
    .i2c0_scl_i  (i2c0_scl_i),
    .i2c0_scl_o  (i2c0_scl_o),
    .i2c0_sda_i  (i2c0_sda_i),
    .i2c0_sda_o  (i2c0_sda_o),
    .i2c1_scl_i  (i2c1_scl_i),
    .i2c1_scl_o  (i2c1_scl_o),
    .i2c1_sda_i  (i2c1_sda_i),
    .i2c1_sda_o  (i2c1_sda_o),
    .uart_rx_i   (uart_rx_i),
    .uart_tx_o   (uart_tx_o)
  );

  initial begin
    clk_sys = 1'b0;
    forever #10 clk_sys = ~clk_sys;
  end

  initial begin
    clk_aon = 1'b0;
    forever #15259 clk_aon = ~clk_aon;
  end

  // Minimal I2C slave behavior for smoke/L1 tests:
  // - No clock-stretch (SCL input always high/released)
  // - Drive ACK low on each 9th bit slot while bus is active
  always_ff @(posedge clk_sys or negedge por_n) begin
    if (!por_n) begin
      i2c0_scl_o_d   <= 1'b1;
      i2c0_sda_o_d   <= 1'b1;
      i2c1_scl_o_d   <= 1'b1;
      i2c1_sda_o_d   <= 1'b1;
      i2c0_bus_active<= 1'b0;
      i2c1_bus_active<= 1'b0;
      i2c0_bit_mod9  <= 4'd0;
      i2c1_bit_mod9  <= 4'd0;
    end else begin
      // START/STOP detect on I2C0
      if (i2c0_scl_o && i2c0_sda_o_d && !i2c0_sda_o) begin
        i2c0_bus_active <= 1'b1;
        i2c0_bit_mod9   <= 4'd0;
      end else if (i2c0_scl_o && !i2c0_sda_o_d && i2c0_sda_o) begin
        i2c0_bus_active <= 1'b0;
        i2c0_bit_mod9   <= 4'd0;
      end else if (i2c0_bus_active && !i2c0_scl_o_d && i2c0_scl_o) begin
        if (i2c0_bit_mod9 == 4'd8) i2c0_bit_mod9 <= 4'd0;
        else i2c0_bit_mod9 <= i2c0_bit_mod9 + 4'd1;
      end

      // START/STOP detect on I2C1
      if (i2c1_scl_o && i2c1_sda_o_d && !i2c1_sda_o) begin
        i2c1_bus_active <= 1'b1;
        i2c1_bit_mod9   <= 4'd0;
      end else if (i2c1_scl_o && !i2c1_sda_o_d && i2c1_sda_o) begin
        i2c1_bus_active <= 1'b0;
        i2c1_bit_mod9   <= 4'd0;
      end else if (i2c1_bus_active && !i2c1_scl_o_d && i2c1_scl_o) begin
        if (i2c1_bit_mod9 == 4'd8) i2c1_bit_mod9 <= 4'd0;
        else i2c1_bit_mod9 <= i2c1_bit_mod9 + 4'd1;
      end

      i2c0_scl_o_d <= i2c0_scl_o;
      i2c0_sda_o_d <= i2c0_sda_o;
      i2c1_scl_o_d <= i2c1_scl_o;
      i2c1_sda_o_d <= i2c1_sda_o;
    end
  end

  always_comb begin
    i2c0_slave_ack_low = i2c0_bus_active && (i2c0_bit_mod9 == 4'd8);
    i2c1_slave_ack_low = i2c1_bus_active && (i2c1_bit_mod9 == 4'd8);

    if (!por_n) begin
      i2c0_scl_i = 1'b1;
      i2c0_sda_i = 1'b1;
      i2c1_scl_i = 1'b1;
      i2c1_sda_i = 1'b1;
    end else begin
      i2c0_scl_i = 1'b1;
      i2c1_scl_i = 1'b1;

      // Mirror line by default to avoid false arbitration-lost;
      // pull low in ACK slot when master releases SDA.
      i2c0_sda_i = ((i2c0_slave_ack_low) && (i2c0_sda_o == 1'b1)) ? 1'b0 : i2c0_sda_o;
      i2c1_sda_i = ((i2c1_slave_ack_low) && (i2c1_sda_o == 1'b1)) ? 1'b0 : i2c1_sda_o;
    end
  end

  initial begin
    por_n      = 1'b0;
    uart_rx_i  = 1'b1;
    apb_if0.init_master();
    repeat (5) @(posedge clk_sys);
    por_n = 1'b1;
  end

`ifdef DUMP_FSDB
  initial begin
    string fsdb_name;
    bit udma_only;
    if (!$value$plusargs("FSDB_FILE=%s", fsdb_name))
      fsdb_name = "uvm_default.fsdb";
    $fsdbDumpfile(fsdb_name);

    // Enable dumping of memory / unpacked array(MDA) objects such as:
    //   dut.u_udma.ch_src/ch_dst/ch_len/ch_cfg
    //   dut.u_udma.u_core.rem_len/src_cur/dst_cur
    $fsdbDumpMDA();

    // Optional focused dump for debug performance:
    //   +FSDB_UDMA_ONLY=1
    udma_only = 1'b0;
    void'($value$plusargs("FSDB_UDMA_ONLY=%0d", udma_only));
    if (udma_only) begin
      $fsdbDumpvars(0, tb_top.dut.u_udma);
      $fsdbDumpvars(0, tb_top.dut.u_udma.u_reg);
      $fsdbDumpvars(0, tb_top.dut.u_udma.u_core);
    end else begin
      $fsdbDumpvars(0, tb_top);
      // Explicit UDMA scopes improve visibility for some viewers/tools.
      $fsdbDumpvars(0, tb_top.dut.u_udma);
      $fsdbDumpvars(0, tb_top.dut.u_udma.u_reg);
      $fsdbDumpvars(0, tb_top.dut.u_udma.u_core);
    end
  end
`endif

endmodule

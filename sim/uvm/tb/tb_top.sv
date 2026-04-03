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

  apb_if apb_if0(.pclk(clk_sys), .presetn(por_n));
  tb_connect u_tb_connect(.apb_if0(apb_if0));

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

  initial begin
    por_n      = 1'b0;
    i2c0_scl_i = 1'b1;
    i2c0_sda_i = 1'b1;
    i2c1_scl_i = 1'b1;
    i2c1_sda_i = 1'b1;
    uart_rx_i  = 1'b1;
    apb_if0.init_master();
    repeat (5) @(posedge clk_sys);
    por_n = 1'b1;
  end

endmodule

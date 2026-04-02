module sf_i2c_top (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [11:0] paddr,
  input  logic [31:0] pwdata,
  output logic [31:0] prdata,
  output logic        pready,
  output logic        pslverr,
  input  logic        scl_i,
  output logic        scl_o,
  input  logic        sda_i,
  output logic        sda_o,
  output logic        irq
);
  logic i2c_en, dir, done, busy, nack, timeout, start_go;
  logic [1:0] speed;
  logic [6:0] slv_addr;
  logic [7:0] tx_data, rx_data, byte_cnt;

  sf_i2c_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .i2c_en, .speed, .slv_addr, .tx_data, .byte_cnt, .start_go, .dir,
    .rx_data, .done, .busy, .nack, .timeout,
    .irq
  );

  sf_i2c_core u_core (
    .clk(pclk), .rst_n(presetn), .i2c_en, .speed, .slv_addr, .tx_data, .byte_cnt,
    .start_go, .dir, .rx_data, .busy, .done, .nack, .timeout,
    .scl_i, .scl_o, .sda_i, .sda_o
  );
endmodule

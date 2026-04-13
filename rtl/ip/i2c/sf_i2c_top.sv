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
  input  logic [7:0]  tx_byte_data,
  input  logic        tx_byte_vld,
  output logic        tx_byte_req,
  output logic        rx_byte_vld,
  output logic        rx_byte_last,
  output logic [7:0]  rx_byte_data,
  output logic        irq
);
  logic i2c_en, dir, done, busy, nack, arb_lost, timeout, start_go;
  logic master_start, master_stop, repeat_start, subaddr_en;
  logic inj_nack, inj_arb_lost, inj_timeout;
  logic [1:0] speed;
  logic [6:0] slv_addr;
  logic [7:0] tx_data, subaddr, rx_data, byte_cnt;

  sf_i2c_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .i2c_en, .speed, .slv_addr, .tx_data, .subaddr, .byte_cnt, .start_go, .dir,
    .master_start, .master_stop, .repeat_start, .subaddr_en,
    .inj_nack, .inj_arb_lost, .inj_timeout,
    .rx_data, .done, .busy, .nack, .arb_lost, .timeout,
    .irq
  );

  sf_i2c_core u_core (
    .clk(pclk), .rst_n(presetn), .i2c_en, .speed, .slv_addr, .tx_data, .subaddr, .byte_cnt,
    .start_go, .dir, .master_start, .master_stop, .repeat_start, .subaddr_en,
    .inj_nack, .inj_arb_lost, .inj_timeout,
    .tx_byte_data, .tx_byte_vld, .tx_byte_req, .rx_byte_vld, .rx_byte_last, .rx_byte_data,
    .rx_data, .busy, .done, .nack, .arb_lost, .timeout,
    .scl_i, .scl_o, .sda_i, .sda_o
  );
endmodule

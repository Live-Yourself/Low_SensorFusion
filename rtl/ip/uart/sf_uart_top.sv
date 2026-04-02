module sf_uart_top (
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
  input  logic        rx_i,
  output logic        tx_o,
  output logic        irq
);
  logic uart_en, tx_start, tx_done, rx_valid;
  logic [7:0] tx_data, rx_data;

  sf_uart_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr, .uart_en, .tx_start, .tx_data,
    .rx_data, .tx_done, .rx_valid, .irq
  );

  sf_uart_core u_core (
    .clk(pclk), .rst_n(presetn), .uart_en, .tx_start, .tx_data,
    .rx_data, .tx_done, .rx_valid, .rx_i, .tx_o
  );
endmodule

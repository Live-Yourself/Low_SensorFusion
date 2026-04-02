module sf_spi_top (
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
  output logic        sclk_o,
  output logic        mosi_o,
  input  logic        miso_i,
  output logic        cs_n_o,
  output logic        irq
);
  logic spi_en, start, done;
  logic [1:0] spi_mode;
  logic [7:0] tx_data, rx_data;

  sf_spi_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .spi_en, .spi_mode, .tx_data, .start, .rx_data, .done, .irq
  );

  sf_spi_core u_core (
    .clk(pclk), .rst_n(presetn), .spi_en, .spi_mode, .tx_data, .start,
    .rx_data, .done, .sclk_o, .mosi_o, .miso_i, .cs_n_o
  );
endmodule

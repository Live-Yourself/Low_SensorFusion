module sf_gpio_top #(
  parameter int W = 16
) (
  input  logic         pclk,
  input  logic         presetn,
  input  logic         psel,
  input  logic         penable,
  input  logic         pwrite,
  input  logic [11:0]  paddr,
  input  logic [31:0]  pwdata,
  output logic [31:0]  prdata,
  output logic         pready,
  output logic         pslverr,
  input  logic [W-1:0] gpio_i,
  output logic [W-1:0] gpio_o,
  output logic [W-1:0] gpio_oe,
  output logic         irq
);
  logic [W-1:0] gpio_dir, gpio_out, gpio_sample;

  sf_gpio_reg_top #(.W(W)) u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr, .gpio_dir, .gpio_out, .gpio_in(gpio_sample), .irq
  );

  sf_gpio_core #(.W(W)) u_core (
    .gpio_dir, .gpio_out, .gpio_in(gpio_i), .gpio_o, .gpio_oe, .gpio_sample
  );
endmodule

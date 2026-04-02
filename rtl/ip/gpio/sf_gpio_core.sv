module sf_gpio_core #(
  parameter int W = 16
) (
  input  logic [W-1:0] gpio_dir,
  input  logic [W-1:0] gpio_out,
  input  logic [W-1:0] gpio_in,
  output logic [W-1:0] gpio_o,
  output logic [W-1:0] gpio_oe,
  output logic [W-1:0] gpio_sample
);
  assign gpio_o      = gpio_out;
  assign gpio_oe     = gpio_dir;
  assign gpio_sample = gpio_in;
endmodule

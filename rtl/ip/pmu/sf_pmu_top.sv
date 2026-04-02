module sf_pmu_top (
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
  input  logic wake_rtc_i,
  input  logic wake_gpio_i,
  input  logic wake_i2c0_i,
  input  logic wake_i2c1_i,
  input  logic wake_wdt_i,
  output logic [1:0] mode_o
);
  logic [1:0] mode_req, cur_mode;
  logic [4:0] wake_en, wake_cause;

  sf_pmu_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr, .mode_req, .wake_en, .cur_mode, .wake_cause
  );

  sf_pmu_core u_core (
    .clk(pclk), .rst_n(presetn), .mode_req, .wake_en,
    .wake_rtc_i, .wake_gpio_i, .wake_i2c0_i, .wake_i2c1_i, .wake_wdt_i,
    .cur_mode, .wake_cause
  );

  assign mode_o = cur_mode;
endmodule

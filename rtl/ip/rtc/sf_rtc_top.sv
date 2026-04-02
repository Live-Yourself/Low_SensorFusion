module sf_rtc_top (
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
  output logic        irq
);
  logic rtc_en, cmp_en, cmp_hit;
  logic [31:0] cmp_val, rtc_cnt;

  sf_rtc_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .rtc_en, .cmp_en, .cmp_val, .rtc_cnt, .cmp_hit, .irq
  );

  sf_rtc_core u_core (
    .clk(pclk), .rst_n(presetn), .rtc_en, .cmp_val, .rtc_cnt, .cmp_hit
  );
endmodule

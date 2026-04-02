module sf_timer_wdt_top (
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
  logic tmr_en, wdt_en, kick, tmr_irq, wdt_irq;
  logic [31:0] reload, cnt;

  sf_timer_wdt_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .tmr_en, .wdt_en, .reload, .kick,
    .cnt, .tmr_irq, .wdt_irq, .irq
  );

  sf_timer_wdt_core u_core (
    .clk(pclk), .rst_n(presetn), .tmr_en, .wdt_en, .reload, .kick,
    .cnt, .tmr_irq, .wdt_irq
  );
endmodule

module sf_fusion_top (
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
  input  logic [15:0] sample_i,
  input  logic        sample_vld,
  output logic        irq
);
  logic fus_en, event_hit;
  logic [1:0] win_sel;
  logic [15:0] threshold;
  logic [31:0] event_cnt;

  sf_fusion_reg_top u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .fus_en, .win_sel, .threshold,
    .event_hit, .event_cnt,
    .irq
  );

  sf_fusion_core u_core (
    .clk(pclk), .rst_n(presetn), .fus_en, .win_sel, .threshold,
    .sample_i, .sample_vld, .event_hit, .event_cnt
  );
endmodule

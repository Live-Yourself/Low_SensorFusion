module sf_event_intc_top #(
  parameter int N_IRQ = 32
) (
  input  logic             pclk,
  input  logic             presetn,
  input  logic             psel,
  input  logic             penable,
  input  logic             pwrite,
  input  logic [11:0]      paddr,
  input  logic [31:0]      pwdata,
  output logic [31:0]      prdata,
  output logic             pready,
  output logic             pslverr,
  input  logic [N_IRQ-1:0] irq_src,
  output logic             cpu_irq
);
  logic [N_IRQ-1:0] irq_mask, irq_pend, irq_clr;

  sf_event_intc_reg_top #(.N_IRQ(N_IRQ)) u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .irq_mask, .irq_pend, .irq_clr, .cpu_irq
  );

  sf_event_intc_core #(.N_IRQ(N_IRQ)) u_core (
    .clk(pclk), .rst_n(presetn), .irq_src, .irq_clr, .irq_pend
  );
endmodule

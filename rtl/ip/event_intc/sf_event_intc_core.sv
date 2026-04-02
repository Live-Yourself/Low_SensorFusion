module sf_event_intc_core #(
  parameter int N_IRQ = 32
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic [N_IRQ-1:0] irq_src,
  input  logic [N_IRQ-1:0] irq_clr,
  output logic [N_IRQ-1:0] irq_pend
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) irq_pend <= '0;
    else irq_pend <= (irq_pend | irq_src) & ~irq_clr;
  end
endmodule

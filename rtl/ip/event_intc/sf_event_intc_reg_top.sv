module sf_event_intc_reg_top #(
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
  output logic [N_IRQ-1:0] irq_mask,
  input  logic [N_IRQ-1:0] irq_pend,
  output logic [N_IRQ-1:0] irq_clr,
  output logic             cpu_irq
);
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign cpu_irq = |(irq_pend & ~irq_mask);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      irq_mask <= '0;
      irq_clr  <= '0;
    end else begin
      irq_clr <= '0;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: irq_mask <= pwdata[N_IRQ-1:0];
          8'h08: irq_clr  <= pwdata[N_IRQ-1:0];
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = irq_mask;
      8'h04: prdata = irq_pend;
      default: ;
    endcase
  end
endmodule

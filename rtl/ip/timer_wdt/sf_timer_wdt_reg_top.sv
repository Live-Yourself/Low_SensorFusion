module sf_timer_wdt_reg_top (
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
  output logic        tmr_en,
  output logic        wdt_en,
  output logic [31:0] reload,
  output logic        kick,
  input  logic [31:0] cnt,
  input  logic        tmr_irq,
  input  logic        wdt_irq,
  output logic        irq
);
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = tmr_irq | wdt_irq;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tmr_en <= 1'b0;
      wdt_en <= 1'b0;
      reload <= 32'h0000_FFFF;
      kick   <= 1'b0;
    end else begin
      kick <= 1'b0;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: begin tmr_en <= pwdata[0]; wdt_en <= pwdata[1]; end
          8'h04: reload <= pwdata;
          8'h08: kick <= pwdata[0];
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {30'h0, wdt_en, tmr_en};
      8'h04: prdata = reload;
      8'h0C: prdata = cnt;
      8'h10: prdata = {30'h0, wdt_irq, tmr_irq};
      default: ;
    endcase
  end
endmodule

module sf_timer_wdt_core (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tmr_en,
  input  logic        wdt_en,
  input  logic [31:0] reload,
  input  logic        kick,
  output logic [31:0] cnt,
  output logic        tmr_irq,
  output logic        wdt_irq
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 32'h0;
      tmr_irq <= 1'b0;
      wdt_irq <= 1'b0;
    end else begin
      tmr_irq <= 1'b0;
      if (tmr_en | wdt_en) begin
        cnt <= cnt + 1'b1;
        if (cnt >= reload) begin
          cnt <= 32'h0;
          if (tmr_en) tmr_irq <= 1'b1;
          if (wdt_en && !kick) wdt_irq <= 1'b1;
          if (kick) wdt_irq <= 1'b0;
        end
      end
    end
  end
endmodule

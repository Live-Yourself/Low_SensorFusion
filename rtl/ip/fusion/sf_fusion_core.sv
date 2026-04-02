module sf_fusion_core (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        fus_en,
  input  logic [1:0]  win_sel,
  input  logic [15:0] threshold,
  input  logic [15:0] sample_i,
  input  logic        sample_vld,
  output logic        event_hit,
  output logic [31:0] event_cnt
);
  logic [15:0] avg;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      avg <= '0;
      event_hit <= 1'b0;
      event_cnt <= '0;
    end else begin
      event_hit <= 1'b0;
      if (fus_en && sample_vld) begin
        avg <= (win_sel == 2'b01) ? ((avg + sample_i) >> 1) : ((3*avg + sample_i) >> 2);
        if (avg > threshold) begin
          event_hit <= 1'b1;
          event_cnt <= event_cnt + 1'b1;
        end
      end
    end
  end
endmodule

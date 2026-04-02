module sf_rtc_core (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        rtc_en,
  input  logic [31:0] cmp_val,
  output logic [31:0] rtc_cnt,
  output logic        cmp_hit
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rtc_cnt <= 32'h0;
      cmp_hit <= 1'b0;
    end else begin
      cmp_hit <= 1'b0;
      if (rtc_en) begin
        rtc_cnt <= rtc_cnt + 1'b1;
        if (rtc_cnt == cmp_val) cmp_hit <= 1'b1;
      end
    end
  end
endmodule

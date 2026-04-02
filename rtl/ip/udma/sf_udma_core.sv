module sf_udma_core #(
  parameter int N_CH = 8
) (
  input  logic clk,
  input  logic rst_n,
  input  logic udma_en,
  input  logic [N_CH-1:0] ch_en,
  input  logic [31:0] ch_len [N_CH],
  output logic [N_CH-1:0] ch_done
);
  logic [31:0] cnt [N_CH];
  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ch_done <= '0;
      for (i=0; i<N_CH; i++) cnt[i] <= '0;
    end else begin
      ch_done <= '0;
      if (udma_en) begin
        for (i=0; i<N_CH; i++) begin
          if (ch_en[i]) cnt[i] <= (ch_len[i] == 0) ? 32'd1 : ch_len[i];
          else if (cnt[i] != 0) begin
            cnt[i] <= cnt[i] - 1'b1;
            if (cnt[i] == 1) ch_done[i] <= 1'b1;
          end
        end
      end
    end
  end
endmodule

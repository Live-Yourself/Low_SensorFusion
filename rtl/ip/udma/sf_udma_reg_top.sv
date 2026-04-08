module sf_udma_reg_top #(
  parameter int N_CH = 8
) (
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
  output logic        udma_en,
  output logic [N_CH-1:0] ch_en,
  output logic [31:0] ch_len [N_CH],
  input  logic [N_CH-1:0] ch_done,
  output logic        irq
);
  integer i;
  logic [N_CH-1:0] ch_en_n;
  logic [N_CH-1:0] done_lat;
  assign pready = 1'b1;
  assign pslverr = 1'b0;
  assign irq = |done_lat;

  always_comb begin
    ch_en_n = '0;
    if (psel && penable && pwrite) begin
      for (int j = 0; j < N_CH; j++) begin
        if (paddr[11:5] == (7'h08 + j)) begin
          ch_en_n[j] = 1'b1;
        end
      end
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      udma_en <= 1'b0;
      ch_en   <= '0;
      done_lat<= '0;
      for (i=0; i<N_CH; i++) ch_len[i] <= '0;
    end else begin
      done_lat <= done_lat | ch_done;
      if (psel && penable && pwrite) begin
        if (paddr[7:0] == 8'h00) udma_en <= pwdata[0];
        for (i=0; i<N_CH; i++) begin
          if (paddr[11:5] == (7'h08 + i)) begin
            ch_len[i] <= pwdata;
            ch_en[i]  <= 1'b1;
          end
        end
        if (paddr[7:0] == 8'h04) done_lat <= done_lat & ~pwdata[N_CH-1:0];
      end
      ch_en <= ch_en_n;
    end
  end

  always_comb begin
    prdata = 32'h0;
    if (paddr[11:0] == 12'h000) prdata = {31'h0, udma_en};
    else if (paddr[11:0] == 12'h004) prdata = {{(32-N_CH){1'b0}}, done_lat};
  end
endmodule

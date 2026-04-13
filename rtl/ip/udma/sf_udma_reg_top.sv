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
  output logic [N_CH-1:0] ch_start,
  output logic [N_CH-1:0] ch_clr,
  output logic [31:0] ch_src [N_CH],
  output logic [31:0] ch_dst [N_CH],
  output logic [31:0] ch_len [N_CH],
  output logic [31:0] ch_cfg [N_CH],
  input  logic [N_CH-1:0] ch_busy,
  input  logic [N_CH-1:0] ch_done,
  input  logic [N_CH-1:0] ch_err,
  output logic        irq
);
  integer i;
  logic [N_CH-1:0] done_lat, err_lat;
  logic [N_CH-1:0] irq_en_mask;
  logic [11:0] ch_base;
  logic addr_valid;
  logic wr_ro;
  logic hit_ch;

  assign pready = 1'b1;
  assign pslverr = (psel && penable) ? (!addr_valid || wr_ro) : 1'b0;
  assign irq = |((done_lat | err_lat) & irq_en_mask);

  always_comb begin
    ch_base = paddr[11:0] & 12'hFE0;
  end

  always_comb begin
    hit_ch = 1'b0;
    for (int j=0; j<N_CH; j++) begin
      if (ch_base == (12'h100 + j*12'h20)) hit_ch = 1'b1;
    end
  end

  always_comb begin
    if ((paddr[11:0] == 12'h000) || (paddr[11:0] == 12'h004)) addr_valid = 1'b1;
    else if (hit_ch) begin
      unique case (paddr[4:0])
        5'h00, 5'h04, 5'h08, 5'h0C, 5'h10: addr_valid = 1'b1;
        default: addr_valid = 1'b0;
      endcase
    end else addr_valid = 1'b0;
  end

  always_comb begin
    wr_ro = 1'b0;
    if (pwrite && psel && penable) begin
      if (paddr[11:0] == 12'h004) wr_ro = 1'b1; // GLB_STAT is RO
    end
  end

  always_comb begin
    for (int j=0; j<N_CH; j++) irq_en_mask[j] = ch_cfg[j][3];
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      udma_en <= 1'b0;
      ch_start <= '0;
      ch_clr   <= '0;
      done_lat <= '0;
      err_lat  <= '0;
      for (i=0; i<N_CH; i++) begin
        ch_src[i] <= '0;
        ch_dst[i] <= '0;
        ch_len[i] <= '0;
        ch_cfg[i] <= '0;
      end
    end else begin
      ch_start <= '0;
      ch_clr   <= '0;
      done_lat <= done_lat | ch_done;
      err_lat  <= err_lat  | ch_err;

      if (psel && penable && pwrite && addr_valid && !wr_ro) begin
        if (paddr[11:0] == 12'h000) udma_en <= pwdata[0];

        for (i=0; i<N_CH; i++) begin
          if (ch_base == (12'h100 + i*12'h20)) begin
            case (paddr[4:0])
              5'h00: ch_src[i] <= pwdata;
              5'h04: ch_dst[i] <= pwdata;
              5'h08: ch_len[i] <= pwdata;
              5'h0C: begin
                ch_cfg[i] <= pwdata;
                if (pwdata[0]) ch_start[i] <= 1'b1;
              end
              5'h10: begin
                if (pwdata[0]) done_lat[i] <= 1'b0;
                if (pwdata[1]) err_lat[i]  <= 1'b0;
                if (pwdata[0] | pwdata[1]) ch_clr[i] <= 1'b1;
              end
              default: ;
            endcase
          end
        end
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    if (paddr[11:0] == 12'h000) prdata = {31'h0, udma_en};
    else if (paddr[11:0] == 12'h004) prdata = {31'h0, (|ch_busy)};
    else begin
      for (int j = 0; j < N_CH; j++) begin
        if (ch_base == (12'h100 + j*12'h20)) begin
          case (paddr[4:0])
            5'h00: prdata = ch_src[j];
            5'h04: prdata = ch_dst[j];
            5'h08: prdata = ch_len[j];
            5'h0C: prdata = ch_cfg[j];
            5'h10: prdata = {30'h0, err_lat[j], done_lat[j]};
            default: ;
          endcase
        end
      end
    end
  end
endmodule

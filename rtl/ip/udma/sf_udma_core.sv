module sf_udma_core #(
  parameter int N_CH = 8,
  parameter int MEM_AW = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic udma_en,
  input  logic [N_CH-1:0] ch_start,
  input  logic [N_CH-1:0] ch_clr,
  input  logic [31:0] ch_src [N_CH],
  input  logic [31:0] ch_dst [N_CH],
  input  logic [31:0] ch_len [N_CH],
  input  logic [31:0] ch_cfg [N_CH],
  // I2C0 data-stream sideband (minimal functional data plane)
  input  logic        i2c0_rx_vld,
  input  logic [7:0]  i2c0_rx_data,
  input  logic        i2c0_rx_last,
  input  logic        i2c0_tx_req,
  output logic        i2c0_tx_vld,
  output logic [7:0]  i2c0_tx_data,
  // SRAM port (single port, functional model)
  output logic        mem_en,
  output logic        mem_we,
  output logic [MEM_AW-1:0] mem_addr,
  output logic [31:0] mem_wdata,
  input  logic [31:0] mem_rdata,
  output logic [N_CH-1:0] ch_busy,
  output logic [N_CH-1:0] ch_done,
  output logic [N_CH-1:0] ch_err
);
  localparam int CH_I2C0_RX = 0;
  localparam int CH_I2C0_TX = 1;

  logic [31:0] rem_len [N_CH];
  logic [31:0] src_cur [N_CH];
  logic [31:0] dst_cur [N_CH];
  logic [31:0] rx_pack_word;
  logic [1:0]  rx_pack_cnt;

  logic [31:0] tx_word_buf;
  logic        tx_word_vld;
  logic [1:0]  tx_byte_idx;
  logic        tx_rd_pending;
  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    logic              mem_req_vld_l;
    logic              mem_req_we_l;
    logic [MEM_AW-1:0] mem_req_addr_l;
    logic [31:0]       mem_req_wdata_l;
    logic              tx_rd_grant_l;
    logic              full_word_l;
    logic              tail_word_l;
    logic              flush_word_l;

    if (!rst_n) begin
      ch_busy <= '0;
      ch_done <= '0;
      ch_err  <= '0;
      i2c0_tx_vld <= 1'b0;
      i2c0_tx_data <= 8'h00;
      mem_en <= 1'b0;
      mem_we <= 1'b0;
      mem_addr <= '0;
      mem_wdata <= '0;
      rx_pack_word <= 32'h0;
      rx_pack_cnt  <= 2'd0;
      tx_word_buf  <= 32'h0;
      tx_word_vld  <= 1'b0;
      tx_byte_idx  <= 2'd0;
      tx_rd_pending <= 1'b0;
      for (i=0; i<N_CH; i++) begin
        rem_len[i] <= '0;
        src_cur[i] <= '0;
        dst_cur[i] <= '0;
      end
    end else begin
      ch_done <= '0;
      ch_err  <= '0;
      i2c0_tx_vld <= 1'b0;
      mem_en <= 1'b0;
      mem_we <= 1'b0;
      mem_addr <= '0;
      mem_wdata <= '0;

      mem_req_vld_l   = 1'b0;
      mem_req_we_l    = 1'b0;
      mem_req_addr_l  = '0;
      mem_req_wdata_l = '0;
      tx_rd_grant_l   = 1'b0;

      if (udma_en) begin
        for (i=0; i<N_CH; i++) begin
          if (ch_clr[i]) begin
            ch_busy[i] <= 1'b0;
            rem_len[i] <= '0;
            if (i == CH_I2C0_RX) begin
              rx_pack_word <= 32'h0;
              rx_pack_cnt  <= 2'd0;
            end
            if (i == CH_I2C0_TX) begin
              tx_rd_pending <= 1'b0;
              tx_word_vld   <= 1'b0;
              tx_byte_idx   <= 2'd0;
            end
          end else if (ch_start[i] && !ch_busy[i]) begin
            src_cur[i] <= ch_src[i];
            dst_cur[i] <= ch_dst[i];
            rem_len[i] <= (ch_len[i] == 0) ? 32'd1 : ch_len[i];
            ch_busy[i] <= 1'b1;
            if (i == CH_I2C0_RX) begin
              rx_pack_word <= 32'h0;
              rx_pack_cnt  <= 2'd0;
            end
            if (i == CH_I2C0_TX) begin
              tx_rd_pending <= 1'b0;
              tx_word_vld   <= 1'b0;
              tx_byte_idx   <= 2'd0;
            end
          end
        end

        // CH0: I2C0 RX -> SRAM write
        if (ch_busy[CH_I2C0_RX]) begin
          if (i2c0_rx_vld) begin
            if (dst_cur[CH_I2C0_RX][1:0] != 2'b00) begin
              ch_err[CH_I2C0_RX]  <= 1'b1;
              ch_busy[CH_I2C0_RX] <= 1'b0;
            end else begin
              full_word_l  = (rx_pack_cnt == 2'd3);
              tail_word_l  = (i2c0_rx_last && (rx_pack_cnt != 2'd3));
              flush_word_l = full_word_l || tail_word_l;

              case (rx_pack_cnt)
                2'd0: rx_pack_word[7:0]   <= i2c0_rx_data;
                2'd1: rx_pack_word[15:8]  <= i2c0_rx_data;
                2'd2: rx_pack_word[23:16] <= i2c0_rx_data;
                default: rx_pack_word[31:24] <= i2c0_rx_data;
              endcase

              if (flush_word_l) begin
                // single-port memory request arbitration: RX write has priority
                if (!mem_req_vld_l) begin
                  mem_req_vld_l  = 1'b1;
                  mem_req_we_l   = 1'b1;
                  mem_req_addr_l = dst_cur[CH_I2C0_RX][MEM_AW+1:2];
                  case (rx_pack_cnt)
                    2'd0: mem_req_wdata_l = {24'h0, i2c0_rx_data};
                    2'd1: mem_req_wdata_l = {16'h0, i2c0_rx_data, rx_pack_word[7:0]};
                    2'd2: mem_req_wdata_l = {8'h0, i2c0_rx_data, rx_pack_word[15:0]};
                    default: mem_req_wdata_l = {i2c0_rx_data, rx_pack_word[23:0]};
                  endcase
                end

                rx_pack_cnt  <= 2'd0;
                rx_pack_word <= 32'h0;

                if (ch_cfg[CH_I2C0_RX][2]) dst_cur[CH_I2C0_RX] <= dst_cur[CH_I2C0_RX] + 32'd4;

                if (rem_len[CH_I2C0_RX] == 32'd0) begin
                  ch_err[CH_I2C0_RX]  <= 1'b1;
                  ch_busy[CH_I2C0_RX] <= 1'b0;
                end else if (tail_word_l) begin
                  // Tail packet(<4B): zero-pad and close current transfer gracefully.
                  rem_len[CH_I2C0_RX] <= 32'd0;
                  ch_done[CH_I2C0_RX] <= 1'b1;
                  ch_busy[CH_I2C0_RX] <= 1'b0;
                end else if (rem_len[CH_I2C0_RX] == 32'd1) begin
                  rem_len[CH_I2C0_RX] <= 32'd0;
                  ch_done[CH_I2C0_RX] <= 1'b1;
                  ch_busy[CH_I2C0_RX] <= 1'b0;
                end else begin
                  rem_len[CH_I2C0_RX] <= rem_len[CH_I2C0_RX] - 32'd1;
                end
              end else begin
                rx_pack_cnt <= rx_pack_cnt + 2'd1;
              end
            end
          end
        end

        // CH1: SRAM read -> I2C0 TX
        if (ch_busy[CH_I2C0_TX]) begin
          if (rem_len[CH_I2C0_TX] == 0 && !tx_rd_pending && !tx_word_vld) begin
            ch_done[CH_I2C0_TX] <= 1'b1;
            ch_busy[CH_I2C0_TX] <= 1'b0;
          end else if (tx_rd_pending) begin
            tx_word_buf  <= mem_rdata;
            tx_word_vld  <= 1'b1;
            tx_byte_idx  <= 2'd0;
            tx_rd_pending <= 1'b0;
          end else if (i2c0_tx_req) begin
            if (tx_word_vld) begin
              case (tx_byte_idx)
                2'd0: i2c0_tx_data <= tx_word_buf[7:0];
                2'd1: i2c0_tx_data <= tx_word_buf[15:8];
                2'd2: i2c0_tx_data <= tx_word_buf[23:16];
                default: i2c0_tx_data <= tx_word_buf[31:24];
              endcase
              i2c0_tx_vld <= 1'b1;

              if (tx_byte_idx == 2'd3) begin
                tx_word_vld <= 1'b0;
                tx_byte_idx <= 2'd0;
                if (ch_cfg[CH_I2C0_TX][1]) src_cur[CH_I2C0_TX] <= src_cur[CH_I2C0_TX] + 32'd4;

                if (rem_len[CH_I2C0_TX] == 32'd1) begin
                  rem_len[CH_I2C0_TX] <= 32'd0;
                  ch_done[CH_I2C0_TX] <= 1'b1;
                  ch_busy[CH_I2C0_TX] <= 1'b0;
                end else begin
                  rem_len[CH_I2C0_TX] <= rem_len[CH_I2C0_TX] - 32'd1;
                end
              end else begin
                tx_byte_idx <= tx_byte_idx + 2'd1;
              end
            end else if (src_cur[CH_I2C0_TX][1:0] != 2'b00) begin
              ch_err[CH_I2C0_TX]  <= 1'b1;
              ch_busy[CH_I2C0_TX] <= 1'b0;
            end else if (rem_len[CH_I2C0_TX] == 0) begin
              ch_done[CH_I2C0_TX] <= 1'b1;
              ch_busy[CH_I2C0_TX] <= 1'b0;
            end else begin
              // issue TX read request only when RX write does not occupy SRAM port
              if (!mem_req_vld_l) begin
                mem_req_vld_l  = 1'b1;
                mem_req_we_l   = 1'b0;
                mem_req_addr_l = src_cur[CH_I2C0_TX][MEM_AW+1:2];
                mem_req_wdata_l= 32'h0;
                tx_rd_grant_l  = 1'b1;
              end
            end
          end
        end

        // Other channels: keep a lightweight lifecycle model
        for (i=2; i<N_CH; i++) begin
          if (ch_busy[i]) begin
            if (rem_len[i] == 0) begin
              ch_done[i] <= 1'b1;
              ch_busy[i] <= 1'b0;
            end else begin
              if (ch_cfg[i][1]) src_cur[i] <= src_cur[i] + 32'd4;
              if (ch_cfg[i][2]) dst_cur[i] <= dst_cur[i] + 32'd4;
              rem_len[i] <= rem_len[i] - 32'd1;

              if ((src_cur[i][1:0] != 2'b00) || (dst_cur[i][1:0] != 2'b00)) begin
                ch_err[i]  <= 1'b1;
                ch_busy[i] <= 1'b0;
              end
            end
          end
        end
      end else begin
        ch_busy <= '0;
        rx_pack_word <= 32'h0;
        rx_pack_cnt  <= 2'd0;
        tx_word_vld  <= 1'b0;
        tx_byte_idx  <= 2'd0;
        tx_rd_pending <= 1'b0;
      end

      // single-port SRAM arbitration apply
      if (mem_req_vld_l) begin
        mem_en   <= 1'b1;
        mem_we   <= mem_req_we_l;
        mem_addr <= mem_req_addr_l;
        mem_wdata<= mem_req_wdata_l;
      end
      if (tx_rd_grant_l) begin
        tx_rd_pending <= 1'b1;
      end
    end
  end
endmodule

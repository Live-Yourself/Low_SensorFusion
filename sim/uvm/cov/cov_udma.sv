class cov_udma extends uvm_component;
  `uvm_component_utils(cov_udma)

  // CHn_SRC alignment coverage.
  // Weight = 8(ch) + 2(align) + 16(cross) = 26
  covergroup cg_udma_src with function sample(int unsigned ch_idx, bit aligned);
    option.per_instance = 1;
    cp_ch: coverpoint ch_idx { bins ch[] = {[0:7]}; }
    cp_align: coverpoint aligned { bins aligned = {1'b1}; bins misaligned = {1'b0}; }
    cx_src: cross cp_ch, cp_align;
  endgroup

  // CHn_DST alignment coverage.
  // Weight = 8(ch) + 2(align) + 16(cross) = 26
  covergroup cg_udma_dst with function sample(int unsigned ch_idx, bit aligned);
    option.per_instance = 1;
    cp_ch: coverpoint ch_idx { bins ch[] = {[0:7]}; }
    cp_align: coverpoint aligned { bins aligned = {1'b1}; bins misaligned = {1'b0}; }
    cx_dst: cross cp_ch, cp_align;
  endgroup

  // CHn_LEN coverage.
  // Weight = 8(ch) + 5(len) + 40(cross) = 53
  covergroup cg_udma_len with function sample(int unsigned ch_idx, bit [31:0] len_word);
    option.per_instance = 1;
    cp_ch: coverpoint ch_idx { bins ch[] = {[0:7]}; }
    cp_len: coverpoint len_word {
      bins zero = {32'd0};
      bins one = {32'd1};
      bins len_2_8 = {[32'd2:32'd8]};
      bins len_9_64 = {[32'd9:32'd64]};
      bins len_65_max = {[32'd65:32'hFFFF_FFFF]};
    }
    cx_udma_len: cross cp_ch, cp_len;
  endgroup

  // CHn_CFG coverage.
  // Weight = 8(ch) + 2 + 2 + 2 + 2 + 16(cfg cross) = 32
  covergroup cg_udma_cfg with function sample(int unsigned ch_idx, bit ch_en, bit inc_src, bit inc_dst, bit irq_en);
    option.per_instance = 1;
    cp_ch: coverpoint ch_idx { bins ch[] = {[0:7]}; }
    cp_ch_en: coverpoint ch_en { bins off = {0}; bins on = {1}; }
    cp_inc_src: coverpoint inc_src { bins off = {0}; bins on = {1}; }
    cp_inc_dst: coverpoint inc_dst { bins off = {0}; bins on = {1}; }
    cp_irq_en: coverpoint irq_en { bins off = {0}; bins on = {1}; }
    cx_cfg4: cross cp_ch_en, cp_inc_src, cp_inc_dst, cp_irq_en;
  endgroup

  // CHn_STAT(W1C) clear-behavior coverage.
  // Weight = 8(ch) + 2(done) + 2(err) + 4(cross) = 16
  covergroup cg_udma_stat with function sample(int unsigned ch_idx, bit done_clr, bit err_clr);
    option.per_instance = 1;
    cp_ch: coverpoint ch_idx { bins ch[] = {[0:7]}; }
    cp_done_clr: coverpoint done_clr { bins no = {0}; bins yes = {1}; }
    cp_err_clr: coverpoint err_clr { bins no = {0}; bins yes = {1}; }
    cx_stat: cross cp_done_clr, cp_err_clr;
  endgroup

  localparam logic [31:0] UDMA_BASE = 32'h4000_A000;
  localparam int unsigned BINS_UDMA_SRC  = 26;
  localparam int unsigned BINS_UDMA_DST  = 26;
  localparam int unsigned BINS_UDMA_LEN  = 53;
  localparam int unsigned BINS_UDMA_CFG  = 32;
  localparam int unsigned BINS_UDMA_STAT = 16;

  int unsigned sample_cnt;

  function new(string name = "cov_udma", uvm_component parent = null);
    super.new(name, parent);
    cg_udma_src = new();
    cg_udma_dst = new();
    cg_udma_len = new();
    cg_udma_cfg = new();
    cg_udma_stat = new();
    sample_cnt = 0;
  endfunction

  // Key collection logic:
  // 1) Decode channel template window exactly: 0x100 + n*0x20.
  // 2) Decode register slot (+0x00/+0x04/+0x08/+0x0C/+0x10), avoid false LEN hits.
  function void sample_apb(apb_seq_item tr, output bit hit);
    logic [31:0] ofs;
    logic [31:0] ch_blk_ofs;
    logic [4:0] reg_slot;
    int unsigned ch;

    hit = 1'b0;
    if (tr.pslverr || !tr.is_write) return;

    if ((tr.addr & 32'hFFFF_F000) == UDMA_BASE) begin
      ofs = tr.addr & 32'h0000_0FFF;
      if ((ofs >= 32'h100) && (ofs <= 32'h1F0)) begin
        ch_blk_ofs = ofs - 32'h100;
        ch = ch_blk_ofs >> 5;
        reg_slot = ch_blk_ofs[4:0];
        case (reg_slot)
          5'h00: begin
            cg_udma_src.sample(ch, (tr.wdata[1:0] == 2'b00));
            hit = 1'b1;
          end
          5'h04: begin
            cg_udma_dst.sample(ch, (tr.wdata[1:0] == 2'b00));
            hit = 1'b1;
          end
          5'h08: begin
            cg_udma_len.sample(ch, tr.wdata);
            hit = 1'b1;
          end
          5'h0C: begin
            cg_udma_cfg.sample(ch, tr.wdata[0], tr.wdata[1], tr.wdata[2], tr.wdata[3]);
            hit = 1'b1;
          end
          5'h10: begin
            cg_udma_stat.sample(ch, tr.wdata[0], tr.wdata[1]);
            hit = 1'b1;
          end
          default: begin
          end
        endcase
      end
    end

    if (hit) sample_cnt++;
  endfunction

  function int unsigned get_cov_weight();
    return (BINS_UDMA_SRC + BINS_UDMA_DST + BINS_UDMA_LEN + BINS_UDMA_CFG + BINS_UDMA_STAT);
  endfunction

  function int unsigned get_samples();
    return sample_cnt;
  endfunction

  function real get_cov_len();
    return cg_udma_len.get_coverage();
  endfunction

  function real get_cov_total();
    return (
      cg_udma_src.get_coverage()  * BINS_UDMA_SRC +
      cg_udma_dst.get_coverage()  * BINS_UDMA_DST +
      cg_udma_len.get_coverage()  * BINS_UDMA_LEN +
      cg_udma_cfg.get_coverage()  * BINS_UDMA_CFG +
      cg_udma_stat.get_coverage() * BINS_UDMA_STAT
    ) / get_cov_weight();
  endfunction
endclass

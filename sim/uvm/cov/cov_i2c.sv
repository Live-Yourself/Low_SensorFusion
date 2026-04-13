class cov_i2c extends uvm_component;
  `uvm_component_utils(cov_i2c)

  covergroup cg_i2c_ctrl with function sample(bit [1:0] speed, bit dir, bit repeat_start, bit subaddr_en);
    option.per_instance = 1;
    cp_speed: coverpoint speed { bins std = {2'b00}; bins fast = {2'b01}; bins fmp = {2'b10}; }
    cp_dir: coverpoint dir { bins wr = {0}; bins rd = {1}; }
    cp_rs: coverpoint repeat_start { bins off = {0}; bins on = {1}; }
    cp_sub: coverpoint subaddr_en { bins off = {0}; bins on = {1}; }
    cx_i2c_ctrl: cross cp_speed, cp_dir, cp_rs, cp_sub;
  endgroup

  covergroup cg_i2c_cmd with function sample(bit [7:0] byte_cnt);
    option.per_instance = 1;
    cp_cnt: coverpoint byte_cnt {
      bins one = {8'd1};
      bins two = {8'd2};
      bins len_3_8 = {[8'd3:8'd8]};
      bins len_9_32 = {[8'd9:8'd32]};
      bins len_33_255 = {[8'd33:8'd255]};
    }
  endgroup

  localparam logic [31:0] I2C0_BASE = 32'h4000_8000;
  localparam logic [31:0] I2C1_BASE = 32'h4000_9000;
  localparam int unsigned BINS_I2C_CTRL = 33;
  localparam int unsigned BINS_I2C_CMD  = 5;

  int unsigned sample_cnt;

  function new(string name = "cov_i2c", uvm_component parent = null);
    super.new(name, parent);
    cg_i2c_ctrl = new();
    cg_i2c_cmd  = new();
    sample_cnt  = 0;
  endfunction

  // 关键采集逻辑：仅采集合法 APB 写，且命中 I2C CTRL/CMD 地址窗口时采样
  function void sample_apb(apb_seq_item tr, output bit hit);
    logic [31:0] ofs;

    hit = 1'b0;
    if (tr.pslverr || !tr.is_write) return;

    if (((tr.addr & 32'hFFFF_F000) == I2C0_BASE) || ((tr.addr & 32'hFFFF_F000) == I2C1_BASE)) begin
      ofs = tr.addr & 32'h0000_0FFF;
      if (ofs == 32'h000) begin
        cg_i2c_ctrl.sample(tr.wdata[2:1], tr.wdata[6], tr.wdata[5], tr.wdata[7]);
        hit = 1'b1;
      end else if (ofs == 32'h010) begin
        cg_i2c_cmd.sample(tr.wdata[7:0]);
        hit = 1'b1;
      end
    end

    if (hit) sample_cnt++;
  endfunction

  function int unsigned get_cov_weight();
    return (BINS_I2C_CTRL + BINS_I2C_CMD);
  endfunction

  function int unsigned get_samples();
    return sample_cnt;
  endfunction

  function real get_cov_ctrl();
    return cg_i2c_ctrl.get_coverage();
  endfunction

  function real get_cov_cmd();
    return cg_i2c_cmd.get_coverage();
  endfunction

  function real get_cov_total();
    return (get_cov_ctrl() * BINS_I2C_CTRL + get_cov_cmd() * BINS_I2C_CMD) / get_cov_weight();
  endfunction
endclass

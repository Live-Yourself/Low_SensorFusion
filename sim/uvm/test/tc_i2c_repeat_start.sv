class tc_i2c_repeat_start extends base_test;
  `uvm_component_utils(tc_i2c_repeat_start)

  function new(string name = "tc_i2c_repeat_start", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] stat, int_stat, ctrl_rb;
    bit hit;

    phase.raise_objection(this);

    // Enable I2C DONE/ERR interrupt latch visibility and clear stale status
    apb_write32(32'h4000_8018, 32'h0000_0003);
    apb_write32(32'h4000_801C, 32'h0000_0003);

    // CTRL: en=1,start=1,stop=1,repeat=1,dir=1,subaddr_en=1
    apb_write32(32'h4000_8000, 32'h0000_00F9);
    apb_read32 (32'h4000_8000, ctrl_rb);
    if (ctrl_rb[7:0] !== 8'hF9) begin
      `uvm_error("I2C_RS", $sformatf("I2C CTRL write/read mismatch, expect=0xF9 got=0x%02h", ctrl_rb[7:0]))
      phase.drop_objection(this);
      return;
    end
    apb_write32(32'h4000_8004, 32'h0000_0050);
    apb_write32(32'h4000_8020, 32'h0000_0012); // subaddr
    apb_write32(32'h4000_8010, 32'h0000_0102);

    wait_apb_bit(32'h4000_801C, 0, 1'b1, 20000, hit);
    if (!hit) begin
      apb_read32(32'h4000_8014, stat);
      apb_read32(32'h4000_801C, int_stat);
      `uvm_error("I2C_RS", $sformatf("I2C repeat-start timeout: STAT=0x%08h INT_STAT=0x%08h", stat, int_stat))
      `uvm_error("I2C_RS", "I2C repeated-start timeout waiting DONE_INT_STAT")
      phase.drop_objection(this);
      return;
    end

    apb_read32(32'h4000_801C, int_stat);
    if (int_stat[1]) begin
      `uvm_error("I2C_RS", $sformatf("I2C repeat-start ERR_INT_STAT set, int_stat=0x%08h", int_stat))
    end

    apb_read32(32'h4000_8014, stat);
    if (stat[0] !== 1'b0) begin
      `uvm_error("I2C_RS", $sformatf("BUSY expected 0 after done, got stat=0x%08h", stat))
    end
    if (stat[4:2] != 3'b000) begin
      `uvm_error("I2C_RS", $sformatf("I2C repeat-start error flags set, stat=0x%08h", stat))
    end

    `uvm_info("I2C_RS", $sformatf("I2C STAT = 0x%08h", stat), UVM_LOW)
    apb_write32(32'h4000_801C, 32'h0000_0003);
    phase.drop_objection(this);
  endtask
endclass

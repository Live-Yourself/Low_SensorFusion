class tc_i2c_basic_rw extends base_test;
  `uvm_component_utils(tc_i2c_basic_rw)

  function new(string name = "tc_i2c_basic_rw", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] rdata, stat, int_stat, ctrl_rb;
    bit hit;

    phase.raise_objection(this);

    // Enable I2C DONE/ERR interrupt latch visibility and clear stale status
    apb_write32(32'h4000_8018, 32'h0000_0003);
    apb_write32(32'h4000_801C, 32'h0000_0003);

    // Step1: write data to slave register (subaddr + data)
    // CTRL: en=1,start=1,stop=1,repeat=0,dir=0,subaddr_en=1
    apb_write32(32'h4000_8000, 32'h0000_0099);
    apb_read32 (32'h4000_8000, ctrl_rb);
    if (ctrl_rb[7:0] !== 8'h99) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C CTRL write/read mismatch before write cmd, expect=0x99 got=0x%02h", ctrl_rb[7:0]))
      phase.drop_objection(this);
      return;
    end
    apb_write32(32'h4000_8004, 32'h0000_0050); // slave addr = 0x50
    apb_write32(32'h4000_8020, 32'h0000_000F); // subaddr = 0x0F
    apb_write32(32'h4000_8008, 32'h0000_00A5); // tx_data payload
    apb_write32(32'h4000_8010, 32'h0000_0101); // go=1, byte_cnt=1

    wait_apb_bit(32'h4000_801C, 0, 1'b1, 20000, hit);
    if (!hit) begin
      apb_read32(32'h4000_8014, stat);
      apb_read32(32'h4000_801C, int_stat);
      `uvm_error("I2C_BASIC", $sformatf("I2C write timeout: STAT=0x%08h INT_STAT=0x%08h", stat, int_stat))
      `uvm_error("I2C_BASIC", "I2C write transaction timeout waiting DONE_INT_STAT")
      phase.drop_objection(this);
      return;
    end

    apb_read32(32'h4000_801C, int_stat);
    if (int_stat[1]) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C write ERR_INT_STAT set, int_stat=0x%08h", int_stat))
    end

    apb_read32(32'h4000_8014, stat);
    if (stat[4:2] != 3'b000) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C write error flags set, stat=0x%08h", stat))
    end

    // Clear DONE/ERR latch before next command
    apb_write32(32'h4000_801C, 32'h0000_0003);

    // Step2: read data from same register (repeated-start enabled)
    // CTRL: en=1,start=1,stop=1,repeat=1,dir=1,subaddr_en=1
    apb_write32(32'h4000_8000, 32'h0000_00F9);
    apb_read32 (32'h4000_8000, ctrl_rb);
    if (ctrl_rb[7:0] !== 8'hF9) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C CTRL write/read mismatch before read cmd, expect=0xF9 got=0x%02h", ctrl_rb[7:0]))
      phase.drop_objection(this);
      return;
    end
    // subaddr keeps previous programmed value (0x0F), no need to rewrite
    apb_write32(32'h4000_8010, 32'h0000_0101);

    wait_apb_bit(32'h4000_801C, 0, 1'b1, 20000, hit);
    if (!hit) begin
      apb_read32(32'h4000_8014, stat);
      apb_read32(32'h4000_801C, int_stat);
      `uvm_error("I2C_BASIC", $sformatf("I2C read timeout: STAT=0x%08h INT_STAT=0x%08h", stat, int_stat))
      `uvm_error("I2C_BASIC", "I2C read transaction timeout waiting DONE_INT_STAT")
      phase.drop_objection(this);
      return;
    end

    apb_read32(32'h4000_801C, int_stat);
    if (int_stat[1]) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C read ERR_INT_STAT set, int_stat=0x%08h", int_stat))
    end

    apb_read32(32'h4000_8014, stat);
    if (stat[4:2] != 3'b000) begin
      `uvm_error("I2C_BASIC", $sformatf("I2C read error flags set, stat=0x%08h", stat))
    end

    apb_read32(32'h4000_800C, rdata);
    `uvm_info("I2C_BASIC", $sformatf("I2C0 RXDATA = 0x%08h", rdata), UVM_LOW)
    if (^rdata[7:0] === 1'bx) begin
      `uvm_error("I2C_BASIC", "I2C0 RXDATA contains X after write-then-read transaction")
    end

    // Final clear
    apb_write32(32'h4000_801C, 32'h0000_0003);

    phase.drop_objection(this);
  endtask
endclass

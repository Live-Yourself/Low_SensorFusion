class tc_udma_basic extends base_test;
  `uvm_component_utils(tc_udma_basic)

  function new(string name = "tc_udma_basic", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] stat;
    bit hit;

    phase.raise_objection(this);

    apb_write32(32'h4000_A000, 32'h0000_0001);
    // CH2 base: 0x4000_A140 (CH0/CH1 reserved for I2C0 RX/TX data-plane linkage)
    apb_write32(32'h4000_A140, 32'h0000_1000); // CH2_SRC
    apb_write32(32'h4000_A144, 32'h0000_2000); // CH2_DST
    apb_write32(32'h4000_A148, 32'h0000_0008); // CH2_LEN
    apb_write32(32'h4000_A14C, 32'h0000_000F); // CH2_CFG: en/inc_src/inc_dst/irq_en

    wait_apb_bit(32'h4000_A150, 0, 1'b1, 20000, hit);
    if (!hit) begin
      `uvm_error("UDMA_BASIC", "UDMA CH2 timeout waiting DONE")
    end

    apb_read32(32'h4000_A150, stat);
    `uvm_info("UDMA_BASIC", $sformatf("UDMA CH2_STAT = 0x%08h", stat), UVM_LOW)

    apb_write32(32'h4000_A150, 32'h0000_0001);
    apb_read32(32'h4000_A150, stat);
    if (stat[0] !== 1'b0) begin
      `uvm_error("UDMA_BASIC", $sformatf("UDMA CH2 DONE clear failed, stat=0x%08h", stat))
    end

    phase.drop_objection(this);
  endtask
endclass

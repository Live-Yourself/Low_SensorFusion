class smoke_apb_test extends base_test;
  `uvm_component_utils(smoke_apb_test)

  function new(string name = "smoke_apb_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] rdata;

    phase.raise_objection(this);

    // PMU MODE_REQ
    apb_write32(32'h4000_1000, 32'h0000_0000);
    apb_read32 (32'h4000_1000, rdata);
    `uvm_info("SMOKE", $sformatf("PMU PWR_MODE = 0x%08h", rdata), UVM_LOW)

    // RTC CMP
    apb_write32(32'h4000_2008, 32'h0000_0010);
    apb_read32 (32'h4000_2008, rdata);
    `uvm_info("SMOKE", $sformatf("RTC CMP = 0x%08h", rdata), UVM_LOW)

    // I2C0 ADDR
    apb_write32(32'h4000_8000, 32'h0000_0001);
    apb_write32(32'h4000_8004, 32'h0000_0050);
    apb_read32 (32'h4000_8004, rdata);
    `uvm_info("SMOKE", $sformatf("I2C0 ADDR = 0x%08h", rdata), UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass

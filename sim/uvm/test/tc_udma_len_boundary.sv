class tc_udma_len_boundary extends base_test;
  `uvm_component_utils(tc_udma_len_boundary)

  function new(string name = "tc_udma_len_boundary", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task automatic run_one_len(input logic [31:0] len);
    logic [31:0] stat;
    bit hit;

    apb_write32(32'h4000_A148, len);        // CH2_LEN
    apb_write32(32'h4000_A14C, 32'h0000_000F); // CH2_CFG start
    wait_apb_bit(32'h4000_A150, 0, 1'b1, 20000, hit);
    if (!hit) begin
      `uvm_error("UDMA_BOUND", $sformatf("timeout waiting DONE for len=%0d", len))
      return;
    end

    apb_read32(32'h4000_A150, stat);
    `uvm_info("UDMA_BOUND", $sformatf("len=%0d done_stat=0x%08h", len, stat), UVM_LOW)

    apb_write32(32'h4000_A150, 32'h0000_0001);
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    apb_write32(32'h4000_A000, 32'h0000_0001);
    apb_write32(32'h4000_A140, 32'h0000_1000); // CH2_SRC
    apb_write32(32'h4000_A144, 32'h0000_2000); // CH2_DST

    run_one_len(32'd0);
    run_one_len(32'd1);
    run_one_len(32'd16);

    phase.drop_objection(this);
  endtask
endclass

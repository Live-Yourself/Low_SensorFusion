class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  soc_env m_env;
  virtual apb_if apb_vif;
  bit m_reset_ready;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = soc_env::type_id::create("m_env", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal("NOVIF", "apb_vif not found for base_test")
    end
    m_reset_ready = 1'b0;
  endfunction

  task automatic wait_reset_release();
    if (!m_reset_ready) begin
      wait (apb_vif.presetn === 1'b1);
      @(posedge apb_vif.pclk);
      m_reset_ready = 1'b1;
    end
  endtask

  task automatic apb_write32(
    input logic [31:0] addr,
    input logic [31:0] data,
    input bit exp_pslverr = 1'b0
  );
    apb_one_shot_seq seq;
    wait_reset_release();
    seq = apb_one_shot_seq::type_id::create("seq_wr");
    seq.is_write = 1'b1;
    seq.addr     = addr;
    seq.wdata    = data;
    seq.start(m_env.m_apb_agent.sqr);
    if (seq.pslverr !== exp_pslverr) begin
      `uvm_error("APB_ACC", $sformatf("APB WRITE PSLVERR mismatch @0x%08h exp=%0b got=%0b", addr, exp_pslverr, seq.pslverr))
    end
  endtask

  task automatic apb_read32(
    input logic [31:0] addr,
    output logic [31:0] data,
    input bit exp_pslverr = 1'b0
  );
    apb_one_shot_seq seq;
    wait_reset_release();
    seq = apb_one_shot_seq::type_id::create("seq_rd");
    seq.is_write = 1'b0;
    seq.addr     = addr;
    seq.wdata    = '0;
    seq.start(m_env.m_apb_agent.sqr);
    data = seq.rdata;
    if (seq.pslverr !== exp_pslverr) begin
      `uvm_error("APB_ACC", $sformatf("APB READ PSLVERR mismatch @0x%08h exp=%0b got=%0b", addr, exp_pslverr, seq.pslverr))
    end
  endtask

  task automatic wait_apb_bit(
    input logic [31:0] addr,
    input int unsigned bit_idx,
    input logic exp,
    input int unsigned max_poll,
    output bit hit
  );
    logic [31:0] r;
    hit = 1'b0;
    for (int i = 0; i < max_poll; i++) begin
      apb_read32(addr, r);
      if (r[bit_idx] === exp) begin
        hit = 1'b1;
        break;
      end
    end
  endtask
endclass

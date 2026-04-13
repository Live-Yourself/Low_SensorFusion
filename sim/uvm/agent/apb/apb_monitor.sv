class apb_monitor extends uvm_component;
  `uvm_component_utils(apb_monitor)

  virtual apb_if apb_vif;
  uvm_analysis_port#(apb_seq_item) ap;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal("NOVIF", "apb_vif not found for apb_monitor")
    end
  endfunction

  task run_phase(uvm_phase phase);
    apb_seq_item tr;

    forever begin
      @(posedge apb_vif.pclk);
      if (apb_vif.psel && apb_vif.penable && apb_vif.pready) begin
        tr = apb_seq_item::type_id::create("tr");
        tr.is_write = apb_vif.pwrite;
        tr.addr     = apb_vif.paddr;
        tr.wdata    = apb_vif.pwdata;
        tr.rdata    = apb_vif.prdata;
        tr.pslverr  = apb_vif.pslverr;
        ap.write(tr);
      end
    end
  endtask
endclass

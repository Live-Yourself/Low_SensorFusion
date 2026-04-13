class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  virtual apb_if apb_vif;
  apb_sequencer sqr;
  apb_driver    drv;
  apb_monitor   mon;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal("NOVIF", "apb_vif not found for apb_agent")
    end

    if (is_active == UVM_ACTIVE) begin
      sqr = apb_sequencer::type_id::create("sqr", this);
      drv = apb_driver::type_id::create("drv", this);
      uvm_config_db#(virtual apb_if)::set(this, "drv", "apb_vif", apb_vif);
    end

    mon = apb_monitor::type_id::create("mon", this);
    uvm_config_db#(virtual apb_if)::set(this, "mon", "apb_vif", apb_vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass

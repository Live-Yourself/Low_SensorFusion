class apb_driver extends uvm_driver#(apb_seq_item);
  `uvm_component_utils(apb_driver)

  virtual apb_if apb_vif;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal("NOVIF", "apb_vif not found for apb_driver")
    end
  endfunction

  task run_phase(uvm_phase phase);
    apb_seq_item req;
    apb_seq_item rsp;

    forever begin
      seq_item_port.get_next_item(req);

      if (req.is_write) begin
        apb_vif.apb_write(req.addr, req.wdata);
      end else begin
        apb_vif.apb_read(req.addr, req.rdata);
      end

      rsp = apb_seq_item::type_id::create("rsp");
      rsp.copy(req);

      rsp.pslverr = apb_vif.pslverr;
      rsp.set_id_info(req);
      seq_item_port.item_done(rsp);
    end
  endtask
endclass

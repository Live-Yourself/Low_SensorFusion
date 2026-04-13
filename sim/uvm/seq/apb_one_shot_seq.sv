class apb_one_shot_seq extends uvm_sequence#(apb_seq_item);
  `uvm_object_utils(apb_one_shot_seq)

  bit          is_write;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;
  logic        pslverr;

  function new(string name = "apb_one_shot_seq");
    super.new(name);
  endfunction

  task body();
    apb_seq_item req;
    apb_seq_item rsp;

    req = apb_seq_item::type_id::create("req");
    start_item(req);
    req.is_write = is_write;
    req.addr     = addr;
    req.wdata    = wdata;
    finish_item(req);

    get_response(rsp);
    rdata = rsp.rdata;
    pslverr = rsp.pslverr;
  endtask
endclass

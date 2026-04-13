class apb_seq_item extends uvm_sequence_item;
  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int(is_write, UVM_DEFAULT)
    `uvm_field_int(addr,     UVM_DEFAULT)
    `uvm_field_int(wdata,    UVM_DEFAULT)
    `uvm_field_int(rdata,    UVM_DEFAULT)
    `uvm_field_int(pslverr,  UVM_DEFAULT)
  `uvm_object_utils_end

  rand bit          is_write;
  rand logic [31:0] addr;
  rand logic [31:0] wdata;
  logic [31:0]      rdata;
  logic             pslverr;

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction
endclass

`uvm_analysis_imp_decl(_apb)

class soc_scoreboard extends uvm_component;
  `uvm_component_utils(soc_scoreboard)

  uvm_analysis_imp_apb#(apb_seq_item, soc_scoreboard) apb_imp;
  bit check_pslverr;
  int unsigned apb_total_cnt;
  int unsigned apb_err_cnt;

  function new(string name = "soc_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    apb_imp = new("apb_imp", this);
    check_pslverr = 1'b1;
    apb_total_cnt = 0;
    apb_err_cnt   = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(bit)::get(this, "", "check_pslverr", check_pslverr));
  endfunction

  function void write_apb(apb_seq_item tr);
    apb_total_cnt++;
    if (check_pslverr && tr.pslverr) begin
      apb_err_cnt++;
      `uvm_error("APB_SCB", $sformatf("APB PSLVERR @ addr=0x%08h", tr.addr))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("APB_SCB", $sformatf("APB monitor summary: total=%0d pslverr=%0d strict=%0b", apb_total_cnt, apb_err_cnt, check_pslverr), UVM_LOW)
  endfunction
endclass

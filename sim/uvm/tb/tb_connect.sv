module tb_connect(apb_if apb_if0);
  import uvm_pkg::*;

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_if0);
    run_test("smoke_apb_test");
  end
endmodule

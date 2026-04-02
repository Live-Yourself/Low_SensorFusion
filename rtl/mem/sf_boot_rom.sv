module sf_boot_rom #(
  parameter int AW = 10
) (
  input  logic          clk,
  input  logic [AW-1:0] addr,
  output logic [31:0]   rdata
);
  logic [31:0] mem [0:(1<<AW)-1];
  initial begin
    integer i;
    for (i = 0; i < (1<<AW); i++) mem[i] = 32'h0000_0013; // NOP(ADDI x0,x0,0)
  end
  always_ff @(posedge clk) begin
    rdata <= mem[addr];
  end
endmodule

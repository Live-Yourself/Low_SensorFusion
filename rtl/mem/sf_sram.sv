module sf_sram #(
  parameter int AW = 16
) (
  input  logic          clk,
  input  logic          en,
  input  logic          we,
  input  logic [AW-1:0] addr,
  input  logic [31:0]   wdata,
  output logic [31:0]   rdata
);
  logic [31:0] mem [0:(1<<AW)-1];

  always_ff @(posedge clk) begin
    if (en) begin
      if (we) mem[addr] <= wdata;
      rdata <= mem[addr];
    end
  end
endmodule

module apb_decoder #(
  parameter int NS = 8
) (
  input  logic [31:0] paddr,
  input  logic        psel,
  output logic [NS-1:0] psel_vec
);
  integer i;
  always_comb begin
    psel_vec = '0;
    if (psel) begin
      i = paddr[15:12];
      if (i < NS) psel_vec[i] = 1'b1;
    end
  end
endmodule

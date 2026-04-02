module sf_cdc_sync (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  output logic dout
);
  logic ff1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ff1  <= 1'b0;
      dout <= 1'b0;
    end else begin
      ff1  <= din;
      dout <= ff1;
    end
  end
endmodule

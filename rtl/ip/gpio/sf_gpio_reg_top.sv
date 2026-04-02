module sf_gpio_reg_top #(
  parameter int W = 16
) (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [11:0] paddr,
  input  logic [31:0] pwdata,
  output logic [31:0] prdata,
  output logic        pready,
  output logic        pslverr,
  output logic [W-1:0] gpio_dir,
  output logic [W-1:0] gpio_out,
  input  logic [W-1:0] gpio_in,
  output logic         irq
);
  logic [W-1:0] gpio_in_d;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = |(gpio_in ^ gpio_in_d);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      gpio_dir  <= '0;
      gpio_out  <= '0;
      gpio_in_d <= '0;
    end else begin
      gpio_in_d <= gpio_in;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: gpio_dir <= pwdata[W-1:0];
          8'h04: gpio_out <= pwdata[W-1:0];
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {{(32-W){1'b0}}, gpio_dir};
      8'h04: prdata = {{(32-W){1'b0}}, gpio_out};
      8'h08: prdata = {{(32-W){1'b0}}, gpio_in};
      default: ;
    endcase
  end
endmodule

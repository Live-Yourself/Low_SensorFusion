module sf_spi_reg_top (
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
  output logic        spi_en,
  output logic [1:0]  spi_mode,
  output logic [7:0]  tx_data,
  output logic        start,
  input  logic [7:0]  rx_data,
  input  logic        done,
  output logic        irq
);
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = done;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      spi_en   <= 1'b0;
      spi_mode <= 2'b00;
      tx_data  <= '0;
      start    <= 1'b0;
    end else begin
      start <= 1'b0;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: begin spi_en <= pwdata[0]; spi_mode <= pwdata[2:1]; end
          8'h08: begin tx_data <= pwdata[7:0]; start <= 1'b1; end
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {29'h0, spi_mode, spi_en};
      8'h0C: prdata = {24'h0, rx_data};
      8'h10: prdata = {31'h0, done};
      default: ;
    endcase
  end
endmodule

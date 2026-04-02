module sf_uart_reg_top (
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
  output logic        uart_en,
  output logic        tx_start,
  output logic [7:0]  tx_data,
  input  logic [7:0]  rx_data,
  input  logic        tx_done,
  input  logic        rx_valid,
  output logic        irq
);
  logic rx_ie, tx_ie;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = (rx_ie & rx_valid) | (tx_ie & tx_done);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      uart_en   <= 1'b0;
      tx_start  <= 1'b0;
      tx_data   <= '0;
      rx_ie     <= 1'b0;
      tx_ie     <= 1'b0;
    end else begin
      tx_start <= 1'b0;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: uart_en <= pwdata[0];
          8'h08: begin tx_data <= pwdata[7:0]; tx_start <= 1'b1; end
          8'h14: begin rx_ie <= pwdata[0]; tx_ie <= pwdata[1]; end
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {31'h0, uart_en};
      8'h0C: prdata = {24'h0, rx_data};
      8'h10: prdata = {30'h0, rx_valid, tx_done};
      8'h14: prdata = {30'h0, tx_ie, rx_ie};
      default: ;
    endcase
  end
endmodule

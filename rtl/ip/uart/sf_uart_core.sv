module sf_uart_core (
  input  logic clk,
  input  logic rst_n,
  input  logic uart_en,
  input  logic tx_start,
  input  logic [7:0] tx_data,
  output logic [7:0] rx_data,
  output logic tx_done,
  output logic rx_valid,
  input  logic rx_i,
  output logic tx_o
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_done  <= 1'b0;
      rx_valid <= 1'b0;
      rx_data  <= '0;
      tx_o     <= 1'b1;
    end else begin
      tx_done  <= 1'b0;
      rx_valid <= 1'b0;
      if (uart_en && tx_start) begin
        tx_o    <= tx_data[0];
        tx_done <= 1'b1;
      end
      if (uart_en) begin
        rx_data  <= {7'h0, rx_i};
        rx_valid <= 1'b1;
      end
    end
  end
endmodule

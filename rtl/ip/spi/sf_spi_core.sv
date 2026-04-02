module sf_spi_core (
  input  logic clk,
  input  logic rst_n,
  input  logic spi_en,
  input  logic [1:0] spi_mode,
  input  logic [7:0] tx_data,
  input  logic start,
  output logic [7:0] rx_data,
  output logic done,
  output logic sclk_o,
  output logic mosi_o,
  input  logic miso_i,
  output logic cs_n_o
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data <= '0;
      done    <= 1'b0;
    end else begin
      done <= 1'b0;
      if (spi_en && start) begin
        rx_data <= tx_data ^ {7'h0, miso_i};
        done    <= 1'b1;
      end
    end
  end
  assign sclk_o = clk ^ spi_mode[0];
  assign mosi_o = tx_data[7];
  assign cs_n_o = ~(spi_en & start);
endmodule

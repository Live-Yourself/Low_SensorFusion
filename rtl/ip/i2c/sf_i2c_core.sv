module sf_i2c_core (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       i2c_en,
  input  logic [1:0] speed,
  input  logic [6:0] slv_addr,
  input  logic [7:0] tx_data,
  input  logic [7:0] byte_cnt,
  input  logic       start_go,
  input  logic       dir,
  output logic [7:0] rx_data,
  output logic       busy,
  output logic       done,
  output logic       nack,
  output logic       timeout,
  input  logic       scl_i,
  output logic       scl_o,
  input  logic       sda_i,
  output logic       sda_o
);
  logic [7:0] cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy <= 1'b0; done <= 1'b0; nack <= 1'b0; timeout <= 1'b0;
      cnt <= '0; rx_data <= '0;
    end else begin
      done <= 1'b0;
      if (start_go && i2c_en && !busy) begin
        busy <= 1'b1;
        cnt  <= (byte_cnt == 0) ? 8'd1 : byte_cnt;
      end else if (busy) begin
        if (cnt == 0) begin
          busy <= 1'b0;
          done <= 1'b1;
          rx_data <= tx_data ^ {1'b0, slv_addr};
        end else cnt <= cnt - 1'b1;
      end
    end
  end
  assign scl_o = scl_i;
  assign sda_o = dir ? 1'b1 : tx_data[0];
endmodule

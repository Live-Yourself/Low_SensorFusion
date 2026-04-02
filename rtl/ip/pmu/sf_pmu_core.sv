module sf_pmu_core (
  input  logic      clk,
  input  logic      rst_n,
  input  logic [1:0] mode_req,
  input  logic [4:0] wake_en,
  input  logic wake_rtc_i,
  input  logic wake_gpio_i,
  input  logic wake_i2c0_i,
  input  logic wake_i2c1_i,
  input  logic wake_wdt_i,
  output logic [1:0] cur_mode,
  output logic [4:0] wake_cause
);
  logic [4:0] wake_raw;
  assign wake_raw = {wake_wdt_i, wake_i2c1_i, wake_i2c0_i, wake_gpio_i, wake_rtc_i};

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur_mode   <= 2'b00;
      wake_cause <= '0;
    end else begin
      if (|(wake_en & wake_raw)) begin
        cur_mode   <= 2'b00;
        wake_cause <= wake_en & wake_raw;
      end else begin
        cur_mode <= mode_req;
      end
    end
  end
endmodule

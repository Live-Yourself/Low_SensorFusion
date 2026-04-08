module sf_i2c_reg_top (
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
  output logic        i2c_en,
  output logic [1:0]  speed,
  output logic [6:0]  slv_addr,
  output logic [7:0]  tx_data,
  output logic [7:0]  byte_cnt,
  output logic        start_go,
  output logic        dir,
  input  logic [7:0]  rx_data,
  input  logic        done,
  input  logic        busy,
  input  logic        nack,
  input  logic        timeout,
  output logic        irq
);
  logic done_ie, err_ie;
  logic done_lat, err_lat;

  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = (done_ie & done_lat) | (err_ie & err_lat);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      i2c_en   <= 1'b0;
      speed    <= 2'b00;
      slv_addr <= '0;
      tx_data  <= '0;
      byte_cnt <= '0;
      start_go <= 1'b0;
      dir      <= 1'b0;
      done_ie  <= 1'b0;
      err_ie   <= 1'b0;
      done_lat <= 1'b0;
      err_lat  <= 1'b0;
    end else begin
      start_go <= 1'b0;
      if (done) done_lat <= 1'b1;
      if (nack | timeout) err_lat <= 1'b1;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: begin i2c_en <= pwdata[0]; speed <= pwdata[2:1]; dir <= pwdata[6]; end
          8'h04: slv_addr <= pwdata[6:0];
          8'h08: tx_data <= pwdata[7:0];
          8'h10: begin byte_cnt <= pwdata[7:0]; start_go <= pwdata[8]; end
          8'h18: begin done_ie <= pwdata[0]; err_ie <= pwdata[1]; end
          8'h1C: begin if (pwdata[0]) done_lat <= 1'b0; if (pwdata[1]) err_lat <= 1'b0; end
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {25'h0, dir, 3'b0, speed, i2c_en};
      8'h04: prdata = {25'h0, slv_addr};
      8'h0C: prdata = {24'h0, rx_data};
      8'h14: prdata = {27'h0, timeout, nack, done, busy};
      8'h18: prdata = {30'h0, err_ie, done_ie};
      8'h1C: prdata = {30'h0, err_lat, done_lat};
      default: ;
    endcase
  end
endmodule

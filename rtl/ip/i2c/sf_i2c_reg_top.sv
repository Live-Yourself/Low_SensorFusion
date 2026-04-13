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
  output logic [7:0]  subaddr,
  output logic [7:0]  byte_cnt,
  output logic        start_go,
  output logic        dir,
  output logic        master_start,
  output logic        master_stop,
  output logic        repeat_start,
  output logic        subaddr_en,
  output logic        inj_nack,
  output logic        inj_arb_lost,
  output logic        inj_timeout,
  input  logic [7:0]  rx_data,
  input  logic        done,
  input  logic        busy,
  input  logic        nack,
  input  logic        arb_lost,
  input  logic        timeout,
  output logic        irq
);
  logic done_ie, err_ie;
  logic done_lat, err_lat;
  logic addr_valid;
  logic wr_ro;

  assign pready  = 1'b1;
  assign pslverr = (psel && penable) ? (!addr_valid || wr_ro) : 1'b0;
  assign irq     = (done_ie & done_lat) | (err_ie & err_lat);

  always_comb begin
    unique case (paddr[11:0])
      12'h000, 12'h004, 12'h008, 12'h00C, 12'h010, 12'h014, 12'h018, 12'h01C, 12'h020: addr_valid = 1'b1;
      default: addr_valid = 1'b0;
    endcase
  end

  always_comb begin
    wr_ro = 1'b0;
    if (pwrite && psel && penable) begin
      if ((paddr[11:0] == 12'h00C) || (paddr[11:0] == 12'h014)) wr_ro = 1'b1;
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      i2c_en   <= 1'b0;
      speed    <= 2'b00;
      slv_addr <= '0;
      tx_data  <= '0;
      subaddr  <= '0;
      byte_cnt <= '0;
      start_go <= 1'b0;
      dir      <= 1'b0;
      repeat_start <= 1'b0;
      master_start <= 1'b0;
      master_stop  <= 1'b0;
      subaddr_en   <= 1'b0;
      inj_nack     <= 1'b0;
      inj_arb_lost <= 1'b0;
      inj_timeout  <= 1'b0;
      done_ie  <= 1'b0;
      err_ie   <= 1'b0;
      done_lat <= 1'b0;
      err_lat  <= 1'b0;
    end else begin
      start_go <= 1'b0;
      inj_nack <= 1'b0;
      inj_arb_lost <= 1'b0;
      inj_timeout <= 1'b0;
      if (done) done_lat <= 1'b1;
      if (nack | arb_lost | timeout) err_lat <= 1'b1;
      if (psel && penable && pwrite && addr_valid && !wr_ro) begin
        case (paddr[11:0])
          8'h00: begin
            i2c_en       <= pwdata[0];
            speed        <= pwdata[2:1];
            master_start <= pwdata[3];
            master_stop  <= pwdata[4];
            repeat_start <= pwdata[5];
            dir          <= pwdata[6];
            subaddr_en   <= pwdata[7];
          end
          8'h04: slv_addr <= pwdata[6:0];
          8'h08: tx_data <= pwdata[7:0];
          8'h10: begin
            byte_cnt      <= pwdata[7:0];
            start_go      <= pwdata[8];
            inj_nack      <= pwdata[9];
            inj_arb_lost  <= pwdata[10];
            inj_timeout   <= pwdata[11];
          end
          8'h18: begin done_ie <= pwdata[0]; err_ie <= pwdata[1]; end
          8'h1C: begin if (pwdata[0]) done_lat <= 1'b0; if (pwdata[1]) err_lat <= 1'b0; end
          8'h20: subaddr <= pwdata[7:0];
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[11:0])
      8'h00: prdata = {24'h0, subaddr_en, dir, repeat_start, master_stop, master_start, speed, i2c_en};
      8'h04: prdata = {25'h0, slv_addr};
      8'h0C: prdata = {24'h0, rx_data};
      8'h10: prdata = {20'h0, inj_timeout, inj_arb_lost, inj_nack, start_go, byte_cnt};
      8'h14: prdata = {27'h0, timeout, arb_lost, nack, done, busy};
      8'h18: prdata = {30'h0, err_ie, done_ie};
      8'h1C: prdata = {30'h0, err_lat, done_lat};
      8'h20: prdata = {24'h0, subaddr};
      default: ;
    endcase
  end
endmodule

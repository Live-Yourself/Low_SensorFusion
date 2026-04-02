module sf_rtc_reg_top (
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
  output logic        rtc_en,
  output logic        cmp_en,
  output logic [31:0] cmp_val,
  input  logic [31:0] rtc_cnt,
  input  logic        cmp_hit,
  output logic        irq
);
  logic cmp_hit_lat;

  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = cmp_en & cmp_hit_lat;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rtc_en      <= 1'b0;
      cmp_en      <= 1'b0;
      cmp_val     <= 32'h0000_FFFF;
      cmp_hit_lat <= 1'b0;
    end else begin
      if (cmp_hit) cmp_hit_lat <= 1'b1;
      if (psel && penable && pwrite) begin
        case (paddr[7:0])
          8'h00: begin rtc_en <= pwdata[0]; cmp_en <= pwdata[1]; end
          8'h08: cmp_val <= pwdata;
          8'h0C: if (pwdata[0]) cmp_hit_lat <= 1'b0;
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {30'h0, cmp_en, rtc_en};
      8'h04: prdata = rtc_cnt;
      8'h08: prdata = cmp_val;
      8'h0C: prdata = {31'h0, cmp_hit_lat};
      default: ;
    endcase
  end
endmodule

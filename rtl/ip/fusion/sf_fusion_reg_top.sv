module sf_fusion_reg_top (
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
  output logic        fus_en,
  output logic [1:0]  win_sel,
  output logic [15:0] threshold,
  input  logic        event_hit,
  input  logic [31:0] event_cnt,
  output logic        irq
);
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = event_hit;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      fus_en     <= 1'b0;
      win_sel    <= 2'b00;
      threshold  <= 16'h0100;
    end else if (psel && penable && pwrite) begin
      case (paddr[7:0])
        8'h00: begin fus_en <= pwdata[0]; win_sel <= pwdata[2:1]; end
        8'h04: threshold <= pwdata[15:0];
        default: ;
      endcase
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {29'h0, win_sel, fus_en};
      8'h04: prdata = {16'h0, threshold};
      8'h08: prdata = {31'h0, event_hit};
      8'h0C: prdata = event_cnt;
      default: ;
    endcase
  end
endmodule

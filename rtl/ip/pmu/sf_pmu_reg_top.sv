module sf_pmu_reg_top (
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
  output logic [1:0]  mode_req,
  output logic [4:0]  wake_en,
  input  logic [1:0]  cur_mode,
  input  logic [4:0]  wake_cause
);
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      mode_req <= 2'b00;
      wake_en  <= 5'b00001;
    end else if (psel && penable && pwrite) begin
      case (paddr[7:0])
        8'h00: mode_req <= pwdata[1:0];
        8'h04: wake_en  <= pwdata[4:0];
        default: ;
      endcase
    end
  end

  always_comb begin
    prdata = 32'h0;
    case (paddr[7:0])
      8'h00: prdata = {30'h0, mode_req};
      8'h04: prdata = {27'h0, wake_en};
      8'h08: prdata = {30'h0, cur_mode};
      8'h0C: prdata = {27'h0, wake_cause};
      default: ;
    endcase
  end
endmodule

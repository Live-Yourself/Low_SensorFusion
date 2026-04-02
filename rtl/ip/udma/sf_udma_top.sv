module sf_udma_top #(
  parameter int N_CH = 8
) (
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
  output logic        irq
);
  logic udma_en;
  logic [N_CH-1:0] ch_en, ch_done;
  logic [31:0] ch_len [N_CH];

  sf_udma_reg_top #(.N_CH(N_CH)) u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .udma_en, .ch_en, .ch_len, .ch_done, .irq
  );

  sf_udma_core #(.N_CH(N_CH)) u_core (
    .clk(pclk), .rst_n(presetn), .udma_en, .ch_en, .ch_len, .ch_done
  );
endmodule

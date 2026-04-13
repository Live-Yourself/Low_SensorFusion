module sf_udma_top #(
  parameter int N_CH = 8,
  parameter int MEM_AW = 16
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
  input  logic        i2c0_rx_vld,
  input  logic [7:0]  i2c0_rx_data,
  input  logic        i2c0_rx_last,
  input  logic        i2c0_tx_req,
  output logic        i2c0_tx_vld,
  output logic [7:0]  i2c0_tx_data,
  output logic        irq
);
  logic udma_en;
  logic [N_CH-1:0] ch_start, ch_clr;
  logic [N_CH-1:0] ch_busy, ch_done, ch_err;
  logic [31:0] ch_src [N_CH];
  logic [31:0] ch_dst [N_CH];
  logic [31:0] ch_len [N_CH];
  logic [31:0] ch_cfg [N_CH];
  logic        mem_en, mem_we;
  logic [MEM_AW-1:0] mem_addr;
  logic [31:0] mem_wdata, mem_rdata;

  sf_udma_reg_top #(.N_CH(N_CH)) u_reg (
    .pclk, .presetn, .psel, .penable, .pwrite, .paddr, .pwdata,
    .prdata, .pready, .pslverr,
    .udma_en, .ch_start, .ch_clr, .ch_src, .ch_dst, .ch_len, .ch_cfg,
    .ch_busy, .ch_done, .ch_err, .irq
  );

  sf_udma_core #(.N_CH(N_CH), .MEM_AW(MEM_AW)) u_core (
    .clk(pclk), .rst_n(presetn), .udma_en,
    .ch_start, .ch_clr, .ch_src, .ch_dst, .ch_len, .ch_cfg,
    .i2c0_rx_vld, .i2c0_rx_data, .i2c0_rx_last, .i2c0_tx_req, .i2c0_tx_vld, .i2c0_tx_data,
    .mem_en, .mem_we, .mem_addr, .mem_wdata, .mem_rdata,
    .ch_busy, .ch_done, .ch_err
  );

  sf_sram #(.AW(MEM_AW)) u_dma_sram (
    .clk  (pclk),
    .en   (mem_en),
    .we   (mem_we),
    .addr (mem_addr),
    .wdata(mem_wdata),
    .rdata(mem_rdata)
  );
endmodule

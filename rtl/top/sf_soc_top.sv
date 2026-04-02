`include "sf_defs.svh"

module sf_soc_top (
  input  logic        clk_sys,
  input  logic        clk_aon,
  input  logic        por_n,
  input  logic        apb_psel,
  input  logic        apb_penable,
  input  logic        apb_pwrite,
  input  logic [31:0] apb_paddr,
  input  logic [31:0] apb_pwdata,
  output logic [31:0] apb_prdata,
  output logic        apb_pready,
  output logic        apb_pslverr,
  input  logic        i2c0_scl_i,
  output logic        i2c0_scl_o,
  input  logic        i2c0_sda_i,
  output logic        i2c0_sda_o,
  input  logic        i2c1_scl_i,
  output logic        i2c1_scl_o,
  input  logic        i2c1_sda_i,
  output logic        i2c1_sda_o,
  input  logic        uart_rx_i,
  output logic        uart_tx_o
);
  localparam int APB_NS = 13;

  logic sys_rst_n;
  logic [APB_NS-1:0] apb_psel_vec;

  logic [31:0] pmu_prdata, rtc_prdata, gpio_prdata, timer_prdata;
  logic [31:0] uart_prdata, spi_prdata, i2c0_prdata, i2c1_prdata;
  logic [31:0] udma_prdata, intc_prdata, fusion_prdata;

  logic pmu_pready, rtc_pready, gpio_pready, timer_pready;
  logic uart_pready, spi_pready, i2c0_pready, i2c1_pready;
  logic udma_pready, intc_pready, fusion_pready;

  logic pmu_pslverr, rtc_pslverr, gpio_pslverr, timer_pslverr;
  logic uart_pslverr, spi_pslverr, i2c0_pslverr, i2c1_pslverr;
  logic udma_pslverr, intc_pslverr, fusion_pslverr;

  logic i2c0_irq, i2c1_irq, rtc_irq, uart_irq, spi_irq;
  logic gpio_irq, timer_wdt_irq, udma_irq, cpu_irq, fusion_irq;

  logic [15:0] gpio_i, gpio_o, gpio_oe;
  logic spi_sclk_o, spi_mosi_o, spi_cs_n_o;
  logic [1:0] pmu_mode;
  logic [31:0] irq_src;

  logic [31:0] prdata_mux;
  logic pready_mux;
  logic pslverr_mux;

  logic [1:0] pmu_mode;

  sf_rst_sync u_reset_sync (
    .clk      (clk_sys),
    .rst_n_in (por_n),
    .rst_n_out(sys_rst_n)
  );

  apb_decoder #(.NS(APB_NS)) u_apb_decoder (
    .paddr    (apb_paddr),
    .psel     (apb_psel),
    .psel_vec (apb_psel_vec)
  );

  sf_pmu_top u_pmu (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[1]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (pmu_prdata), .pready(pmu_pready), .pslverr(pmu_pslverr),
    .wake_rtc_i(rtc_irq), .wake_gpio_i(gpio_irq), .wake_i2c0_i(i2c0_irq), .wake_i2c1_i(i2c1_irq), .wake_wdt_i(timer_wdt_irq),
    .mode_o(pmu_mode)
  );

  sf_rtc_top u_rtc (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[2]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (rtc_prdata), .pready(rtc_pready), .pslverr(rtc_pslverr),
    .irq     (rtc_irq)
  );

  sf_gpio_top #(.W(16)) u_gpio (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[3]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (gpio_prdata), .pready(gpio_pready), .pslverr(gpio_pslverr),
    .gpio_i  (gpio_i), .gpio_o(gpio_o), .gpio_oe(gpio_oe), .irq(gpio_irq)
  );

  sf_timer_wdt_top u_timer_wdt (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[4]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (timer_prdata), .pready(timer_pready), .pslverr(timer_pslverr),
    .irq     (timer_wdt_irq)
  );

  sf_uart_top u_uart (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[6]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (uart_prdata), .pready(uart_pready), .pslverr(uart_pslverr),
    .rx_i    (uart_rx_i), .tx_o(uart_tx_o), .irq(uart_irq)
  );

  sf_spi_top u_spi (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[7]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (spi_prdata), .pready(spi_pready), .pslverr(spi_pslverr),
    .sclk_o  (spi_sclk_o), .mosi_o(spi_mosi_o), .miso_i(1'b0), .cs_n_o(spi_cs_n_o), .irq(spi_irq)
  );

  sf_i2c_top u_i2c0 (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[8]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (i2c0_prdata), .pready(i2c0_pready), .pslverr(i2c0_pslverr),
    .scl_i(i2c0_scl_i), .scl_o(i2c0_scl_o), .sda_i(i2c0_sda_i), .sda_o(i2c0_sda_o),
    .irq(i2c0_irq)
  );

  sf_i2c_top u_i2c1 (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[9]), .penable(apb_penable),
    .pwrite  (apb_pwrite),      .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (i2c1_prdata), .pready(i2c1_pready), .pslverr(i2c1_pslverr),
    .scl_i(i2c1_scl_i), .scl_o(i2c1_scl_o), .sda_i(i2c1_sda_i), .sda_o(i2c1_sda_o),
    .irq(i2c1_irq)
  );

  sf_udma_top #(.N_CH(8)) u_udma (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[10]), .penable(apb_penable),
    .pwrite  (apb_pwrite),       .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (udma_prdata), .pready(udma_pready), .pslverr(udma_pslverr),
    .irq     (udma_irq)
  );

  sf_event_intc_top #(.N_IRQ(32)) u_intc (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[11]), .penable(apb_penable),
    .pwrite  (apb_pwrite),       .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (intc_prdata), .pready(intc_pready), .pslverr(intc_pslverr),
    .irq_src (irq_src), .cpu_irq(cpu_irq)
  );

  sf_fusion_top u_fusion (
    .pclk    (clk_sys), .presetn(sys_rst_n),
    .psel    (apb_psel_vec[12]), .penable(apb_penable),
    .pwrite  (apb_pwrite),       .paddr  (apb_paddr[11:0]), .pwdata(apb_pwdata),
    .prdata  (fusion_prdata), .pready(fusion_pready), .pslverr(fusion_pslverr),
    .sample_i(16'h0000), .sample_vld(1'b0), .irq(fusion_irq)
  );

  always_comb begin
    prdata_mux  = 32'h0;
    pready_mux  = 1'b1;
    pslverr_mux = 1'b0;
    unique case (1'b1)
      apb_psel_vec[1]:  begin prdata_mux = pmu_prdata;    pready_mux = pmu_pready;    pslverr_mux = pmu_pslverr;    end
      apb_psel_vec[2]:  begin prdata_mux = rtc_prdata;    pready_mux = rtc_pready;    pslverr_mux = rtc_pslverr;    end
      apb_psel_vec[3]:  begin prdata_mux = gpio_prdata;   pready_mux = gpio_pready;   pslverr_mux = gpio_pslverr;   end
      apb_psel_vec[4]:  begin prdata_mux = timer_prdata;  pready_mux = timer_pready;  pslverr_mux = timer_pslverr;  end
      apb_psel_vec[6]:  begin prdata_mux = uart_prdata;   pready_mux = uart_pready;   pslverr_mux = uart_pslverr;   end
      apb_psel_vec[7]:  begin prdata_mux = spi_prdata;    pready_mux = spi_pready;    pslverr_mux = spi_pslverr;    end
      apb_psel_vec[8]:  begin prdata_mux = i2c0_prdata;   pready_mux = i2c0_pready;   pslverr_mux = i2c0_pslverr;   end
      apb_psel_vec[9]:  begin prdata_mux = i2c1_prdata;   pready_mux = i2c1_pready;   pslverr_mux = i2c1_pslverr;   end
      apb_psel_vec[10]: begin prdata_mux = udma_prdata;   pready_mux = udma_pready;   pslverr_mux = udma_pslverr;   end
      apb_psel_vec[11]: begin prdata_mux = intc_prdata;   pready_mux = intc_pready;   pslverr_mux = intc_pslverr;   end
      apb_psel_vec[12]: begin prdata_mux = fusion_prdata; pready_mux = fusion_pready; pslverr_mux = fusion_pslverr; end
      default: ;
    endcase
  end

  assign apb_prdata  = prdata_mux;
  assign apb_pready  = pready_mux;
  assign apb_pslverr = pslverr_mux;

  assign gpio_i = '0;
  assign irq_src = {
    22'h0,
    fusion_irq,
    udma_irq,
    i2c1_irq,
    i2c0_irq,
    spi_irq,
    uart_irq,
    timer_wdt_irq,
    gpio_irq,
    rtc_irq
  };

  logic unused_clk_aon;
  logic unused_cpu_irq;
  logic [1:0] unused_pmu_mode;
  logic [15:0] unused_gpio_o, unused_gpio_oe;
  logic unused_spi_sclk_o, unused_spi_mosi_o, unused_spi_cs_n_o;

  assign unused_clk_aon   = clk_aon;
  assign unused_cpu_irq   = cpu_irq;
  assign unused_pmu_mode  = pmu_mode;
  assign unused_gpio_o    = gpio_o;
  assign unused_gpio_oe   = gpio_oe;
  assign unused_spi_sclk_o= spi_sclk_o;
  assign unused_spi_mosi_o= spi_mosi_o;
  assign unused_spi_cs_n_o= spi_cs_n_o;
endmodule

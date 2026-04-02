package sf_soc_pkg;
  localparam logic [31:0] APB_BASE       = 32'h4000_0000;
  localparam logic [31:0] SYSCTRL_BASE   = 32'h4000_0000;
  localparam logic [31:0] PMU_BASE       = 32'h4000_1000;
  localparam logic [31:0] RTC_BASE       = 32'h4000_2000;
  localparam logic [31:0] GPIO_BASE      = 32'h4000_3000;
  localparam logic [31:0] TIMER_WDT_BASE = 32'h4000_4000;
  localparam logic [31:0] UART0_BASE     = 32'h4000_6000;
  localparam logic [31:0] SPI0_BASE      = 32'h4000_7000;
  localparam logic [31:0] I2C0_BASE      = 32'h4000_8000;
  localparam logic [31:0] I2C1_BASE      = 32'h4000_9000;
  localparam logic [31:0] UDMA_BASE      = 32'h4000_A000;
  localparam logic [31:0] INTC_BASE      = 32'h4000_B000;
  localparam logic [31:0] FUSION_BASE    = 32'h4000_C000;

  localparam int APB_NSLAVES = 10;
endpackage

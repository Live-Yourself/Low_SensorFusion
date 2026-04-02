# RTL 目录框架与文件说明（UVM-SFSoC-v1）

本文档用于说明当前 `rtl/` 目录及其子目录中各文件的含义与作用，便于后续开发、验证与维护。

---

## 1. 顶层目录说明

- `rtl/top/`：SoC 顶层与全局参数定义。
- `rtl/common/`：通用模块与公共宏定义。
- `rtl/bus/`：总线桥接与地址解码。
- `rtl/mem/`：片上存储模型（ROM/SRAM）。
- `rtl/ip/`：各外设 IP 实现，每个 IP 采用统一四文件结构：
  - `*_pkg.sv`：参数/类型定义
  - `*_reg_top.sv`：寄存器与APB接口层
  - `*_core.sv`：核心功能逻辑
  - `*_top.sv`：封装与连接层

---

## 2. rtl/top

### 2.1 `sf_soc_top.sv`
SoC 顶层集成文件，作用：
- 提供统一 APB 接口（`apb_psel/penable/pwrite/paddr/pwdata`）。
- 使用 `apb_decoder` 进行外设片选。
- 例化 PMU/RTC/GPIO/TIMER_WDT/UART/SPI/I2C0/I2C1/UDMA/INTC/FUSION。
- 通过读回 mux 输出 `apb_prdata`，并选择 `apb_pready/apb_pslverr`。
- 汇总中断源到 `event_intc`。

### 2.2 `sf_soc_pkg.sv`
SoC 全局地址映射与常量定义，例如 APB 各外设 base 地址。

---

## 3. rtl/common

### 3.1 `sf_defs.svh`
全局宏定义，如功耗模式宏、APB 响应宏等。

### 3.2 `sf_rst_sync.sv`
异步复位同步释放模块，避免复位释放亚稳态问题。

### 3.3 `sf_cdc_sync.sv`
单比特跨时钟域同步模块（两级触发器结构）。

---

## 4. rtl/bus

### 4.1 `apb_decoder.sv`
根据 APB 地址切片产生 one-hot 片选向量（`psel_vec`）。

### 4.2 `ahb2apb_bridge.sv`
AHB 到 APB 的简化桥接模块，用于后续CPU总线接入。

---

## 5. rtl/mem

### 5.1 `sf_boot_rom.sv`
Boot ROM 行为模型，提供启动指令/默认内容。

### 5.2 `sf_sram.sv`
SRAM 行为模型，支持基础读写与使能控制。

---

## 6. rtl/ip（各IP目录）

## 6.1 `ip/i2c/`
- `sf_i2c_pkg.sv`：I2C 速率枚举定义。
- `sf_i2c_reg_top.sv`：I2C APB寄存器层（控制、状态、中断）。
- `sf_i2c_core.sv`：I2C 核心状态行为模型。
- `sf_i2c_top.sv`：寄存器层与核心层连接封装。

## 6.2 `ip/udma/`
- `sf_udma_pkg.sv`：通道数等参数定义。
- `sf_udma_reg_top.sv`：UDMA 通道配置与状态寄存器层。
- `sf_udma_core.sv`：通道计数/完成事件核心逻辑。
- `sf_udma_top.sv`：UDMA 封装顶层。

## 6.3 `ip/pmu/`
- `sf_pmu_pkg.sv`：PMU 模式类型定义。
- `sf_pmu_reg_top.sv`：功耗模式与唤醒寄存器层。
- `sf_pmu_core.sv`：模式切换与唤醒原因生成。
- `sf_pmu_top.sv`：PMU 封装顶层。

## 6.4 `ip/rtc/`
- `sf_rtc_pkg.sv`：RTC 默认比较值等定义。
- `sf_rtc_reg_top.sv`：RTC 控制/计数/比较寄存器层。
- `sf_rtc_core.sv`：计数与比较命中逻辑。
- `sf_rtc_top.sv`：RTC 封装顶层。

## 6.5 `ip/uart/`
- `sf_uart_pkg.sv`：UART 参数定义。
- `sf_uart_reg_top.sv`：UART APB 寄存器层。
- `sf_uart_core.sv`：UART 收发行为核心。
- `sf_uart_top.sv`：UART 封装顶层。

## 6.6 `ip/spi/`
- `sf_spi_pkg.sv`：SPI 模式枚举定义。
- `sf_spi_reg_top.sv`：SPI 控制/状态寄存器层。
- `sf_spi_core.sv`：SPI 收发核心行为。
- `sf_spi_top.sv`：SPI 封装顶层。

## 6.7 `ip/gpio/`
- `sf_gpio_pkg.sv`：GPIO 位宽参数。
- `sf_gpio_reg_top.sv`：GPIO 方向/输出/输入寄存器层。
- `sf_gpio_core.sv`：GPIO 引脚方向与数据路径。
- `sf_gpio_top.sv`：GPIO 封装顶层。

## 6.8 `ip/timer_wdt/`
- `sf_timer_wdt_pkg.sv`：默认重载值定义。
- `sf_timer_wdt_reg_top.sv`：Timer/WDT APB 寄存器层。
- `sf_timer_wdt_core.sv`：计数、超时与kick逻辑。
- `sf_timer_wdt_top.sv`：Timer/WDT 封装顶层。

## 6.9 `ip/event_intc/`
- `sf_event_intc_pkg.sv`：中断路数参数定义。
- `sf_event_intc_reg_top.sv`：屏蔽/挂起/清除寄存器层。
- `sf_event_intc_core.sv`：中断挂起与清除核心。
- `sf_event_intc_top.sv`：中断控制器封装顶层。

## 6.10 `ip/fusion/`
- `sf_fusion_pkg.sv`：窗口类型定义。
- `sf_fusion_reg_top.sv`：融合配置/阈值/统计寄存器层。
- `sf_fusion_core.sv`：滑动平均与阈值事件检测。
- `sf_fusion_top.sv`：融合单元封装顶层。

---

## 7. 当前建议

- 继续为 `sf_soc_top.sv` 增加 APB 主机驱动 testbench（或最小CPU桩），打通端到端寄存器读写。
- 后续补充 `sysctrl` 占位模块，使地址 `0x4000_0000` 具备可访问寄存器行为。
- 增加顶层 filelist 文档，固定编译顺序与依赖关系。

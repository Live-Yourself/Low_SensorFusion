# SoC 顶层规格说明书（UVM-SFSoC-v1）

## 1. 文档目的
定义低功耗传感器融合 SoC（UVM-SFSoC-v1）的顶层架构、接口、时钟复位、低功耗、存储映射与中断机制，作为 RTL、验证、综合与形式验证的统一基线。

---

## 2. 设计目标与范围

### 2.1 目标
- 面向可穿戴/工业监测/智能家居传感端场景。
- 支持双路 I2C 传感器采集与低功耗自治搬运。
- 提供可验证、可综合、可扩展的小型 MCU SoC。

### 2.2 v1 范围
- CPU：RV32IMC，单核。
- 总线：AHB-Lite（主干）+ APB（外设）。
- 外设：I2Cx2、SPIx1、UARTx1、GPIO、TIMER、WDT、RTC、uDMA。
- 低功耗：RUN/SLEEP/DEEP-SLEEP，AON + SYS 域。
- 轻量融合：滑动平均与阈值检测。

### 2.3 v1 不包含
- Cache/MMU、复杂安全启动链、I2C Slave 模式、复杂 QoS 仲裁。

---

## 3. 顶层模块框图（文字版）
- 计算子系统：`cpu_subsys`、`rom_ctrl`、`sram_ctrl`
- 互连子系统：`ahb_matrix_lite`、`apb_bridge`
- 外设子系统：`i2c0`、`i2c1`、`spi0`、`uart0`、`gpio`、`timer0`、`wdt`、`rtc`
- 数据搬运：`udma_top`（I2C/SPI/UART 通道）
- 电源时钟：`pmu_ctrl`、`clk_rst_mgr`
- 事件中断：`event_intc`
- 轻量融合：`fusion_preproc`

---

## 4. 总线与地址架构

### 4.1 AHB-Lite 主设备
- M0：CPU 指令/数据访问
- M1：uDMA 内存写读访问

### 4.2 AHB-Lite 从设备
- S0：Boot ROM
- S1：SRAM
- S2：AHB2APB Bridge

### 4.3 APB 从设备
- SYSCTRL、PMU、RTC、GPIO、TIMER、WDT、UART、SPI、I2C0、I2C1、UDMA、EVT、FUSION

---

## 5. 时钟与复位

### 5.1 时钟源
- `clk_sys`：系统主时钟（默认 50MHz，可配置到 100MHz）
- `clk_aon`：AON 时钟（默认 32.768kHz）
- `clk_i2c`：I2C 分频时钟（由 `clk_sys` 派生）

### 5.2 复位
- `por_n`：上电复位（全局）
- `sys_rst_n`：系统域复位（PMU 可控）
- `aon_rst_n`：AON 域复位（仅 POR 触发）

### 5.3 复位策略
- POR 后，CPU 从 Boot ROM 启动。
- APB 外设默认复位值由寄存器规范定义。
- DEEP-SLEEP 唤醒后，保留区 SRAM 不清零，非保留区可选清零。

---

## 6. 电源域与低功耗机制

### 6.1 电源域
- AON 域：RTC、PMU、唤醒逻辑、少量寄存器保留。
- SYS 域：CPU、主 SRAM、大部分外设。

### 6.2 模式定义
- RUN：全速运行。
- SLEEP：CPU 停钟，外设可按配置继续工作。
- DEEP-SLEEP：SYS 域下电或停钟，仅 AON 保持。

### 6.3 唤醒源
- RTC 比较匹配
- GPIO 边沿
- I2C 传输完成事件（若配置可唤醒）
- WDT 超时

### 6.4 模式切换时序约束
- 进入低功耗前需完成 AHB/APB 空闲握手。
- uDMA 活动通道需根据策略：阻塞进入或保存上下文后暂停。

---

## 7. 存储子系统

### 7.1 Boot ROM
- 容量：32KB
- 功能：启动向量、基础初始化、跳转到 SRAM/外部存储映像

### 7.2 SRAM
- 容量：256KB
- 分区建议：
  - 128KB 程序/数据
  - 96KB DMA 环形缓冲
  - 32KB retention bank（低功耗保留）

### 7.3 对齐与访问规则
- AHB 访问支持 8/16/32bit。
- DMA 传输长度单位为 byte，建议 4-byte 对齐以获得最佳吞吐。

---

## 8. 外设功能摘要

### 8.1 I2C Master（x2）
- 速率：100k/400k/1MHz
- 地址：7-bit
- 操作：START/STOP/repeated-start，读写，ACK/NACK 检测，时钟拉伸超时

### 8.2 SPI Master（x1）
- 模式：Mode0~3
- 数据宽度：8bit（v1）
- 用途：外部 Flash 或高速外设

### 8.3 UART（x1）
- 可配置波特率
- TX/RX FIFO
- 中断：RX 可用、TX 空、错误状态

### 8.4 uDMA
- 通道：I2C0 RX/TX、I2C1 RX/TX、SPI0 RX/TX、UART0 RX/TX
- 描述符：源/目的地址、长度、触发方式、完成中断

### 8.5 fusion_preproc
- 输入：DMA 缓冲数据
- 算法：3点/5点滑动平均、阈值比较
- 输出：事件标志、中断、统计计数

---

## 9. 中断与事件
- 中断控制器支持 32 路源（v1 使用子集）。
- 关键中断：I2C0、I2C1、uDMA、RTC、GPIO、TIMER、WDT、UART、FUSION。
- 支持：屏蔽、状态、清除、优先级（静态 4 级）。

---

## 10. 启动流程（Boot Flow）
1. POR 释放，AON 与 SYS 初始化。
2. CPU 取 Boot ROM 向量。
3. 配置时钟与 SRAM 区域。
4. 初始化 APB 外设（I2C/uDMA/RTC）。
5. 进入主循环：采集 -> 处理 -> 上报 -> 休眠。

---

## 11. 性能与功耗目标（v1 参考）
- `clk_sys` = 50MHz 下，I2C 400k 正常采样无丢包。
- 双 I2C + uDMA 并发时，CPU 占用率显著降低（相对轮询模式）。
- SLEEP 模式可由 RTC 周期唤醒并恢复采集任务。

---

## 12. 可测性与可实现性要求
- 所有 APB 寄存器具备可读回特性（RO/W1C 除外）。
- 关键状态机输出调试观测信号（仅仿真可见）。
- 代码规范满足 DC 综合与 FM 对比前提。

---

## 13. 版本管理
- 当前版本：v1.0（2026-04-02）
- 变更原则：先更新本文档，再同步 RTL 与 UVM。

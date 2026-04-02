# UVM-SFSoC-v1 项目说明（方案1：低功耗传感器融合 SoC）

## 1. 项目目标
构建一个面向可穿戴、工业监测、智能家居场景的小型 SoC 前端开发与验证项目，核心能力为：

- 多路 I2C 传感器采集
- 低功耗自治搬运（uDMA-like）
- 轻量数据融合与事件上报
- 完整 UVM 验证闭环（功能、异常、低功耗场景）

---

## 2. 目录规划
根目录按以下结构组织：

- `rtl/`：RTL 设计代码
- `sim/`：仿真目录
  - `sim/uvm/`：UVM 验证平台
  - `sim/work/`：编译与运行工作目录
- `syn/`：综合（DC）脚本与结果
- `fm/`：形式等价检查（Formality）脚本与结果
- `md/`：项目文档（本文件及后续规格文档）

---

## 3. SoC 顶层定义（v1）

### 3.1 核心与总线
- CPU：RV32IMC 单核 MCU
- 总线：AHB-Lite + APB 分层结构
- 存储：Boot ROM + SRAM（含 retention bank 规划）

### 3.2 外设
- I2C Master x2（100k/400k/1MHz，7-bit 地址，repeated-start）
- SPI/QSPI Master x1
- UART x1
- GPIO / Timer / WDT / RTC

### 3.3 数据通路
- uDMA-like：支持 I2C/SPI/UART 数据搬运至 SRAM
- Ring Buffer：采样数据缓存
- 轻量前处理：滑动平均 + 阈值触发（事件模式）

### 3.4 低功耗
- 电源域：AON + SYS
- 工作模式：RUN / SLEEP / DEEP-SLEEP
- 唤醒源：RTC / GPIO / I2C 传输完成 / WDT

---

## 4. 典型业务流程
1. RTC 定时唤醒 SoC
2. I2C0 读取 IMU，I2C1 读取温湿度
3. uDMA 将数据写入 SRAM 缓冲
4. CPU 执行轻量融合与阈值判断
5. 命中事件则 UART 上报，否则回到低功耗模式

---

## 5. 验证目标（UVM）

### 5.1 基础功能
- I2C 读写正确性（单次/连续/repeated-start）
- uDMA 搬运正确性（地址、长度、中断）
- APB 寄存器可编程性与复位值检查

### 5.2 异常与鲁棒性
- I2C NACK、时钟拉伸超时、总线忙冲突
- DMA 边界条件（0 长度、非对齐、跨边界）
- 中断屏蔽/清除/并发触发

### 5.3 低功耗验证
- RUN/SLEEP/DEEP-SLEEP 切换
- 唤醒源有效性及时序正确性
- 低功耗模式下外设自治行为约束

---

## 6. 里程碑（建议）
- M1：完成顶层规格与寄存器草案
- M2：I2C + uDMA + APB 基础 RTL 打通
- M3：UVM 基础环境 + smoke 回归通过
- M4：低功耗场景与异常场景回归通过
- M5：DC 综合与 FM 等价检查闭环

---

## 7. 下一步计划
后续文档将在 `md/` 目录补充：
- 《SoC 顶层规格说明书》
- 《寄存器地图定义》
- 《UVM 验证计划（VPlan）》
- 《综合与形式验证流程说明》

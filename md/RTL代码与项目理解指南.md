# RTL代码与项目理解指南（UVM-SFSoC-v1）

## 1. 文档目的

本指南用于帮助你**快速建立对当前项目的整体认知**，并形成一套可执行的 RTL 阅读方法：
- 先理解 SoC 架构与地址空间
- 再理解顶层互连与中断汇聚
- 最后按 IP 模板深入 `reg_top/core/top`

建议配合以下文档一起阅读：
- `md/SOC_SensorFusion_v1_项目说明.md`
- `md/SoC_顶层规格说明书.md`
- `md/寄存器地图定义.md`
- `md/UVM_Phase0_运行说明.md`

---

## 2. 先建立“全局心智模型”

可以先把项目抽象成 4 层：

1) **规格层（md）**  
定义“应该做什么”（地址、寄存器、模式、流程）。

2) **顶层集成层（rtl/top + rtl/bus）**  
定义“谁和谁连接，地址怎么路由，中断怎么汇总”。

3) **外设实现层（rtl/ip）**  
定义“每个外设具体怎么工作”。

4) **验证层（sim/uvm）**  
定义“如何证明它做对了”。

如果阅读过程中迷失，回到这 4 层定位自己当前在看“规格、连接、实现、验证”哪一层。

---

## 3. 推荐阅读顺序（高效版）

### Step A：先看文档，确认目标与边界
1. `md/SOC_SensorFusion_v1_项目说明.md`：看项目目标、典型业务流程。  
2. `md/SoC_顶层规格说明书.md`：看顶层架构、时钟复位、低功耗。  
3. `md/寄存器地图定义.md`：看 APB 地址和寄存器字段。  

完成标志：你能说清楚“有哪些 IP、每个 IP 大概做什么、地址在什么区间”。

### Step B：看顶层连接，建立数据/控制路径
1. `rtl/top/sf_soc_top.sv`
2. `rtl/bus/apb_decoder.sv`
3. `rtl/top/sf_soc_pkg.sv`

完成标志：你能回答：
- APB 地址如何变成片选 `psel_vec`？
- `apb_prdata/pready/pslverr` 如何 mux 回来？
- 中断源如何拼成 `irq_src`？

### Step C：按“模板”看任一 IP（建议 PMU、I2C、UDMA、FUSION）
每个 IP 基本都是：
- `*_pkg.sv`：参数/类型
- `*_reg_top.sv`：APB 寄存器行为
- `*_core.sv`：功能逻辑
- `*_top.sv`：reg 与 core 粘接

完成标志：你能在一个 IP 内追踪“某个寄存器位 -> core 行为 -> 状态/中断回读”。

### Step D：最后看验证入口
1. `sim/uvm/test/smoke_apb_test.sv`
2. `sim/uvm/tb/tb_top.sv`
3. `sim/work/vcs_flist.f`

完成标志：你知道当前 smoke 在验证哪些寄存器链路。

---

## 4. 顶层 `sf_soc_top.sv` 的阅读抓手

建议按下面 5 个锚点读，不要从头“平推”：

### 锚点1：接口与复位
- 输入 APB 主口：`apb_psel/apb_penable/apb_pwrite/apb_paddr/apb_pwdata`
- 输出 APB 从口：`apb_prdata/apb_pready/apb_pslverr`
- `sf_rst_sync` 将 `por_n` 同步成 `sys_rst_n`

### 锚点2：地址译码
- `apb_decoder` 使用 `paddr[15:12]` 生成 one-hot `psel_vec`
- 意味着每个外设窗口为 4KB（与寄存器地图文档一致）

### 锚点3：外设例化顺序（你可当作“片选索引表”）
- `psel_vec[1]` PMU
- `psel_vec[2]` RTC
- `psel_vec[3]` GPIO
- `psel_vec[4]` TIMER_WDT
- `psel_vec[6]` UART
- `psel_vec[7]` SPI
- `psel_vec[8]` I2C0
- `psel_vec[9]` I2C1
- `psel_vec[10]` UDMA
- `psel_vec[11]` INTC
- `psel_vec[12]` FUSION

### 锚点4：APB 读回 mux
- `unique case (1'b1)` 根据 `psel_vec[x]` 选择对应 `prdata/pready/pslverr`
- 未命中时给默认值

### 锚点5：中断汇聚
- 各 IP 的 `*_irq` 被拼成 `irq_src`，送到 `sf_event_intc_top`
- 这是你做中断相关 debug 的第一入口

---

## 5. IP 级阅读方法（以 `reg_top -> core -> top` 为主线）

### 5.1 先看 `reg_top`
目标：回答“软件可编程接口是什么”。
- 关注 APB 写条件：`psel && penable && pwrite`
- 关注地址分发：`case (paddr[7:0])`
- 关注复位值（是否与寄存器文档一致）

### 5.2 再看 `core`
目标：回答“硬件行为如何随寄存器变化”。
- 输入通常来自 `reg_top` 输出（如 `mode_req`、`fus_en`）
- 输出通常返回 `reg_top`（如 `cur_mode`、`event_hit/event_cnt`）

### 5.3 最后看 `top`
目标：确认“reg/core 是否正确连线”。
- 看端口一一对应
- 看有无反向/位宽/命名不一致

---

## 6. 一个可复用的“寄存器追踪模板”

当你想理解任意寄存器位（例如 `FUS_CTRL.fus_en`）时，按这个顺序：

1. 在 `md/寄存器地图定义.md` 找地址、位定义。
2. 到对应 `*_reg_top.sv` 找写入位置和复位值。
3. 到对应 `*_core.sv` 找该位如何影响状态机/运算。
4. 回到 `*_reg_top.sv` 找状态/中断如何回读。
5. 到 `*_top.sv` 确认连线完整。

做到这 5 步，基本就完成了该功能的设计理解闭环。

---

## 7. 与 UVM 联动理解（建议实践）

当前 Phase-0 可用 smoke 测试点：
- PMU 寄存器写读
- RTC 比较寄存器写读
- I2C0 地址寄存器写读

建议你在看 RTL 时同步做两件事：
1. 观察 test 对哪些地址发起读写；
2. 在 RTL 中定位这些地址在 `reg_top` 的落点。

这样能快速把“验证行为”和“设计实现”对齐。

---

## 8. 当前阶段阅读重点（按优先级）

### P0（先搞懂）
- APB 路由（decoder + mux）
- PMU/RTC/I2C0 的寄存器通路
- 中断汇聚到 INTC 的链路

### P1（随后补齐）
- UDMA 通道寄存器与完成中断
- FUSION 事件触发路径
- 低功耗模式切换与唤醒原因

### P2（收敛阶段）
- 异常路径（NACK/timeout/busy 等）
- 覆盖率对应的 corner case

---

## 9. 代码审阅建议清单（每看完一个 IP 勾选）

- [ ] 地址偏移与文档一致
- [ ] 复位值与文档一致
- [ ] `RW/RO/W1C` 行为一致
- [ ] `reg_top -> core` 控制路径完整
- [ ] `core -> reg_top` 状态回读完整
- [ ] `irq` 触发和清除条件清楚
- [ ] 顶层连线位宽与方向一致

---

## 10. 你可以这样安排 3 天上手

### Day 1：全局
- 看完 3 份核心文档（项目说明、顶层规格、寄存器地图）
- 跑通一次 Phase-0 smoke
- 读完 `sf_soc_top.sv` 和 `apb_decoder.sv`

### Day 2：模块
- 深读 PMU、RTC、I2C0 三个 IP（按 `reg->core->top`）
- 完成 3 个寄存器追踪闭环

### Day 3：系统
- 深读 UDMA、INTC、FUSION
- 把中断链路和事件链路画成你自己的一页图

---

## 11. 后续可扩展方向

当你熟悉当前骨架后，建议优先推进：
- APB agent 完整化（driver/monitor/sequencer）
- RAL 模型与寄存器自动检查
- 中断与低功耗场景用例扩展

这三项会直接提升你对 RTL 理解的“可验证性”和“可维护性”。

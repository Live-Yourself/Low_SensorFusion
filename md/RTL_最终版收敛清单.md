# RTL 最终版收敛清单（可打勾执行计划版，全模块）

> 适用范围：`rtl/` 下所有模块（`top/common/bus/mem/ip/*`）。
>
> 计划基线来源：`md/骨架版到完整版_分阶段开发与验证计划.md`。
>
> 执行原则：每个阶段按“RTL项 + UVM项 + 证据项”三线并行，未完成本阶段 Exit Criteria 不进入下一阶段。

### 最近一次勾选更新（2026-04-13）

- I2C：完成位级状态机重构、SCL分频、移位/采样、ACK/NACK与repeated-start主流程。
- UDMA：完成通道模板寄存器对齐、IRQ_EN门控、`busy/done/err` 生命周期收敛。
- UDMA：新增单端口 SRAM 访问仲裁（RX写优先）与 RX 尾包处理（不足4字节零填充落word）。
- UDMA：`CHn_LEN` 单位明确为 word（1 word=4 bytes），并与 `addr +4` 语义对齐。
- APB健壮性：I2C/UDMA reg_top 增加 `pslverr` 地址/访问属性检查。
- 关联文件：
	- `rtl/ip/i2c/sf_i2c_core.sv`
	- `rtl/ip/i2c/sf_i2c_reg_top.sv`
	- `rtl/ip/udma/sf_udma_core.sv`
	- `rtl/ip/udma/sf_udma_reg_top.sv`

---

## 0. 阶段总览与当前状态

- [x] Phase 0：验证平台起步与骨架烟测（已完成）
- [ ] Phase 1：关键功能闭环（I2C + UDMA + APB）
- [ ] Phase 2：系统闭环（中断 + 低功耗 + E2E）
- [ ] Phase 3：异常/随机/覆盖收敛
- [ ] Phase 4：实现签收与封板（DC/FM）

---

## 1. 分阶段可执行计划（打勾推进）

## 1.1 Phase 0（已完成，保持门禁）

### 目标
- [x] `smoke_apb_test` 连续通过，形成最小可运行链路

### 已完成项
- [x] `tb_top/env/base_test/smoke_apb_test` 链路
- [x] APB 基础访问可用
- [x] `sim/work` 统一 filelist 与脚本入口

### 维持项（后续每阶段都要保持）
- [ ] 每次改动后 `smoke_apb_test` 仍通过

## 1.2 Phase 1（关键功能闭环：I2C + UDMA + APB）

### A. I2C（`rtl/ip/i2c/*`）
- [x] `sf_i2c_reg_top.sv`：CTRL/ADDR/TX/RX/CMD/STAT/INT/SUBADDR 字段语义完全一致
- [x] `sf_i2c_core.sv`：修复状态机冲突（含 `ST_SUBADDR` 转移）
- [x] `sf_i2c_core.sv`：完成 START/ADDR/SUBADDR/DATA/STOP/DONE 主流程闭环
- [x] `sf_i2c_top.sv`：reg-core 连线与 irq 行为一致

### B. UDMA（`rtl/ip/udma/*`）
- [x] `sf_udma_reg_top.sv`：`GLB_CTRL/GLB_STAT` + `CHn_*` 模板地址一致
- [x] `sf_udma_core.sv`：`busy/done/err` 生命周期、0/1/max 长度闭环
- [x] `sf_udma_top.sv`：reg-core 接口一致

### C. APB 与顶层一致性（`rtl/top/*` + 各 `reg_top`）
- [ ] `pready/pslverr` 策略统一
- [ ] 关键寄存器复位值与文档一致
- [ ] I2C/UDMA 中断到 INTC 映射正确

### D. UVM 对应项（Phase1 必过）
- [ ] `smoke_apb_test`
- [ ] `tc_i2c_basic_rw`
- [ ] `tc_i2c_repeat_start`
- [ ] `tc_udma_basic`
- [ ] `tc_udma_len_boundary`

### E. Phase 1 Exit Criteria
- [ ] 关键功能用例全部通过
- [ ] 功能覆盖率 > 70%
- [ ] 无未关闭 P0

## 1.3 Phase 2（系统闭环：中断 + 低功耗 + E2E）

### A. 模块完成项
- [ ] `rtl/ip/event_intc/*`：屏蔽/挂起/清除/优先级行为完整
- [ ] `rtl/ip/pmu/*`：RUN/SLEEP/DEEP-SLEEP 切换与唤醒一致
- [ ] `rtl/ip/rtc/*`：定时唤醒与中断闭环
- [ ] `rtl/ip/udma/*`：与 SRAM/外设真实握手、回压处理、错误上报与中断联动完整
- [ ] `rtl/top/sf_soc_top.sv`：唤醒源与中断汇聚路径完整

### B. 系统联动项
- [ ] I2C -> UDMA -> FUSION -> INTC 端到端链路打通
- [ ] 低功耗切换时外设行为与策略一致
- [ ] UDMA 在 SLEEP/DEEP-SLEEP 下停启/保持策略与 PMU 规格一致

### C. UVM 对应项（Phase2 必过）
- [ ] `tc_sleep_wakeup_rtc`
- [ ] `tc_wakeup_cause_check`
- [ ] `tc_sensor_fusion_e2e`
- [ ] 多中断并发优先级场景

### D. Phase 2 Exit Criteria
- [ ] 低功耗关键场景通过
- [ ] E2E 多 seed 稳定通过

## 1.4 Phase 3（异常/随机/覆盖收敛）

### A. 异常路径补齐（重点模块）
- [ ] I2C：NACK/timeout/busy/arb-lost 真实检测与恢复
- [ ] UDMA：错误通道隔离、并发冲突处理、IRQ门控一致
- [ ] UDMA：突发回压/超时/非法地址/未对齐访问异常策略闭环
- [ ] UART/SPI/TIMER_WDT/GPIO：边界与错误路径补齐

### B. 回归与覆盖
- [ ] 随机回归（大样本 seeds）
- [ ] 功能覆盖收敛
- [ ] 代码覆盖收敛（line/branch/fsm/toggle）

### C. Phase 3 Exit Criteria
- [ ] func > 90%
- [ ] line > 90%
- [ ] fsm > 95%
- [ ] 无未关闭 P0/P1

## 1.5 Phase 4（实现签收与封板）

### A. 设计实现项
- [ ] 清理不可综合结构
- [ ] 约束与复位策略对齐
- [ ] UDMA 多通道仲裁与数据面路径完成综合时序收敛

### B. 工具签收项
- [ ] DC 综合通过并达到目标
- [ ] FM/LEC 等价通过
- [ ] ECO 后回归通过

### C. Phase 4 Exit Criteria
- [ ] 签收评审通过
- [ ] 版本冻结（tag + 报告归档）

---

## 2. 全局签收门槛（最终版必须全部满足）

- [ ] **编译零错误**：VCS/Verilator/Lint 无 error。
- [ ] **Lint 收敛**：无 blocker/critical，剩余 waiver 有评审记录。
- [ ] **CDC/RDC 收敛**：跨域、复位域问题闭环。
- [ ] **UVM 功能回归通过**：Must-pass 集合 100% 通过。
- [ ] **覆盖率达标**：func/code（line/branch/fsm/toggle）达到阶段目标。
- [ ] **综合可实现**：DC 编译通过，无不可综合结构。
- [ ] **形式等价通过**：FM/LEC 通过（RTL vs netlist）。
- [ ] **文档一致性**：寄存器地图、顶层规格、VPlan 与 RTL 一致。

---

## 3. 全模块详细收敛清单（按文件）

### 3.1 `rtl/common/`

#### `sf_defs.svh`
- [ ] 宏定义无冲突、无重复语义
- [ ] 功耗模式/APB响应宏与文档一致

#### `sf_rst_sync.sv`
- [ ] 异步复位同步释放行为正确（含仿真波形）
- [ ] 不同复位脉宽场景稳定

#### `sf_cdc_sync.sv`
- [ ] 双触发器同步结构正确
- [ ] CDC 工具识别为合法同步器

### 3.2 `rtl/bus/`

#### `apb_decoder.sv`
- [ ] 地址窗口 one-hot 片选正确
- [ ] 越界地址默认行为明确（无误选）

#### `ahb2apb_bridge.sv`
- [ ] AHB->APB 时序握手正确
- [ ] wait-state/错误响应路径可测

### 3.3 `rtl/mem/`

#### `sf_boot_rom.sv`
- [ ] 启动向量正确
- [ ] 读时序与初始化内容稳定

#### `sf_sram.sv`
- [ ] 读写时序正确
- [ ] retention 分区行为与 PMU 规格一致

### 3.4 `rtl/top/`

#### `sf_soc_pkg.sv`
- [ ] 全局地址映射与 `md/寄存器地图定义.md` 一致
- [ ] 外设窗口无重叠

#### `sf_soc_top.sv`
- [ ] APB mux/ready/pslverr 路径完整
- [ ] 各 IP 中断映射至 INTC 正确
- [ ] 低功耗相关连线（PMU/RTC/WAKE）一致

---

## 4. 各 IP 模块清单（逐文件）

## 4.1 I2C（`rtl/ip/i2c/`）

#### `sf_i2c_pkg.sv`
- [ ] 速率枚举/参数定义与实现一致

#### `sf_i2c_reg_top.sv`
- [x] `I2C_CTRL/ADDR/TXDATA/RXDATA/CMD/STAT/INT/SUBADDR` 全字段语义正确
- [x] `W1C` 清除行为正确
- [x] `GO` 脉冲与命令生命周期一致

#### `sf_i2c_core.sv`
- [x] **SCL 分频时钟生成**（100k/400k/1M）正确
- [x] **位级状态机**（START/ADDR/ACK/SUBADDR/DATA/STOP）完整
- [x] **移位寄存器** TX/RX 与 bit 计数正确
- [x] **真实采样**：`sda_i` 采样、ACK/NACK 检测、仲裁丢失判定
- [x] **open-drain 语义**：`scl/sda` 输出使能与线值分离（建议 `*_oe_n`）
- [ ] timeout/clock-stretch 处理正确

#### `sf_i2c_top.sv`
- [x] reg/core 端口无丢失、无重名冲突
- [x] IRQ 汇总行为与寄存器定义一致

## 4.2 UDMA（`rtl/ip/udma/`）

#### `sf_udma_pkg.sv`
- [ ] 通道数、默认参数与 top 一致

#### `sf_udma_reg_top.sv`
- [x] `GLB_CTRL/GLB_STAT` 正确
- [x] `CHn_SRC/DST/LEN/CFG/STAT` 地址模板正确（`0x100+n*0x20`）
- [x] `CHn_CFG[0]` 启动、`CHn_STAT` W1C 清除正确
- [x] `IRQ_EN` 门控生效

#### `sf_udma_core.sv`
- [x] 通道 `busy/done/err` 生命周期正确
- [x] 源/目的地址递增规则正确
- [x] 边界长度（0/1/max）正确
- [ ] 与 SRAM/外设数据面握手真实打通（非仅计数器）
- [ ] 多通道并发仲裁（公平性/优先级）策略明确且可测
- [ ] 回压（ready/valid wait）下长度计数与完成判定正确
- [ ] 异常路径（非法地址/总线错误）上报 `err` 并可恢复

#### `sf_udma_top.sv`
- [x] reg/core 接口一致，数据面接口完整
- [ ] 与 `sf_sram`、I2C/SPI/UART 数据端口实连并完成联调

## 4.3 PMU（`rtl/ip/pmu/`）

#### `sf_pmu_pkg.sv`
- [ ] 模式枚举定义一致

#### `sf_pmu_reg_top.sv`
- [ ] `PWR_MODE/WAKE_EN/PWR_STAT/WAKE_CAUSE` 字段正确
- [ ] `WAKE_CAUSE` W1C 正确

#### `sf_pmu_core.sv`
- [ ] RUN/SLEEP/DEEP-SLEEP 状态迁移合法
- [ ] 非法跳转保护

#### `sf_pmu_top.sv`
- [ ] 唤醒源接入完整、输出模式可观测

## 4.4 RTC（`rtl/ip/rtc/`）

#### `sf_rtc_pkg.sv`
- [ ] 默认比较值与文档一致

#### `sf_rtc_reg_top.sv`
- [ ] `CTRL/CNT/CMP/INT_STAT` 行为正确

#### `sf_rtc_core.sv`
- [ ] 计数与比较命中准确
- [ ] 命中脉冲与中断状态锁存一致

#### `sf_rtc_top.sv`
- [ ] IRQ/寄存器联动正确

## 4.5 GPIO（`rtl/ip/gpio/`）

#### `sf_gpio_pkg.sv`
- [ ] 位宽参数一致

#### `sf_gpio_reg_top.sv`
- [ ] `DIR/OUT/IN` 访问属性正确

#### `sf_gpio_core.sv`
- [ ] 输入采样/输出驱动正确
- [ ] 中断触发策略与文档一致

#### `sf_gpio_top.sv`
- [ ] 顶层引脚与寄存器路径完整

## 4.6 TIMER_WDT（`rtl/ip/timer_wdt/`）

#### `sf_timer_wdt_pkg.sv`
- [ ] 默认重载值一致

#### `sf_timer_wdt_reg_top.sv`
- [ ] `CTRL/RELOAD/KICK/CNT/STAT` 正确

#### `sf_timer_wdt_core.sv`
- [ ] 定时器到期/看门狗超时逻辑正确
- [ ] `kick` 脉冲生效

#### `sf_timer_wdt_top.sv`
- [ ] IRQ 汇总正确

## 4.7 UART（`rtl/ip/uart/`）

#### `sf_uart_pkg.sv`
- [ ] 参数定义一致

#### `sf_uart_reg_top.sv`
- [ ] `CTRL/BAUD/TXD/RXD/STAT/INT` 正确

#### `sf_uart_core.sv`
- [ ] 收发状态机、波特率分频正确
- [ ] overrun/错误路径可测

#### `sf_uart_top.sv`
- [ ] 外部引脚与中断路径正确

## 4.8 SPI（`rtl/ip/spi/`）

#### `sf_spi_pkg.sv`
- [ ] mode 枚举一致

#### `sf_spi_reg_top.sv`
- [ ] `CTRL/TX/RX/STAT` 正确

#### `sf_spi_core.sv`
- [ ] CPOL/CPHA 模式行为正确
- [ ] 传输完成判定正确

#### `sf_spi_top.sv`
- [ ] 引脚/中断路径正确

## 4.9 EVENT INTC（`rtl/ip/event_intc/`）

#### `sf_event_intc_pkg.sv`
- [ ] 中断路数参数正确

#### `sf_event_intc_reg_top.sv`
- [ ] `MASK/PEND/CLR/PRIO` 访问语义正确

#### `sf_event_intc_core.sv`
- [ ] 挂起、屏蔽、清除、优先级行为正确

#### `sf_event_intc_top.sv`
- [ ] `irq_src` 到 `cpu_irq` 路径正确

## 4.10 FUSION（`rtl/ip/fusion/`）

#### `sf_fusion_pkg.sv`
- [ ] 窗口参数定义一致

#### `sf_fusion_reg_top.sv`
- [ ] `CTRL/THR/STAT/CNT` 正确

#### `sf_fusion_core.sv`
- [ ] 滑动平均与阈值命中逻辑正确
- [ ] 事件计数/溢出语义正确

#### `sf_fusion_top.sv`
- [ ] sample 输入与 IRQ 联动正确

---

## 5. 交叉专项收敛（系统级）

- [ ] **APB 一致性**：所有 `reg_top` 的 `pready/pslverr` 策略统一。
- [ ] **中断一致性**：各 IP 中断锁存/清除语义统一。
- [ ] **低功耗一致性**：PMU 模式与外设活动约束一致。
- [ ] **I2C+UDMA 数据链路**：I2C/SPI/UART 与 UDMA 数据面真实连通。
- [ ] **复位一致性**：POR/软复位后关键寄存器复位值一致。

---

## 6. UVM 对应签收用例（建议最小必须集）

- [ ] `smoke_apb_test`
- [ ] `tc_i2c_basic_rw`
- [ ] `tc_i2c_repeat_start`
- [ ] `tc_i2c_nack_recovery`
- [ ] `tc_i2c_timeout`
- [ ] `tc_udma_basic`
- [ ] `tc_udma_len_boundary`
- [ ] `tc_dual_i2c_udma_concurrent`
- [ ] `tc_sleep_wakeup_rtc`
- [ ] `tc_sensor_fusion_e2e`

---

## 7. 最终签收产物（必须归档）

- [ ] 编译日志、lint/CDC/RDC 报告
- [ ] UVM 回归报告（含 seed、失败归因）
- [ ] 覆盖率报告（func/code）
- [ ] DC 综合报告（timing/area/power）
- [ ] FM 等价报告
- [ ] 版本冻结清单（tag + 变更摘要 + 文档版本）

---

## 8. 阶段判定建议

- **Alpha（可联调）**：基本编译 + smoke 通过
- **Beta（可回归）**：关键功能 + 关键异常通过，覆盖率达阶段门槛
- **RC（可签收）**：全局门槛全部满足，综合/形式通过
- **Final（封板）**：签收评审通过，无 P0/P1 未关闭

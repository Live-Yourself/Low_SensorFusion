# UVM 验证计划（VPlan）- UVM-SFSoC-v1

## 1. 目标与范围

### 1.0 阶段进度快照（2026-04-08）
- Phase 0（验证平台起步与骨架烟测）：✅ 已完成
- Phase 1（关键功能闭环：I2C + UDMA + APB）：🔄 准备进入

当前执行策略：保留 Phase 0 smoke 门禁，同时增量引入 Phase 1 功能用例与判分闭环。

### 1.1 验证目标
- 验证 SoC 在功能、异常、低功耗三大维度满足规格。
- 建立可复用 UVM 平台，支持模块级与子系统级回归。
- 提供覆盖率闭环与可追踪测试矩阵。

### 1.2 DUT 范围
- 顶层 SoC + AHB/APB + I2C0/I2C1 + uDMA + PMU/RTC + UART/SPI + FUSION。

---

## 2. 验证架构

### 2.1 TB 拓扑
- `soc_env`
  - `apb_agent`（主动）
  - `ahb_agent`（被动监控）
  - `i2c_agent0/1`（被动监控 + 从设备模型）
  - `uart_agent`（被动）
  - `spi_agent`（被动）
  - `intr_agent`（中断采样）
  - `pm_agent`（低功耗状态观察）
  - `soc_scoreboard`
  - `soc_cov`
  - `soc_ral_model`

### 2.2 参考模型与比对
- I2C 事务级参考模型：校验 start/addr/rw/ack/data/stop 序列。
- uDMA 参考模型：校验地址、长度、递增规则、完成中断。
- FUSION 参考模型：滑动平均与阈值事件比对。

---

## 3. 配置与激励策略

### 3.1 测试层次
- L0：模块 smoke
- L1：子系统功能
- L2：SoC 场景与随机回归
- L3：低功耗/异常组合压力

### 3.2 随机化维度
- I2C 速率、地址、读写方向、字节数
- DMA 长度、对齐、突发间隔
- 中断并发关系
- 低功耗切换时机（传输中/空闲）

### 3.3 约束原则
- 保持协议合法随机为主，非法场景由负测显式注入。
- 随机种子固定可复现，失败自动记录种子。

---

## 4. 用例矩阵（核心）

### 4.1 基础功能
- `tc_boot_smoke`：上电启动、寄存器可访问。
- `tc_i2c0_basic_rw`：I2C0 基本读写。
- `tc_i2c1_basic_rw`：I2C1 基本读写。
- `tc_i2c_repeat_start`：重复起始读流程。
- `tc_udma_memcpy_basic`：DMA 基础搬运。
- `tc_uart_loopback`：UART 收发一致性。

### 4.2 协议异常
- `tc_i2c_nack_recovery`：NACK 处理与状态清除。
- `tc_i2c_timeout`：时钟拉伸超时。
- `tc_i2c_bus_busy`：总线忙冲突仲裁。

### 4.3 DMA 与并发
- `tc_udma_len_boundary`：0/1/最大长度边界。
- `tc_udma_align_stress`：非对齐地址压力。
- `tc_dual_i2c_udma_concurrent`：双 I2C + DMA 并发。

### 4.4 低功耗
- `tc_sleep_wakeup_rtc`：SLEEP + RTC 唤醒。
- `tc_deepsleep_retention`：DEEP-SLEEP 保留区验证。
- `tc_sleep_with_dma`：低功耗与 DMA 活动协同。
- `tc_wakeup_cause_check`：唤醒原因寄存器检查。

### 4.5 端到端场景
- `tc_sensor_fusion_e2e`：双传感采集 -> 融合 -> 事件上报。

---

## 5. 断言（SVA）计划
- I2C 协议时序断言：start/stop 合法性、ACK 周期。
- DMA 断言：`CH_EN` 后最终 `DONE|ERR` 收敛。
- PMU 断言：模式迁移合法，不出现非法跳转。
- 中断断言：`INT_PEND` 与源事件对应关系。

---

## 6. 覆盖率计划

### 6.1 功能覆盖
- I2C 覆盖点：速率 x 方向 x 长度 x ACK/NACK
- DMA 覆盖点：通道 x 长度区间 x 对齐类型
- 低功耗覆盖点：模式切换路径 x 唤醒源
- 中断覆盖点：单源/多源并发、屏蔽/清除路径

### 6.2 交叉覆盖（示例）
- `i2c_speed` x `dma_len_bucket`
- `pm_mode` x `wake_source`
- `i2c_error_type` x `recovery_path`

### 6.3 代码覆盖目标
- 行覆盖 >= 95%
- 分支覆盖 >= 90%
- FSM 覆盖 >= 95%
- Toggle 覆盖 >= 90%

---

## 7. 回归策略
- 冒烟回归：每次提交执行 `smoke_apb_test`（Phase 0 门禁保留）+ 关键 L1。
- 夜间回归：执行 L2 随机 200~500 seeds。
- 周回归：执行 L3 压力 + 覆盖率收敛分析。
- Bug 修复后：强制执行对应 test + 相关子集回归。

---

## 8. 结果判定与签收标准
- 所有 Must-Pass 用例通过。
- 无 P1/P0 未关闭缺陷。
- 覆盖率达到目标并完成未覆盖项解释。
- 与规格文档一致性审查通过。

---

## 9. 缺陷分级
- P0：系统死锁/不可启动/数据严重错误
- P1：关键协议异常恢复失败
- P2：功能边界问题
- P3：日志、可观测性、非关键差异

---

## 10. 交付物
- UVM 测试列表与回归报告
- 覆盖率报告（功能+代码）
- 失败用例根因分析与修复记录
- 阶段性签收评审材料

---

## 11. 与收敛清单联动
- RTL 侧阶段门禁与模块收敛项：`md/RTL_最终版收敛清单.md`
- UVM 侧阶段门禁与平台收敛项：`md/UVM_最终版收敛清单.md`
- 要求：每次 RTL 或 UVM 关键改动后，同步更新对应收敛清单勾选与“最近一次更新”说明。

---

## 12. 版本信息
- 当前版本：v1.2（2026-04-09）

### v1.2 更新说明
- 新增 VPlan 与 `md/UVM_最终版收敛清单.md` 的联动规则。
- 明确 RTL/UVM 双清单并行维护要求。

### v1.1 更新说明
- 同步 Phase 0 完成状态。
- 明确 Phase 1 过渡期“smoke 保留门禁 + L1 增量用例”策略。

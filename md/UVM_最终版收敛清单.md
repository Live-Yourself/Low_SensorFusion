# UVM 最终版收敛清单（对齐 RTL 最终版 + VPlan）

> 基线来源：
> - `md/RTL_最终版收敛清单.md`
> - `md/UVM_验证计划_VPlan.md`
>
> 适用范围：`sim/uvm/*` + `sim/work/*`
>
> 执行原则：每个阶段按“平台能力 + 用例 + 覆盖率 + 证据”闭环推进；未达 Exit Criteria 不进入下一阶段。

---

## 0. 阶段总览

- [x] Phase 0：平台起步与 smoke 门禁
- [ ] Phase 1：I2C + UDMA + APB 闭环
- [ ] Phase 2：中断/低功耗/E2E
- [ ] Phase 3：异常/随机/覆盖收敛
- [ ] Phase 4：签收与归档

---

## 1. Phase 1（当前）

### 最近一次更新（2026-04-13）
- 已确认当前 Must-pass 用例均通过：`smoke_apb_test`、`tc_i2c_basic_rw`、`tc_i2c_repeat_start`、`tc_udma_basic`、`tc_udma_len_boundary`。
- 新增 `sim/uvm/cov/soc_cov.sv`，开始收集 Phase1 控制面功能覆盖率（I2C CTRL/CMD + UDMA CHn_LEN）。
- 风险关注项：UDMA CH1（SRAM->I2C TX）在上游不足4次 `tx_req` 终止场景下的尾包收敛行为需继续观察与补强。

### 1.1 Must-pass 用例（与 RTL Phase1 对齐）
- [x] `smoke_apb_test`
- [x] `tc_i2c_basic_rw`
- [x] `tc_i2c_repeat_start`
- [x] `tc_udma_basic`
- [x] `tc_udma_len_boundary`

### 1.2 平台能力（当前代码对齐项）
- [x] APB agent（driver/monitor/sequencer）可复用
- [x] `base_test` 统一 APB 访问封装
- [x] `base_test` 增加 reset 释放等待，避免 reset 期误访问
- [x] APB item/response 正确携带 `rdata/pslverr`
- [x] scoreboard 具备 APB `pslverr` 检查与统计报告
- [x] I2C TB 最小从设备 ACK 行为（支持 L1 协议路径）

### 1.3 Phase1 Exit Criteria
- [x] Must-pass 用例 100% 通过
- [ ] 功能覆盖率 > 70%
- [ ] 无未关闭 P0

---

## 2. Phase 2（系统闭环）

### 2.1 新增/完善测试
- [ ] `tc_sleep_wakeup_rtc`
- [ ] `tc_wakeup_cause_check`
- [ ] `tc_sensor_fusion_e2e`
- [ ] 多中断并发优先级场景

### 2.2 平台能力补齐
- [ ] `intr_agent`：中断采样与时序校验
- [ ] `pm_agent`：低功耗状态观测
- [ ] 基础 RAL 模型接入（I2C/UDMA/INTC 最小集合）

### 2.3 Exit Criteria
- [ ] 系统联动场景稳定通过
- [ ] E2E 多 seed 稳定通过

---

## 3. Phase 3（异常/随机/覆盖收敛）

### 3.1 异常与压力测试
- [ ] `tc_i2c_nack_recovery`
- [ ] `tc_i2c_timeout`
- [ ] `tc_udma_align_stress`
- [ ] `tc_dual_i2c_udma_concurrent`

### 3.2 平台能力补齐
- [x] `soc_cov`：已落地 Phase1 控制面覆盖（I2C/UDMA），INTC/交叉覆盖待后续补齐
- [ ] 随机约束分层（合法随机 + 非法注入）
- [ ] 回归失败自动归因模板（test/seed/关键信号）

### 3.3 Exit Criteria
- [ ] func > 90%
- [ ] line > 90%
- [ ] fsm > 95%
- [ ] 无未关闭 P0/P1

---

## 4. Phase 4（签收与归档）

- [ ] Must-pass + 回归集全部通过
- [ ] 覆盖率报告归档（func/code）
- [ ] 缺陷清零证明（P0/P1）
- [ ] 版本冻结材料（tag + 变更摘要 + 证据链接）

---

## 5. UVM 平台文件级清单（当前工程）

### 5.1 `sim/uvm/seq/`
- [x] `apb_seq_item.sv`：字段注册完整（含 `rdata/pslverr`）
- [x] `apb_one_shot_seq.sv`：响应携带 `rdata/pslverr`

### 5.2 `sim/uvm/agent/apb/`
- [x] `apb_driver.sv`：读写事务与响应回传正确
- [x] `apb_monitor.sv`：事务采样完整
- [x] `apb_agent.sv`：主动 agent 连线正确

### 5.3 `sim/uvm/env/`
- [x] `soc_env.sv`：agent->scoreboard 连线完成
- [x] `soc_scoreboard.sv`：`pslverr` 严格检查开关 + 汇总统计

### 5.4 `sim/uvm/test/`
- [x] `base_test.sv`：统一 APB API + reset 等待 + `pslverr` 期望校验
- [x] `tc_i2c_basic_rw.sv`：INT_STAT 轮询、W1C 清理、超时快照、早退出
- [x] `tc_i2c_repeat_start.sv`：CTRL 回读、INT_STAT 轮询、超时快照、早退出
- [x] `tc_udma_basic.sv`：DONE/W1C 基本路径
- [x] `tc_udma_len_boundary.sv`：0/1/常规边界长度路径

### 5.5 `sim/uvm/tb/`
- [x] `tb_top.sv`：+UVM_TESTNAME 运行入口
- [x] `tb_top.sv`：I2C 最小 ACK 从设备行为模型

---

## 6. 当前待办（建议优先级）

1. [ ] 基于 `soc_cov` 生成并归档 Phase1 功能覆盖率报告，达到 >70%
2. [ ] 确认并记录“无未关闭 P0”证据（缺陷清单/回归结论）
3. [ ] 跟踪 UDMA CH1 尾包收敛风险（不足4次 `tx_req` 的终止场景）
4. [ ] 增补 `tc_i2c_nack_recovery` 与 `tc_i2c_timeout`
5. [ ] 增补 `tc_udma_align_stress`

# Phase1 RTL + UVM 可执行清单（2026-04-08）

目标：在保持 `smoke_apb_test` 门禁稳定通过的前提下，完成 I2C + UDMA + APB 的功能闭环。

---

## 0. 执行顺序（必须按优先级）

1. **P0：先消除编译/联调阻塞项（RTL）**
2. **P1：完成 I2C/UDMA 主流程 RTL 闭环**
3. **P1：补齐 APB 寄存器行为一致性**
4. **P1：UVM 用例承接 + 自动判分最小闭环**
5. **P2：覆盖率采集与收敛（阶段目标 >70%）**

---

## 1. RTL 可执行清单

## 1.1 P0 阻塞项（本周立即完成）

- 文件：[rtl/top/sf_soc_top.sv](rtl/top/sf_soc_top.sv)
  - [ ] 清理重复声明（`pmu_mode` 在文件中重复定义）
  - [ ] 重新编译确认无语法/重复定义错误
  - DoD：可稳定通过编译，`smoke_apb_test` 不回退

## 1.2 I2C 主流程闭环（Phase1 核心）

- 文件：[rtl/ip/i2c/sf_i2c_core.sv](rtl/ip/i2c/sf_i2c_core.sv)
  - [ ] 增加最小状态机：`IDLE -> START -> ADDR -> DATA -> STOP -> DONE`
  - [ ] 区分读写方向 `dir` 的 `sda_o` 驱动行为
  - [ ] 明确 `busy`/`done` 脉冲时序（`done` 单拍）
  - [ ] `byte_cnt==0` 的行为固定（定义为 1 byte 或直接非法）
  - [ ] 预留 repeated-start 路径控制位（先框架可测）
  - DoD：可跑通基础读写与 repeated-start 框架测试

- 文件：[rtl/ip/i2c/sf_i2c_reg_top.sv](rtl/ip/i2c/sf_i2c_reg_top.sv)
  - [ ] 明确寄存器语义：`start_go` 自清零、`done_lat/err_lat` RW1C
  - [ ] `STATUS` 与 `IRQ_EN/IRQ_STATUS` 字段定义对齐文档
  - [ ] 复位值统一并可读回校验
  - DoD：APB 读回与状态机行为一致，IRQ 可预期触发与清除

## 1.3 UDMA 主流程闭环（Phase1 核心）

- 文件：[rtl/ip/udma/sf_udma_core.sv](rtl/ip/udma/sf_udma_core.sv)
  - [ ] `ch_en` 触发后装载计数并进入运行态
  - [ ] `ch_done` 保持单拍脉冲定义
  - [ ] 长度边界行为固定（0/1/max）
  - [ ] 避免 `ch_en` 每拍重装载导致永不完成
  - DoD：`ch_len` 边界场景均可收敛到 `done`

- 文件：[rtl/ip/udma/sf_udma_reg_top.sv](rtl/ip/udma/sf_udma_reg_top.sv)
  - [ ] 梳理 `ch_en` 产生方式（脉冲/电平）并与 core 约定一致
  - [ ] `done_lat` 锁存与清除（RW1C）行为固定
  - [ ] APB 地址映射与每通道寄存器读回补齐
  - DoD：多通道基本配置/完成中断行为可稳定复现

## 1.4 顶层联动一致性

- 文件：[rtl/top/sf_soc_top.sv](rtl/top/sf_soc_top.sv)
  - [ ] 检查 I2C0/I2C1/UDMA 中断到 `irq_src` 映射一致性
  - [ ] 确认 APB 从设备 `prdata/pready/pslverr` mux 无遗漏
  - DoD：顶层 APB 访问与中断汇聚路径可观测

---

## 2. UVM 可执行清单（与 RTL 同步推进）

## 2.1 先保底门禁（不改）

- 文件：[sim/uvm/test/smoke_apb_test.sv](sim/uvm/test/smoke_apb_test.sv)
  - [ ] 保持为提交门禁 test
  - [ ] 每次 RTL 改动后先跑 `smoke_apb_test`

## 2.2 APB 组件最小可复用化

- 目录：[sim/uvm/agent/apb](sim/uvm/agent/apb)
  - [ ] 新增 `apb_sequencer.sv`
  - [ ] 新增 `apb_driver.sv`
  - [ ] 新增 `apb_monitor.sv`
  - [ ] 新增 `apb_agent.sv`
- 目录：[sim/uvm/seq](sim/uvm/seq)
  - [ ] 新增 `apb_seq_item.sv`
  - [ ] 新增 `apb_one_shot_seq.sv`
  - DoD：test 不再直接调用 `vif` 任务，改由 sequence 驱动

## 2.3 Env 判分闭环

- 文件：[sim/uvm/env/soc_env.sv](sim/uvm/env/soc_env.sv)
  - [ ] 挂接 `apb_agent`
  - [ ] 增加最小 `scoreboard`（寄存器写后读一致性）
  - [ ] 增加 `predictor`（I2C/UDMA 关键状态预测）
  - DoD：测试结果由自动比对给出 PASS/FAIL，不依赖人工看 log

## 2.4 Phase1 首批用例

- 目录：[sim/uvm/test](sim/uvm/test)
  - [ ] `tc_i2c_basic_rw.sv`
  - [ ] `tc_i2c_repeat_start.sv`
  - [ ] `tc_udma_basic.sv`
  - [ ] `tc_udma_len_boundary.sv`（0/1/max）
  - DoD：四个用例可稳定回归，并记录 seed

## 2.5 覆盖率最小闭环

- 目录：[sim/uvm/cov](sim/uvm/cov)
  - [ ] I2C 覆盖：方向 x 字节数 x start 类型（normal/repeat）
  - [ ] UDMA 覆盖：通道 x 长度桶（0/1/2~15/16+）
  - [ ] APB 覆盖：关键寄存器 reset value + RW1C 清除路径
  - DoD：Phase1 功能覆盖率 >70%

---

## 3. 任务拆分（建议一周节奏）

- Day1~Day2：P0/P1 RTL（I2C/UDMA 核心行为）
- Day3：寄存器层统一（I2C/UDMA reg_top）
- Day4：UVM APB agent + env 判分最小闭环
- Day5：四个 Phase1 用例 + 覆盖率首轮评估

---

## 4. 每日完成定义（Definition of Done）

- [ ] 编译通过
- [ ] `smoke_apb_test` 通过
- [ ] 当日新增 test 通过
- [ ] 回归日志 + seed 归档
- [ ] 文档同步（本清单 + 相关 md）

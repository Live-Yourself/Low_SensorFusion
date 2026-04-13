# UVM Phase 阶段运行说明（sim/work 统一入口）

本文档用于统一说明 Phase 0 与 Phase 1 的运行方式、回归入口与判定标准。

---

## 1. 总体约定

- 编译与运行入口目录：`sim/work`
- filelist：`sim/work/vcs_flist.f`
- 仿真顶层：`tb_top`
- 基础门禁测试：`smoke_apb_test`

---

## 2. Phase 0 运行说明（已完成）

阶段目标：跑通 `smoke_apb_test`，验证 APB 寄存器访问链路。

### 2.1 阶段状态（2026-04-08）

- ✅ Phase 0 已完成
- ✅ `smoke_apb_test` 已达到稳定通过（满足连续 3 次通过准入要求）
- ✅ 当前无阻塞进入下一阶段的 P0 问题

### 2.2 主要文件

- `sim/uvm/tb/tb_top.sv`
- `sim/uvm/if/apb_if.sv`
- `sim/uvm/common/soc_uvm_pkg.sv`
- `sim/uvm/test/smoke_apb_test.sv`
- `sim/work/vcs_flist.f`

### 2.3 Phase 0 测试点

- PMU 寄存器写读
- RTC 比较寄存器写读
- I2C0 地址寄存器写读

---

## 3. Phase 1 运行说明（当前阶段）

阶段目标：完成 `I2C + UDMA + APB` 最小功能闭环，并保持 smoke 门禁稳定。

### 3.0 RTL 交付状态（2026-04-08 同步）

- 已完成 I2C/UDMA/APB 的 Phase1 完整版 RTL 升级（寄存器与行为模型对齐）：
  - `rtl/ip/i2c/sf_i2c_reg_top.sv`
  - `rtl/ip/i2c/sf_i2c_core.sv`
  - `rtl/ip/i2c/sf_i2c_top.sv`
  - `rtl/ip/udma/sf_udma_reg_top.sv`
  - `rtl/ip/udma/sf_udma_core.sv`
  - `rtl/ip/udma/sf_udma_top.sv`
- 当前文档与寄存器定义已同步到 `md/寄存器地图定义.md` v1.1。

## 3.1 必跑测试集合

- 提交门禁：
  - `smoke_apb_test`
  - `tc_i2c_basic_rw`（新增）
- 日构建回归：
  - `smoke_apb_test`
  - `tc_i2c_basic_rw`
  - `tc_i2c_repeat_start`
  - `tc_udma_basic`
  - `tc_udma_len_boundary`

## 3.2 运行流程

1. 在 `sim/work` 目录执行统一编译+仿真脚本。
2. 先执行提交门禁（smoke + i2c basic）。
3. 再执行 Phase 1 全测试回归（可多 seed）。
4. 归档日志、seed、覆盖率结果并更新阶段记录。

## 3.3 通过标准（Phase 1）

- `smoke_apb_test` 持续通过，不回退。
- I2C 基础读写、repeated-start 测试通过。
- UDMA 基础搬运与长度边界（0/1/常规）测试通过。
- APB 关键寄存器 `reset value` 与 `RW1C` 行为检查通过。
- 功能覆盖率达到阶段目标（>70%）。

## 3.4 失败处理要求

- 失败必须记录 test 名称、seed、关键报错与初步根因。
- 同一问题修复后，至少重跑“对应 test + 门禁集合”。
- 发现 P0/P1 问题优先阻断合入。

---

## 4. 目录约定

- `sim/uvm/filelist` 已移除，filelist 统一放 `sim/work`
- `sim/uvm/scripts` 已移除，编译脚本统一放 `sim/work`

---

## 5. 维护规则

- 阶段目标变化时，必须同步更新本文档对应章节。
- 新增/删除测试用例时，必须同步更新“必跑测试集合”。
- 门禁策略变化时，必须同步更新“通过标准”。

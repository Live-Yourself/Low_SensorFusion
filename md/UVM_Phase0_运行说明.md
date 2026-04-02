# UVM Phase-0 运行说明（迁移到 sim/work）

当前阶段目标：跑通 `smoke_apb_test`，验证 APB 寄存器访问链路。

## 主要文件
- `sim/uvm/tb/tb_top.sv`
- `sim/uvm/if/apb_if.sv`
- `sim/uvm/common/soc_uvm_pkg.sv`
- `sim/uvm/test/smoke_apb_test.sv`
- `sim/work/vcs_flist.f`

## 测试点
- PMU 寄存器写读
- RTC 比较寄存器写读
- I2C0 地址寄存器写读

## 下一步
- 增加 APB agent（driver/monitor/sequencer）
- 引入 scoreboard 与基础覆盖
- 扩展 I2C/UDMA 功能用例

## 目录约定更新
- `sim/uvm/filelist` 已移除，filelist 统一放 `sim/work`
- `sim/uvm/scripts` 已移除，后续编译脚本统一放 `sim/work`

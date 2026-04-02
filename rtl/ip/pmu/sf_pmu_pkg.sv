package sf_pmu_pkg;
  typedef enum logic [1:0] {
    PMU_RUN  = 2'b00,
    PMU_SLEEP= 2'b01,
    PMU_DEEP = 2'b10
  } pmu_mode_e;
endpackage

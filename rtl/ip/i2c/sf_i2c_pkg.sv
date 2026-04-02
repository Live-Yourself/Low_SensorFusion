package sf_i2c_pkg;
  typedef enum logic [1:0] {
    I2C_STD  = 2'b00,
    I2C_FAST = 2'b01,
    I2C_FMP  = 2'b10
  } i2c_speed_e;
endpackage

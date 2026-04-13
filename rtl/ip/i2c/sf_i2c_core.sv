module sf_i2c_core (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       i2c_en,
  input  logic [1:0] speed,
  input  logic [6:0] slv_addr,
  input  logic [7:0] tx_data,
  input  logic [7:0] subaddr,
  input  logic [7:0] byte_cnt,
  input  logic       start_go,
  input  logic       dir,
  input  logic       master_start,
  input  logic       master_stop,
  input  logic       repeat_start,
  input  logic       subaddr_en,
  input  logic       inj_nack,
  input  logic       inj_arb_lost,
  input  logic       inj_timeout,
  input  logic [7:0] tx_byte_data,
  input  logic       tx_byte_vld,
  output logic       tx_byte_req,
  output logic       rx_byte_vld,
  output logic       rx_byte_last,
  output logic [7:0] rx_byte_data,
  output logic [7:0] rx_data,
  output logic       busy,
  output logic       done,
  output logic       nack,
  output logic       arb_lost,
  output logic       timeout,
  input  logic       scl_i,
  output logic       scl_o,
  input  logic       sda_i,
  output logic       sda_o
);
  typedef enum logic [4:0] {
    ST_IDLE,
    ST_START_A,
    ST_START_B,
    ST_LOAD,
    ST_BIT_LOW,
    ST_BIT_HIGH,
    ST_ACK_LOW,
    ST_ACK_HIGH,
    ST_RESTART_A,
    ST_RESTART_B,
    ST_STOP_A,
    ST_STOP_B,
    ST_DONE,
    ST_ERROR
  } i2c_state_e;

  localparam logic [7:0] TIMEOUT_CYCLES = 8'hFF;

  i2c_state_e state;
  logic [15:0] div_cnt;
  logic [15:0] div_val;
  logic        tick;

  logic [7:0]  shifter;
  logic [2:0]  bit_cnt;
  logic [7:0]  bytes_left;
  logic [7:0]  timeout_cnt;
  logic [2:0]  phase_step;

  logic        cmd_dir;
  logic        cmd_subaddr_en;
  logic        cmd_repeat_start;
  logic        cmd_master_stop;
  logic [6:0]  cmd_slv_addr;
  logic [7:0]  cmd_tx_data;
  logic [7:0]  cmd_subaddr;

  logic        drive_scl_low;
  logic        drive_sda_low;
  logic        sda_sampled;

  logic        ack_err;
  logic        arb_err;
  logic        timeout_err;

  always_comb begin
    unique case (speed)
      2'b00: div_val = 16'd249; // ~100k (assuming ~50MHz pclk)
      2'b01: div_val = 16'd62;  // ~400k
      default: div_val = 16'd24; // ~1MHz
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      div_cnt <= 16'd0;
      tick <= 1'b0;
    end else if (busy) begin
      if (div_cnt == div_val) begin
        div_cnt <= 16'd0;
        tick <= 1'b1;
      end else begin
        div_cnt <= div_cnt + 16'd1;
        tick <= 1'b0;
      end
    end else begin
      div_cnt <= 16'd0;
      tick <= 1'b0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= ST_IDLE;
      busy            <= 1'b0;
      done            <= 1'b0;
      nack            <= 1'b0;
      arb_lost        <= 1'b0;
      timeout         <= 1'b0;
      rx_data         <= 8'h00;
      shifter         <= 8'h00;
      bit_cnt         <= 3'd7;
      bytes_left      <= 8'd0;
      timeout_cnt     <= 8'd0;
      phase_step      <= 3'd0;
      cmd_dir         <= 1'b0;
      cmd_subaddr_en  <= 1'b0;
      cmd_repeat_start<= 1'b0;
      cmd_master_stop <= 1'b0;
      cmd_slv_addr    <= 7'h00;
      cmd_tx_data     <= 8'h00;
      cmd_subaddr     <= 8'h00;
      tx_byte_req     <= 1'b0;
      rx_byte_vld     <= 1'b0;
      rx_byte_last    <= 1'b0;
      rx_byte_data    <= 8'h00;
      drive_scl_low   <= 1'b0;
      drive_sda_low   <= 1'b0;
      sda_sampled     <= 1'b1;
      ack_err         <= 1'b0;
      arb_err         <= 1'b0;
      timeout_err     <= 1'b0;
    end else begin
      done     <= 1'b0;
      nack     <= 1'b0;
      arb_lost <= 1'b0;
      timeout  <= 1'b0;
      tx_byte_req <= 1'b0;
      rx_byte_vld <= 1'b0;
      rx_byte_last <= 1'b0;

      if (busy) timeout_cnt <= timeout_cnt + 8'd1;
      else timeout_cnt <= 8'd0;

      if (busy && (timeout_cnt == TIMEOUT_CYCLES) && inj_timeout) begin
        timeout_err <= 1'b1;
        state <= ST_ERROR;
      end

      case (state)
        ST_IDLE: begin
          busy          <= 1'b0;
          drive_scl_low <= 1'b0;
          drive_sda_low <= 1'b0;
          phase_step    <= 3'd0;
          ack_err       <= 1'b0;
          arb_err       <= 1'b0;
          timeout_err   <= 1'b0;
          if (start_go && i2c_en) begin
            busy             <= 1'b1;
            cmd_dir          <= dir;
            cmd_subaddr_en   <= subaddr_en;
            cmd_repeat_start <= repeat_start;
            cmd_master_stop  <= master_stop;
            cmd_slv_addr     <= slv_addr;
            cmd_tx_data      <= tx_data;
            cmd_subaddr      <= subaddr;
            bytes_left       <= (byte_cnt == 8'd0) ? 8'd1 : byte_cnt;
            state            <= master_start ? ST_START_A : ST_LOAD;
          end
        end

        ST_START_A: if (tick) begin
          drive_scl_low <= 1'b0;
          drive_sda_low <= 1'b0;
          state <= ST_START_B;
        end

        ST_START_B: if (tick) begin
          drive_sda_low <= 1'b1;
          drive_scl_low <= 1'b0;
          state <= ST_LOAD;
        end

        ST_LOAD: begin
          bit_cnt <= 3'd7;
          if (phase_step == 3'd0) begin
            shifter <= {cmd_slv_addr, (cmd_subaddr_en || !cmd_dir) ? 1'b0 : 1'b1};
            phase_step <= 3'd1;
            state <= ST_BIT_LOW;
          end else if ((phase_step == 3'd1) && cmd_subaddr_en) begin
            shifter <= cmd_subaddr;
            phase_step <= cmd_repeat_start && cmd_dir ? 3'd2 : 3'd3;
            state <= ST_BIT_LOW;
          end else if (phase_step == 3'd2) begin
            state <= ST_RESTART_A;
          end else begin
            if (cmd_dir) begin
              shifter <= 8'h00;
              state <= ST_BIT_LOW;
            end else if (tx_byte_vld) begin
              shifter <= tx_byte_data;
              state <= ST_BIT_LOW;
            end else begin
              tx_byte_req <= 1'b1;
              state <= ST_LOAD;
            end
          end
        end

        ST_BIT_LOW: if (tick) begin
          drive_scl_low <= 1'b1;
          // Read data phase: master releases SDA; write/address/subaddr phase: shift out bits
          if (cmd_dir && (phase_step == 3'd3)) drive_sda_low <= 1'b0;
          else drive_sda_low <= ~shifter[bit_cnt];
          state <= ST_BIT_HIGH;
        end

        ST_BIT_HIGH: if (tick) begin
          drive_scl_low <= 1'b0;
          sda_sampled <= sda_i;
          if (shifter[bit_cnt] && (sda_i == 1'b0)) begin
            arb_err <= 1'b1;
            state <= ST_ERROR;
          end else if (bit_cnt == 3'd0) begin
            state <= ST_ACK_LOW;
          end else begin
            bit_cnt <= bit_cnt - 3'd1;
            state <= ST_BIT_LOW;
          end
        end

        ST_ACK_LOW: if (tick) begin
          drive_scl_low <= 1'b1;
          // Write/address/subaddr: slave drives ACK (master releases SDA)
          // Read data: master drives ACK=0 for more bytes, NACK=1 for last byte
          if (cmd_dir && (phase_step == 3'd3)) drive_sda_low <= (bytes_left > 8'd1);
          else drive_sda_low <= 1'b0;
          state <= ST_ACK_HIGH;
        end

        ST_ACK_HIGH: if (tick) begin
          drive_scl_low <= 1'b0;
          if (cmd_dir && (phase_step == 3'd3)) begin
            // Read byte complete
            if (bytes_left > 8'd1) begin
              bytes_left <= bytes_left - 8'd1;
              bit_cnt <= 3'd7;
              shifter <= 8'h00;
              state <= ST_BIT_LOW;
            end else if (cmd_master_stop) begin
              state <= ST_STOP_A;
            end else begin
              state <= ST_DONE;
            end
          end else begin
            // Slave ACK check for write/address/subaddr phases
            if (inj_nack || (sda_i == 1'b1)) begin
              ack_err <= 1'b1;
              state <= ST_ERROR;
            end else if (phase_step == 3'd1 && cmd_subaddr_en) begin
              state <= ST_LOAD;
            end else if (phase_step == 3'd2) begin
              state <= ST_RESTART_A;
            end else if (cmd_dir) begin
              bit_cnt <= 3'd7;
              shifter <= 8'h00;
              state <= ST_BIT_LOW;
            end else begin
              if (bytes_left > 8'd1) begin
                bytes_left <= bytes_left - 8'd1;
                state <= ST_LOAD;
              end else if (cmd_master_stop) begin
                state <= ST_STOP_A;
              end else begin
                state <= ST_DONE;
              end
            end
          end
        end

        ST_RESTART_A: if (tick) begin
          drive_scl_low <= 1'b0;
          drive_sda_low <= 1'b0;
          state <= ST_RESTART_B;
        end

        ST_RESTART_B: if (tick) begin
          if (inj_arb_lost) begin
            arb_err <= 1'b1;
            state <= ST_ERROR;
          end else begin
            drive_sda_low <= 1'b1;
            phase_step <= 3'd3;
            shifter <= {cmd_slv_addr, 1'b1};
            bit_cnt <= 3'd7;
            state <= ST_BIT_LOW;
          end
        end

        ST_STOP_A: if (tick) begin
          drive_scl_low <= 1'b1;
          drive_sda_low <= 1'b1;
          state <= ST_STOP_B;
        end

        ST_STOP_B: if (tick) begin
          drive_scl_low <= 1'b0;
          drive_sda_low <= 1'b0;
          state <= ST_DONE;
        end

        ST_ERROR: begin
          if (ack_err) nack <= 1'b1;
          if (arb_err) arb_lost <= 1'b1;
          if (timeout_err) timeout <= 1'b1;
          state <= cmd_master_stop ? ST_STOP_A : ST_DONE;
        end

        ST_DONE: begin
          done <= 1'b1;
          busy <= 1'b0;
          drive_scl_low <= 1'b0;
          drive_sda_low <= 1'b0;
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase

      // Read data sampling path
      if (state == ST_BIT_HIGH && tick && cmd_dir) begin
        shifter[bit_cnt] <= sda_i;
        if (bit_cnt == 3'd0) begin
          rx_data <= {shifter[7:1], sda_i};
          rx_byte_data <= {shifter[7:1], sda_i};
          rx_byte_vld <= 1'b1;
          rx_byte_last <= (bytes_left == 8'd1);
        end
      end
    end
  end

  // Open-drain style model: 0 = pull low, 1 = release high
  assign scl_o = drive_scl_low ? 1'b0 : 1'b1;
  assign sda_o = drive_sda_low ? 1'b0 : 1'b1;

  logic unused_scl_i;
  assign unused_scl_i = scl_i;
endmodule

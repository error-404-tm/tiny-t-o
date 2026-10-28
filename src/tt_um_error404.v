/*
 * Copyright (c) 2026 Joe Frost
 * SPDX-License-Identifier: Apache-2.0
 *
 * UART moving-average filter with tamper lockout.
 *
 * 16-bit samples arrive over UART (low byte first), pass through an
 * 8-tap moving-average filter, and the filtered value is sent back over
 * UART (low byte first). If the lid switch input goes low, the design
 * latches into a secure hold and ignores samples until the unlock
 * sequence 0x09, 0x0B, 0x54 is received with the lid closed again.
 */

`default_nettype none

module tt_um_error404 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // 50 MHz clock / 115200 baud = 434 clocks per bit
  localparam [15:0] CLOCKS_PER_BIT = 16'd434;

  wire rst = ~rst_n;

  // Pin mapping (UART pins follow the Tiny Tapeout convention)
  wire lid_switch = ui_in[0];  // 1 = lid closed, 0 = open / tamper
  wire uart_rx_in = ui_in[3];  // UART RX

  wire [7:0]  rx_byte;
  wire        rx_byte_valid;
  wire [15:0] rx_sample;
  wire        rx_sample_valid;
  wire [15:0] filtered_data;
  wire        output_valid;
  wire        uart_start;
  wire [7:0]  uart_data;
  wire        uart_busy;
  wire        uart_tx_out;
  wire        secure_hold;
  wire [2:0]  debug_state;
  wire        tx_frame_busy;

  uart_rx uart_receiver (
      .clk           (clk),
      .rst           (rst),
      .rx            (uart_rx_in),
      .clocks_per_bit(CLOCKS_PER_BIT),
      .data          (rx_byte),
      .data_valid    (rx_byte_valid)
  );

  sample_rx sample_receiver (
      .clk         (clk),
      .rst         (rst),
      .secure_hold (secure_hold),
      .uart_data   (rx_byte),
      .uart_valid  (rx_byte_valid),
      .sample_data (rx_sample),
      .sample_valid(rx_sample_valid)
  );

  moving_average filter (
      .clk         (clk),
      .reset       (rst),
      .sample_valid(rx_sample_valid),
      .sample_in   (rx_sample),
      .secure_hold (secure_hold),
      .sample_out  (filtered_data),
      .output_valid(output_valid)
  );

  sample_tx sample_transmitter (
      .clk         (clk),
      .rst         (rst),
      .secure_hold (secure_hold),
      .sample_valid(output_valid),
      .sample_data (filtered_data),
      .uart_busy   (uart_busy),
      .uart_start  (uart_start),
      .uart_data   (uart_data),
      .busy        (tx_frame_busy)
  );

  uart_tx uart_transmitter (
      .clk           (clk),
      .rst           (rst),
      .start         (uart_start),
      .data          (uart_data),
      .clocks_per_bit(CLOCKS_PER_BIT),
      .tx            (uart_tx_out),
      .busy          (uart_busy)
  );

  security_ctrl lid_sensor (
      .clk        (clk),
      .rst        (rst),
      .lid_switch (lid_switch),
      .cmd_byte   (rx_byte),
      .cmd_valid  (rx_byte_valid),
      .secure_hold(secure_hold),
      .debug_state(debug_state)
  );

  assign uo_out[0]   = secure_hold;
  assign uo_out[1]   = uart_busy;
  assign uo_out[2]   = output_valid;
  assign uo_out[3]   = 1'b0;
  assign uo_out[4]   = uart_tx_out;  // UART TX
  assign uo_out[7:5] = debug_state;

  // Bidirectional pins are unused
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, tx_frame_busy, ui_in[7:4], ui_in[2:1], uio_in, 1'b0};

endmodule

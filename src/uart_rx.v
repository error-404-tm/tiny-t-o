`default_nettype none

// 8N1 UART receiver. data_valid pulses for one clock per received byte.
module uart_rx (
    input  wire        clk,
    input  wire        rst,
    input  wire        rx,
    input  wire [15:0] clocks_per_bit,
    output reg  [7:0]  data,
    output reg         data_valid
);

  localparam [1:0] IDLE      = 2'd0;
  localparam [1:0] START_BIT = 2'd1;
  localparam [1:0] DATA_BITS = 2'd2;
  localparam [1:0] STOP_BIT  = 2'd3;

  reg [1:0]  state;
  reg [15:0] clock_counter;
  reg [2:0]  bit_index;
  reg [7:0]  data_buffer;

  // Two-flop synchronizer: the RX pin is asynchronous to clk
  reg rx_meta, rx_sync;

  always @(posedge clk) begin
    if (rst) begin
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
    end else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state         <= IDLE;
      clock_counter <= 16'd0;
      bit_index     <= 3'd0;
      data_buffer   <= 8'd0;
      data          <= 8'd0;
      data_valid    <= 1'b0;
    end else begin
      data_valid <= 1'b0;

      case (state)
        // Wait for the line to go low
        IDLE: begin
          clock_counter <= 16'd0;
          bit_index     <= 3'd0;
          if (!rx_sync) state <= START_BIT;
        end

        // Move to the middle of the start bit and confirm it is still low
        START_BIT: begin
          if (clock_counter == ((clocks_per_bit - 16'd1) >> 1)) begin
            clock_counter <= 16'd0;
            state <= rx_sync ? IDLE : DATA_BITS;  // false start -> IDLE
          end else begin
            clock_counter <= clock_counter + 16'd1;
          end
        end

        // Sample 8 data bits, LSB first
        DATA_BITS: begin
          if (clock_counter == clocks_per_bit - 16'd1) begin
            clock_counter          <= 16'd0;
            data_buffer[bit_index] <= rx_sync;
            if (bit_index == 3'd7) state <= STOP_BIT;
            bit_index <= bit_index + 3'd1;
          end else begin
            clock_counter <= clock_counter + 16'd1;
          end
        end

        // Wait one bit time, accept the frame only if the stop bit is high
        STOP_BIT: begin
          if (clock_counter == clocks_per_bit - 16'd1) begin
            clock_counter <= 16'd0;
            if (rx_sync) begin
              data       <= data_buffer;
              data_valid <= 1'b1;
            end
            state <= IDLE;
          end else begin
            clock_counter <= clock_counter + 16'd1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

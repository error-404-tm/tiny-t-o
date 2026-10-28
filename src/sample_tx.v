`default_nettype none

// Sends a 16-bit sample as two UART bytes, low byte first.
module sample_tx (
    input  wire        clk,
    input  wire        rst,
    input  wire        secure_hold,
    input  wire        sample_valid,
    input  wire [15:0] sample_data,
    input  wire        uart_busy,
    output reg         uart_start,
    output reg  [7:0]  uart_data,
    output reg         busy
);

  localparam [2:0] IDLE      = 3'd0;
  localparam [2:0] SEND_LOW  = 3'd1;
  localparam [2:0] WAIT_LOW  = 3'd2;
  localparam [2:0] SEND_HIGH = 3'd3;
  localparam [2:0] WAIT_HIGH = 3'd4;

  reg [2:0]  state;
  reg [15:0] sample_latched;
  reg        delay;  // gives uart_tx one cycle to raise busy

  always @(posedge clk) begin
    if (rst) begin
      state          <= IDLE;
      sample_latched <= 16'd0;
      delay          <= 1'b0;
      uart_start     <= 1'b0;
      uart_data      <= 8'd0;
      busy           <= 1'b0;
    end else begin
      uart_start <= 1'b0;

      if (secure_hold) begin
        state <= IDLE;
        busy  <= 1'b0;
        delay <= 1'b0;
      end else begin
        case (state)
          IDLE: begin
            busy <= 1'b0;
            if (sample_valid) begin
              sample_latched <= sample_data;
              busy           <= 1'b1;
              state          <= SEND_LOW;
            end
          end

          SEND_LOW: begin
            if (!uart_busy) begin
              uart_data  <= sample_latched[7:0];
              uart_start <= 1'b1;
              delay      <= 1'b1;
              state      <= WAIT_LOW;
            end
          end

          WAIT_LOW: begin
            if (!uart_busy && !delay) state <= SEND_HIGH;
            delay <= 1'b0;
          end

          SEND_HIGH: begin
            if (!uart_busy) begin
              uart_data  <= sample_latched[15:8];
              uart_start <= 1'b1;
              delay      <= 1'b1;
              state      <= WAIT_HIGH;
            end
          end

          WAIT_HIGH: begin
            if (!uart_busy && !delay) begin
              busy  <= 1'b0;
              state <= IDLE;
            end
            delay <= 1'b0;
          end

          default: state <= IDLE;
        endcase
      end
    end
  end

endmodule

`default_nettype none

// 8N1 UART transmitter. Pulse start for one clock while busy is low.
module uart_tx (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  data,
    input  wire [15:0] clocks_per_bit,
    output reg         tx,
    output reg         busy
);

  reg [15:0] baud_counter;
  reg [3:0]  bit_index;     // 0-7 data bits, 8 stop bit
  reg [7:0]  data_latched;

  always @(posedge clk) begin
    if (rst) begin
      tx           <= 1'b1;
      busy         <= 1'b0;
      baud_counter <= 16'd0;
      bit_index    <= 4'd0;
      data_latched <= 8'd0;
    end else if (!busy) begin
      tx <= 1'b1;
      if (start) begin
        busy         <= 1'b1;
        data_latched <= data;
        baud_counter <= 16'd0;
        bit_index    <= 4'd0;
        tx           <= 1'b0;  // start bit begins immediately
      end
    end else if (baud_counter < clocks_per_bit - 16'd1) begin
      baud_counter <= baud_counter + 16'd1;
    end else begin
      baud_counter <= 16'd0;
      if (bit_index < 4'd8) begin
        tx        <= data_latched[bit_index[2:0]];
        bit_index <= bit_index + 4'd1;
      end else if (bit_index == 4'd8) begin
        tx        <= 1'b1;  // stop bit
        bit_index <= 4'd9;
      end else begin
        tx        <= 1'b1;  // stop bit done
        busy      <= 1'b0;
        bit_index <= 4'd0;
      end
    end
  end

endmodule

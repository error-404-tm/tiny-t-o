`default_nettype none

// Assembles two UART bytes (low byte first) into one 16-bit sample.
module sample_rx (
    input  wire        clk,
    input  wire        rst,
    input  wire        secure_hold,
    input  wire [7:0]  uart_data,
    input  wire        uart_valid,
    output reg  [15:0] sample_data,
    output reg         sample_valid
);

  reg [7:0] low_byte;
  reg       byte_select;

  always @(posedge clk) begin
    if (rst) begin
      sample_data  <= 16'd0;
      sample_valid <= 1'b0;
      low_byte     <= 8'd0;
      byte_select  <= 1'b0;
    end else begin
      sample_valid <= 1'b0;

      if (secure_hold) begin
        // Do not consume UART bytes as sample data while locked
        byte_select <= 1'b0;
      end else if (uart_valid) begin
        if (!byte_select) begin
          low_byte    <= uart_data;
          byte_select <= 1'b1;
        end else begin
          sample_data  <= {uart_data, low_byte};
          sample_valid <= 1'b1;
          byte_select  <= 1'b0;
        end
      end
    end
  end

endmodule

`default_nettype none

// 8-tap moving-average filter over 16-bit samples.
// output_valid pulses once the first 8 samples have been seen.
module moving_average (
    input  wire        clk,
    input  wire        reset,
    input  wire        sample_valid,
    input  wire [15:0] sample_in,
    input  wire        secure_hold,
    output reg  [15:0] sample_out,
    output reg         output_valid
);

  reg [15:0] samples[0:7];
  reg [18:0] sum;
  reg [2:0]  index;
  reg [3:0]  count;

  wire [18:0] next_sum = sum - {3'b000, samples[index]} + {3'b000, sample_in};

  integer i;

  always @(posedge clk) begin
    if (reset) begin
      sum          <= 19'd0;
      index        <= 3'd0;
      count        <= 4'd0;
      sample_out   <= 16'd0;
      output_valid <= 1'b0;
      for (i = 0; i < 8; i = i + 1) samples[i] <= 16'd0;
    end else if (secure_hold) begin
      // Preserve filter state while locked
      output_valid <= 1'b0;
    end else if (sample_valid) begin
      sum            <= next_sum;     // drop oldest, add newest
      samples[index] <= sample_in;    // overwrite oldest
      index          <= index + 3'd1;
      if (count < 4'd8) count <= count + 4'd1;

      if (count >= 4'd7) begin
        sample_out   <= next_sum[18:3];  // divide by 8
        output_valid <= 1'b1;
      end else begin
        output_valid <= 1'b0;
      end
    end else begin
      output_valid <= 1'b0;
    end
  end

endmodule

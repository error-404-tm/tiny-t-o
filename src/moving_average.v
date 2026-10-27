`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 03:25:25 PM
// Design Name: 
// Module Name: moving_average
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module moving_average(
    input wire clk,
    input wire reset,
    input wire sample_valid,
    input wire [15:0] sample_in,
    input wire secure_hold,
    
    output reg [15:0] sample_out,
    output reg output_valid
    );
    
    reg [15:0] samples [0:7];
    reg [18:0] sum;
    reg [2:0]  index;
    reg [3:0]  count;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            sum          <= 0;
            index        <= 0;
            count        <= 0;
            sample_out   <= 0;
            output_valid <= 0;

            for (i = 0; i < 8; i = i + 1)
                samples[i] <= 0;
        end
        else if (secure_hold) begin
            // Security hold:
            // preserve filter state.
            output_valid <= 1'b0;
        end 
        else if (sample_valid) begin

            // Remove oldest sample and add newest
            sum <= sum - samples[index] + sample_in;

            // Replace oldest sample
            samples[index] <= sample_in;

            // Advance circular-buffer position
            index <= index + 1;

            // Wait until we've received 8 real samples
            if (count < 8)
                count <= count + 1;

            if (count >= 7) begin
                sample_out <=
                    (sum - samples[index] + sample_in) >> 3;
                output_valid <= 1;
            end
            else begin
                output_valid <= 0;
            end
        end
        else begin
            output_valid <= 0;
        end
    end

    
    
endmodule

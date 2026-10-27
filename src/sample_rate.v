`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 02:41:34 PM
// Design Name: 
// Module Name: sample_rate
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


module sample_rate(
    input wire clk,
    output reg sample_enable = 0
    );
    reg [25:0] counter = 0;
    
    always @(posedge clk) begin
        if (counter == 49_999_999) begin
            counter <=0;
            sample_enable <=1;
        end
        else begin
            counter <= counter + 1;
            sample_enable <= 0;
        end
    end
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 02:12:16 PM
// Design Name: 
// Module Name: clk_divid
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


module clk_divid(
    input clk_in,
    output div_out
    );
    
    reg [25:0] counter = 0;

always @(posedge clk_in) begin
    counter <= counter + 1;
end
    assign div_out = counter[24];
    
endmodule

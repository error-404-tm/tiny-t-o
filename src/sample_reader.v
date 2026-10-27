`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 11:45:47 AM
// Design Name: 
// Module Name: sample_reader
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


module sample_reader (
    input  wire        clk,
    input  wire        enable,
    input  wire        reset,
    output reg  [15:0] sample_data,
    output reg         sample_valid
    
);

    reg [15:0] memory [0:15];
    reg [7:0] address = 0;

    initial begin
        $readmemh("samples.mem", memory);
    end
    
    always @(posedge clk) begin
    sample_valid <= 1'b0;
        if(reset) begin
            address <= 0;
        end
        else if (enable) begin
            sample_data  <= memory[address];
            address <= address + 1;
            sample_valid <= 1'b1;
        end
    end

endmodule

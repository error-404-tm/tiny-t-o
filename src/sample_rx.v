`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/28/2026 07:16:26 PM
// Design Name: 
// Module Name: sample_rx
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


module sample_rx (
    input  wire        clk,
    input  wire        secure_hold,
    input  wire [7:0]  uart_data,
    input  wire        uart_valid,

    output reg  [15:0] sample_data  = 16'd0,
    output reg         sample_valid = 1'b0
);

    reg [7:0] low_byte = 8'd0;
    reg       byte_select = 1'b0;

    always @(posedge clk) begin

    sample_valid <= 1'b0;

    if (secure_hold) begin
        // Security hold:
        // do not consume UART bytes as sample data.
        byte_select <= 1'b0;
    end
    else if (uart_valid) begin

        if (byte_select == 1'b0) begin
            low_byte    <= uart_data;
            byte_select <= 1'b1;
        end
        else begin
            sample_data  <= {uart_data, low_byte};
            sample_valid <= 1'b1;
            byte_select  <= 1'b0;
        end

    end
end

endmodule

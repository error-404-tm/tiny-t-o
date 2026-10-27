`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 02:12:25 PM
// Design Name: 
// Module Name: sample_tx
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


module sample_tx (
    input  wire        clk,
    input  wire        secure_hold,
    input  wire        sample_valid,
    input  wire [15:0] sample_data,

    input  wire        uart_busy,
    output reg         uart_start = 0,
    output reg  [7:0]  uart_data  = 0,

    output reg         busy = 0
);

    localparam IDLE             = 3'd0;
    localparam SEND_LOW         = 3'd1;
    localparam WAIT_LOW         = 3'd2;
    localparam SEND_HIGH        = 3'd3;
    localparam WAIT_HIGH        = 3'd4;
    
    
    reg [2:0] state = IDLE;
    reg [15:0] sample_latched = 0;
    reg delay = 0;

    always @(posedge clk) begin
        uart_start <= 1'b0;
    
        if (secure_hold) begin
            state <= IDLE;
            busy  <= 1'b0;
            delay <= 1'b0;
        end
        else begin
            case (state)
    
                IDLE: begin
                    busy <= 1'b0;
    
                    if (sample_valid) begin
                        sample_latched <= sample_data;
                        busy <= 1'b1;
                        state <= SEND_LOW;
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
                    if (!uart_busy & !delay) begin
                        state <= SEND_HIGH;
                    end
                    delay <= 0;
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
                    if (!uart_busy & !delay) begin
                        busy  <= 1'b0;
                        state <= IDLE;
                    end
                    delay <= 0;
                end
    
            endcase
        end     
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/28/2026 07:04:48 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx (
    input  wire        clk,
    input  wire        rx,
    input  wire [15:0] clocks_per_bit,
    //input  wire        secure_hold,

    output reg  [7:0]  data       = 8'd0,
    output reg         data_valid = 1'b0
);

    localparam IDLE       = 3'd0;
    localparam START_BIT  = 3'd1;
    localparam DATA_BITS  = 3'd2;
    localparam STOP_BIT   = 3'd3;

    reg [2:0]  state = IDLE;

    reg [15:0] clock_counter = 16'd0;
    reg [2:0]  bit_index     = 3'd0;
    reg [7:0]  data_buffer   = 8'd0;

    always @(posedge clk) begin

        // data_valid is only asserted for one clock
        data_valid <= 1'b0;
        
        
            case (state)
    
                // -----------------------------------------
                // Wait for RX line to go low
                // -----------------------------------------
                IDLE: begin
                    clock_counter <= 16'd0;
                    bit_index     <= 3'd0;
    
                    if (rx == 1'b0) begin
                        state <= START_BIT;
                    end
                end
    
    
                // -----------------------------------------
                // Move to the middle of the start bit
                // and make sure it is still low.
                // -----------------------------------------
                START_BIT: begin
    
                    if (clock_counter ==
                        ((clocks_per_bit - 1) >> 1)) begin
    
                        clock_counter <= 16'd0;
    
                        if (rx == 1'b0) begin
                            state <= DATA_BITS;
                        end
                        else begin
                            // False start
                            state <= IDLE;
                        end
    
                    end
                    else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end
    
    
                // -----------------------------------------
                // Sample 8 data bits, LSB first
                // -----------------------------------------
                DATA_BITS: begin
    
                    if (clock_counter == clocks_per_bit - 1) begin
    
                        clock_counter <= 16'd0;
    
                        data_buffer[bit_index] <= rx;
    
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STOP_BIT;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
    
                    end
                    else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end
    
    
                // -----------------------------------------
                // Wait one stop-bit interval.
                // Then publish the received byte.
                // -----------------------------------------
                STOP_BIT: begin
    
                    if (clock_counter == clocks_per_bit - 1) begin
    
                        clock_counter <= 16'd0;
    
                        // Only accept frame if stop bit is high
                        if (rx == 1'b1) begin
                            data       <= data_buffer;
                            data_valid <= 1'b1;
                        end
    
                        state <= IDLE;
    
                    end
                    else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end
    
    
                default: begin
                    state <= IDLE;
                end
    
            endcase
       
    end

endmodule
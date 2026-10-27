`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 12:22:19 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx (
    input  wire        clk,
    input  wire        start,
    input  wire [7:0]  data,
    input  wire [15:0] clocks_per_bit,

    output reg         tx   = 1'b1,
    output reg         busy = 1'b0
);

    reg [15:0] baud_counter = 0;
    reg [3:0]  bit_index = 0;
    reg [7:0]  data_latched = 0;

    always @(posedge clk) begin
        // IDLE
        if (!busy) begin
            tx <= 1'b1;

            if (start) begin
                busy         <= 1'b1;
                data_latched <= data;
                baud_counter <= 0;
                bit_index    <= 0;

                // Start bit begins immediately
                tx <= 1'b0;
            end
        end

        // TRANSMITTING
        else begin

            if (baud_counter < clocks_per_bit - 1) begin
                baud_counter <= baud_counter + 1;
            end

            else begin
                baud_counter <= 0;

                case (bit_index)

                    0: begin
                        tx <= data_latched[0];
                        bit_index <= 1;
                    end

                    1: begin
                        tx <= data_latched[1];
                        bit_index <= 2;
                    end

                    2: begin
                        tx <= data_latched[2];
                        bit_index <= 3;
                    end

                    3: begin
                        tx <= data_latched[3];
                        bit_index <= 4;
                    end

                    4: begin
                        tx <= data_latched[4];
                        bit_index <= 5;
                    end

                    5: begin
                        tx <= data_latched[5];
                        bit_index <= 6;
                    end

                    6: begin
                        tx <= data_latched[6];
                        bit_index <= 7;
                    end

                    7: begin
                        tx <= data_latched[7];
                        bit_index <= 8;
                    end

                    8: begin
                        // Stop bit
                        tx <= 1'b1;
                        bit_index <= 9;
                    end

                    9: begin
                        // Transmission complete
                        tx <= 1'b1;
                        busy <= 1'b0;
                        bit_index <= 0;
                    end

                endcase
            end
        end
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2026 01:22:35 PM
// Design Name: 
// Module Name: security_ctrl
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


module security_ctrl(
    input  wire       clk,
    input  wire       lid_switch,
    input  wire [7:0] cmd_byte,
    input  wire       cmd_valid,
    output reg        secure_hold = 1'b0,
    output wire [2:0] debug_state
);

    localparam LATCH  = 3'd0;
    localparam PASS1  = 3'd1;
    localparam PASS2  = 3'd2;
    localparam RUN_OK = 3'd3;

    reg lid_meta = 1'b1;
    reg lid_sync = 1'b1;
    reg [2:0] state = RUN_OK;
    
    assign debug_state = state;

    always @(posedge clk) begin
            lid_meta <= lid_switch;
            lid_sync <= lid_meta;

        case (state)

            RUN_OK: begin
                secure_hold <= 1'b0;

                // Assuming 0 = lid open / tamper
                if (!lid_sync)
                    state <= LATCH;
            end


            LATCH: begin
                secure_hold <= 1'b1;

                if (cmd_valid) begin
                    if (cmd_byte == 8'h09)
                        state <= PASS1;
                    else
                        state <= LATCH;
                end
            end


            PASS1: begin
                secure_hold <= 1'b1;

                if (cmd_valid) begin
                    if (cmd_byte == 8'h0B)
                        state <= PASS2;
                    else
                        state <= LATCH;
                end
            end


            PASS2: begin
                secure_hold <= 1'b1;

                if (cmd_valid) begin
                    if ((cmd_byte == 8'h54) && lid_sync)
                        state <= RUN_OK;
                    else
                        state <= LATCH;
                end
            end


            default: begin
                state       <= LATCH;
                secure_hold <= 1'b1;
            end

        endcase
    end

endmodule

`default_nettype none

// Tamper lockout. Opening the lid (lid_switch = 0) latches secure_hold.
// Unlock by sending 0x09, 0x0B, 0x54 over UART with the lid closed.
module security_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire       lid_switch,
    input  wire [7:0] cmd_byte,
    input  wire       cmd_valid,
    output reg        secure_hold,
    output wire [2:0] debug_state
);

  localparam [2:0] LATCH  = 3'd0;
  localparam [2:0] PASS1  = 3'd1;
  localparam [2:0] PASS2  = 3'd2;
  localparam [2:0] RUN_OK = 3'd3;

  reg       lid_meta, lid_sync;
  reg [2:0] state;

  assign debug_state = state;

  always @(posedge clk) begin
    if (rst) begin
      lid_meta    <= 1'b1;
      lid_sync    <= 1'b1;
      state       <= RUN_OK;
      secure_hold <= 1'b0;
    end else begin
      lid_meta <= lid_switch;
      lid_sync <= lid_meta;

      case (state)
        RUN_OK: begin
          secure_hold <= 1'b0;
          if (!lid_sync) state <= LATCH;
        end

        LATCH: begin
          secure_hold <= 1'b1;
          if (cmd_valid && cmd_byte == 8'h09) state <= PASS1;
        end

        PASS1: begin
          secure_hold <= 1'b1;
          if (cmd_valid) state <= (cmd_byte == 8'h0B) ? PASS2 : LATCH;
        end

        PASS2: begin
          secure_hold <= 1'b1;
          if (cmd_valid) state <= (cmd_byte == 8'h54 && lid_sync) ? RUN_OK : LATCH;
        end

        default: begin
          state       <= LATCH;
          secure_hold <= 1'b1;
        end
      endcase
    end
  end

endmodule

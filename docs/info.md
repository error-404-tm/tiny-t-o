## How it works

The design is a UART-connected digital filter with a tamper lockout.

1. **UART receive** (`uart_rx`): 8N1 at 115200 baud with a 50 MHz clock. The RX pin passes through a two-flop synchronizer.
2. **Sample assembly** (`sample_rx`): pairs of received bytes are combined into 16-bit samples, low byte first.
3. **Moving average** (`moving_average`): an 8-tap circular buffer keeps a running sum. Each new sample replaces the oldest one, and the output is the sum divided by 8. Output starts once 8 samples have arrived.
4. **UART transmit** (`sample_tx`, `uart_tx`): each filtered value is sent back as two bytes, low byte first.
5. **Tamper lockout** (`security_ctrl`): if `LID_SW` goes low, the design latches into a secure hold. While held, incoming samples are ignored and nothing is transmitted, but the filter keeps its state. To unlock, close the lid (`LID_SW` high) and send the bytes `0x09`, `0x0B`, `0x54` in that order. Any wrong byte returns to the locked state.

The current lockout state is visible on `STATE[2:0]`: 3 = running, 0 = locked, 1 and 2 = partway through the unlock code.

## How to test

1. Hold `LID_SW` (ui[0]) high and reset the design.
2. Connect a USB-UART adapter at 115200 8N1: adapter TX to `UART_RX` (ui[3]), adapter RX to `UART_TX` (uo[4]).
3. Send 16-bit samples as two bytes each, low byte first. After the eighth sample, every new sample produces one 16-bit reply equal to the average of the last eight.
4. Pull `LID_SW` low. `SECURE_HOLD` (uo[0]) goes high and samples are ignored.
5. Pull `LID_SW` high again and send `09 0B 54`. `SECURE_HOLD` drops and filtering resumes where it left off.

The cocotb testbench in `test/test.py` runs through all of these steps.

## External hardware

- A USB-UART adapter (3.3 V logic)
- A switch or jumper on `LID_SW`

# SPDX-FileCopyrightText: © 2026 Joe Frost
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer, with_timeout

CLK_NS = 20                 # 50 MHz
CLOCKS_PER_BIT = 434        # 115200 baud
BIT_NS = CLK_NS * CLOCKS_PER_BIT

LID_BIT = 0                 # ui_in[0]
RX_BIT = 3                  # ui_in[3]


class Harness:
    def __init__(self, dut):
        self.dut = dut
        self.ui = (1 << LID_BIT) | (1 << RX_BIT)   # lid closed, RX idle high
        self.received = []

    def _apply(self):
        self.dut.ui_in.value = self.ui

    def set_bit(self, bit, level):
        if level:
            self.ui |= 1 << bit
        else:
            self.ui &= ~(1 << bit)
        self._apply()

    async def send_byte(self, value):
        bits = [0] + [(value >> i) & 1 for i in range(8)] + [1]
        for b in bits:
            self.set_bit(RX_BIT, b)
            await Timer(BIT_NS, unit="ns")

    async def send_sample(self, value):
        await self.send_byte(value & 0xFF)
        await self.send_byte((value >> 8) & 0xFF)

    async def uart_monitor(self):
        """Decode bytes coming out of uo_out[4]."""
        while True:
            await FallingEdge(self.dut.uart_tx)
            await Timer(BIT_NS + BIT_NS // 2, unit="ns")   # middle of bit 0
            value = 0
            for i in range(8):
                value |= int(self.dut.uart_tx.value) << i
                await Timer(BIT_NS, unit="ns")
            assert int(self.dut.uart_tx.value) == 1, "bad stop bit"
            self.received.append(value)

    async def expect_sample(self, expected, timeout_bits=60):
        async def wait():
            while len(self.received) < 2:
                await Timer(BIT_NS, unit="ns")
        await with_timeout(wait(), timeout_bits * BIT_NS, "ns")
        lo, hi = self.received.pop(0), self.received.pop(0)
        got = (hi << 8) | lo
        self.dut._log.info(f"filtered output = {got}")
        assert got == expected, f"expected {expected}, got {got}"

    def secure_hold(self):
        return int(self.dut.uo_out.value) & 1


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    cocotb.start_soon(Clock(dut.clk, CLK_NS, unit="ns").start())

    h = Harness(dut)
    dut.ena.value = 1
    dut.uio_in.value = 0
    h._apply()
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)
    cocotb.start_soon(h.uart_monitor())

    assert h.secure_hold() == 0

    dut._log.info("First 8 samples: no output until the window is full")
    samples = [100, 200, 300, 400, 500, 600, 700, 800]
    for s in samples[:-1]:
        await h.send_sample(s)
    assert h.received == []
    await h.send_sample(samples[-1])
    await h.expect_sample(sum(samples) // 8)           # 450

    dut._log.info("Window slides")
    await h.send_sample(1700)
    await h.expect_sample((sum(samples[1:]) + 1700) // 8)  # 650

    dut._log.info("Tamper: open the lid")
    h.set_bit(LID_BIT, 0)
    await ClockCycles(dut.clk, 5)
    assert h.secure_hold() == 1

    dut._log.info("Samples are ignored while locked")
    await h.send_sample(0xFFFF)
    await Timer(30 * BIT_NS, unit="ns")
    assert h.received == []

    dut._log.info("Wrong unlock code keeps it locked")
    h.set_bit(LID_BIT, 1)
    for b in (0x09, 0x0B, 0x55):
        await h.send_byte(b)
    await ClockCycles(dut.clk, 5)
    assert h.secure_hold() == 1

    dut._log.info("Correct unlock code releases it")
    for b in (0x09, 0x0B, 0x54):
        await h.send_byte(b)
    await ClockCycles(dut.clk, 5)
    assert h.secure_hold() == 0

    dut._log.info("Filter state was preserved through the lockout")
    await h.send_sample(900)
    await h.expect_sample((sum(samples[2:]) + 1700 + 900) // 8)  # 737
    dut._log.info("Done")

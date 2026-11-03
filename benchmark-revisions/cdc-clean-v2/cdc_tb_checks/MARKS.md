# Marked CDC violations (include these in the TB)

| Mark | Issue | How we catch it |
|---|---|---|
| A | Raw reset release | Embedded Verilog monitor: while reset is asserted, destination is idle / empty / not full |
| B | Foreign-domain async reset | Lint: `always @(posedge clkA or negedge rstB)` that is not a reset-sync pipe |
| C | Binary pointer CDC | Lint: `wptr - rptr` / `count = wptr` |
| D | Missing 2-flop (`req == ack` combo) | Lint: `src_ready_o = (src_req == dst_ack)` |
| E | Data without hold | Embedded Verilog monitor: save `valid/data` and compare on the next destination clock while stalled |
| F | Abort as async reset | Lint: same family as B |
| G | Reset AND-ed into ready | Lint: `src_ready_o = src_rst_ni &&` (GPT `RST_PH_GLCH`) |
| H | Uncoordinated dual reset | Embedded Verilog monitor: either reset => destination request/valid must be idle |

The embedded monitors intentionally use `always`, `if`, registers, and
`$display`; they do not use SystemVerilog concurrent assertions.

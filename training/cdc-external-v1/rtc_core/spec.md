Implement the SystemVerilog module `rtc_core`.

Core logic for Real-Time Clock with alarm functionality

Functional contract and interface notes:

Module: rtc_core
Purpose: Core logic for Real-Time Clock with alarm functionality
Implements RTC functionality:
- Time counting: seconds, minutes, hours, day, month, year
- BCD and binary counting modes
- 24-hour and 12-hour (AM/PM) modes, PM in bit 7 of the hours byte
- Leap year handling (2000-2099)
- Alarm comparison with field masking
- Second tick and alarm interrupts
- Clock source selection (32.768 kHz or system clock for testing)
CLOCK DOMAINS (GitHub #56 H4/H7, round_2 items 4/5/6, round_3 items 1/2/3)
This module spans TWO domains and every crossing between them is explicit.
COUNTER DOMAIN  - `selected_clk` (= rtc_clk, or pclk in clock_select=1 test
mode), reset by `rtc_rst_n` through reset_sync (async
assert, synchronous deassert on selected_clk). Holds the
divider, the six time counters, the calendar arithmetic
and the alarm comparator.
APB DOMAIN      - `clk` (pclk), reset by `rst_n`. Holds the shadow copy of
the time that software reads, the sticky status flags,
and the source side of the time-set commit.
The four crossings, and the primitive each uses:
1. CONFIG / ALARM (pclk -> counter), quasi-static
`glitch_free_n_dff_arn` over one 34-bit bundle - the ten configuration
and alarm fields, the clock select, and the cfg_valid flag that
authorizes them - captured only when two consecutive samples agree, so
a torn word is never applied and the valid bit can never be seen ahead
of the fields it qualifies. These change
only while software is programming the block; they are not sampled
raw. Latency: SYNC_STAGES selected_clk cycles for the chain plus TWO
more for the filter (the delayed copy has to agree with the output
before the hold loads) - five at the default depth. The one bit that
is not held, time_set_mode, arrives in the chain's SYNC_STAGES.
2. TIME SET COMMIT (pclk -> counter), event + 48 bits of data
`cdc_4_phase_handshake`. Software raises RTC_CONFIG.time_set_mode,
writes the six time registers (which STAGE in the register block -
see rtc_config_regs.sv), then clears time_set_mode; that falling edge
is the commit. The six staged bytes cross as ONE closed-loop transfer
and load all six counters on a single counter-domain edge, so no field
can be lost or mixed with a previous batch. Closed loop, so it is
correct at ANY clock ratio - including the real 100 MHz : 32.768 kHz.
Latency: the load lands ~4-5 selected_clk cycles after the commit and
the full four-phase cycle completes in ~7 (~210 us on real silicon);
the register block keeps presenting the STAGED values until
`time_commit_busy` drops, so the readback never shows a stale time.
FOUR-phase, not two-phase, because the two domains reset
INDEPENDENTLY (`presetn` and `rtc_resetn` are separate pins and the
counter domain is meant to survive an APB reset). A two-phase
handshake stores its transfer state as toggle PARITY, which is
relative: reset one side alone and the other side's stale toggle
reads as a brand-new request. Measured both ways round on this block:
a presetn-only pulse fabricated a commit of the all-zero data the
same reset had just cleared (day/month loaded 0), and an
rtc_resetn-only pulse replayed the last committed time into the
freshly reset counters. In four-phase the request is a LEVEL and
`req = 0` IS idle, absolutely - a reset side observing req low
correctly concludes nothing is pending. See docs/markdown/rtl-cdc/
cdc.md "Reset Considerations", which states this as a design rule.
WATCHDOG, AND WHAT IT DOES NOT DO: if the counter clock is not
running the request can never be acknowledged.
COMMIT_TIMEOUT_CYCLES bounds the wait and the expiry is REPORTED -
RTC_STATUS.commit_timeout, sticky, W1C - but the transfer is NOT
cancelled. It stays pending with its data held, and lands unchanged
whenever the counter clock returns. So commit_timeout means exactly
"not acknowledged within the window; read the time back to find out
where it got to", and a timed-out commit MAY STILL LAND LATER,
carrying the time software asked for.
Cancelling was tried and is wrong: resetting the source side alone
drops the request level but leaves the DESTINATION's four-phase
state (its ack level, reset only by rtc_resetn) behind, so the next
request is satisfied by that stale ack in about one pclk cycle
instead of a real round trip - the protocol stops being a handshake.
Measured: req held high for 1 cycle where a genuine crossing needs
tens. Withdrawing a request needs BOTH sides to agree, which is
another handshake; not cancelling is simpler and strictly safer,
because the worst case is a correct time arriving late rather than
an unsynchronised link.
One commit may be queued behind an un-acknowledged one. It is only
handed to the handshake when the link is idle again, so a stalled
transfer can never be delivered twice, and the queued commit carries
the values captured at ITS OWN commit pulse - r_commit_data is loaded
from the staging registers when time_set_commit fires, not later when
the link finally accepts it, so what software wrote is what lands
however long the queue waits. `time_commit_busy` is cleared by the
timeout EVENT and never by its level, so a retry issued during a
stall keeps the staged registers visible until it lands or until its
own window expires, whichever comes first.
A QUEUED COMMIT HAS ITS OWN COMMIT_TIMEOUT_CYCLES WINDOW, counted in
pclk from its commit pulse. If it is not accepted within that window,
commit_timeout is reported again and busy is released while the
commit stays queued. A commit accepted within its window inherits
nothing and reports nothing - which is every commit in normal
operation, where the queue drains in about ten counter clocks. The
window exists because a queued commit that is never accepted cannot
be reported any other way: the in-flight watchdog is a level that
never dropped, so its edge detector can never fire a second time, and
busy would hang forever with the staged bytes pinned in the register
file and time_valid low. Expiry does NOT cancel anything -
r_commit_pend and r_commit_data are kept, the commit lands when the
clock returns, and the flag it raised retires by itself when the
commit that FINALLY LANDS FROM THAT SLOT completes. A THIRD commit
while one is queued replaces r_commit_data, re-raises busy and gives
itself a fresh window - the queue stays one deep and only the newest
word is ever delivered - but the report already standing for the slot
is not orphaned by the replacement: it retires when that newest word
lands.
RESETS AND THIS LINK. The source side is reset with the COUNTER
domain (rtc_resetn, synchronized into pclk), NOT with the bus:
- presetn alone: the link is untouched. An in-flight commit lands
intact. This is the whole point - resetting the source alone
zeroes r_src_data_hold while the request is already inside the
destination's synchronizer (the destination then loads zeros),
and it abandons the destination's ack level, which afterwards
satisfies the next request in about one pclk cycle instead of a
real round trip. Both were measured on this block.
- rtc_resetn alone (or both): BOTH ends reset together, so the link
is idle and an unacknowledged commit is DROPPED. Software must
not possible in any handshake, which is why this is the only
reset allowed to touch the source.
3. TIME READ (counter -> pclk), 49 bits, must be COHERENT
Two paths, both landing in the same pclk shadow registers:
(a) `sync_pulse` on the counter-domain update event, which captures
r_snap_* - a snapshot loaded atomically on the SAME edge the
counters change and stable for a whole second afterwards. This
is the fast path: the shadow is coherent ~3-4 pclk after a tick.
(b) `glitch_free_n_dff_arn` (3 flops) over {time_valid, six
counters}, captured only when two CONSECUTIVE synchronized
samples are identical. A counter change is instantaneous
relative to pclk, so at most ONE sample of the chain can be a
half-old/half-new mix; requiring the same word twice in a row
rejects that sample and can never latch a torn time. This path
needs no gating handshake, so it also picks up changes that
produce no event at all (a testbench forcing the counters, or a
publish that was never seen), which makes the shadow
self-healing rather than dependent on one pulse.
Read latency: one tick plus 3-4 pclk of synchronizer.
The pclk shadow is also seeded safely out of reset: the synchronizer
chain resets to zero and takes SYNC_STAGES cycles to fill with real
counter values, and "all zero" is a legal-looking but WRONG time
(day 0, month 0). The capture is gated until the chain has filled.
4. STATUS EVENTS (counter -> pclk)
r_second_tick and r_alarm_match are LEVELS one counter-clock wide
(~30.5 us on silicon). They are synchronized with
`glitch_free_n_dff_arn` and edge-detected in pclk, so each one becomes
a SINGLE-cycle set event. That is what stops a W1C from being undone:
the wide source level can no longer re-arm the flag one pclk after
software cleared it (round_3 item 2). The sticky flags themselves live
here in pclk. A set and a clear in the same cycle: SET WINS, so a tick
is never silently dropped.
RESET TABLE - which flops reset on which reset
presetn only            NOTHING that keeps state across a bus reset.
Specifically untouched: the counter domain
(divider, counters, snapshot, alarm and the
applied-configuration hold), the commit
handshake in both directions, the pclk
bookkeeping that tracks it (r_commit_pend /
_busy / _snapped / _inflight / _timedout /
_loaded / _timeout_d / _data, and the queued
commit's watchdog r_pend_wdog / r_pend_wdog_arm
/ r_pend_expired / r_pend_reported), the
DESTINATION sides of
u_snap_pulse_sync, u_load_pulse_sync and
u_event_sync with their edge detectors,
r_commit_timeout_flag (the one status flag that
follows the transfer it reports, not the register
file), and r_clk_sel_held with its settle filter.
Reset:
the register file, the read shadow and its fill
counter, the wrapper's snapshot/latch flops, the
config-valid flag, and the alarm/tick status
flags. The counter domain keeps the configuration
it last applied (cfg_valid drops with the
register file, and an unauthorized word is never
loaded), EXCEPT time_set_mode, which is taken
live so a bus reset during staging releases the
pause instead of pinning the divider forever.
A commit in flight or queued still lands - after
a warm bus reset the time software asked for
arrives, carrying r_commit_data.
rtc_resetn only         counter domain resets (async assert, release
synchronized onto selected_clk), AND everything
listed above as untouched by presetn, through
u_rtc_rst_pclk_sync. Both ends idle: an
unacknowledged commit is dropped, re-issue it. A
commit staged entirely under this reset never
sets busy and is never delivered on release.
pclk status/shadow keep their flops but the
shadow refills from the reset counters within a
few pclk.
RELEASE DEPENDS ON pclk. The clock-select settle
one-shot runs on pclk and gates u_ctr_reset_sync,
so the counter domain leaves reset roughly 7-9
pclk edges after rtc_resetn rises - and with pclk
stopped it never leaves reset at all. Recovery
requires both clocks running, not just rtc_clk.
both                    everything, as at power-on.
The bookkeeping is on the handshake's reset and not on presetn because
they track the same object. Splitting them is a reset-domain crossing
with three teeth, all measured: a commit staged while rtc_resetn was low
set busy with no way to clear (the primitive holds src_ready low through
its own source reset, so nothing can complete OR time out); the timeout
edge detector, cleared by presetn while the watchdog level it samples
was not, manufactured an event at release; and the COMPLETION EVIDENCE -
the destination side of the snapshot pulse synchronizer - is parity, so
a bus reset over the load either destroyed the pulse (busy stuck, the
register file left presenting staged values) or fabricated one (the
pre-commit time published as the commit's answer), one per toggle
parity. The same argument covers u_event_sync: reset the synchronized
copy of a still-high counter-domain level and release looks like a fresh
0->1, manufacturing a status flag with no tick behind it.
The configuration hold is here for the mirror-image reason (cdc.md Rule
5): the register file's reset defaults are a COMMAND once they cross -
rtc_enable=0 stops the clock, clock_select=0 flips the mux - so the
counter domain applies the crossed bundle only while the crossed
cfg_valid flag says software has written RTC_CONFIG since the last bus
reset, and otherwise holds what it last applied.
REQUIRED TIMING CONSTRAINTS (not optional - the crossings depend on them)
Two of the crossings carry MULTI-BIT data whose bits must land in the same
destination cycle as each other. A blanket `set_false_path` does NOT give
that: it permits unbounded skew between bits, and skewed bits defeat both
the two-identical-samples filter on the read bundle and the quasi-static
argument for the config bundle. Constrain them as bounded datapaths:
# counter -> pclk: the 49-bit read bundle (u_read_sync's first stage)
set_max_delay -datapath_only \
-from [get_pins u_rtc_core/r_{seconds,minutes,hours,day,month,year}_reg[*]/C] \
-to   [get_pins u_rtc_core/u_read_sync/*r_q_array_reg[0][*]/D] <pclk_period>
# pclk -> counter: the config/alarm bundle (u_cfg_sync's first stage)
set_max_delay -datapath_only \
-from [get_pins u_config_regs/*/C] \
-to   [get_pins u_rtc_core/u_cfg_sync/*r_q_array_reg[0][*]/D] <rtc_clk_period>
# counter -> pclk: the snapshot registers, captured by the sync_pulse
#                  event; quasi-static between events but still bounded
set_max_delay -datapath_only \
-from [get_pins u_rtc_core/r_snap_*_reg[*]/C] \
-to   [get_pins u_rtc_core/r_shd_*_reg[*]/D] <pclk_period>
# single-bit toggles/levels (sync_pulse, the 4-phase req/ack) take the
# usual -datapath_only max_delay of one destination period.
The four-phase handshake's own data bus is quasi-static: it is held by
r_src_data_hold for the whole request and is only sampled after the
request level has been through the destination synchronizer, so one
destination period of max_delay is sufficient there too.
TIMEKEEPING WHILE SOFTWARE IS SETTING THE TIME: the divider is held at
zero while the counter domain sees time_set_mode and across the commit, so
in the ordinary case there is no tick, no second interrupt, no alarm
evaluation and no counter advance until the new time has been loaded. That
pause is BEST EFFORT: time_set_mode crosses through a 3-flop synchronizer,
and at the production ratio a software sequence short enough may never be
sampled by the counter domain at all. The hard guarantee is separate and
does not depend on it - the commit's dst_valid brackets the load and gates
w_time_update, so a tick can never land adjacent to the load and the time
that becomes readable after a commit is exactly the committed time. The hold releases ON the load edge -
it is qualified with dst_valid alone, not with the one-cycle-longer
w_commit_active used by the alarm gate - so the first second after a
commit is EXACTLY one divider period (100 selected_clk edges in test mode,
32768 in production), not one period plus a hold cycle.
CHECK BY INSPECTION (these were assertions; properties belong in external
formal bindings, not inside the module):
- Counter updates are never back-to-back: a rollover and a commit load
cannot land on adjacent counter clocks, because the commit's dst_valid
gates w_time_update and the divider restarts from zero on the load.
- The snapshot registers are written from the same values on the same
edge as the counters, so r_snap_* is the counters or one update behind,
never a different time.
- A commit load restarts the divider (the hold branch zeroes it on that
edge), so the first second after a commit is a whole period.
Deviations, stated rather than hidden:
- A commit that is still queued when a bus reset lands still lands, and
carries the bytes captured at its commit pulse rather than the register
file's reset values.
- commit_timeout does not tell you whether the commit landed. It says
the acknowledge did not come back in time AND has still not arrived:
it is a report of an OUTSTANDING stall, so it is retired when the
stalled commit finally completes, as well as by W1C. Software that
needs a latched record must read it while the stall persists.
- A commit that lands exactly on the alarm value does NOT fire the
alarm. Alarms are evaluated on a tick, and a commit is not a tick -
setting the clock to the alarm time arms the alarm for the next time
the counter REACHES that value, one full second later at the earliest.
- `selected_clk` comes from rtc_clk_mux (RLB TASK-010, was RLB-010), which resolves per
target. On XILINX/SYNTH_PRAGMA it is a device glitchless cell (BUFGCTRL with
IGNORE0/IGNORE1, or ALTCLKCTRL) and a live RTC_CONFIG.clock_select
change is safe, including away from a stopped crystal. On every other
target -- simulation included -- it is the original combinational mux
bit for bit, and there the constraint is unchanged: changing
clock_select while the RTC is enabled can produce a runt clock pulse,
so software must change it with rtc_enable low. A PORTABLE glitch-free
mux cannot close that gap -- break-before-make needs BOTH clocks
running, which is exactly what clock_select does not guarantee -- so
the device cell is the only real answer. On the combinational branch
the runt also has a second-order effect worth naming: a
commit in flight across a live clock_select switch can be stranded
(the destination side sees a corrupted or missing edge), in which case
it is the watchdog above that resolves it - the commit is abandoned
and reported in RTC_STATUS.commit_timeout rather than hanging.
- The alarm compare values, the mask and the mode bits cross as ONE
quasi-static bundle, sampled free-running. While software is part-way
through programming it the counter domain can observe an intermediate
combination for one counter clock (a new alarm second against an old
alarm minute). Program RTC_ALARM_* and the mask with the alarm
disabled, then enable it last; set the counting format before enabling
the RTC.
- RTC_ALARM_HOUR is compared against the WHOLE hours byte, bit 7
included. In 12-hour mode bit 7 is the PM flag, so 3 PM is 0x83 in
binary counting and 0x93 in BCD; an alarm hour with bit 7 clear can
only ever match an AM hour.
- Loading an out-of-range time (day 40, hours 90 in 12-hour mode) is
software's problem: the counters accept it and the arithmetic is still
defined (every comparison is >=, never ==), but the calendar only
becomes meaningful again after the field wraps. In BCD counting a
loaded value of 100 or more cannot be represented in two digits, so
the next tick CLAMPS it to 99 rather than truncating the tens digit
into a nonsense date.
Follows PIC/PIT pattern: separate core logic from register interface

Required clock and reset behavior:

- Clock ports: clk, rtc_clk.
- Reset ports: rst_n, rtc_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (SYNC_STAGES) ) u_ctr_reset_sync ( .clk (selected_clk), .rst_n (w_ctr_rst_in_n), .sync_rst_n (w_ctr_rst_n) );
- reset_sync: reset_sync #( .N (SYNC_STAGES) ) u_rtc_rst_pclk_sync ( .clk (clk), .rst_n (rtc_rst_n), .sync_rst_n (w_rtc_rst_n_pclk) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (SYNC_STAGES), .WIDTH (CFG_WIDTH) ) u_cfg_sync ( .clk (selected_clk), .rst_n (w_ctr_rst_n), .d (w_cfg_bundle_pclk), .q (w_cfg_sync) );
- cdc_4_phase_handshake: cdc_4_phase_handshake #( .DATA_WIDTH (TIME_WIDTH), .SYNC_STAGES (SYNC_STAGES), .TIMEOUT_CYCLES (COMMIT_TIMEOUT_CYCLES) ) u_commit_cdc ( .clk_src (clk), .rst_src_n (w_commit_src_rst_n), .src_valid (w_commit_src_valid), .src_ready (w_commit_src_ready), .src_data (r_commit_data), .src_timeout (w_commit_timeout), .clk_dst (selected_clk), .rst_dst_n (w_ctr_rst_n), .dst_valid (w_commit_dst_valid), .dst_ready (w_commit_load), .dst_data (w_commit_dst_data) );
- sync_pulse: sync_pulse #( .SYNC_STAGES (SYNC_STAGES) ) u_snap_pulse_sync ( .i_src_clk (selected_clk), .i_src_rst_n (w_ctr_rst_n), .i_pulse (w_snap_pulse), .i_dst_clk (clk), .i_dst_rst_n (w_commit_bk_rst_n), .o_pulse (w_snap_valid_pclk) );
- sync_pulse: sync_pulse #( .SYNC_STAGES (SYNC_STAGES) ) u_load_pulse_sync ( .i_src_clk (selected_clk), .i_src_rst_n (w_ctr_rst_n), .i_pulse (w_commit_load), .i_dst_clk (clk), .i_dst_rst_n (w_commit_bk_rst_n), .o_pulse (w_commit_load_pclk) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (SYNC_STAGES), .WIDTH (READ_WIDTH) ) u_read_sync ( .clk (clk), .rst_n (rst_n), .d (w_read_bundle_ctr), .q (w_read_bundle_pclk) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (SYNC_STAGES), .WIDTH (2) ) u_event_sync ( .clk (clk), .rst_n (w_commit_bk_rst_n), .d ({r_alarm_match, r_second_tick}), .q (w_evt_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module rtc_core #(
    // Watchdog on the time-set commit handshake, in pclk cycles. FLOOR: the
    // commit needs about ten counter clocks end to end, so this must exceed
    // 10 * (pclk frequency / counter clock frequency) - at 100 MHz pclk
    // against a 32.768 kHz crystal that is ~30500 cycles. The default leaves
    // roughly 2x margin on that worst case and is ~655 us of real time, which
    // is far longer than any healthy commit and far shorter than a human
    // waiting to find out the clock is dead. 0 DISABLES both watchdogs (the
    // handshake primitive's and the queued-commit one); a stalled commit then
    // hangs busy with no report, which is only ever what a formal harness
    // wants.
    parameter int COMMIT_TIMEOUT_CYCLES = 65535
) (
    //========================================================================
    // Clocks and resets
    //========================================================================
    input  wire       clk,            // APB (pclk) domain clock
    input  wire       rst_n,          // APB domain reset, active low
    input  wire       rtc_clk,        // RTC clock (32.768 kHz)
    input  wire       rtc_rst_n,      // Counter domain reset, active low
    //========================================================================
    // Configuration from registers (pclk domain, quasi-static)
    //========================================================================
    input  wire       cfg_rtc_enable,
    input  wire       cfg_hour_mode_12,     // 0=24h, 1=12h
    input  wire       cfg_bcd_mode,         // 0=binary, 1=BCD
    input  wire       cfg_clock_select,     // 0=rtc_clk, 1=clk (for testing)
    input  wire       cfg_time_set_mode,    // 1=allow setting time (stops counter)
    input  wire       cfg_valid,            // 1=RTC_CONFIG has been written since presetn
    input  wire       cfg_alarm_enable,
    input  wire       cfg_alarm_int_enable,
    input  wire       cfg_second_int_enable,
    //========================================================================
    // Time set: staged values (pclk) + commit event
    //========================================================================
    input  wire [7:0] time_seconds_in,
    input  wire [7:0] time_minutes_in,
    input  wire [7:0] time_hours_in,
    input  wire [7:0] time_day_in,
    input  wire [7:0] time_month_in,
    input  wire [7:0] time_year_in,
    input  wire       time_set_commit,      // one pclk pulse: load the six above
    output wire       time_commit_busy,     // high until the load is visible here
    //========================================================================
    // Time read: coherent pclk shadow of the counters
    //========================================================================
    output wire [7:0] time_seconds_out,
    output wire [7:0] time_minutes_out,
    output wire [7:0] time_hours_out,
    output wire [7:0] time_day_out,
    output wire [7:0] time_month_out,
    output wire [7:0] time_year_out,
    //========================================================================
    // Alarm configuration (pclk domain, quasi-static)
    //========================================================================
    input  wire [7:0] alarm_seconds,
    input  wire [7:0] alarm_minutes,
    input  wire [7:0] alarm_hours,
    input  wire       alarm_sec_match_en,
    input  wire       alarm_min_match_en,
    input  wire       alarm_hour_match_en,
    //========================================================================
    // Status outputs (pclk domain)
    //========================================================================
    output wire       status_alarm_flag,
    output wire       status_second_tick,
    output wire       status_time_valid,
    output wire       status_pm_indicator,
    output wire       status_commit_timeout,
    //========================================================================
    // Status flag clears (pclk, one cycle, decoded from the W1C write)
    //========================================================================
    input  wire       clear_alarm_flag,
    input  wire       clear_second_tick,
    input  wire       clear_commit_timeout,
    //========================================================================
    // Interrupt outputs (pclk domain)
    //========================================================================
    output wire       rtc_alarm_irq,
    output wire       rtc_second_irq
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.

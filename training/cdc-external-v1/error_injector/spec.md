Implement the SystemVerilog module `error_injector`.

//   Shared test stimulus: corrupts a coded valid/ready stream between an

Functional contract and interface notes:

Module: error_injector
Purpose:
Shared test stimulus: corrupts a coded valid/ready stream between an
encoder and a decoder under host control -- an exact number of errors per
block, a burst, an error rate, or random burst clusters.
Module: error_injector
Description:
A three-stage valid/ready pipeline on the stream (data XORed with the
error pattern, keep/last untouched), so it sits anywhere on a coded
stream. Errors must be injected AFTER the encoder -- an error in the
generator's data is encoded faithfully and the code cannot see it --
which is why this is its own block and not a mode of the pattern
generator.
Granularity: SYMBOL_WIDTH = 1 makes it a bit injector (every hit XORs a
1, as binary BCH wants). SYMBOL_WIDTH = m makes it a symbol injector:
every hit XORs a random nonzero m-bit value into the symbol (a zero
would be no error), as Reed-Solomon wants. One module, both codecs.
Modes (cfg_mode):
0 NONE      pass through
1 COUNT     exactly cfg_count errors per block at uniformly random
distinct positions, by selection sampling (Knuth's
Algorithm S): symbol j of n is hit with probability
e_left / (n - j), evaluated as r16 * (n - j) < e_left << 16
with a 16-bit random r16; the last positions are hit with
certainty when e_left catches up, so the count is exact
whenever cfg_count <= n
2 BURST     cfg_count consecutive symbols from a random start
3 RATE      each symbol independently with probability cfg_rate / 65536
4 CLUSTERS  per block, draw N uniformly from [cfg_cnt_min, cfg_cnt_max],
then per cluster draw a length uniformly from
[cfg_len_min, cfg_len_max] and a uniform start in
[0, N_SYMBOLS - length]; every symbol in a cluster range is
hit. Overlapping clusters merge. Two dedicated xorshift
streams draw the count/lengths and the starts, so cluster
geometry is independent of the per-lane hit randoms.
Presets model real media: small count and length ranges
give DRAM multi-bit-upset patterns, larger ranges give
flash disturbed pages.
5 LOCALIZED hits at cfg_rate density confined to one sub-window per
block: the window width is drawn uniformly from
[cfg_len_min, cfg_len_max] and its start uniformly from
[0, N_SYMBOLS - width]. Models a damaged page region, a
failed symbol column, or a half-plane failure -- real
errors are often far more localized than uniform.
6 BADBLOCK  per block, with probability cfg_len_min / 65536 the block
runs at the elevated rate cfg_len_max, otherwise at
cfg_rate; models NAND retention tails and worn blocks --
most of the stream is clean with a hard minority that is
very bad, which uniform RATE cannot express.
7 DEBUG     deterministic walking errors: block b hits the symbols at
((b * step + j) mod N_SYMBOLS) for j < cfg_count, step =
cfg_rate. No randoms on the hit path -- a counter and a
subtract-compare -- so it is the hand-checkable bring-up
mode whose timing closes by inspection. Every position is
exercised over a campaign, at a configurable pace.
COUNT timing: exact selection sampling needs the running hit count --
each lane's threshold depends on how many lower lanes hit -- a prefix
recurrence that is ~111 logic levels when all lanes of a wide beat decide
in one cycle and cannot close at 100 MHz. Stage C therefore decides
GRP lanes per cycle (group-local 4-bit prefix, the group-start count
folded into per-lane thresholds in parallel), walking a wide beat over
N_GRP cycles while it waits in the B skid; the hit mask and count
accumulate in registers and release on the final group. GRP is 2 so the
conditional-increment ripple stays carry-chain shallow post-route; COUNT
mode on a 32-bit beat takes 16 cycles (~6 Mbit/s), far above any UART-fed
loop rate. A beat that has no errors left to place -- every count=0 beat,
and the tail of a block whose count is already placed -- shortcuts the
walk: e_left == 0 clamps every lane's capacity to zero, so the decision is
final after group 0 and clean beats stream at line rate (issue #89).
BURST, RATE and CLUSTERS are per-lane independent and stay
single-cycle, full rate.
Pipeline (each stage a register with valid/ready):
A  accept the beat, snapshot the lane generators (r16 draw + error
value), the block position, and -- on a block's first beat -- draw
the cluster table from the two stream generators
B  the per-lane products r16 * (n - pos - u) and the burst start, in
DSPs, from A's registers -- the multiply is the long path
C  the decisions and the error mask; the statistics update one cycle
later from the registered hit count; the configuration is
re-registered locally, so the CSR block is off every path.
Statistics for the host: total symbols injected (bits when
SYMBOL_WIDTH = 1), blocks with at least one injected symbol, blocks with
more than T_SYMBOLS injected (the ones a decoder must flag), and the
count injected into the most recent block. cfg_clear zeroes them;
cfg_seed_load reseeds every generator.
Erasure marking: with cfg_mark_erasure set, out_erasure carries the
beat's hit mask -- lane u flagged exactly where a symbol was corrupted.
Wired to a decoder's erasure sideband it turns any placement mode into an
erasure run: the positions the decoder is TOLD about are precisely the
ones that were hit, which is the information a RAID stripe map or an
MC's known-bad column has. With the bit clear out_erasure is all zero.
Parameters:
SYMBOL_WIDTH:     1 = bit injector, m = symbol injector (GF(2^m) symbols
SYMBOLS_PER_BEAT: lanes per beat
N_SYMBOLS:        block length in symbols (<= 65535)
T_SYMBOLS:        correctable count, for the over-t statistic only
DATA_WIDTH:       SYMBOL_WIDTH * SYMBOLS_PER_BEAT

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module error_injector #(
    parameter int SYMBOL_WIDTH     = 1,
    parameter int SYMBOLS_PER_BEAT = 8,
    parameter int N_SYMBOLS        = 8191,
    parameter int T_SYMBOLS        = 8,
    parameter int DATA_WIDTH       = SYMBOL_WIDTH * SYMBOLS_PER_BEAT
) (
    input  logic                        aclk,
    input  logic                        aresetn,
    input  logic                        in_valid,
    output logic                        in_ready,
    input  logic [DATA_WIDTH-1:0]       in_data,
    input  logic [SYMBOLS_PER_BEAT-1:0] in_keep,
    input  logic                        in_last,
    output logic                        out_valid,
    input  logic                        out_ready,
    output logic [DATA_WIDTH-1:0]       out_data,
    output logic [SYMBOLS_PER_BEAT-1:0] out_keep,
    output logic                        out_last,
    // the beat's hit mask when cfg_mark_erasure is set, else all zero
    output logic [SYMBOLS_PER_BEAT-1:0] out_erasure,
    input  logic [2:0]                  cfg_mode,
    input  logic [7:0]                  cfg_count,
    input  logic [15:0]                 cfg_rate,
    input  logic [31:0]                 cfg_seed,
    input  logic                        cfg_seed_load,
    input  logic                        cfg_clear,
    input  logic                        cfg_mark_erasure,
    input  logic [7:0]                  cfg_cnt_min,
    input  logic [7:0]                  cfg_cnt_max,
    input  logic [15:0]                 cfg_len_min,
    input  logic [15:0]                 cfg_len_max,
    output logic [31:0]                 o_inj_symbols,
    output logic [31:0]                 o_inj_blocks,
    output logic [31:0]                 o_inj_over_t,
    output logic [7:0]                  o_last_block_errors
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.

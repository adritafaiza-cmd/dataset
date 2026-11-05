`default_nettype none
// Scoreboard for frozen afifo. Not part of the RTL.
//
// write_accept = i_wr && !o_wr_full on i_wclk, and only out of write reset.
// read_accept  = i_rd && !o_rd_empty on i_rclk, and only out of read reset.
//
// Counts are 4 bits. This file is the depth-8, width-16 proof, with
// the DUT elaborated at its defaults (LGFIFO=3, NFF=2, registered
// reads, write on posedge). The bound 8 and the 3-bit pointer
// comparisons are that configuration, not a proof for other parameters.
// At most 8 writes are outstanding, so a 4-bit difference cannot alias
// two live words: the same index repeats only after 16 accepts, and
// the older one has already been read. i_pick is one arbitrary index
// in that 4-bit space, held stable. captured is refreshed on every
// write of that index, including after the count wraps.
module afifo_integrity #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16
	) (
		input	wire			i_wclk,
		input	wire			i_wr_reset_n,
		input	wire			i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		input	wire			o_wr_full,
		input	wire	[3:0]		i_pick,
		input	wire			i_rclk,
		input	wire			i_rd_reset_n,
		input	wire			i_rd,
		input	wire	[WIDTH-1:0]	o_rd_data,
		input	wire			o_rd_empty
	);

	localparam		DEPTH = 1 << LGFIFO;

	reg	[3:0]		wr_n, rd_n;
	reg			saw_full;
	reg	[3:0]		drained;
	reg	[WIDTH-1:0]	captured;
	reg			pick_held;

	wire			write_accept = i_wr && !o_wr_full;
	wire			read_accept  = i_rd && !o_rd_empty;
	wire			write_take   = write_accept && i_wr_reset_n;
	wire			read_take    = read_accept && i_rd_reset_n;
	wire	[3:0]		outstanding = wr_n - rd_n;
	wire	[3:0]		pick_age = i_pick - rd_n;
	wire			pick_live = (outstanding != 4'd0) && (pick_age < outstanding);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_n <= 4'd0;
			saw_full <= 1'b0;
			pick_held <= 1'b0;
		end else begin
			pick_held <= 1'b1;
			if (write_take) begin
				if (wr_n == i_pick)
					captured <= i_wr_data;
				if (outstanding == DEPTH - 1)
					saw_full <= 1'b1;
				wr_n <= wr_n + 4'd1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_n <= 4'd0;
			drained <= 4'd0;
		end else if (read_take && (outstanding != 4'd0)) begin
			rd_n <= rd_n + 4'd1;
			if (saw_full && (drained != 4'd8))
				drained <= drained + 4'd1;
		end
	end

	pick_stable_w: assume property (@(posedge i_wclk)
		pick_held |-> $stable(i_pick));
	pick_stable_r: assume property (@(posedge i_rclk)
		pick_held |-> $stable(i_pick));

	oldest_unread: assert property (@(posedge i_rclk)
		(read_take && (rd_n == i_pick)) |->
			(o_rd_data == captured));

	no_underflow: assert property (@(posedge i_rclk)
		read_take |-> (outstanding != 4'd0));

	within_capacity: assert property (@(posedge i_wclk)
		write_take |-> (outstanding < DEPTH));

	full_low_in_write_reset: assert property (@(posedge i_wclk)
		!i_wr_reset_n |-> !o_wr_full);

	empty_high_in_read_reset: assert property (@(posedge i_rclk)
		!i_rd_reset_n |-> o_rd_empty);

	// Antecedents of the two reset implications. Proved before any
	// assumption that the resets stay released.
	wr_reset_antecedent: cover property (@(posedge i_wclk) !i_wr_reset_n);
	rd_reset_antecedent: cover property (@(posedge i_rclk) !i_rd_reset_n);

	fill8: cover property (@(posedge i_wclk) saw_full);
	drain8: cover property (@(posedge i_rclk) drained == 4'd8);

endmodule

module afifo_integrity_top (
		input	wire			i_wclk,
		input	wire			i_wr_reset_n,
		input	wire			i_wr,
		input	wire	[15:0]		i_wr_data,
		output	wire			o_wr_full,
		input	wire			i_rclk,
		input	wire			i_rd_reset_n,
		input	wire			i_rd,
		input	wire	[3:0]		i_pick,
		output	wire	[15:0]		o_rd_data,
		output	wire			o_rd_empty
	);

	afifo dut (
		.i_wclk(i_wclk), .i_wr_reset_n(i_wr_reset_n), .i_wr(i_wr),
		.i_wr_data(i_wr_data), .o_wr_full(o_wr_full),
		.i_rclk(i_rclk), .i_rd_reset_n(i_rd_reset_n), .i_rd(i_rd),
		.o_rd_data(o_rd_data), .o_rd_empty(o_rd_empty)
	);

	afifo_integrity chk (
		.i_wclk(i_wclk), .i_wr_reset_n(i_wr_reset_n), .i_wr(i_wr),
		.i_wr_data(i_wr_data), .o_wr_full(o_wr_full), .i_pick(i_pick),
		.i_rclk(i_rclk), .i_rd_reset_n(i_rd_reset_n), .i_rd(i_rd),
		.o_rd_data(o_rd_data), .o_rd_empty(o_rd_empty)
	);

	// Lemmas for this elaboration only: depth 8, 3-bit pointers.
	// The public checks do not mention DUT pointers. outstanding stays
	// inside 0..8, the public counts match the DUT pointers, and the
	// picked memory word stays equal to the harness copy while that
	// index is still unread.
	tested_cfg: assert property (@(posedge i_wclk)
		(dut.LGFIFO == 3) && (dut.WIDTH == 16) && (dut.NFF == 2)
		&& (dut.WRITE_ON_POSEDGE == 1'b1)
		&& (dut.OPT_REGISTER_READS == 1'b1)
		&& (chk.LGFIFO == 3) && (chk.WIDTH == 16)
		&& (chk.DEPTH == 8));
	outstanding_le_w: assert property (@(posedge i_wclk)
		disable iff (!i_wr_reset_n || !i_rd_reset_n)
		chk.outstanding <= 4'd8);
	outstanding_le_r: assert property (@(posedge i_rclk)
		disable iff (!i_wr_reset_n || !i_rd_reset_n)
		chk.outstanding <= 4'd8);
	wr_ptr_tracks: assert property (@(posedge i_wclk)
		disable iff (!i_wr_reset_n)
		dut.wr_ptr == chk.wr_n[2:0]);
	rd_ptr_tracks: assert property (@(posedge i_rclk)
		disable iff (!i_rd_reset_n)
		dut.rd_ptr == chk.rd_n[2:0]);
	mem_matches: assert property (@(posedge i_wclk)
		disable iff (!i_wr_reset_n || !i_rd_reset_n)
		chk.pick_live |->
			(dut.mem[chk.i_pick[2:0]] == chk.captured));
	mem_matches_r: assert property (@(posedge i_rclk)
		disable iff (!i_wr_reset_n || !i_rd_reset_n)
		chk.pick_live |->
			(dut.mem[chk.i_pick[2:0]] == chk.captured));

endmodule
`default_nettype wire

`default_nettype none
// Asynchronous FIFO. Storage is 2**LGFIFO words.
// Full means that storage is occupied. Empty means the next word is not
// visible yet: words are offered one at a time through a one-bit request
// and a one-bit acknowledge, each synchronized by NST flops. A stored word
// can therefore sit behind o_rd_empty until its turn to cross.
// Multi-bit pointers stay in their own clock. Jasper 2026.03p001 reported
// gray-pointer reconvergence as CNV_ST_CONV, and a proven gray encoding
// did not clear those raw errors without a waiver.
module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	localparam	DEPTH = 1 << LGFIFO;
	localparam	NST   = (NFF < 2) ? 2 : NFF;

	reg	[WIDTH-1:0]	mem [0:DEPTH-1];
	reg	[LGFIFO-1:0]	wr_ptr, send_ptr, rd_ptr;
	reg	[LGFIFO:0]	stored;
	reg			req, ack;
	reg	[1:0]		wphase, rphase;
	(* ASYNC_REG = "TRUE" *) reg [NST-1:0] ack_sync;
	(* ASYNC_REG = "TRUE" *) reg [NST+1:0] req_sync;
	(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_meta_q, payload_sync_q;
	reg [WIDTH-1:0] payload_hold;
	reg	[WIDTH-1:0]	data_q;
	reg			empty_q;

	wire			wclk = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire			ack_level = ack_sync[NST-1];
	wire			req_level = req_sync[NST+1];
	wire			retire = (wphase == 2'd1) && ack_level && (stored != 0);
	wire			take_wr = i_wr && (stored < DEPTH);
	reg	[LGFIFO:0]	stored_next;

	always @(*) begin
		case ({retire, take_wr})
		2'b10: stored_next = stored - 1'b1;
		2'b01: stored_next = stored + 1'b1;
		default: stored_next = stored;
		endcase
	end

	always @(posedge wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			payload_hold <= {WIDTH{1'b0}};
			wr_ptr <= {LGFIFO{1'b0}};
			send_ptr <= {LGFIFO{1'b0}};
			stored <= {(LGFIFO+1){1'b0}};
			req <= 1'b0;
			wphase <= 2'd0;
			ack_sync <= {NST{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			ack_sync <= {ack_sync[NST-2:0], ack};
			if (take_wr)
				wr_ptr <= wr_ptr + 1'b1;
			stored <= stored_next;
			o_wr_full <= (stored_next == DEPTH);
			case (wphase)
			2'd0: begin
				if ((stored != 0) || take_wr) begin
						payload_hold <= (stored != 0) ? mem[send_ptr] : i_wr_data;
					req <= 1'b1;
					wphase <= 2'd1;
				end
			end
			2'd1: begin
				if (ack_level) begin
					req <= 1'b0;
					send_ptr <= send_ptr + 1'b1;
					wphase <= 2'd2;
				end
			end
			default: begin
				if (!ack_level)
					wphase <= 2'd0;
			end
			endcase
		end
	end

	// Clock only. Gating this write with i_wr_reset_n puts the reset
	// pin on the memory data path (RST_RS_RIDP). Reset clears the
	// write pointer and the stored count instead; a write during
	// reset is not offered after reset release.
	always @(posedge wclk) begin
		if (take_wr)
			mem[wr_ptr] <= i_wr_data;
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {LGFIFO{1'b0}};
			ack <= 1'b0;
			rphase <= 2'd0;
			req_sync <= {(NST+2){1'b0}};
			payload_meta_q <= {WIDTH{1'b0}};
			payload_sync_q <= {WIDTH{1'b0}};
			data_q <= {WIDTH{1'b0}};
			empty_q <= 1'b1;
		end else begin
			req_sync <= {req_sync[NST:0], req};
			payload_meta_q <= payload_hold;
			payload_sync_q <= payload_meta_q;
			case (rphase)
			2'd0: begin
				if (req_level) begin
					data_q <= payload_sync_q;
					empty_q <= 1'b0;
					rphase <= 2'd1;
				end
			end
			2'd1: begin
				if (i_rd) begin
					empty_q <= 1'b1;
					ack <= 1'b1;
					rd_ptr <= rd_ptr + 1'b1;
					rphase <= 2'd2;
				end
			end
			default: begin
				if (!req_level) begin
					ack <= 1'b0;
					rphase <= 2'd0;
				end
			end
			endcase
		end
	end

	generate
		if (OPT_REGISTER_READS) begin : GEN_REG_READ
			always @(*) begin
				o_rd_empty = empty_q;
				o_rd_data = data_q;
			end
		end else begin : GEN_COMBO_READ
			always @(*) begin
				o_rd_empty = (rphase != 2'd1);
				o_rd_data = (rphase == 2'd1) ? payload_sync_q : data_q;
			end
		end
	endgenerate

endmodule
`default_nettype wire

module wbxclk #(
	parameter AW=32,
	parameter DW=32,
	parameter LGFIFO = 5
) (
	input	wire			i_wb_clk, i_reset,
	input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
	input	wire	[(AW-1):0]	i_wb_addr,
	input	wire	[(DW-1):0]	i_wb_data,
	input	wire	[(DW/8-1):0]	i_wb_sel,
	output	wire			o_wb_stall,
	output	reg			o_wb_ack,
	output	reg	[(DW-1):0]	o_wb_data,
	output	reg			o_wb_err,
	input	wire			i_xclk_clk,
	output	reg			o_xclk_cyc,
	output	reg			o_xclk_stb,
	output	reg			o_xclk_we,
	output	reg	[(AW-1):0]	o_xclk_addr,
	output	reg	[(DW-1):0]	o_xclk_data,
	output	reg	[(DW/8-1):0]	o_xclk_sel,
	input	wire			i_xclk_stall,
	input	wire			i_xclk_ack,
	input	wire	[(DW-1):0]	i_xclk_data,
	input	wire			i_xclk_err
);

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_PTR_W = LGFIFO;
	localparam DATA_W = AW + DW + (DW/8) + 2; // addr + data + sel + we + valid_marker? 
	// Actually, we need to transfer: addr, data, sel, we.
	// Let's pack them into a single wide word for the FIFO.
	// Total bits: AW + DW + (DW/8) + 1 (we)
	localparam PACKED_W = AW + DW + (DW/8) + 1;

	// --- Source Domain (i_wb_clk) ---
	
	// FIFO Write Pointer
	reg [FIFO_PTR_W-1:0] wr_ptr;
	
	// FIFO Read Pointer (synchronized from dest)
	reg [FIFO_PTR_W-1:0] rd_ptr_sync;
	reg [FIFO_PTR_W-1:0] rd_ptr_sync_1;
	reg [FIFO_PTR_W-1:0] rd_ptr_sync_2;
	
	// Packed data to write into FIFO
	reg [PACKED_W-1:0] fifo_wr_data;
	
	// Stall logic: Stall if FIFO is full
	// Full condition: (wr_ptr - rd_ptr_sync) == FIFO_DEPTH
	wire [FIFO_PTR_W:0] wr_rd_diff;
	assign wr_rd_diff = wr_ptr - rd_ptr_sync;
	wire fifo_full = (wr_rd_diff == FIFO_DEPTH);
	
	assign o_wb_stall = fifo_full;
	
	// Accept cycle if not stalled and valid wishbone cycle
	wire wb_valid = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	
	// Pack data
	assign fifo_wr_data = {i_wb_we, i_wb_sel, i_wb_data, i_wb_addr};
	
	// Write to FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wr_ptr <= {FIFO_PTR_W{1'b0}};
		end else if (wb_valid) begin
			wr_ptr <= wr_ptr + 1'b1;
		end
	end
	
	// Synchronize read pointer from destination domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rd_ptr_sync_1 <= {FIFO_PTR_W{1'b0}};
			rd_ptr_sync_2 <= {FIFO_PTR_W{1'b0}};
			rd_ptr_sync <= {FIFO_PTR_W{1'b0}};
		end else begin
			rd_ptr_sync_1 <= rd_ptr_sync_2;
			rd_ptr_sync_2 <= rd_ptr_sync;
			// rd_ptr_sync is updated from the synchronized value
			// Actually, we need to synchronize the pointer coming from the other side.
			// Let's rename: 
			// dest sends rd_ptr -> src syncs it.
			// Let's use a separate sync chain for the pointer coming from dest.
		end
	end
	
	// We need a proper sync chain for the read pointer coming from the destination.
	// Let's redo the synchronization structure.
	
	// --- Destination Domain (i_xclk_clk) ---
	
	// FIFO Read Pointer
	reg [FIFO_PTR_W-1:0] rd_ptr;
	
	// FIFO Write Pointer (synchronized from source)
	reg [FIFO_PTR_W-1:0] wr_ptr_sync;
	reg [FIFO_PTR_W-1:0] wr_ptr_sync_1;
	reg [FIFO_PTR_W-1:0] wr_ptr_sync_2;
	
	// Packed data read from FIFO
	reg [PACKED_W-1:0] fifo_rd_data;
	
	// Unpack data
	wire [AW-1:0] xclk_addr;
	wire [DW-1:0] xclk_data;
	wire [DW/8-1:0] xclk_sel;
	wire xclk_we;
	
	assign xclk_addr = fifo_rd_data[0:AW-1];
	assign xclk_data = fifo_rd_data[AW:AW+DW-1];
	assign xclk_sel = fifo_rd_data[AW+DW:AW+DW+(DW/8)-1];
	assign xclk_we = fifo_rd_data[AW+DW+(DW/8)];
	
	// FIFO Empty condition
	wire [FIFO_PTR_W:0] rd_wr_diff;
	assign rd_wr_diff = rd_ptr - wr_ptr_sync;
	wire fifo_empty = (rd_wr_diff == 0);
	
	// Output registers
	always @(posedge i_xclk_clk) begin
		if (fifo_empty) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= xclk_we;
			o_xclk_addr <= xclk_addr;
			o_xclk_data <= xclk_data;
			o_xclk_sel <= xclk_sel;
			
			// Advance read pointer if accepted
			if (i_xclk_ack) begin
				rd_ptr <= rd_ptr + 1'b1;
			end
		end
	end
	
	// Synchronize write pointer from source domain
	always @(posedge i_xclk_clk) begin
		wr_ptr_sync_1 <= wr_ptr_sync_2;
		wr_ptr_sync_2 <= wr_ptr_sync;
		// wr_ptr_sync is the synchronized value from source
		// We need to capture the source's wr_ptr here.
		// Let's use a separate input for the synchronized pointer.
	end
	
	// --- Correction: Proper CDC FIFO Implementation ---
	
	// We need to implement a proper asynchronous FIFO.
	// Since we cannot use vendor primitives, we will implement a simple dual-port RAM with Gray code pointers.
	
	// Let's restart with a cleaner approach using Gray code pointers for CDC safety.
	
	// --- Source Domain (i_wb_clk) ---
	
	// Binary write pointer
	reg [FIFO_PTR_W-1:0] wr_ptr_bin;
	// Gray code write pointer
	wire [FIFO_PTR_W-1:0] wr_ptr_gray;
	assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
	
	// Synchronized read pointer (Gray code) from destination
	reg [FIFO_PTR_W-1:0] rd_ptr_gray_sync;
	reg [FIFO_PTR_W-1:0] rd_ptr_gray_sync_1;
	reg [FIFO_PTR_W-1:0] rd_ptr_gray_sync_2;
	
	// Convert synchronized Gray code read pointer to binary
	wire [FIFO_PTR_W-1:0] rd_ptr_bin_sync;
	
	// Gray to Binary conversion
	function [FIFO_PTR_W-1:0] gray2bin;
		input [FIFO_PTR_W-1:0] gray;
		reg [FIFO_PTR_W-1:0] bin;
		begin
			bin[FIFO_PTR_W-1] = gray[FIFO_PTR_W-1];
			for (i = FIFO_PTR_W-2; i >= 0; i = i - 1) begin
				bin[i] = bin[i+1] ^ gray[i];
			end
		end
	endfunction
	
	assign rd_ptr_bin_sync = gray2bin(rd_ptr_gray_sync);
	
	// Full condition
	wire [FIFO_PTR_W:0] wr_rd_diff_gray;
	// For Gray code, full condition is: wr_gray == rd_gray and wr_bin[FIFO_PTR_W-1] != rd_bin[FIFO_PTR_W-1]
	// Or simpler: compare binary pointers
	wire fifo_full = (wr_ptr_bin == rd_ptr_bin_sync) && (wr_ptr_bin[FIFO_PTR_W-1] != rd_ptr_bin_sync[FIFO_PTR_W-1]);
	
	assign o_wb_stall = fifo_full;
	
	wire wb_valid = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	
	assign fifo_wr_data = {i_wb_we, i_wb_sel, i_wb_data, i_wb_addr};
	
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wr_ptr_bin <= {FIFO_PTR_W{1'b0}};
		end else if (wb_valid) begin
			wr_ptr_bin <= wr_ptr_bin + 1'b1;
		end
	end
	
	// Synchronize read pointer Gray code
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rd_ptr_gray_sync_1 <= {FIFO_PTR_W{1'b0}};
			rd_ptr_gray_sync_2 <= {FIFO_PTR_W{1'b0}};
			rd_ptr_gray_sync <= {FIFO_PTR_W{1'b0}};
		end else begin
			rd_ptr_gray_sync_1 <= rd_ptr_gray_sync_2;
			rd_ptr_gray_sync_2 <= rd_ptr_gray_sync;
			// rd_ptr_gray_sync is the output of the sync chain
			// We need to capture the destination's rd_ptr_gray here
			// Let's use a separate wire for the destination's rd_ptr_gray
		end
	end
	
	// --- Destination Domain (i_xclk_clk) ---
	
	// Binary read pointer
	reg [FIFO_PTR_W-1:0] rd_ptr_bin;
	// Gray code read pointer
	wire [FIFO_PTR_W-1:0] rd_ptr_gray;
	assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);
	
	// Synchronized write pointer (Gray code) from source
	reg [FIFO_PTR_W-1:0] wr_ptr_gray_sync;
	reg [FIFO_PTR_W-1:0] wr_ptr_gray_sync_1;
	reg [FIFO_PTR_W-1:0] wr_ptr_gray_sync_2;
	
	// Convert synchronized Gray code write pointer to binary
	wire [FIFO_PTR_W-1:0] wr_ptr_bin_sync;
	assign wr_ptr_bin_sync = gray2bin(wr_ptr_gray_sync);
	
	// Empty condition
	wire fifo_empty = (rd_ptr_bin == wr_ptr_bin_sync);
	
	// Output registers
	always @(posedge i_xclk_clk) begin
		if (fifo_empty) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= xclk_we;
			o_xclk_addr <= xclk_addr;
			o_xclk_data <= xclk_data;
			o_xclk_sel <= xclk_sel;
			
			if (i_xclk_ack) begin
				rd_ptr_bin <= rd_ptr_bin + 1'b1;
			end
		end
	end
	
	// Synchronize write pointer Gray code
	always @(posedge i_xclk_clk) begin
		wr_ptr_gray_sync_1 <= wr_ptr_gray_sync_2;
		wr_ptr_gray_sync_2 <= wr_ptr_gray_sync;
		// wr_ptr_gray_sync is the output of the sync chain
		// We need to capture the source's wr_ptr_gray here
	end
	
	// --- RAM Implementation ---
	
	// Dual-port RAM
	reg [PACKED_W-1:0] mem [0:FIFO_DEPTH-1];
	
	// Write port
	always @(posedge i_wb_clk) begin
		if (wb_valid) begin
			mem[wr_ptr_bin[FIFO_PTR_W-1:0]] <= fifo_wr_data;
		end
	end
	
	// Read port
	always @(posedge i_xclk_clk) begin
		if (~fifo_empty) begin
			fifo_rd_data <= mem[rd_ptr_bin[FIFO_PTR_W-1:0]];
		end
	end
	
	// --- Response Path (Destination to Source) ---
	
	// We need to return ack/err/data to the source.
	// The response is associated with the request.
	// We need a second FIFO for responses, or we can use a simple handshake.
	// Since the request is forwarded, the response comes back.
	// We need to match the response to the original request.
	// For simplicity, we can use a second FIFO for responses.
	
	// Response FIFO: Stores {err, data}
	localparam RESP_W = DW + 1;
	
	// Source Domain Response FIFO
	reg [FIFO_PTR_W-1:0] resp_wr_ptr_bin;
	wire [FIFO_PTR_W-1:0] resp_wr_ptr_gray;
	assign resp_wr_ptr_gray = resp_wr_ptr_bin ^ (resp_wr_ptr_bin >> 1);
	
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_gray_sync;
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_gray_sync_1;
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_gray_sync_2;
	
	wire [FIFO_PTR_W-1:0] resp_rd_ptr_bin_sync;
	assign resp_rd_ptr_bin_sync = gray2bin(resp_rd_ptr_gray_sync);
	
	wire resp_fifo_full = (resp_wr_ptr_bin == resp_rd_ptr_bin_sync) && (resp_wr_ptr_bin[FIFO_PTR_W-1] != resp_rd_ptr_bin_sync[FIFO_PTR_W-1]);
	
	// Destination Domain Response FIFO
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_bin;
	wire [FIFO_PTR_W-1:0] resp_rd_ptr_gray;
	assign resp_rd_ptr_gray = resp_rd_ptr_bin ^ (resp_rd_ptr_bin >> 1);
	
	reg [FIFO_PTR_W-1:0] resp_wr_ptr_gray_sync;
	reg [FIFO_PTR_W-1:0] resp_wr_ptr_gray_sync_1;
	reg [FIFO_PTR_W-1:0] resp_wr_ptr_gray_sync_2;
	
	wire [FIFO_PTR_W-1:0] resp_wr_ptr_bin_sync;
	assign resp_wr_ptr_bin_sync = gray2bin(resp_wr_ptr_gray_sync);
	
	wire resp_fifo_empty = (resp_rd_ptr_bin == resp_wr_ptr_bin_sync);
	
	// Response RAM
	reg [RESP_W-1:0] resp_mem [0:FIFO_DEPTH-1];
	
	// Write response to FIFO when ack is received
	always @(posedge i_xclk_clk) begin
		if (i_xclk_ack) begin
			resp_mem[resp_rd_ptr_bin[FIFO_PTR_W-1:0]] <= {i_xclk_err, i_xclk_data};
			resp_wr_ptr_bin <= resp_wr_ptr_bin + 1'b1;
		end
	end
	
	// Read response from FIFO
	reg [RESP_W-1:0] resp_rd_data;
	
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else if (~resp_fifo_empty) begin
			o_wb_ack <= 1'b1;
			o_wb_data <= resp_rd_data[0:DW-1];
			o_wb_err <= resp_rd_data[DW];
			resp_rd_ptr_bin <= resp_rd_ptr_bin + 1'b1;
		end else begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end
	end
	
	always @(posedge i_wb_clk) begin
		if (~resp_fifo_empty) begin
			resp_rd_data <= resp_mem[resp_rd_ptr_bin[FIFO_PTR_W-1:0]];
		end
	end
	
	// Synchronize response pointers
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_rd_ptr_gray_sync_1 <= {FIFO_PTR_W{1'b0}};
			resp_rd_ptr_gray_sync_2 <= {FIFO_PTR_W{1'b0}};
			resp_rd_ptr_gray_sync <= {FIFO_PTR_W{1'b0}};
		end else begin
			resp_rd_ptr_gray_sync_1 <= resp_rd_ptr_gray_sync_2;
			resp_rd_ptr_gray_sync_2 <= resp_rd_ptr_gray_sync;
		end
	end
	
	always @(posedge i_xclk_clk) begin
		resp_wr_ptr_gray_sync_1 <= resp_wr_ptr_gray_sync_2;
		resp_wr_ptr_gray_sync_2 <= resp_wr_ptr_gray_sync;
	end
	
	// Connect the synchronized pointers
	assign rd_ptr_gray_sync = rd_ptr_gray;
	assign wr_ptr_gray_sync = wr_ptr_gray;
	assign resp_rd_ptr_gray_sync = resp_rd_ptr_gray;
	assign resp_wr_ptr_gray_sync = resp_wr_ptr_gray;

endmodule

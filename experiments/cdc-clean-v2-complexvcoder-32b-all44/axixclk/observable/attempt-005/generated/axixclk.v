module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// CDC FIFO for AW channel
	cdc_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH (LGFIFO)
	) aw_cdc (
		.src_clk (S_AXI_ACLK),
		.src_rstn (S_AXI_ARESETN),
		.dst_clk (M_AXI_ACLK),
		.dst_rstn (M_AXI_ARESETN),
		.src_data ({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.src_valid (S_AXI_AWVALID),
		.src_ready (S_AXI_AWREADY),
		.dst_data ({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.dst_valid (M_AXI_AWVALID),
		.dst_ready (M_AXI_AWREADY)
	);

	// CDC FIFO for W channel
	cdc_fifo #(
		.WIDTH (C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1),
		.DEPTH (LGFIFO)
	) w_cdc (
		.src_clk (S_AXI_ACLK),
		.src_rstn (S_AXI_ARESETN),
		.dst_clk (M_AXI_ACLK),
		.dst_rstn (M_AXI_ARESETN),
		.src_data ({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.src_valid (S_AXI_WVALID),
		.src_ready (S_AXI_WREADY),
		.dst_data ({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.dst_valid (M_AXI_WVALID),
		.dst_ready (M_AXI_WREADY)
	);

	// CDC FIFO for B channel
	cdc_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + 2),
		.DEPTH (LGFIFO)
	) b_cdc (
		.src_clk (M_AXI_ACLK),
		.src_rstn (M_AXI_ARESETN),
		.dst_clk (S_AXI_ACLK),
		.dst_rstn (S_AXI_ARESETN),
		.src_data ({M_AXI_BID, M_AXI_BRESP}),
		.src_valid (M_AXI_BVALID),
		.src_ready (M_AXI_BREADY),
		.dst_data ({S_AXI_BID, S_AXI_BRESP}),
		.dst_valid (S_AXI_BVALID),
		.dst_ready (S_AXI_BREADY)
	);

	// CDC FIFO for AR channel
	cdc_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH (LGFIFO)
	) ar_cdc (
		.src_clk (S_AXI_ACLK),
		.src_rstn (S_AXI_ARESETN),
		.dst_clk (M_AXI_ACLK),
		.dst_rstn (M_AXI_ARESETN),
		.src_data ({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.src_valid (S_AXI_ARVALID),
		.src_ready (S_AXI_ARREADY),
		.dst_data ({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.dst_valid (M_AXI_ARVALID),
		.dst_ready (M_AXI_ARREADY)
	);

	// CDC FIFO for R channel
	cdc_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH (LGFIFO)
	) r_cdc (
		.src_clk (M_AXI_ACLK),
		.src_rstn (M_AXI_ARESETN),
		.dst_clk (S_AXI_ACLK),
		.dst_rstn (S_AXI_ARESETN),
		.src_data ({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.src_valid (M_AXI_RVALID),
		.src_ready (M_AXI_RREADY),
		.dst_data ({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.dst_valid (S_AXI_RVALID),
		.dst_ready (S_AXI_RREADY)
	);

	// Reset signal for M_AXI
	reg [XCLOCK_FFS-1:0] rst_ffs;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			rst_ffs <= {(XCLOCK_FFS){1'b1}};
		else
			rst_ffs <= {rst_ffs[XCLOCK_FFS-2:0], 1'b0};
	end
	assign M_AXI_ARESETN = rst_ffs[XCLOCK_FFS-1];

endmodule

// CDC FIFO module
module cdc_fifo #(
		parameter WIDTH = 32,
		parameter DEPTH = 8
	) (
		input	wire				src_clk,
		input	wire				src_rstn,
		input	wire				dst_clk,
		input	wire				dst_rstn,
		input	wire [WIDTH-1 : 0]	src_data,
		input	wire				src_valid,
		output	reg					src_ready,
		output	reg [WIDTH-1 : 0]	dst_data,
		output	reg					dst_valid,
		input	wire				dst_ready
	);

	// FIFO memory
	reg [WIDTH-1 : 0] mem [0 : DEPTH-1];
	reg [$clog2(DEPTH)-1 : 0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH)-1 : 0] wr_ptr_gray, rd_ptr_gray;
	reg [$clog2(DEPTH)-1 : 0] wr_ptr_gray_sync, rd_ptr_gray_sync;
	reg [$clog2(DEPTH)-1 : 0] wr_ptr_bin_sync, rd_ptr_bin_sync;

	// Binary to Gray conversion
	function [$clog2(DEPTH)-1 : 0] bin_to_gray;
		input [$clog2(DEPTH)-1 : 0] bin;
		bin_to_gray = (bin >> 1) ^ bin;
	endfunction

	// Gray to Binary conversion
	function [$clog2(DEPTH)-1 : 0] gray_to_bin;
		input [$clog2(DEPTH)-1 : 0] gray;
		integer i;
		reg [$clog2(DEPTH)-1 : 0] bin;
		bin = gray[$clog2(DEPTH)-1];
		for (i = $clog2(DEPTH)-2; i >= 0; i = i - 1)
			bin[i] = bin[i+1] ^ gray[i];
		gray_to_bin = bin;
	endfunction

	// Write pointer logic
	always @(posedge src_clk or negedge src_rstn) begin
		if (!src_rstn) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (src_ready && src_valid) begin
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
		end
	end

	// Read pointer logic
	always @(posedge dst_clk or negedge dst_rstn) begin
		if (!dst_rstn) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
		end else if (dst_ready && dst_valid) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
		end
	end

	// Gray code synchronization
	sync_gray #(
		.WIDTH ($clog2(DEPTH))
	) sync_wr (
		.clk (dst_clk),
		.rstn (dst_rstn),
		.src_data (wr_ptr_gray),
		.dst_data (wr_ptr_gray_sync)
	);

	sync_gray #(
		.WIDTH ($clog2(DEPTH))
	) sync_rd (
		.clk (src_clk),
		.rstn (src_rstn),
		.src_data (rd_ptr_gray),
		.dst_data (rd_ptr_gray_sync)
	);

	// Convert synchronized Gray codes back to binary
	always @(posedge src_clk or negedge src_rstn) begin
		if (!src_rstn)
			rd_ptr_bin_sync <= 0;
		else
			rd_ptr_bin_sync <= gray_to_bin(rd_ptr_gray_sync);
	end

	always @(posedge dst_clk or negedge dst_rstn) begin
		if (!dst_rstn)
			wr_ptr_bin_sync <= 0;
		else
			wr_ptr_bin_sync <= gray_to_bin(wr_ptr_gray_sync);
	end

	// FIFO write
	always @(posedge src_clk) begin
		if (src_ready && src_valid)
			mem[wr_ptr] <= src_data;
	end

	// FIFO read
	always @(posedge dst_clk) begin
		if (dst_ready && dst_valid)
			dst_data <= mem[rd_ptr];
	end

	// FIFO status
	always @(posedge src_clk or negedge src_rstn) begin
		if (!src_rstn)
			src_ready <= 1'b1;
		else
			src_ready <= (wr_ptr_bin_sync != (rd_ptr_bin_sync + DEPTH - 1));
	end

	always @(posedge dst_clk or negedge dst_rstn) begin
		if (!dst_rstn)
			dst_valid <= 1'b0;
		else
			dst_valid <= (wr_ptr_bin_sync != rd_ptr_bin_sync);
	end

endmodule

// Gray code synchronizer
module sync_gray #(
		parameter WIDTH = 4
	) (
		input	wire				clk,
		input	wire				rstn,
		input	wire [WIDTH-1 : 0]	src_data,
		output	reg [WIDTH-1 : 0]	dst_data
	);

	reg [WIDTH-1 : 0] sync_reg1, sync_reg2;

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			sync_reg1 <= 0;
			sync_reg2 <= 0;
		end else begin
			sync_reg1 <= src_data;
			sync_reg2 <= sync_reg1;
		end
	end

	assign dst_data = sync_reg2;

endmodule

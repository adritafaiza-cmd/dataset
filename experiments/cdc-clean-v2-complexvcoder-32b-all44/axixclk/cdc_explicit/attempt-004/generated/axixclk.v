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

	// Internal signals
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_awfifo_wdata;
	wire s_awfifo_wvalid;
	wire s_awfifo_wready;
	wire [C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 - 1 : 0] s_wfifo_wdata;
	wire s_wfifo_wvalid;
	wire s_wfifo_wready;
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_arfifo_wdata;
	wire s_arfifo_wvalid;
	wire s_arfifo_wready;
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_awfifo_rdata;
	wire m_awfifo_rvalid;
	wire m_awfifo_rready;
	wire [C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 - 1 : 0] m_wfifo_rdata;
	wire m_wfifo_rvalid;
	wire m_wfifo_rready;
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_arfifo_rdata;
	wire m_arfifo_rvalid;
	wire m_arfifo_rready;
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 - 1 : 0] m_rfifo_rdata;
	wire m_rfifo_rvalid;
	wire m_rfifo_rready;
	wire s_bvalid;
	wire s_bready;
	wire s_rvalid;
	wire s_rready;
	wire m_bvalid;
	wire m_bready;
	wire m_rvalid;
	wire m_rready;

	// CDC FIFOs
	cdc_fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(2**LGFIFO),
		.XCLOCK_FFS(XCLOCK_FFS)
	) write_addr_fifo (
		.clk_wr(S_AXI_ACLK),
		.rst_wr(~S_AXI_ARESETN),
		.clk_rd(M_AXI_ACLK),
		.rst_rd(~M_AXI_ARESETN),
		.wr_data(s_awfifo_wdata),
		.wr_en(s_awfifo_wvalid),
		.wr_rdy(s_awfifo_wready),
		.rd_data(m_awfifo_rdata),
		.rd_en(m_awfifo_rready),
		.rd_rdy(m_awfifo_rvalid)
	);

	cdc_fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(2**LGFIFO),
		.XCLOCK_FFS(XCLOCK_FFS)
	) write_data_fifo (
		.clk_wr(S_AXI_ACLK),
		.rst_wr(~S_AXI_ARESETN),
		.clk_rd(M_AXI_ACLK),
		.rst_rd(~M_AXI_ARESETN),
		.wr_data(s_wfifo_wdata),
		.wr_en(s_wfifo_wvalid),
		.wr_rdy(s_wfifo_wready),
		.rd_data(m_wfifo_rdata),
		.rd_en(m_wfifo_rready),
		.rd_rdy(m_wfifo_rvalid)
	);

	cdc_fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(2**LGFIFO),
		.XCLOCK_FFS(XCLOCK_FFS)
	) read_addr_fifo (
		.clk_wr(S_AXI_ACLK),
		.rst_wr(~S_AXI_ARESETN),
		.clk_rd(M_AXI_ACLK),
		.rst_rd(~M_AXI_ARESETN),
		.wr_data(s_arfifo_wdata),
		.wr_en(s_arfifo_wvalid),
		.wr_rdy(s_arfifo_wready),
		.rd_data(m_arfifo_rdata),
		.rd_en(m_arfifo_rready),
		.rd_rdy(m_arfifo_rvalid)
	);

	cdc_fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(2**LGFIFO),
		.XCLOCK_FFS(XCLOCK_FFS)
	) read_data_fifo (
		.clk_wr(M_AXI_ACLK),
		.rst_wr(~M_AXI_ARESETN),
		.clk_rd(S_AXI_ACLK),
		.rst_rd(~S_AXI_ARESETN),
		.wr_data(m_rfifo_rdata),
		.wr_en(m_rfifo_rready),
		.wr_rdy(m_rfifo_rvalid),
		.rd_data({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.rd_en(s_rready),
		.rd_rdy(s_rvalid)
	);

	// AXI Write Address Channel
	assign s_awfifo_wdata = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
	assign S_AXI_AWREADY = s_awfifo_wready;
	assign m_awfifo_rready = m_awfifo_rvalid;

	// AXI Write Data Channel
	assign s_wfifo_wdata = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
	assign S_AXI_WREADY = s_wfifo_wready;
	assign m_wfifo_rready = m_wfifo_rvalid;

	// AXI Write Response Channel
	assign M_AXI_BREADY = m_bready;
	assign s_bvalid = m_bvalid;
	assign s_bready = S_AXI_BREADY;
	assign S_AXI_BID = M_AXI_BID;
	assign S_AXI_BRESP = M_AXI_BRESP;
	assign S_AXI_BVALID = s_bvalid;

	// AXI Read Address Channel
	assign s_arfifo_wdata = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
	assign S_AXI_ARREADY = s_arfifo_wready;
	assign m_arfifo_rready = m_arfifo_rvalid;

	// AXI Read Data Channel
	assign M_AXI_RREADY = m_rready;
	assign s_rvalid = m_rfifo_rvalid;
	assign s_rready = S_AXI_RREADY;
	assign m_rfifo_rdata = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};

	// AXI Master Reset
	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// AXI Write Address Channel M_AXI
	assign M_AXI_AWID = m_awfifo_rdata[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR = m_awfifo_rdata[C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = m_awfifo_rdata[8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: 8];
	assign M_AXI_AWSIZE = m_awfifo_rdata[3 + 2 + 1 + 4 + 3 + 4 - 1 -: 3];
	assign M_AXI_AWBURST = m_awfifo_rdata[2 + 1 + 4 + 3 + 4 - 1 -: 2];
	assign M_AXI_AWLOCK = m_awfifo_rdata[1 + 4 + 3 + 4 - 1];
	assign M_AXI_AWCACHE = m_awfifo_rdata[4 + 3 + 4 - 1 -: 4];
	assign M_AXI_AWPROT = m_awfifo_rdata[3 + 4 - 1 -: 3];
	assign M_AXI_AWQOS = m_awfifo_rdata[4 - 1 -: 4];
	assign M_AXI_AWVALID = m_awfifo_rvalid;

	// AXI Write Data Channel M_AXI
	assign M_AXI_WDATA = m_wfifo_rdata[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 - 1 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB = m_wfifo_rdata[(C_S_AXI_DATA_WIDTH/8) + 1 - 1 -: (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST = m_wfifo_rdata[1];
	assign M_AXI_WVALID = m_wfifo_rvalid;

	// AXI Read Address Channel M_AXI
	assign M_AXI_ARID = m_arfifo_rdata[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR = m_arfifo_rdata[C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = m_arfifo_rdata[8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 -: 8];
	assign M_AXI_ARSIZE = m_arfifo_rdata[3 + 2 + 1 + 4 + 3 + 4 - 1 -: 3];
	assign M_AXI_ARBURST = m_arfifo_rdata[2 + 1 + 4 + 3 + 4 - 1 -: 2];
	assign M_AXI_ARLOCK = m_arfifo_rdata[1 + 4 + 3 + 4 - 1];
	assign M_AXI_ARCACHE = m_arfifo_rdata[4 + 3 + 4 - 1 -: 4];
	assign M_AXI_ARPROT = m_arfifo_rdata[3 + 4 - 1 -: 3];
	assign M_AXI_ARQOS = m_arfifo_rdata[4 - 1 -: 4];
	assign M_AXI_ARVALID = m_arfifo_rvalid;

endmodule

module cdc_fifo #(
	parameter WIDTH = 8,
	parameter DEPTH = 16,
	parameter XCLOCK_FFS = 2
) (
	input wire clk_wr,
	input wire rst_wr,
	input wire clk_rd,
	input wire rst_rd,
	input wire [WIDTH-1:0] wr_data,
	input wire wr_en,
	output wire wr_rdy,
	output wire [WIDTH-1:0] rd_data,
	input wire rd_en,
	output wire rd_rdy
);

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH)-1:0] wr_ptr_gray, rd_ptr_gray;
	reg [$clog2(DEPTH)-1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	// Write pointer logic
	always @(posedge clk_wr or posedge rst_wr) begin
		if (rst_wr) begin
			wr_ptr <= 0;
		end else if (wr_en && wr_rdy) begin
			wr_ptr <= wr_ptr + 1;
		end
	end

	// Read pointer logic
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			rd_ptr <= 0;
		end else if (rd_en && rd_rdy) begin
			rd_ptr <= rd_ptr + 1;
		end
	end

	// Gray code conversion
	assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
	assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

	// Cross-clock domain synchronization of gray codes
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			wr_ptr_gray_sync <= 0;
		end else begin
			wr_ptr_gray_sync <= wr_ptr_gray;
		end
	end

	always @(posedge clk_wr or posedge rst_wr) begin
		if (rst_wr) begin
			rd_ptr_gray_sync <= 0;
		end else begin
			rd_ptr_gray_sync <= rd_ptr_gray;
		end
	end

	// Binary conversion and ready signals
	always @(wr_ptr_gray_sync or rd_ptr) begin
		integer i;
		reg [$clog2(DEPTH)-1:0] wr_ptr_bin_sync;
		wr_ptr_bin_sync = 0;
		for (i = 0; i < $clog2(DEPTH); i = i + 1) begin
			wr_ptr_bin_sync[i] = wr_ptr_gray_sync[i] ^ wr_ptr_bin_sync[i-1];
		end
		wr_rdy = (wr_ptr_bin_sync != rd_ptr + 1);
	end

	always @(rd_ptr_gray_sync or wr_ptr) begin
		integer i;
		reg [$clog2(DEPTH)-1:0] rd_ptr_bin_sync;
		rd_ptr_bin_sync = 0;
		for (i = 0; i < $clog2(DEPTH); i = i + 1) begin
			rd_ptr_bin_sync[i] = rd_ptr_gray_sync[i] ^ rd_ptr_bin_sync[i-1];
		end
		rd_rdy = (rd_ptr_bin_sync != wr_ptr);
	end

	// Memory write
	always @(posedge clk_wr) begin
		if (wr_en && wr_rdy) begin
			mem[wr_ptr] <= wr_data;
		end
	end

	// Memory read
	always @(posedge clk_rd) begin
		if (rd_en && rd_rdy) begin
			rd_data <= mem[rd_ptr];
		end
	end

endmodule

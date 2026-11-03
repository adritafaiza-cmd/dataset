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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_sync;
	wire [7 : 0]			awlen_sync;
	wire [2 : 0]			awsize_sync;
	wire [1 : 0]			awburst_sync;
	wire				awlock_sync;
	wire [3 : 0]			awcache_sync;
	wire [2 : 0]			awprot_sync;
	wire [3 : 0]			awqos_sync;
	wire				awvalid_sync;
	wire				awready_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_sync;
	wire				wlast_sync;
	wire				wvalid_sync;
	wire				wready_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_sync;
	wire [7 : 0]			arlen_sync;
	wire [2 : 0]			arsize_sync;
	wire [1 : 0]			arburst_sync;
	wire				arlock_sync;
	wire [3 : 0]			arcache_sync;
	wire [2 : 0]			arprot_sync;
	wire [3 : 0]			arqos_sync;
	wire				arvalid_sync;
	wire				arready_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire				bvalid_sync;
	wire				bready_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync;
	wire [1 : 0]			rresp_sync;
	wire				rlast_sync;
	wire				rvalid_sync;
	wire				rready_sync;

	wire				m_axi_aresetn_sync;

	wire				awfifo_empty;
	wire				awfifo_full;
	wire				wfifo_empty;
	wire				wfifo_full;
	wire				arfifo_empty;
	wire				arfifo_full;
	wire				rfifo_empty;
	wire				rfifo_full;
	wire				bfifo_empty;
	wire				bfifo_full;

	wire				awfifo_rd;
	wire				awfifo_wr;
	wire				wfifo_rd;
	wire				wfifo_wr;
	wire				arfifo_rd;
	wire				arfifo_wr;
	wire				rfifo_rd;
	wire				rfifo_wr;
	wire				bfifo_rd;
	wire				bfifo_wr;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_din;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_din_addr;
	wire [7 : 0]			awfifo_din_len;
	wire [2 : 0]			awfifo_din_size;
	wire [1 : 0]			awfifo_din_burst;
	wire				awfifo_din_lock;
	wire [3 : 0]			awfifo_din_cache;
	wire [2 : 0]			awfifo_din_prot;
	wire [3 : 0]			awfifo_din_qos;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_dout;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_dout_addr;
	wire [7 : 0]			awfifo_dout_len;
	wire [2 : 0]			awfifo_dout_size;
	wire [1 : 0]			awfifo_dout_burst;
	wire				awfifo_dout_lock;
	wire [3 : 0]			awfifo_dout_cache;
	wire [2 : 0]			awfifo_dout_prot;
	wire [3 : 0]			awfifo_dout_qos;

	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_din;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wfifo_din_strb;
	wire				wfifo_din_last;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_dout;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wfifo_dout_strb;
	wire				wfifo_dout_last;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_din;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_din_addr;
	wire [7 : 0]			arfifo_din_len;
	wire [2 : 0]			arfifo_din_size;
	wire [1 : 0]			arfifo_din_burst;
	wire				arfifo_din_lock;
	wire [3 : 0]			arfifo_din_cache;
	wire [2 : 0]			arfifo_din_prot;
	wire [3 : 0]			arfifo_din_qos;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_dout;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_dout_addr;
	wire [7 : 0]			arfifo_dout_len;
	wire [2 : 0]			arfifo_dout_size;
	wire [1 : 0]			arfifo_dout_burst;
	wire				arfifo_dout_lock;
	wire [3 : 0]			arfifo_dout_cache;
	wire [2 : 0]			arfifo_dout_prot;
	wire [3 : 0]			arfifo_dout_qos;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_din;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_din_data;
	wire [1 : 0]			rfifo_din_resp;
	wire				rfifo_din_last;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_dout;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_dout_data;
	wire [1 : 0]			rfifo_dout_resp;
	wire				rfifo_dout_last;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bfifo_din;
	wire [1 : 0]			bfifo_din_resp;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bfifo_dout;
	wire [1 : 0]			bfifo_dout_resp;

	assign M_AXI_ARESETN = ~S_AXI_ARESETN;

	assign awfifo_din = S_AXI_AWID;
	assign awfifo_din_addr = S_AXI_AWADDR;
	assign awfifo_din_len = S_AXI_AWLEN;
	assign awfifo_din_size = S_AXI_AWSIZE;
	assign awfifo_din_burst = S_AXI_AWBURST;
	assign awfifo_din_lock = S_AXI_AWLOCK;
	assign awfifo_din_cache = S_AXI_AWCACHE;
	assign awfifo_din_prot = S_AXI_AWPROT;
	assign awfifo_din_qos = S_AXI_AWQOS;

	assign wfifo_din = S_AXI_WDATA;
	assign wfifo_din_strb = S_AXI_WSTRB;
	assign wfifo_din_last = S_AXI_WLAST;

	assign arfifo_din = S_AXI_ARID;
	assign arfifo_din_addr = S_AXI_ARADDR;
	assign arfifo_din_len = S_AXI_ARLEN;
	assign arfifo_din_size = S_AXI_ARSIZE;
	assign arfifo_din_burst = S_AXI_ARBURST;
	assign arfifo_din_lock = S_AXI_ARLOCK;
	assign arfifo_din_cache = S_AXI_ARCACHE;
	assign arfifo_din_prot = S_AXI_ARPROT;
	assign arfifo_din_qos = S_AXI_ARQOS;

	assign rfifo_din = M_AXI_RID;
	assign rfifo_din_data = M_AXI_RDATA;
	assign rfifo_din_resp = M_AXI_RRESP;
	assign rfifo_din_last = M_AXI_RLAST;

	assign bfifo_din = M_AXI_BID;
	assign bfifo_din_resp = M_AXI_BRESP;

	assign awfifo_wr = S_AXI_AWVALID & ~awfifo_full;
	assign awfifo_rd = M_AXI_AWREADY & ~awfifo_empty;
	assign wfifo_wr = S_AXI_WVALID & ~wfifo_full;
	assign wfifo_rd = M_AXI_WREADY & ~wfifo_empty;
	assign arfifo_wr = S_AXI_ARVALID & ~arfifo_full;
	assign arfifo_rd = M_AXI_ARREADY & ~arfifo_empty;
	assign rfifo_wr = M_AXI_RVALID & ~rfifo_full;
	assign rfifo_rd = S_AXI_RREADY & ~rfifo_empty;
	assign bfifo_wr = M_AXI_BVALID & ~bfifo_full;
	assign bfifo_rd = S_AXI_BREADY & ~bfifo_empty;

	assign S_AXI_AWREADY = ~awfifo_full;
	assign S_AXI_WREADY = ~wfifo_full;
	assign S_AXI_ARREADY = ~arfifo_full;
	assign S_AXI_BVALID = ~bfifo_empty;
	assign S_AXI_RVALID = ~rfifo_empty;

	assign M_AXI_AWID = awfifo_dout;
	assign M_AXI_AWADDR = awfifo_dout_addr;
	assign M_AXI_AWLEN = awfifo_dout_len;
	assign M_AXI_AWSIZE = awfifo_dout_size;
	assign M_AXI_AWBURST = awfifo_dout_burst;
	assign M_AXI_AWLOCK = awfifo_dout_lock;
	assign M_AXI_AWCACHE = awfifo_dout_cache;
	assign M_AXI_AWPROT = awfifo_dout_prot;
	assign M_AXI_AWQOS = awfifo_dout_qos;
	assign M_AXI_AWVALID = ~awfifo_empty;
	assign M_AXI_WDATA = wfifo_dout;
	assign M_AXI_WSTRB = wfifo_dout_strb;
	assign M_AXI_WLAST = wfifo_dout_last;
	assign M_AXI_WVALID = ~wfifo_empty;
	assign M_AXI_BREADY = ~bfifo_full;
	assign M_AXI_ARID = arfifo_dout;
	assign M_AXI_ARADDR = arfifo_dout_addr;
	assign M_AXI_ARLEN = arfifo_dout_len;
	assign M_AXI_ARSIZE = arfifo_dout_size;
	assign M_AXI_ARBURST = arfifo_dout_burst;
	assign M_AXI_ARLOCK = arfifo_dout_lock;
	assign M_AXI_ARCACHE = arfifo_dout_cache;
	assign M_AXI_ARPROT = arfifo_dout_prot;
	assign M_AXI_ARQOS = arfifo_dout_qos;
	assign M_AXI_ARVALID = ~arfifo_empty;
	assign M_AXI_RREADY = ~rfifo_full;

	assign S_AXI_BID = bfifo_dout;
	assign S_AXI_BRESP = bfifo_dout_resp;
	assign S_AXI_RID = rfifo_dout;
	assign S_AXI_RDATA = rfifo_dout_data;
	assign S_AXI_RRESP = rfifo_dout_resp;
	assign S_AXI_RLAST = rfifo_dout_last;

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(1 << LGFIFO)
	) awfifo_inst (
		.clk(M_AXI_ACLK),
		.rst(~M_AXI_ARESETN),
		.din({awfifo_din, awfifo_din_addr, awfifo_din_len, awfifo_din_size, awfifo_din_burst, awfifo_din_lock, awfifo_din_cache, awfifo_din_prot, awfifo_din_qos}),
		.wr(awfifo_wr),
		.rd(awfifo_rd),
		.dout({awfifo_dout, awfifo_dout_addr, awfifo_dout_len, awfifo_dout_size, awfifo_dout_burst, awfifo_dout_lock, awfifo_dout_cache, awfifo_dout_prot, awfifo_dout_qos}),
		.empty(awfifo_empty),
		.full(awfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.C_DEPTH(1 << LGFIFO)
	) wfifo_inst (
		.clk(M_AXI_ACLK),
		.rst(~M_AXI_ARESETN),
		.din({wfifo_din, wfifo_din_strb, wfifo_din_last}),
		.wr(wfifo_wr),
		.rd(wfifo_rd),
		.dout({wfifo_dout, wfifo_dout_strb, wfifo_dout_last}),
		.empty(wfifo_empty),
		.full(wfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(1 << LGFIFO)
	) arfifo_inst (
		.clk(M_AXI_ACLK),
		.rst(~M_AXI_ARESETN),
		.din({arfifo_din, arfifo_din_addr, arfifo_din_len, arfifo_din_size, arfifo_din_burst, arfifo_din_lock, arfifo_din_cache, arfifo_din_prot, arfifo_din_qos}),
		.wr(arfifo_wr),
		.rd(arfifo_rd),
		.dout({arfifo_dout, arfifo_dout_addr, arfifo_dout_len, arfifo_dout_size, arfifo_dout_burst, arfifo_dout_lock, arfifo_dout_cache, arfifo_dout_prot, arfifo_dout_qos}),
		.empty(arfifo_empty),
		.full(arfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.C_DEPTH(1 << LGFIFO)
	) rfifo_inst (
		.clk(S_AXI_ACLK),
		.rst(~S_AXI_ARESETN),
		.din({rfifo_din, rfifo_din_data, rfifo_din_resp, rfifo_din_last}),
		.wr(rfifo_wr),
		.rd(rfifo_rd),
		.dout({rfifo_dout, rfifo_dout_data, rfifo_dout_resp, rfifo_dout_last}),
		.empty(rfifo_empty),
		.full(rfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.C_DEPTH(1 << LGFIFO)
	) bfifo_inst (
		.clk(S_AXI_ACLK),
		.rst(~S_AXI_ARESETN),
		.din({bfifo_din, bfifo_din_resp}),
		.wr(bfifo_wr),
		.rd(bfifo_rd),
		.dout({bfifo_dout, bfifo_dout_resp}),
		.empty(bfifo_empty),
		.full(bfifo_full)
	);

endmodule

module fifo #(
		parameter integer C_WIDTH = 32,
		parameter integer C_DEPTH = 16
	) (
		input	wire				clk,
		input	wire				rst,
		input	wire [C_WIDTH-1 : 0]		din,
		input	wire				wr,
		input	wire				rd,
		output	wire [C_WIDTH-1 : 0]		dout,
		output	wire				empty,
		output	wire				full
	);

	wire [C_DEPTH-1 : 0]		wr_ptr;
	wire [C_DEPTH-1 : 0]		rd_ptr;
	wire				wr_en;
	wire				rd_en;
	wire [C_WIDTH-1 : 0]		mem [C_DEPTH-1 : 0];

	assign wr_en = wr & ~full;
	assign rd_en = rd & ~empty;

	always @(posedge clk) begin
		if (~rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
		end else if (wr_en & ~rd_en) begin
			wr_ptr <= wr_ptr + 1;
		end else if (~wr_en & rd_en) begin
			rd_ptr <= rd_ptr + 1;
		end
	end

	always @(posedge clk) begin
		if (~rst) begin
			mem <= {C_DEPTH{1'b0}};
		end else if (wr_en) begin
			mem[wr_ptr] <= din;
		end
	end

	assign dout = mem[rd_ptr];
	assign empty = (wr_ptr == rd_ptr);
	assign full = (wr_ptr == (rd_ptr + 1) % C_DEPTH);

endmodule

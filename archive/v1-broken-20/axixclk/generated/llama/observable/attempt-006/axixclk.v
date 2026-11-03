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
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire				bvalid_sync;
	wire				bready_sync;
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
	wire				bfifo_empty;
	wire				bfifo_full;
	wire				arfifo_empty;
	wire				arfifo_full;
	wire				rfifo_empty;
	wire				rfifo_full;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_out_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_out_addr;
	wire [7 : 0]			awfifo_out_len;
	wire [2 : 0]			awfifo_out_size;
	wire [1 : 0]			awfifo_out_burst;
	wire				awfifo_out_lock;
	wire [3 : 0]			awfifo_out_cache;
	wire [2 : 0]			awfifo_out_prot;
	wire [3 : 0]			awfifo_out_qos;
	wire				awfifo_out_valid;
	wire				awfifo_out_ready;

	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_out_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wfifo_out_strb;
	wire				wfifo_out_last;
	wire				wfifo_out_valid;
	wire				wfifo_out_ready;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bfifo_out_id;
	wire [1 : 0]			bfifo_out_resp;
	wire				bfifo_out_valid;
	wire				bfifo_out_ready;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_out_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_out_addr;
	wire [7 : 0]			arfifo_out_len;
	wire [2 : 0]			arfifo_out_size;
	wire [1 : 0]			arfifo_out_burst;
	wire				arfifo_out_lock;
	wire [3 : 0]			arfifo_out_cache;
	wire [2 : 0]			arfifo_out_prot;
	wire [3 : 0]			arfifo_out_qos;
	wire				arfifo_out_valid;
	wire				arfifo_out_ready;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_out_id;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_out_data;
	wire [1 : 0]			rfifo_out_resp;
	wire				rfifo_out_last;
	wire				rfifo_out_valid;
	wire				rfifo_out_ready;

	assign M_AXI_ARESETN = m_axi_aresetn_sync;

	// AW channel
	assign awid_sync = S_AXI_AWID;
	assign awaddr_sync = S_AXI_AWADDR;
	assign awlen_sync = S_AXI_AWLEN;
	assign awsize_sync = S_AXI_AWSIZE;
	assign awburst_sync = S_AXI_AWBURST;
	assign awlock_sync = S_AXI_AWLOCK;
	assign awcache_sync = S_AXI_AWCACHE;
	assign awprot_sync = S_AXI_AWPROT;
	assign awqos_sync = S_AXI_AWQOS;
	assign awvalid_sync = S_AXI_AWVALID;
	assign S_AXI_AWREADY = awready_sync;

	// W channel
	assign wdata_sync = S_AXI_WDATA;
	assign wstrb_sync = S_AXI_WSTRB;
	assign wlast_sync = S_AXI_WLAST;
	assign wvalid_sync = S_AXI_WVALID;
	assign S_AXI_WREADY = wready_sync;

	// B channel
	assign bid_sync = M_AXI_BID;
	assign bresp_sync = M_AXI_BRESP;
	assign bvalid_sync = M_AXI_BVALID;
	assign M_AXI_BREADY = bready_sync;

	// AR channel
	assign arid_sync = S_AXI_ARID;
	assign araddr_sync = S_AXI_ARADDR;
	assign arlen_sync = S_AXI_ARLEN;
	assign arsize_sync = S_AXI_ARSIZE;
	assign arburst_sync = S_AXI_ARBURST;
	assign arlock_sync = S_AXI_ARLOCK;
	assign arcache_sync = S_AXI_ARCACHE;
	assign arprot_sync = S_AXI_ARPROT;
	assign arqos_sync = S_AXI_ARQOS;
	assign arvalid_sync = S_AXI_ARVALID;
	assign S_AXI_ARREADY = arready_sync;

	// R channel
	assign rid_sync = M_AXI_RID;
	assign rdata_sync = M_AXI_RDATA;
	assign rresp_sync = M_AXI_RRESP;
	assign rlast_sync = M_AXI_RLAST;
	assign rvalid_sync = M_AXI_RVALID;
	assign M_AXI_RREADY = rready_sync;

	// Clock domain crossing
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
		begin
			awid_sync <= 0;
			awaddr_sync <= 0;
			awlen_sync <= 0;
			awsize_sync <= 0;
			awburst_sync <= 0;
			awlock_sync <= 0;
			awcache_sync <= 0;
			awprot_sync <= 0;
			awqos_sync <= 0;
			awvalid_sync <= 0;
			wdata_sync <= 0;
			wstrb_sync <= 0;
			wlast_sync <= 0;
			wvalid_sync <= 0;
			bid_sync <= 0;
			bresp_sync <= 0;
			bvalid_sync <= 0;
			arid_sync <= 0;
			araddr_sync <= 0;
			arlen_sync <= 0;
			arsize_sync <= 0;
			arburst_sync <= 0;
			arlock_sync <= 0;
			arcache_sync <= 0;
			arprot_sync <= 0;
			arqos_sync <= 0;
			arvalid_sync <= 0;
			rid_sync <= 0;
			rdata_sync <= 0;
			rresp_sync <= 0;
			rlast_sync <= 0;
			rvalid_sync <= 0;
		end
		else
		begin
			awid_sync <= S_AXI_AWID;
			awaddr_sync <= S_AXI_AWADDR;
			awlen_sync <= S_AXI_AWLEN;
			awsize_sync <= S_AXI_AWSIZE;
			awburst_sync <= S_AXI_AWBURST;
			awlock_sync <= S_AXI_AWLOCK;
			awcache_sync <= S_AXI_AWCACHE;
			awprot_sync <= S_AXI_AWPROT;
			awqos_sync <= S_AXI_AWQOS;
			awvalid_sync <= S_AXI_AWVALID;
			wdata_sync <= S_AXI_WDATA;
			wstrb_sync <= S_AXI_WSTRB;
			wlast_sync <= S_AXI_WLAST;
			wvalid_sync <= S_AXI_WVALID;
			bid_sync <= M_AXI_BID;
			bresp_sync <= M_AXI_BRESP;
			bvalid_sync <= M_AXI_BVALID;
			arid_sync <= S_AXI_ARID;
			araddr_sync <= S_AXI_ARADDR;
			arlen_sync <= S_AXI_ARLEN;
			arsize_sync <= S_AXI_ARSIZE;
			arburst_sync <= S_AXI_ARBURST;
			arlock_sync <= S_AXI_ARLOCK;
			arcache_sync <= S_AXI_ARCACHE;
			arprot_sync <= S_AXI_ARPROT;
			arqos_sync <= S_AXI_ARQOS;
			arvalid_sync <= S_AXI_ARVALID;
			rid_sync <= M_AXI_RID;
			rdata_sync <= M_AXI_RDATA;
			rresp_sync <= M_AXI_RRESP;
			rlast_sync <= M_AXI_RLAST;
			rvalid_sync <= M_AXI_RVALID;
		end
	end

	// Clock domain crossing
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
	begin
		if (!M_AXI_ARESETN)
		begin
			m_axi_aresetn_sync <= 1'b0;
		end
		else
		begin
			m_axi_aresetn_sync <= S_AXI_ARESETN;
		end
	end

	// AW channel FIFO
	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DDEPTH(1 << LGFIFO)
	) awfifo (
		.clk(M_AXI_ACLK),
		.rst(!M_AXI_ARESETN),
		.din({awid_sync, awaddr_sync, awlen_sync, awsize_sync, awburst_sync, awlock_sync, awcache_sync, awprot_sync, awqos_sync}),
		.din_valid(awvalid_sync),
		.din_ready(awready_sync),
		.dout({awfifo_out_id, awfifo_out_addr, awfifo_out_len, awfifo_out_size, awfifo_out_burst, awfifo_out_lock, awfifo_out_cache, awfifo_out_prot, awfifo_out_qos}),
		.dout_valid(awfifo_out_valid),
		.dout_ready(awfifo_out_ready),
		.empty(awfifo_empty),
		.full(awfifo_full)
	);

	// W channel FIFO
	fifo #(
		.DWIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DDEPTH(1 << LGFIFO)
	) wfifo (
		.clk(M_AXI_ACLK),
		.rst(!M_AXI_ARESETN),
		.din({wdata_sync, wstrb_sync, wlast_sync}),
		.din_valid(wvalid_sync),
		.din_ready(wready_sync),
		.dout({wfifo_out_data, wfifo_out_strb, wfifo_out_last}),
		.dout_valid(wfifo_out_valid),
		.dout_ready(wfifo_out_ready),
		.empty(wfifo_empty),
		.full(wfifo_full)
	);

	// B channel FIFO
	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + 2),
		.DDEPTH(1 << LGFIFO)
	) bfifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.din({bid_sync, bresp_sync}),
		.din_valid(bvalid_sync),
		.din_ready(bready_sync),
		.dout({bfifo_out_id, bfifo_out_resp}),
		.dout_valid(bfifo_out_valid),
		.dout_ready(bfifo_out_ready),
		.empty(bfifo_empty),
		.full(bfifo_full)
	);

	// AR channel FIFO
	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DDEPTH(1 << LGFIFO)
	) arfifo (
		.clk(M_AXI_ACLK),
		.rst(!M_AXI_ARESETN),
		.din({arid_sync, araddr_sync, arlen_sync, arsize_sync, arburst_sync, arlock_sync, arcache_sync, arprot_sync, arqos_sync}),
		.din_valid(arvalid_sync),
		.din_ready(arready_sync),
		.dout({arfifo_out_id, arfifo_out_addr, arfifo_out_len, arfifo_out_size, arfifo_out_burst, arfifo_out_lock, arfifo_out_cache, arfifo_out_prot, arfifo_out_qos}),
		.dout_valid(arfifo_out_valid),
		.dout_ready(arfifo_out_ready),
		.empty(arfifo_empty),
		.full(arfifo_full)
	);

	// R channel FIFO
	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DDEPTH(1 << LGFIFO)
	) rfifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.din({rid_sync, rdata_sync, rresp_sync, rlast_sync}),
		.din_valid(rvalid_sync),
		.din_ready(rready_sync),
		.dout({rfifo_out_id, rfifo_out_data, rfifo_out_resp, rfifo_out_last}),
		.dout_valid(rfifo_out_valid),
		.dout_ready(rfifo_out_ready),
		.empty(rfifo_empty),
		.full(rfifo_full)
	);

	// AW channel
	assign M_AXI_AWID = awfifo_out_id;
	assign M_AXI_AWADDR = awfifo_out_addr;
	assign M_AXI_AWLEN = awfifo_out_len;
	assign M_AXI_AWSIZE = awfifo_out_size;
	assign M_AXI_AWBURST = awfifo_out_burst;
	assign M_AXI_AWLOCK = awfifo_out_lock;
	assign M_AXI_AWCACHE = awfifo_out_cache;
	assign M_AXI_AWPROT = awfifo_out_prot;
	assign M_AXI_AWQOS = awfifo_out_qos;
	assign M_AXI_AWVALID = awfifo_out_valid;
	assign awfifo_out_ready = M_AXI_AWREADY;

	// W channel
	assign M_AXI_WDATA = wfifo_out_data;
	assign M_AXI_WSTRB = wfifo_out_strb;
	assign M_AXI_WLAST = wfifo_out_last;
	assign M_AXI_WVALID = wfifo_out_valid;
	assign wfifo_out_ready = M_AXI_WREADY;

	// B channel
	assign S_AXI_BID = bfifo_out_id;
	assign S_AXI_BRESP = bfifo_out_resp;
	assign S_AXI_BVALID = bfifo_out_valid;
	assign bfifo_out_ready = S_AXI_BREADY;

	// AR channel
	assign M_AXI_ARID = arfifo_out_id;
	assign M_AXI_ARADDR = arfifo_out_addr;
	assign M_AXI_ARLEN = arfifo_out_len;
	assign M_AXI_ARSIZE = arfifo_out_size;
	assign M_AXI_ARBURST = arfifo_out_burst;
	assign M_AXI_ARLOCK = arfifo_out_lock;
	assign M_AXI_ARCACHE = arfifo_out_cache;
	assign M_AXI_ARPROT = arfifo_out_prot;
	assign M_AXI_ARQOS = arfifo_out_qos;
	assign M_AXI_ARVALID = arfifo_out_valid;
	assign arfifo_out_ready = M_AXI_ARREADY;

	// R channel
	assign S_AXI_RID = rfifo_out_id;
	assign S_AXI_RDATA = rfifo_out_data;
	assign S_AXI_RRESP = rfifo_out_resp;
	assign S_AXI_RLAST = rfifo_out_last;
	assign S_AXI_RVALID = rfifo_out_valid;
	assign rfifo_out_ready = S_AXI_RREADY;

endmodule

module fifo #(
	parameter integer DWIDTH = 32,
	parameter integer DDEPTH = 16
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [DWIDTH-1 : 0]	din,
	input	wire	din_valid,
	output	wire	din_ready,
	output	wire [DWIDTH-1 : 0]	dout,
	output	wire	dout_valid,
	input	wire	dout_ready,
	output	wire	empty,
	output	wire	full
);

	reg [DWIDTH-1 : 0]	ram [DDEPTH-1 : 0];
	reg [DDEPTH-1 : 0]	wptr;
	reg [DDEPTH-1 : 0]	rptr;
	reg [DDEPTH-1 : 0]	count;

	assign empty = (count == 0);
	assign full = (count == DDEPTH);
	assign din_ready = !full;
	assign dout_valid = !empty;

	always @(posedge clk or negedge rst)
	begin
		if (!rst)
		begin
			wptr <= 0;
			rptr <= 0;
			count <= 0;
		end
		else
		begin
			if (din_valid && !full)
			begin
				ram[wptr] <= din;
				wptr <= wptr + 1;
				count <= count + 1;
			end
			if (dout_ready && !empty)
			begin
				rptr <= rptr + 1;
				count <= count - 1;
			end
		end
	end

	assign dout = ram[rptr];

endmodule

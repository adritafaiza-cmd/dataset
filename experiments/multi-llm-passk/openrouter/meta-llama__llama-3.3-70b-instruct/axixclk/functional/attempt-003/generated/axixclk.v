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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr;
	wire [7 : 0]			awlen;
	wire [2 : 0]			awsize;
	wire [1 : 0]			awburst;
	wire				awlock;
	wire [3 : 0]			awcache;
	wire [2 : 0]			awprot;
	wire [3 : 0]			awqos;
	wire				awvalid;
	wire				awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb;
	wire				wlast;
	wire				wvalid;
	wire				wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid;
	wire [1 : 0]			bresp;
	wire				bvalid;
	wire				bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr;
	wire [7 : 0]			arlen;
	wire [2 : 0]			arsize;
	wire [1 : 0]			arburst;
	wire				arlock;
	wire [3 : 0]			arcache;
	wire [2 : 0]			arprot;
	wire [3 : 0]			arqos;
	wire				arvalid;
	wire				arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata;
	wire [1 : 0]			rresp;
	wire				rlast;
	wire				rvalid;
	wire				rready;

	wire				m_axi_aresetn;

	assign M_AXI_ARESETN = m_axi_aresetn;

	assign S_AXI_AWREADY = awready;
	assign S_AXI_WREADY = wready;
	assign S_AXI_BID = bid;
	assign S_AXI_BRESP = bresp;
	assign S_AXI_BVALID = bvalid;
	assign S_AXI_ARREADY = arready;
	assign S_AXI_RID = rid;
	assign S_AXI_RDATA = rdata;
	assign S_AXI_RRESP = rresp;
	assign S_AXI_RLAST = rlast;
	assign S_AXI_RVALID = rvalid;

	assign M_AXI_AWID = awid;
	assign M_AXI_AWADDR = awaddr;
	assign M_AXI_AWLEN = awlen;
	assign M_AXI_AWSIZE = awsize;
	assign M_AXI_AWBURST = awburst;
	assign M_AXI_AWLOCK = awlock;
	assign M_AXI_AWCACHE = awcache;
	assign M_AXI_AWPROT = awprot;
	assign M_AXI_AWQOS = awqos;
	assign M_AXI_AWVALID = awvalid;
	assign M_AXI_WDATA = wdata;
	assign M_AXI_WSTRB = wstrb;
	assign M_AXI_WLAST = wlast;
	assign M_AXI_WVALID = wvalid;
	assign M_AXI_BREADY = bready;
	assign M_AXI_ARID = arid;
	assign M_AXI_ARADDR = araddr;
	assign M_AXI_ARLEN = arlen;
	assign M_AXI_ARSIZE = arsize;
	assign M_AXI_ARBURST = arburst;
	assign M_AXI_ARLOCK = arlock;
	assign M_AXI_ARCACHE = arcache;
	assign M_AXI_ARPROT = arprot;
	assign M_AXI_ARQOS = arqos;
	assign M_AXI_ARVALID = arvalid;
	assign M_AXI_RREADY = rready;

	wire [XCLOCK_FFS-1 : 0]	clk_ffs;
	wire				clk_ffs_valid;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			clk_ffs <= 0;
		end else begin
			clk_ffs <= clk_ffs + 1;
		end
	end

	assign clk_ffs_valid = (clk_ffs == (1 << XCLOCK_FFS) - 1);

	wire				m_axi_aresetn_ff;
	wire				m_axi_aresetn_ff2;

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			m_axi_aresetn_ff <= 1'b0;
		end else if (clk_ffs_valid) begin
			m_axi_aresetn_ff <= S_AXI_ARESETN;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_ff) begin
			m_axi_aresetn_ff2 <= 1'b0;
		end else if (clk_ffs_valid) begin
			m_axi_aresetn_ff2 <= S_AXI_ARESETN;
		end
	end

	assign m_axi_aresetn = m_axi_aresetn_ff2;

	wire [LGFIFO-1 : 0]	awfifo_cnt;
	wire [LGFIFO-1 : 0]	wfifo_cnt;
	wire [LGFIFO-1 : 0]	arfifo_cnt;
	wire [LGFIFO-1 : 0]	rfifo_cnt;

	wire				awfifo_empty;
	wire				awfifo_full;
	wire				wfifo_empty;
	wire				wfifo_full;
	wire				arfifo_empty;
	wire				arfifo_full;
	wire				rfifo_empty;
	wire				rfifo_full;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_addr;
	wire [7 : 0]			awfifo_len;
	wire [2 : 0]			awfifo_size;
	wire [1 : 0]			awfifo_burst;
	wire				awfifo_lock;
	wire [3 : 0]			awfifo_cache;
	wire [2 : 0]			awfifo_prot;
	wire [3 : 0]			awfifo_qos;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	wfifo_id;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wfifo_strb;
	wire				wfifo_last;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_addr;
	wire [7 : 0]			arfifo_len;
	wire [2 : 0]			arfifo_size;
	wire [1 : 0]			arfifo_burst;
	wire				arfifo_lock;
	wire [3 : 0]			arfifo_cache;
	wire [2 : 0]			arfifo_prot;
	wire [3 : 0]			arfifo_qos;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_id;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_data;
	wire [1 : 0]			rfifo_resp;
	wire				rfifo_last;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			awfifo_cnt <= 0;
		end else if (S_AXI_AWVALID && !awfifo_full) begin
			awfifo_cnt <= awfifo_cnt + 1;
		end else if (awready && !awfifo_empty) begin
			awfifo_cnt <= awfifo_cnt - 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			wfifo_cnt <= 0;
		end else if (S_AXI_WVALID && !wfifo_full) begin
			wfifo_cnt <= wfifo_cnt + 1;
		end else if (wready && !wfifo_empty) begin
			wfifo_cnt <= wfifo_cnt - 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			arfifo_cnt <= 0;
		end else if (S_AXI_ARVALID && !arfifo_full) begin
			arfifo_cnt <= arfifo_cnt + 1;
		end else if (arready && !arfifo_empty) begin
			arfifo_cnt <= arfifo_cnt - 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			rfifo_cnt <= 0;
		end else if (M_AXI_RVALID && !rfifo_full) begin
			rfifo_cnt <= rfifo_cnt + 1;
		end else if (rready && !rfifo_empty) begin
			rfifo_cnt <= rfifo_cnt - 1;
		end
	end

	assign awfifo_empty = (awfifo_cnt == 0);
	assign awfifo_full = (awfifo_cnt == (1 << LGFIFO) - 1);
	assign wfifo_empty = (wfifo_cnt == 0);
	assign wfifo_full = (wfifo_cnt == (1 << LGFIFO) - 1);
	assign arfifo_empty = (arfifo_cnt == 0);
	assign arfifo_full = (arfifo_cnt == (1 << LGFIFO) - 1);
	assign rfifo_empty = (rfifo_cnt == 0);
	assign rfifo_full = (rfifo_cnt == (1 << LGFIFO) - 1);

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			awid <= 0;
			awaddr <= 0;
			awlen <= 0;
			awsize <= 0;
			awburst <= 0;
			awlock <= 0;
			awcache <= 0;
			awprot <= 0;
			awqos <= 0;
		end else if (S_AXI_AWVALID && !awfifo_full) begin
			awid <= S_AXI_AWID;
			awaddr <= S_AXI_AWADDR;
			awlen <= S_AXI_AWLEN;
			awsize <= S_AXI_AWSIZE;
			awburst <= S_AXI_AWBURST;
			awlock <= S_AXI_AWLOCK;
			awcache <= S_AXI_AWCACHE;
			awprot <= S_AXI_AWPROT;
			awqos <= S_AXI_AWQOS;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			wid <= 0;
			wdata <= 0;
			wstrb <= 0;
			wlast <= 0;
		end else if (S_AXI_WVALID && !wfifo_full) begin
			wid <= S_AXI_AWID;
			wdata <= S_AXI_WDATA;
			wstrb <= S_AXI_WSTRB;
			wlast <= S_AXI_WLAST;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			arid <= 0;
			araddr <= 0;
			arlen <= 0;
			arsize <= 0;
			arburst <= 0;
			arlock <= 0;
			arcache <= 0;
			arprot <= 0;
			arqos <= 0;
		end else if (S_AXI_ARVALID && !arfifo_full) begin
			arid <= S_AXI_ARID;
			araddr <= S_AXI_ARADDR;
			arlen <= S_AXI_ARLEN;
			arsize <= S_AXI_ARSIZE;
			arburst <= S_AXI_ARBURST;
			arlock <= S_AXI_ARLOCK;
			arcache <= S_AXI_ARCACHE;
			arprot <= S_AXI_ARPROT;
			arqos <= S_AXI_ARQOS;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			rid <= 0;
			rdata <= 0;
			rresp <= 0;
			rlast <= 0;
		end else if (M_AXI_RVALID && !rfifo_full) begin
			rid <= M_AXI_RID;
			rdata <= M_AXI_RDATA;
			rresp <= M_AXI_RRESP;
			rlast <= M_AXI_RLAST;
		end
	end

	assign awvalid = !awfifo_empty;
	assign wvalid = !wfifo_empty;
	assign arvalid = !arfifo_empty;
	assign rvalid = !rfifo_empty;

	assign awready = !awfifo_full && M_AXI_AWREADY;
	assign wready = !wfifo_full && M_AXI_WREADY;
	assign arready = !arfifo_full && M_AXI_ARREADY;
	assign rready = !rfifo_full && S_AXI_RREADY;

	assign bid = M_AXI_BID;
	assign bresp = M_AXI_BRESP;
	assign bvalid = M_AXI_BVALID;
	assign bready = M_AXI_BVALID ? 1'b1 : 1'b0;

endmodule

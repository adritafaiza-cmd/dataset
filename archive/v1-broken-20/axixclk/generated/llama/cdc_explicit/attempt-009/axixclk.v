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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_ff;
	wire [7 : 0]			awlen_ff;
	wire [2 : 0]			awsize_ff;
	wire [1 : 0]			awburst_ff;
	wire				awlock_ff;
	wire [3 : 0]			awcache_ff;
	wire [2 : 0]			awprot_ff;
	wire [3 : 0]			awqos_ff;
	wire				awvalid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_ff;
	wire [7 : 0]			arlen_ff;
	wire [2 : 0]			arsize_ff;
	wire [1 : 0]			arburst_ff;
	wire				arlock_ff;
	wire [3 : 0]			arcache_ff;
	wire [2 : 0]			arprot_ff;
	wire [3 : 0]			arqos_ff;
	wire				arvalid_ff;

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;

	wire				bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bready_ff;

	wire				rvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rready_ff;

	wire				m_axi_awvalid_ff;
	wire				m_axi_wvalid_ff;
	wire				m_axi_arvalid_ff;
	wire				m_axi_bready_ff;
	wire				m_axi_rready_ff;

	wire				m_axi_awready_ff;
	wire				m_axi_wready_ff;
	wire				m_axi_arready_ff;
	wire				m_axi_bvalid_ff;
	wire				m_axi_rvalid_ff;

	wire				s_axi_awready_ff;
	wire				s_axi_wready_ff;
	wire				s_axi_arready_ff;
	wire				s_axi_bvalid_ff;
	wire				s_axi_rvalid_ff;

	wire				s_axi_bready_ff;
	wire				s_axi_rready_ff;

	wire [XCLOCK_FFS-1 : 0]	awvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	wvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	arvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	bvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	rvalid_sync;

	wire [XCLOCK_FFS-1 : 0]	awready_sync;
	wire [XCLOCK_FFS-1 : 0]	wready_sync;
	wire [XCLOCK_FFS-1 : 0]	arready_sync;
	wire [XCLOCK_FFS-1 : 0]	bready_sync;
	wire [XCLOCK_FFS-1 : 0]	rready_sync;

	wire [XCLOCK_FFS-1 : 0]	m_axi_awvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_wvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_arvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_bready_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_rready_sync;

	wire [XCLOCK_FFS-1 : 0]	m_axi_awready_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_wready_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_arready_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_bvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	m_axi_rvalid_sync;

	wire [XCLOCK_FFS-1 : 0]	s_axi_awready_sync;
	wire [XCLOCK_FFS-1 : 0]	s_axi_wready_sync;
	wire [XCLOCK_FFS-1 : 0]	s_axi_arready_sync;
	wire [XCLOCK_FFS-1 : 0]	s_axi_bvalid_sync;
	wire [XCLOCK_FFS-1 : 0]	s_axi_rvalid_sync;

	wire [XCLOCK_FFS-1 : 0]	s_axi_bready_sync;
	wire [XCLOCK_FFS-1 : 0]	s_axi_rready_sync;

	wire				awvalid_pulse;
	wire				wvalid_pulse;
	wire				arvalid_pulse;
	wire				bvalid_pulse;
	wire				rvalid_pulse;

	wire				awready_pulse;
	wire				wready_pulse;
	wire				arready_pulse;
	wire				bready_pulse;
	wire				rready_pulse;

	wire				m_axi_awvalid_pulse;
	wire				m_axi_wvalid_pulse;
	wire				m_axi_arvalid_pulse;
	wire				m_axi_bready_pulse;
	wire				m_axi_rready_pulse;

	wire				m_axi_awready_pulse;
	wire				m_axi_wready_pulse;
	wire				m_axi_arready_pulse;
	wire				m_axi_bvalid_pulse;
	wire				m_axi_rvalid_pulse;

	wire				s_axi_awready_pulse;
	wire				s_axi_wready_pulse;
	wire				s_axi_arready_pulse;
	wire				s_axi_bvalid_pulse;
	wire				s_axi_rvalid_pulse;

	wire				s_axi_bready_pulse;
	wire				s_axi_rready_pulse;

	wire [LGFIFO-1 : 0]	awfifo;
	wire [LGFIFO-1 : 0]	wfifo;
	wire [LGFIFO-1 : 0]	arfifo;
	wire [LGFIFO-1 : 0]	bfifo;
	wire [LGFIFO-1 : 0]	rfifo;

	wire				awfifo_empty;
	wire				wfifo_empty;
	wire				arfifo_empty;
	wire				bfifo_empty;
	wire				rfifo_empty;

	wire				awfifo_full;
	wire				wfifo_full;
	wire				arfifo_full;
	wire				bfifo_full;
	wire				rfifo_full;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_data;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_addr;
	wire [7 : 0]			awfifo_len;
	wire [2 : 0]			awfifo_size;
	wire [1 : 0]			awfifo_burst;
	wire				awfifo_lock;
	wire [3 : 0]			awfifo_cache;
	wire [2 : 0]			awfifo_prot;
	wire [3 : 0]			awfifo_qos;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wfifo_strb;
	wire				wfifo_last;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_data;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_addr;
	wire [7 : 0]			arfifo_len;
	wire [2 : 0]			arfifo_size;
	wire [1 : 0]			arfifo_burst;
	wire				arfifo_lock;
	wire [3 : 0]			arfifo_cache;
	wire [2 : 0]			arfifo_prot;
	wire [3 : 0]			arfifo_qos;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bfifo_data;
	wire [1 : 0]			bfifo_resp;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_data;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_data_payload;
	wire [1 : 0]			rfifo_resp;
	wire				rfifo_last;

	assign M_AXI_ARESETN = ~S_AXI_ARESETN;

	// AW channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awvalid_sync <= {XCLOCK_FFS{1'b0}};
			awready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			awvalid_sync <= {awvalid_sync[XCLOCK_FFS-2:0], S_AXI_AWVALID};
			awready_sync <= {awready_sync[XCLOCK_FFS-2:0], S_AXI_AWREADY};
		end
	end

	assign awvalid_pulse = awvalid_sync[XCLOCK_FFS-1] && ~awvalid_sync[XCLOCK_FFS-2];
	assign awready_pulse = awready_sync[XCLOCK_FFS-1] && ~awready_sync[XCLOCK_FFS-2];

	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			m_axi_awvalid_sync <= {XCLOCK_FFS{1'b0}};
			m_axi_awready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_axi_awvalid_sync <= {m_axi_awvalid_sync[XCLOCK_FFS-2:0], M_AXI_AWVALID};
			m_axi_awready_sync <= {m_axi_awready_sync[XCLOCK_FFS-2:0], M_AXI_AWREADY};
		end
	end

	assign m_axi_awvalid_pulse = m_axi_awvalid_sync[XCLOCK_FFS-1] && ~m_axi_awvalid_sync[XCLOCK_FFS-2];
	assign m_axi_awready_pulse = m_axi_awready_sync[XCLOCK_FFS-1] && ~m_axi_awready_sync[XCLOCK_FFS-2];

	// W channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wvalid_sync <= {XCLOCK_FFS{1'b0}};
			wready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			wvalid_sync <= {wvalid_sync[XCLOCK_FFS-2:0], S_AXI_WVALID};
			wready_sync <= {wready_sync[XCLOCK_FFS-2:0], S_AXI_WREADY};
		end
	end

	assign wvalid_pulse = wvalid_sync[XCLOCK_FFS-1] && ~wvalid_sync[XCLOCK_FFS-2];
	assign wready_pulse = wready_sync[XCLOCK_FFS-1] && ~wready_sync[XCLOCK_FFS-2];

	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			m_axi_wvalid_sync <= {XCLOCK_FFS{1'b0}};
			m_axi_wready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_axi_wvalid_sync <= {m_axi_wvalid_sync[XCLOCK_FFS-2:0], M_AXI_WVALID};
			m_axi_wready_sync <= {m_axi_wready_sync[XCLOCK_FFS-2:0], M_AXI_WREADY};
		end
	end

	assign m_axi_wvalid_pulse = m_axi_wvalid_sync[XCLOCK_FFS-1] && ~m_axi_wvalid_sync[XCLOCK_FFS-2];
	assign m_axi_wready_pulse = m_axi_wready_sync[XCLOCK_FFS-1] && ~m_axi_wready_sync[XCLOCK_FFS-2];

	// B channel
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			m_axi_bvalid_sync <= {XCLOCK_FFS{1'b0}};
			m_axi_bready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_axi_bvalid_sync <= {m_axi_bvalid_sync[XCLOCK_FFS-2:0], M_AXI_BVALID};
			m_axi_bready_sync <= {m_axi_bready_sync[XCLOCK_FFS-2:0], M_AXI_BREADY};
		end
	end

	assign m_axi_bvalid_pulse = m_axi_bvalid_sync[XCLOCK_FFS-1] && ~m_axi_bvalid_sync[XCLOCK_FFS-2];
	assign m_axi_bready_pulse = m_axi_bready_sync[XCLOCK_FFS-1] && ~m_axi_bready_sync[XCLOCK_FFS-2];

	// AR channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arvalid_sync <= {XCLOCK_FFS{1'b0}};
			arready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			arvalid_sync <= {arvalid_sync[XCLOCK_FFS-2:0], S_AXI_ARVALID};
			arready_sync <= {arready_sync[XCLOCK_FFS-2:0], S_AXI_ARREADY};
		end
	end

	assign arvalid_pulse = arvalid_sync[XCLOCK_FFS-1] && ~arvalid_sync[XCLOCK_FFS-2];
	assign arready_pulse = arready_sync[XCLOCK_FFS-1] && ~arready_sync[XCLOCK_FFS-2];

	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			m_axi_arvalid_sync <= {XCLOCK_FFS{1'b0}};
			m_axi_arready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_axi_arvalid_sync <= {m_axi_arvalid_sync[XCLOCK_FFS-2:0], M_AXI_ARVALID};
			m_axi_arready_sync <= {m_axi_arready_sync[XCLOCK_FFS-2:0], M_AXI_ARREADY};
		end
	end

	assign m_axi_arvalid_pulse = m_axi_arvalid_sync[XCLOCK_FFS-1] && ~m_axi_arvalid_sync[XCLOCK_FFS-2];
	assign m_axi_arready_pulse = m_axi_arready_sync[XCLOCK_FFS-1] && ~m_axi_arready_sync[XCLOCK_FFS-2];

	// R channel
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			m_axi_rvalid_sync <= {XCLOCK_FFS{1'b0}};
			m_axi_rready_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_axi_rvalid_sync <= {m_axi_rvalid_sync[XCLOCK_FFS-2:0], M_AXI_RVALID};
			m_axi_rready_sync <= {m_axi_rready_sync[XCLOCK_FFS-2:0], M_AXI_RREADY};
		end
	end

	assign m_axi_rvalid_pulse = m_axi_rvalid_sync[XCLOCK_FFS-1] && ~m_axi_rvalid_sync[XCLOCK_FFS-2];
	assign m_axi_rready_pulse = m_axi_rready_sync[XCLOCK_FFS-1] && ~m_axi_rready_sync[XCLOCK_FFS-2];

	// AW FIFO
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awfifo <= {LGFIFO{1'b0}};
		end else if (awvalid_pulse && ~awfifo_full) begin
			awfifo <= awfifo + 1'b1;
		end else if (~awfifo_empty && awready_pulse) begin
			awfifo <= awfifo - 1'b1;
		end
	end

	assign awfifo_empty = (awfifo == {LGFIFO{1'b0}});
	assign awfifo_full = (awfifo == {LGFIFO{1'b1}});

	// W FIFO
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wfifo <= {LGFIFO{1'b0}};
		end else if (wvalid_pulse && ~wfifo_full) begin
			wfifo <= wfifo + 1'b1;
		end else if (~wfifo_empty && wready_pulse) begin
			wfifo <= wfifo - 1'b1;
		end
	end

	assign wfifo_empty = (wfifo == {LGFIFO{1'b0}});
	assign wfifo_full = (wfifo == {LGFIFO{1'b1}});

	// AR FIFO
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arfifo <= {LGFIFO{1'b0}};
		end else if (arvalid_pulse && ~arfifo_full) begin
			arfifo <= arfifo + 1'b1;
		end else if (~arfifo_empty && arready_pulse) begin
			arfifo <= arfifo - 1'b1;
		end
	end

	assign arfifo_empty = (arfifo == {LGFIFO{1'b0}});
	assign arfifo_full = (arfifo == {LGFIFO{1'b1}});

	// B FIFO
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bfifo <= {LGFIFO{1'b0}};
		end else if (m_axi_bvalid_pulse && ~bfifo_full) begin
			bfifo <= bfifo + 1'b1;
		end else if (~bfifo_empty && m_axi_bready_pulse) begin
			bfifo <= bfifo - 1'b1;
		end
	end

	assign bfifo_empty = (bfifo == {LGFIFO{1'b0}});
	assign bfifo_full = (bfifo == {LGFIFO{1'b1}});

	// R FIFO
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			rfifo <= {LGFIFO{1'b0}};
		end else if (m_axi_rvalid_pulse && ~rfifo_full) begin
			rfifo <= rfifo + 1'b1;
		end else if (~rfifo_empty && m_axi_rready_pulse) begin
			rfifo <= rfifo - 1'b1;
		end
	end

	assign rfifo_empty = (rfifo == {LGFIFO{1'b0}});
	assign rfifo_full = (rfifo == {LGFIFO{1'b1}});

	// AW channel logic
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			awaddr_ff <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			awlen_ff <= {8{1'b0}};
			awsize_ff <= {3{1'b0}};
			awburst_ff <= {2{1'b0}};
			awlock_ff <= 1'b0;
			awcache_ff <= {4{1'b0}};
			awprot_ff <= {3{1'b0}};
			awqos_ff <= {4{1'b0}};
			awvalid_ff <= 1'b0;
		end else if (awvalid_pulse && ~awfifo_full) begin
			awid_ff <= S_AXI_AWID;
			awaddr_ff <= S_AXI_AWADDR;
			awlen_ff <= S_AXI_AWLEN;
			awsize_ff <= S_AXI_AWSIZE;
			awburst_ff <= S_AXI_AWBURST;
			awlock_ff <= S_AXI_AWLOCK;
			awcache_ff <= S_AXI_AWCACHE;
			awprot_ff <= S_AXI_AWPROT;
			awqos_ff <= S_AXI_AWQOS;
			awvalid_ff <= 1'b1;
		end else if (~awfifo_empty && awready_pulse) begin
			awvalid_ff <= 1'b0;
		end
	end

	assign S_AXI_AWREADY = ~awfifo_full && awready_pulse;

	// W channel logic
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wdata_ff <= {C_S_AXI_DATA_WIDTH{1'b0}};
			wstrb_ff <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			wlast_ff <= 1'b0;
			wvalid_ff <= 1'b0;
		end else if (wvalid_pulse && ~wfifo_full) begin
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= 1'b1;
		end else if (~wfifo_empty && wready_pulse) begin
			wvalid_ff <= 1'b0;
		end
	end

	assign S_AXI_WREADY = ~wfifo_full && wready_pulse;

	// B channel logic
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			bresp_ff <= {2{1'b0}};
			bvalid_ff <= 1'b0;
		end else if (m_axi_bvalid_pulse && ~bfifo_full) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= 1'b1;
		end else if (~bfifo_empty && m_axi_bready_pulse) begin
			bvalid_ff <= 1'b0;
		end
	end

	assign M_AXI_BREADY = ~bfifo_full && m_axi_bready_pulse;

	// AR channel logic
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			araddr_ff <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			arlen_ff <= {8{1'b0}};
			arsize_ff <= {3{1'b0}};
			arburst_ff <= {2{1'b0}};
			arlock_ff <= 1'b0;
			arcache_ff <= {4{1'b0}};
			arprot_ff <= {3{1'b0}};
			arqos_ff <= {4{1'b0}};
			arvalid_ff <= 1'b0;
		end else if (arvalid_pulse && ~arfifo_full) begin
			arid_ff <= S_AXI_ARID;
			araddr_ff <= S_AXI_ARADDR;
			arlen_ff <= S_AXI_ARLEN;
			arsize_ff <= S_AXI_ARSIZE;
			arburst_ff <= S_AXI_ARBURST;
			arlock_ff <= S_AXI_ARLOCK;
			arcache_ff <= S_AXI_ARCACHE;
			arprot_ff <= S_AXI_ARPROT;
			arqos_ff <= S_AXI_ARQOS;
			arvalid_ff <= 1'b1;
		end else if (~arfifo_empty && arready_pulse) begin
			arvalid_ff <= 1'b0;
		end
	end

	assign S_AXI_ARREADY = ~arfifo_full && arready_pulse;

	// R channel logic
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			rid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			rdata_ff <= {C_S_AXI_DATA_WIDTH{1'b0}};
			rresp_ff <= {2{1'b0}};
			rlast_ff <= 1'b0;
			rvalid_ff <= 1'b0;
		end else if (m_axi_rvalid_pulse && ~rfifo_full) begin
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= 1'b1;
		end else if (~rfifo_empty && m_axi_rready_pulse) begin
			rvalid_ff <= 1'b0;
		end
	end

	assign M_AXI_RREADY = ~rfifo_full && m_axi_rready_pulse;

	// Output logic
	assign M_AXI_AWID = awid_ff;
	assign M_AXI_AWADDR = awaddr_ff;
	assign M_AXI_AWLEN = awlen_ff;
	assign M_AXI_AWSIZE = awsize_ff;
	assign M_AXI_AWBURST = awburst_ff;
	assign M_AXI_AWLOCK = awlock_ff;
	assign M_AXI_AWCACHE = awcache_ff;
	assign M_AXI_AWPROT = awprot_ff;
	assign M_AXI_AWQOS = awqos_ff;
	assign M_AXI_AWVALID = awvalid_ff;
	assign M_AXI_WDATA = wdata_ff;
	assign M_AXI_WSTRB = wstrb_ff;
	assign M_AXI_WLAST = wlast_ff;
	assign M_AXI_WVALID = wvalid_ff;
	assign M_AXI_BREADY = bvalid_ff;
	assign M_AXI_ARID = arid_ff;
	assign M_AXI_ARADDR = araddr_ff;
	assign M_AXI_ARLEN = arlen_ff;
	assign M_AXI_ARSIZE = arsize_ff;
	assign M_AXI_ARBURST = arburst_ff;
	assign M_AXI_ARLOCK = arlock_ff;
	assign M_AXI_ARCACHE = arcache_ff;
	assign M_AXI_ARPROT = arprot_ff;
	assign M_AXI_ARQOS = arqos_ff;
	assign M_AXI_ARVALID = arvalid_ff;
	assign M_AXI_RREADY = rvalid_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

endmodule

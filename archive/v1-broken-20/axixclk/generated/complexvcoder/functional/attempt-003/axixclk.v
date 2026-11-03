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
	wire [C_S_AXI_ID_WIDTH-1 : 0] write_fifo_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] write_fifo_addr;
	wire [7 : 0] write_fifo_len;
	wire [2 : 0] write_fifo_size;
	wire [1 : 0] write_fifo_burst;
	wire write_fifo_lock;
	wire [3 : 0] write_fifo_cache;
	wire [2 : 0] write_fifo_prot;
	wire [3 : 0] write_fifo_qos;
	wire write_fifo_data_valid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] write_fifo_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] write_fifo_strb;
	wire write_fifo_last;
	wire write_fifo_ready;
	wire write_fifo_full;

	wire [C_S_AXI_ID_WIDTH-1 : 0] read_fifo_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] read_fifo_addr;
	wire [7 : 0] read_fifo_len;
	wire [2 : 0] read_fifo_size;
	wire [1 : 0] read_fifo_burst;
	wire read_fifo_lock;
	wire [3 : 0] read_fifo_cache;
	wire [2 : 0] read_fifo_prot;
	wire [3 : 0] read_fifo_qos;
	wire read_fifo_valid;
	wire read_fifo_ready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] read_fifo_data;
	wire [1 : 0] read_fifo_resp;

	// FIFO instances
	fifo #(
		.ID_WIDTH(C_S_AXI_ID_WIDTH),
		.ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.FF(CLOCK_FFS)
	) write_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.valid(write_fifo_data_valid),
		.data(write_fifo_data),
		.strb(write_fifo_strb),
		.last(write_fifo_last),
		.ready(write_fifo_ready),
		.full(write_fifo_full),
		.id(write_fifo_id),
		.addr(write_fifo_addr),
		.len(write_fifo_len),
		.size(write_fifo_size),
		.burst(write_fifo_burst),
		.lock(write_fifo_lock),
		.cache(write_fifo_cache),
		.prot(write_fifo_prot),
		.qos(write_fifo_qos)
	);

	fifo #(
		.ID_WIDTH(C_S_AXI_ID_WIDTH),
		.ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.FF(CLOCK_FFS)
	) read_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.valid(read_fifo_valid),
		.data(read_fifo_data),
		.ready(read_fifo_ready),
		.id(read_fifo_id),
		.addr(read_fifo_addr),
		.len(read_fifo_len),
		.size(read_fifo_size),
		.burst(read_fifo_burst),
		.lock(read_fifo_lock),
		.cache(read_fifo_cache),
		.prot(read_fifo_prot),
		.qos(read_fifo_qos)
	);

	// AXI4 master to slave
	assign S_AXI_AWREADY = write_fifo_ready;
	assign S_AXI_WREADY = write_fifo_ready;
	assign S_AXI_BID = write_fifo_id;
	assign S_AXI_BRESP = (write_fifo_resp == 2'b00) ? 2'b00 : 2'b11; // Assuming OKAY for now
	assign S_AXI_BVALID = write_fifo_valid;
	assign S_AXI_ARREADY = read_fifo_ready;
	assign S_AXI_RID = read_fifo_id;
	assign S_AXI_RDATA = read_fifo_data;
	assign S_AXI_RRESP = (read_fifo_resp == 2'b00) ? 2'b00 : 2'b11; // Assuming OKAY for now
	assign S_AXI_RLAST = read_fifo_last;
	assign S_AXI_RVALID = read_fifo_valid;

	// AXI4 slave to master
	assign M_AXI_ARESETN = S_AXI_ARESETN;
	assign M_AXI_AWID = write_fifo_id;
	assign M_AXI_AWADDR = write_fifo_addr;
	assign M_AXI_AWLEN = write_fifo_len;
	assign M_AXI_AWSIZE = write_fifo_size;
	assign M_AXI_AWBURST = write_fifo_burst;
	assign M_AXI_AWLOCK = write_fifo_lock;
	assign M_AXI_AWCACHE = write_fifo_cache;
	assign M_AXI_AWPROT = write_fifo_prot;
	assign M_AXI_AWQOS = write_fifo_qos;
	assign M_AXI_AWVALID = write_fifo_data_valid;
	assign M_AXI_WDATA = write_fifo_data;
	assign M_AXI_WSTRB = write_fifo_strb;
	assign M_AXI_WLAST = write_fifo_last;
	assign M_AXI_WVALID = write_fifo_data_valid;
	assign M_AXI_BREADY = write_fifo_ready;
	assign M_AXI_ARID = read_fifo_id;
	assign M_AXI_ARADDR = read_fifo_addr;
	assign M_AXI_ARLEN = read_fifo_len;
	assign M_AXI_ARSIZE = read_fifo_size;
	assign M_AXI_ARBURST = read_fifo_burst;
	assign M_AXI_ARLOCK = read_fifo_lock;
	assign M_AXI_ARCACHE = read_fifo_cache;
	assign M_AXI_ARPROT = read_fifo_prot;
	assign M_AXI_ARQOS = read_fifo_qos;
	assign M_AXI_ARVALID = read_fifo_valid;
	assign M_AXI_RREADY = read_fifo_ready;

endmodule

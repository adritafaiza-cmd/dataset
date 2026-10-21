```verilog
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

	// Clock domain crossing signals
	reg S_AXI_ACLK_CDC;
	reg M_AXI_ACLK_CDC;

	// Cross clock domain sampling
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			S_AXI_ACLK_CDC <= 1'b0;
		else
			S_AXI_ACLK_CDC <= M_AXI_ACLK;
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			M_AXI_ACLK_CDC <= 1'b0;
		else
			M_AXI_ACLK_CDC <= S_AXI_ACLK;
	end

	// Generate M_AXI_ARESETN based on S_AXI_ARESETN sampled in M domain
	// We need to ensure M domain reset is stable before asserting M_AXI_ARESETN low
	reg m_reset_n;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			m_reset_n <= 1'b0;
		else
			m_reset_n <= S_AXI_ARESETN;
	end
	assign M_AXI_ARESETN = m_reset_n;

	// Write Address Channel
	// AW Channel FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:XCLOCK_FFS-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:XCLOCK_FFS-1];
	reg [7:0] aw_fifo_len [0:XCLOCK_FFS-1];
	reg [2:0] aw_fifo_size [0:XCLOCK_FFS-1];
	reg [1:0] aw_fifo_burst [0:XCLOCK_FFS-1];
	reg aw_fifo_lock [0:XCLOCK_FFS-1];
	reg [3:0] aw_fifo_cache [0:XCLOCK_FFS-1];
	reg [2:0] aw_fifo_prot [0:XCLOCK_FFS-1];
	reg [3:0] aw_fifo_qos [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] aw_fifo_valid;
	reg [XCLOCK_FFS-1:0] aw_fifo_ready;
	reg [XCLOCK_FFS-1:0] aw_fifo_write;
	reg [XCLOCK_FFS-1:0] aw_fifo_read;
	reg [XCLOCK_FFS-1:0] aw_fifo_full;
	reg [XCLOCK_FFS-1:0] aw_fifo_empty;
	reg [XCLOCK_FFS-1:0] aw_fifo_count;

	// Write Data Channel
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:XCLOCK_FFS-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:XCLOCK_FFS-1];
	reg w_fifo_last [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] w_fifo_valid;
	reg [XCLOCK_FFS-1:0] w_fifo_ready;
	reg [XCLOCK_FFS-1:0] w_fifo_write;
	reg [XCLOCK_FFS-1:0] w_fifo_read;
	reg [XCLOCK_FFS-1:0] w_fifo_full;
	reg [XCLOCK_FFS-1:0] w_fifo_empty;
	reg [XCLOCK_FFS-1:0] w_fifo_count;

	// Write Response Channel
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] b_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] b_fifo_valid;
	reg [XCLOCK_FFS-1:0] b_fifo_ready;
	reg [XCLOCK_FFS-1:0] b_fifo_write;
	reg [XCLOCK_FFS-1:0] b_fifo_read;
	reg [XCLOCK_FFS-1:0] b_fifo_full;
	reg [XCLOCK_FFS-1:0] b_fifo_empty;
	reg [XCLOCK_FFS-1:0] b_fifo_count;

	// Read Address Channel
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:XCLOCK_FFS-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:XCLOCK_FFS-1];
	reg [7:0] ar_fifo_len [0:XCLOCK_FFS-1];
	reg [2:0] ar_fifo_size [0:XCLOCK_FFS-1];
	reg [1:0] ar_fifo_burst [0:XCLOCK_FFS-1];
	reg ar_fifo_lock [0:XCLOCK_FFS-1];
	reg [3:0] ar_fifo_cache [0:XCLOCK_FFS-1];
	reg [2:0] ar_fifo_prot [0:XCLOCK_FFS-1];
	reg [3:0] ar_fifo_qos [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] ar_fifo_valid;
	reg [XCLOCK_FFS-1:0] ar_fifo_ready;
	reg [XCLOCK_FFS-1:0] ar_fifo_write;
	reg [XCLOCK_FFS-1:0] ar_fifo_read;
	reg [XCLOCK_FFS-1:0] ar_fifo_full;
	reg [XCLOCK_FFS-1:0] ar_fifo_empty;
	reg [XCLOCK_FFS-1:0] ar_fifo_count;

	// Read Data Channel
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:XCLOCK_FFS-1];
	reg [1:0] r_fifo_resp [0:XCLOCK_FFS-1];
	reg r_fifo_last [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] r_fifo_valid;
	reg [XCLOCK_FFS-1:0] r_fifo_ready;
	reg [XCLOCK_FFS-1:0] r_fifo_write;
	reg [XCLOCK_FFS-1:0] r_fifo_read;
	reg [XCLOCK_FFS-1:0] r_fifo_full;
	reg [XCLOCK_FFS-1:0] r_fifo_empty;
	reg [XCLOCK_FFS-1:0] r_fifo_count;

	// Write Response FIFO (M to S)
	reg [C_S_AXI_ID_WIDTH-1:0] m_b_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b_fifo_count;

	// Read Response FIFO (M to S)
	reg [C_S_AXI_ID_WIDTH-1:0] m_r_fifo_id [0:XCLOCK_FFS-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] m_r_fifo_data [0:XCLOCK_FFS-1];
	reg [1:0] m_r_fifo_resp [0:XCLOCK_FFS-1];
	reg r_m_r_fifo_last [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_r_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_r_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_r_fifo_write;
	reg [XCLOCK_FFS-1:0] m_r_fifo_read;
	reg [XCLOCK_FFS-1:0] m_r_fifo_full;
	reg [XCLOCK_FFS-1:0] m_r_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_r_fifo_count;

	// Write Response FIFO (S to M)
	reg [C_S_AXI_ID_WIDTH-1:0] s_b_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b_fifo_count;

	// Read Response FIFO (S to M)
	reg [C_S_AXI_ID_WIDTH-1:0] s_r_fifo_id [0:XCLOCK_FFS-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] s_r_fifo_data [0:XCLOCK_FFS-1];
	reg [1:0] s_r_fifo_resp [0:XCLOCK_FFS-1];
	reg r_s_r_fifo_last [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_r_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_r_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_r_fifo_write;
	reg [XCLOCK_FFS-1:0] s_r_fifo_read;
	reg [XCLOCK_FFS-1:0] s_r_fifo_full;
	reg [XCLOCK_FFS-1:0] s_r_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_r_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b2s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b2s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b2s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b2m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b2m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b2m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b3s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b3s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b3s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b3m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b3m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b3m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b4s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b4s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b4s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b4m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b4m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b4m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b5s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b5s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b5s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b5m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b5m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b5m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b6s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b6s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b6s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b6m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b6m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b6m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b7s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b7s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b7s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b7m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b7m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b7m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b8s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b8s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b8s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b8m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b8m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b8m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b9s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b9s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b9s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b9m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b9m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b9m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b10s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b10s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b10s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b10m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b10m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b10m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b11s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b11s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b11s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b11m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b11m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b11m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b12s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m_b12s_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_valid;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_ready;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_write;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_read;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_full;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_empty;
	reg [XCLOCK_FFS-1:0] m_b12s_fifo_count;

	// Write Response FIFO (S to M) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] s_b12m_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] s_b12m_fifo_resp [0:XCLOCK_FFS-1];
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_valid;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_ready;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_write;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_read;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_full;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_empty;
	reg [XCLOCK_FFS-1:0] s_b12m_fifo_count;

	// Write Response FIFO (M to S) - for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] m_b13s_fifo_id [0:XCLOCK_FFS-1];
	reg [1:0] m
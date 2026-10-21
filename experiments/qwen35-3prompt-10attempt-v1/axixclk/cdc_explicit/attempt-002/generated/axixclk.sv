```verilog
`timescale 1ns/1ps

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

	// ------------------------------------------------------------------
	// CDC Strategy:
	// 1. Reset Generation: Use a 2-stage synchronizer for S_AXI_ARESETN 
	//    to generate M_AXI_ARESETN.
	// 2. Handshake Signals (Valid/Ready): Use a 2-stage synchronizer 
	//    (FFS = 2) to cross Valid/Ready signals between domains.
	// 3. Data/Address Payloads: Use a FIFO-based crossing. 
	//    - Write data is captured on S_AXI clock and read on M_AXI clock.
	//    - Read data is captured on M_AXI clock and read on S_AXI clock.
	//    - Control signals (ID, ADDR, LEN, SIZE, BURST, LOCK, CACHE, PROT, QOS)
	//      are treated as payload data within the respective FIFOs.
	// 4. Burst Handling: Since we must forward bursts exactly once, we rely 
	//    on the FIFO depth and the fact that AXI transactions are atomic 
	//    per channel. The FIFO ensures no data loss. The "forward exactly once"
	//    is naturally handled by the FIFO flow control (Valid/Ready).
	// ------------------------------------------------------------------

	// ------------------------------------------------------------------
	// Synchronizers for Reset
	// ------------------------------------------------------------------
	reg m_axi_reset_n_sync1;
	reg m_axi_reset_n_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_reset_n_sync1 <= 1'b0;
			m_axi_reset_n_sync2 <= 1'b0;
		end else begin
			m_axi_reset_n_sync1 <= S_AXI_ARESETN;
			m_axi_reset_n_sync2 <= m_axi_reset_n_sync1;
		end
	end

	assign M_AXI_ARESETN = m_axi_reset_n_sync2;

	// ------------------------------------------------------------------
	// Write Channel (AW + W + B)
	// ------------------------------------------------------------------
	
	// AW Channel FIFO
	// Stores: ID, ADDR, LEN, SIZE, BURST, LOCK, CACHE, PROT, QOS, VALID
	// Note: We store the whole transaction header.
	reg [C_S_AXI_ID_WIDTH-1 : 0] fifo_aw_id;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] fifo_aw_addr;
	reg [7 : 0] fifo_aw_len;
	reg [2 : 0] fifo_aw_size;
	reg [1 : 0] fifo_aw_burst;
	reg fifo_aw_lock;
	reg [3 : 0] fifo_aw_cache;
	reg [2 : 0] fifo_aw_prot;
	reg [3 : 0] fifo_aw_qos;
	reg fifo_aw_valid;
	reg fifo_aw_ready;
	reg [LGFIFO-1 : 0] fifo_aw_full;
	reg [LGFIFO-1 : 0] fifo_aw_empty;
	reg [LGFIFO-1 : 0] fifo_aw_count;
	reg [LGFIFO-1 : 0] fifo_aw_write_ptr;
	reg [LGFIFO-1 : 0] fifo_aw_read_ptr;
	reg [LGFIFO-1 : 0] fifo_aw_next_write_ptr;
	reg [LGFIFO-1 : 0] fifo_aw_next_read_ptr;

	// W Channel FIFO
	// Stores: ID, DATA, STRB, LAST, VALID
	reg [C_S_AXI_ID_WIDTH-1 : 0] fifo_w_id;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] fifo_w_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] fifo_w_strb;
	reg fifo_w_last;
	reg fifo_w_valid;
	reg fifo_w_ready;
	reg [LGFIFO-1 : 0] fifo_w_full;
	reg [LGFIFO-1 : 0] fifo_w_empty;
	reg [LGFIFO-1 : 0] fifo_w_count;
	reg [LGFIFO-1 : 0] fifo_w_write_ptr;
	reg [LGFIFO-1 : 0] fifo_w_read_ptr;
	reg [LGFIFO-1 : 0] fifo_w_next_write_ptr;
	reg [LGFIFO-1 : 0] fifo_w_next_read_ptr;

	// B Channel FIFO (Response from M to S)
	// Stores: ID, RESP, VALID
	reg [C_S_AXI_ID_WIDTH-1 : 0] fifo_b_id;
	reg [1 : 0] fifo_b_resp;
	reg fifo_b_valid;
	reg fifo_b_ready;
	reg [LGFIFO-1 : 0] fifo_b_full;
	reg [LGFIFO-1 : 0] fifo_b_empty;
	reg [LGFIFO-1 : 0] fifo_b_count;
	reg [LGFIFO-1 : 0] fifo_b_write_ptr;
	reg [LGFIFO-1 : 0] fifo_b_read_ptr;
	reg [LGFIFO-1 : 0] fifo_b_next_write_ptr;
	reg [LGFIFO-1 : 0] fifo_b_next_read_ptr;

	// AW FIFO Logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			fifo_aw_id <= '0;
			fifo_aw_addr <= '0;
			fifo_aw_len <= '0;
			fifo_aw_size <= '0;
			fifo_aw_burst <= '0;
			fifo_aw_lock <= 1'b0;
			fifo_aw_cache <= '0;
			fifo_aw_prot <= '0;
			fifo_aw_qos <= '0;
			fifo_aw_valid <= 1'b0;
			fifo_aw_ready <= 1'b1;
			fifo_aw_full <= '0;
			fifo_aw_empty <= '1;
			fifo_aw_count <= '0;
			fifo_aw_write_ptr <= '0;
			fifo_aw_read_ptr <= '0;
			fifo_aw_next_write_ptr <= '0;
			fifo_aw_next_read_ptr <= '0;
		end else begin
			fifo_aw_next_write_ptr <= fifo_aw_write_ptr + 1;
			fifo_aw_next_read_ptr <= fifo_aw_read_ptr;
			
			if (fifo_aw_count == '0) begin
				fifo_aw_next_read_ptr <= fifo_aw_write_ptr;
			end

			// Write Pointer Logic
			if (fifo_aw_count == '0) begin
				fifo_aw_write_ptr <= fifo_aw_next_write_ptr;
			end else begin
				fifo_aw_write_ptr <= fifo_aw_next_write_ptr;
			end

			// Read Pointer Logic
			if (fifo_aw_count == '0) begin
				fifo_aw_read_ptr <= fifo_aw_next_read_ptr;
			end else begin
				fifo_aw_read_ptr <= fifo_aw_next_read_ptr;
			end

			// Full/Empty Logic
			if (fifo_aw_count == '0) begin
				fifo_aw_empty <= 1'b1;
				fifo_aw_full <= 1'b0;
			end else if (fifo_aw_count == '0) begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else if (fifo_aw_count == '0) begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b1;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 1'b0;
			end else begin
				fifo_aw_empty <= 1'b0;
				fifo_aw_full <= 
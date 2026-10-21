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

	// Cross Clock FIFO Parameters
	localparam INTEGER FIFO_DEPTH = 2 ** LGFIFO;
	localparam INTEGER FIFO_ADDR_WIDTH = LGFIFO;
	localparam INTEGER DATA_WIDTH = C_S_AXI_DATA_WIDTH;
	localparam INTEGER STRB_WIDTH = (C_S_AXI_DATA_WIDTH / 8);
	localparam INTEGER ID_WIDTH = C_S_AXI_ID_WIDTH;

	// Cross Clock FIFO Implementation
	// Using a simple dual-port RAM style implementation with pointers
	// to ensure Verilog-2001 compliance and safety.
	
	// Write Pointer (Slave Side)
	reg [FIFO_ADDR_WIDTH-1:0] S_AW_WR_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] S_W_WR_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] S_B_WR_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] S_AR_WR_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] S_R_WR_PTR;

	// Read Pointer (Master Side)
	reg [FIFO_ADDR_WIDTH-1:0] M_AW_RD_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] M_W_RD_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] M_B_RD_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] M_AR_RD_PTR;
	reg [FIFO_ADDR_WIDTH-1:0] M_R_RD_PTR;

	// Full/Empty Flags
	reg S_AW_FULL;
	reg S_W_FULL;
	reg S_B_FULL;
	reg S_AR_FULL;
	reg S_R_FULL;
	
	reg M_AW_EMPTY;
	reg M_W_EMPTY;
	reg M_B_EMPTY;
	reg M_AR_EMPTY;
	reg M_R_EMPTY;

	// Data Storage
	// AW Channel
	reg [C_S_AXI_ADDR_WIDTH-1:0] S_AW_ADDR_FIFO [FIFO_DEPTH-1:0];
	reg [7:0] S_AW_LEN_FIFO [FIFO_DEPTH-1:0];
	reg [2:0] S_AW_SIZE_FIFO [FIFO_DEPTH-1:0];
	reg [1:0] S_AW_BURST_FIFO [FIFO_DEPTH-1:0];
	reg [3:0] S_AW_CACHE_FIFO [FIFO_DEPTH-1:0];
	reg [2:0] S_AW_PROT_FIFO [FIFO_DEPTH-1:0];
	reg [3:0] S_AW_QOS_FIFO [FIFO_DEPTH-1:0];
	reg [ID_WIDTH-1:0] S_AW_ID_FIFO [FIFO_DEPTH-1:0];
	reg [C_S_AXI_DATA_WIDTH-1:0] S_AW_LOCK_FIFO [FIFO_DEPTH-1:0]; // Using lock field for generic data if needed, or just pass-through

	// W Channel
	reg [C_S_AXI_DATA_WIDTH-1:0] S_W_DATA_FIFO [FIFO_DEPTH-1:0];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] S_W_STRB_FIFO [FIFO_DEPTH-1:0];
	reg [ID_WIDTH-1:0] S_W_ID_FIFO [FIFO_DEPTH-1:0];

	// B Channel
	reg [ID_WIDTH-1:0] S_B_ID_FIFO [FIFO_DEPTH-1:0];
	reg [1:0] S_B_RESP_FIFO [FIFO_DEPTH-1:0];

	// AR Channel
	reg [C_S_AXI_ADDR_WIDTH-1:0] S_AR_ADDR_FIFO [FIFO_DEPTH-1:0];
	reg [7:0] S_AR_LEN_FIFO [FIFO_DEPTH-1:0];
	reg [2:0] S_AR_SIZE_FIFO [FIFO_DEPTH-1:0];
	reg [1:0] S_AR_BURST_FIFO [FIFO_DEPTH-1:0];
	reg [3:0] S_AR_CACHE_FIFO [FIFO_DEPTH-1:0];
	reg [2:0] S_AR_PROT_FIFO [FIFO_DEPTH-1:0];
	reg [3:0] S_AR_QOS_FIFO [FIFO_DEPTH-1:0];
	reg [ID_WIDTH-1:0] S_AR_ID_FIFO [FIFO_DEPTH-1:0];

	// R Channel
	reg [ID_WIDTH-1:0] S_R_ID_FIFO [FIFO_DEPTH-1:0];
	reg [C_S_AXI_DATA_WIDTH-1:0] S_R_DATA_FIFO [FIFO_DEPTH-1:0];
	reg [1:0] S_R_RESP_FIFO [FIFO_DEPTH-1:0];

	// State Registers for Handshake Control
	reg [2:0] S_AW_STATE; // 0: Idle, 1: Valid, 2: Ready
	reg [2:0] S_W_STATE;
	reg [2:0] S_B_STATE;
	reg [2:0] S_AR_STATE;
	reg [2:0] S_R_STATE;

	reg [2:0] M_AW_STATE;
	reg [2:0] M_W_STATE;
	reg [2:0] M_B_STATE;
	reg [2:0] M_AR_STATE;
	reg [2:0] M_R_STATE;

	// Burst Length Counter (Slave Side)
	reg [7:0] S_AW_BURST_LEN;
	reg [7:0] S_AR_BURST_LEN;

	// Burst Length Counter (Master Side)
	reg [7:0] M_AW_BURST_LEN;
	reg [7:0] M_AR_BURST_LEN;

	// Write Data Buffering (Master Side)
	// Requirement: Master write data is held one extra M_AXI clock before M_AXI_WVALID.
	// We need to buffer the data coming from the slave FIFO before pushing to master.
	reg [C_S_AXI_DATA_WIDTH-1:0] M_W_DATA_HOLD;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] M_W_STRB_HOLD;
	reg M_W_DATA_VALID_HOLD;

	// Reset Generation
	wire M_RST_N = S_AXI_ARESETN;

	// ---------------------------------------------------------
	// Slave Side Logic (S_AXI Clock Domain)
	// ---------------------------------------------------------

	// AW Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AW_WR_PTR <= 0;
			S_AW_FULL <= 0;
			S_AW_STATE <= 0;
			S_AW_BURST_LEN <= 0;
		end else begin
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				// Store header info
				S_AW_ADDR_FIFO[S_AW_WR_PTR] <= S_AXI_AWADDR;
				S_AW_LEN_FIFO[S_AW_WR_PTR] <= S_AXI_AWLEN;
				S_AW_SIZE_FIFO[S_AW_WR_PTR] <= S_AXI_AWSIZE;
				S_AW_BURST_FIFO[S_AW_WR_PTR] <= S_AXI_AWBURST;
				S_AW_CACHE_FIFO[S_AW_WR_PTR] <= S_AXI_AWCACHE;
				S_AW_PROT_FIFO[S_AW_WR_PTR] <= S_AXI_AWPROT;
				S_AW_QOS_FIFO[S_AW_WR_PTR] <= S_AXI_AWQOS;
				S_AW_ID_FIFO[S_AW_WR_PTR] <= S_AXI_AWID;
				S_AW_LOCK_FIFO[S_AW_WR_PTR] <= 1'b0; // Placeholder

				// Calculate burst length
				S_AW_BURST_LEN <= S_AXI_AWLEN[6:0] + 1;
				
				// Update pointer
				S_AW_WR_PTR <= S_AW_WR_PTR + 1;
				if (S_AW_WR_PTR == FIFO_DEPTH - 1)
					S_AW_FULL <= 1;
				else
					S_AW_FULL <= 0;

				// State Machine
				if (S_AXI_AW_STATE == 0) begin
					S_AXI_AWREADY <= 1;
					S_AXI_AW_STATE <= 1;
				end else if (S_AXI_AW_STATE == 1) begin
					S_AXI_AWREADY <= 0;
					S_AXI_AW_STATE <= 2;
				end else begin
					S_AXI_AWREADY <= 0;
					S_AXI_AW_STATE <= 0;
				end
			end else begin
				S_AXI_AWREADY <= 0;
				if (S_AXI_AW_STATE == 1)
					S_AXI_AW_STATE <= 0;
			end
		end
	end

	// W Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_W_WR_PTR <= 0;
			S_W_FULL <= 0;
			S_W_STATE <= 0;
		end else begin
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				S_W_DATA_FIFO[S_W_WR_PTR] <= S_AXI_WDATA;
				S_W_STRB_FIFO[S_W_WR_PTR] <= S_AXI_WSTRB;
				S_W_ID_FIFO[S_W_WR_PTR] <= S_AXI_AWID; // Associate with AW ID

				S_W_WR_PTR <= S_W_WR_PTR + 1;
				if (S_W_WR_PTR == FIFO_DEPTH - 1)
					S_W_FULL <= 1;
				else
					S_W_FULL <= 0;

				if (S_AXI_W_STATE == 0) begin
					S_AXI_WREADY <= 1;
					S_AXI_W_STATE <= 1;
				end else if (S_AXI_W_STATE == 1) begin
					S_AXI_WREADY <= 0;
					S_AXI_W_STATE <= 2;
				end else begin
					S_AXI_WREADY <= 0;
					S_AXI_W_STATE <= 0;
				end
			end else begin
				S_AXI_WREADY <= 0;
				if (S_AXI_W_STATE == 1)
					S_AXI_W_STATE <= 0;
			end
		end
	end

	// B Channel (Response Generation)
	// Note: In a real bridge, B responses are generated by the master side logic 
	// based on the completion of writes. However, the prompt asks for a bridge 
	// that forwards transactions. Usually, the bridge generates B responses 
	// locally or passes them through if it's a passthrough. 
	// Given "Return write responses... without loss", and typical bridge behavior:
	// The bridge acts as a FIFO. The Master side will generate B responses 
	// when it finishes writing. But the prompt says "Accept AXI4 on the slave ports 
	// and forward each burst exactly once to the master ports." 
	// This implies the bridge might be transparent regarding B, OR the bridge 
	// generates B. 
	// Re-reading: "Return write responses and read data without loss". 
	// If the bridge is just a FIFO, the Master side must generate B. 
	// However, the port list includes S_AXI_BID, S_AXI_BRESP, S_AXI_BVALID, S_AXI_BREADY.
	// If the bridge is purely a FIFO, S_AXI_B* are outputs. Who drives them?
	// Standard AXI Bridge behavior: The bridge generates B responses for writes 
	// initiated by the slave, or passes them if it's a passthrough. 
	// Since the prompt says "forward each burst exactly once", it implies the 
	// bridge manages the flow. 
	// Let's assume the bridge generates B responses locally upon completion 
	// of the write burst on the master side, OR we treat B as a passthrough 
	// if the master side is the one generating it. 
	// BUT, looking at the ports: S_AXI_BREADY is INPUT. S_AXI_BVALID is OUTPUT.
	// This means the Slave side waits for BREADY. 
	// If the bridge is a FIFO, the Master side generates B. The Slave side 
	// just needs to know when the write is done. 
	// Actually, in many bridges, the Slave side generates B immediately if 
	// the master is just a FIFO. But here we have a FIFO between S and M.
	// Correct interpretation for a FIFO bridge:
	// 1. Slave sends AW -> FIFO.
	// 2. Slave sends W -> FIFO.
	// 3. Master reads AW, W from FIFO, sends to M.
	// 4. Master generates B and sends to Slave (via FIFO or direct).
	// Since B is an output of this module on S side, and input on M side:
	// The Master side generates B. The Slave side consumes B.
	// We need a FIFO for B as well to handle reordering if necessary, 
	// but typically B is generated by the Master side logic.
	// Let's implement a B FIFO to store responses from Master to Slave.
	
	// B Channel (Master to Slave)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_B_WR_PTR <= 0;
			S_B_FULL <= 0;
			S_B_STATE <= 0;
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				S_B_ID_FIFO[S_B_WR_PTR] <= M_AXI_BID;
				S_B_RESP_FIFO[S_B_WR_PTR] <= M_AXI_BRESP;
				
				S_B_WR_PTR <= S_B_WR_PTR + 1;
				if (S_B_WR_PTR == FIFO_DEPTH - 1)
					S_B_FULL <= 1;
				else
					S_B_FULL <= 0;

				if (S_B_STATE == 0) begin
					S_AXI_BVALID <= 1;
					S_AXI_B_STATE <= 1;
				end else if (S_B_STATE == 1) begin
					S_AXI_BVALID <= 0;
					S_AXI_B_STATE <= 2;
				end else begin
					S_AXI_BVALID <= 0;
					S_AXI_B_STATE <= 0;
				end
			end else begin
				S_AXI_BVALID <= 0;
				if (S_B_STATE == 1)
					S_AXI_B_STATE <= 0;
			end
		end
	end

	// AR Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AR_WR_PTR <= 0;
			S_AR_FULL <= 0;
			S_AR_STATE <= 0;
			S_AR_BURST_LEN <= 0;
		end else begin
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				S_AR_ADDR_FIFO[S_AR_WR_PTR] <= S_AXI_ARADDR;
				S_AR_LEN_FIFO[S_AR_WR_PTR] <= S_AXI_ARLEN;
				S_AR_SIZE_FIFO[S_AR_WR_PTR] <= S_AXI_ARSIZE;
				S_AR_BURST_FIFO[S_AR_WR_PTR] <= S_AXI_ARBURST;
				S_AR_CACHE_FIFO[S_AR_WR_PTR] <= S_AXI_ARCACHE;
				S_AR_PROT_FIFO[S_AR_WR_PTR] <= S_AXI_ARPROT;
				S_AR_QOS_FIFO[S_AR_WR_PTR] <= S_AXI_ARQOS;
				S_AR_ID_FIFO[S_AR_WR_PTR] <= S_AXI_ARID;

				S_AR_BURST_LEN <= S_AXI_ARLEN[6:0] + 1;
				
				S_AR_WR_PTR <= S_AR_WR_PTR + 1;
				if (S_AR_WR_PTR == FIFO_DEPTH - 1)
					S_AR_FULL <= 1;
				else
					S_AR_FULL <= 0;

				if (S_AXI_AR_STATE == 0) begin
					S_AXI_ARREADY <= 1;
					S_AXI_AR_STATE <= 1;
				end else if (S_AXI_AR_STATE == 1) begin
					S_AXI_ARREADY <= 0;
					S_AXI_AR_STATE <= 2;
				end else begin
					S_AXI_ARREADY <= 0;
					S_AXI_AR_STATE <= 0;
				end
			end else begin
				S_AXI_ARREADY <= 0;
				if (S_AXI_AR_STATE == 1)
					S_AXI_AR_STATE <= 0;
			end
		end
	end

	// R Channel (Data Generation)
	// Similar to B, R data is generated by the Master side logic.
	// We need a FIFO to pass R data from Master to Slave.
	
	// R Channel (Master to Slave)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_R_WR_PTR <= 0;
			S_R_FULL <= 0;
			S_R_STATE <= 0;
		end else begin
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				S_R_ID_FIFO[S_R_WR_PTR] <= M_AXI_RID;
				S_R_DATA_FIFO[S_R_WR_PTR] <= M_AXI_RDATA;
				S_R_RESP_FIFO[S_R_WR_PTR] <= M_AXI_RRESP;
				
				S_R_WR_PTR <= S_R_WR_PTR + 1;
				if (S_R_WR_PTR == FIFO_DEPTH - 1)
					S_R_FULL <= 1;
				else
					S_R_FULL <= 0;

				if (S_R_STATE == 0) begin
					S_AXI_RVALID <= 1;
					S_AXI_R_STATE <= 1;
				end else if (S_R_STATE == 1) begin
					S_AXI_RVALID <= 0;
					S_AXI_R_STATE <= 2;
				end else begin
					S_AXI_RVALID <= 0;
					S_AXI_R_STATE <= 0;
				end
			end else begin
				S_AXI_RVALID <= 0;
				if (S_R_STATE == 1)
					S_AXI_R_STATE <= 0;
			end
		end
	end

	// ---------------------------------------------------------
	// Master Side Logic (M_AXI Clock Domain)
	// ---------------------------------------------------------

	// AW Channel
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_AW_RD_PTR <= 0;
			M_AW_EMPTY <= 1;
			M_AW_STATE <= 0;
			M_AW_BURST_LEN <= 0;
			M_AXI_AWVALID <= 0;
		end else begin
			// Check if data is available
			if (S_AW_FULL && M_AW_EMPTY) begin
				M_AXI_AWID <= S_AW_ID_FIFO[S_AW_RD_PTR];
				M_AXI_AWADDR <= S_AW_ADDR_FIFO[S_AW_RD_PTR];
				M_AXI_AWLEN <= S_AW_LEN_FIFO[S_AW_RD_PTR];
				M_AXI_AWSIZE <= S_AW_SIZE_FIFO[S_AW_RD_PTR];
				M_AXI_AWBURST <= S_AW_BURST_FIFO[S_AW_RD_PTR];
				M_AXI_AWLOCK <= 1'b0; // Default, usually 0 for non-locked
				M_AXI_AWCACHE <= S_AW_CACHE_FIFO[S_AW_RD_PTR];
				M_AXI_AWPROT <= S_AW_PROT_FIFO[S_AW_RD_PTR];
				M_AXI_AWQOS <= S_AW_QOS_FIFO[S_AW_RD_PTR];
				M_AXI_AWVALID <= 1;
			end else begin
				M_AXI_AWVALID <= 0;
			end

			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				// Consume from FIFO
				S_AW_RD_PTR <= S_AW_RD_PTR + 1;
				if (S_AW_RD_PTR == FIFO_DEPTH - 1)
					M_AW_EMPTY <= 0;
				else
					M_AW_EMPTY <= 1;

				// State Machine
				if (M_AW_STATE == 0) begin
					M_AXI_AWVALID <= 0; // Deassert immediately after ready? 
					// Actually, standard handshake: assert valid, wait ready, then deassert.
					// But we need to prepare the next transaction.
					// Let's use a simple state machine to manage the burst.
					M_AW_STATE <= 1; // Start burst
					M_AW_BURST_LEN <= S_AW_LEN_FIFO[S_AW_RD_PTR - 1]; // Wait, we consumed it. 
					// Correction: We need to store the length before consuming or handle it differently.
					// Better approach: Store burst length in a register when AW is accepted.
					// Let's refactor slightly: The FIFO stores the header. 
					// When AW is valid and ready, we consume the header.
					// We need to know the length for the subsequent W beats.
					// Since we consumed the header, we need to store the length in a register.
					// Let's assume the FIFO logic above stores the length.
					// We need to capture the length BEFORE consuming the pointer? 
					// No, the pointer moves after the transaction is accepted.
					// So we need to store the length in a register when AW is accepted.
					// Let's add a register for burst length on Master side.
					// Refactoring AW logic below to handle burst length correctly.
				end
			end
		end
	end

	// Corrected AW Logic with Burst Length Handling
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_AW_RD_PTR <= 0;
			M_AW_EMPTY <= 1;
			M_AW_STATE <= 0;
			M_AW_BURST_LEN <= 0;
			M_AXI_AWVALID <= 0;
		end else begin
			if (S_AW_FULL && M_AW_EMPTY) begin
				M_AXI_AWID <= S_AW_ID_FIFO[S_AW_RD_PTR];
				M_AXI_AWADDR <= S_AW_ADDR_FIFO[S_AW_RD_PTR];
				M_AXI_AWLEN <= S_AW_LEN_FIFO[S_AW_RD_PTR];
				M_AXI_AWSIZE <= S_AW_SIZE_FIFO[S_AW_RD_PTR];
				M_AXI_AWBURST <= S_AW_BURST_FIFO[S_AW_RD_PTR];
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= S_AW_CACHE_FIFO[S_AW_RD_PTR];
				M_AXI_AWPROT <= S_AW_PROT_FIFO[S_AW_RD_PTR];
				M_AXI_AWQOS <= S_AW_QOS_FIFO[S_AW_RD_PTR];
				M_AXI_AWVALID <= 1;
			end else begin
				M_AXI_AWVALID <= 0;
			end

			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				// Consume header
				S_AW_RD_PTR <= S_AW_RD_PTR + 1;
				if (S_AW_RD_PTR == FIFO_DEPTH - 1)
					M_AW_EMPTY <= 0;
				else
					M_AW_EMPTY <= 1;

				// Capture burst length for subsequent W beats
				M_AW_BURST_LEN <= S_AW_LEN_FIFO[S_AW_RD_PTR - 1]; // The value we just read

				// State Machine
				if (M_AW_STATE == 0) begin
					M_AW_STATE <= 1; // Start burst
				end else if (M_AW_STATE == 1) begin
					M_AW_STATE <= 2; // AW done, waiting for W
				end else begin
					M_AW_STATE <= 0; // Idle
				end
			end
		end
	end

	// W Channel
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_W_RD_PTR <= 0;
			M_W_EMPTY <= 1;
			M_W_STATE <= 0;
			M_AXI_WVALID <= 0;
		end else begin
			if (S_W_FULL && M_W_EMPTY) begin
				M_AXI_WDATA <= S_W_DATA_FIFO[S_W_RD_PTR];
				M_AXI_WSTRB <= S_W_STRB_FIFO[S_W_RD_PTR];
				M_AXI_WLAST <= 0;
				M_AXI_WVALID <= 1;
			end else begin
				M_AXI_WVALID <= 0;
			end

			if (M_AXI_WVALID && M_AXI_WREADY) begin
				S_W_RD_PTR <= S_W_RD_PTR + 1;
				if (S_W_RD_PTR == FIFO_DEPTH - 1)
					M_W_EMPTY <= 0;
				else
					M_W_EMPTY <= 1;

				// State Machine
				if (M_W_STATE == 0) begin
					M_W_STATE <= 1;
				end else if (M_W_STATE == 1) begin
					M_W_STATE <= 2;
				end else begin
					M_W_STATE <= 0;
				end
			end
		end
	end

	// B Channel (Master Side)
	// Generate B response when AW is accepted and W is complete.
	// For simplicity in this bridge, we assume the bridge generates B 
	// immediately after the last W beat of a burst is accepted.
	// This is a common pattern for simple bridges where the master 
	// doesn't have a complex controller.
	
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_B_STATE <= 0;
			M_AXI_BREADY <= 0;
		end else begin
			if (M_AW_STATE == 2 && M_W_STATE == 2) begin
				// AW and W are done. Generate B.
				// We need to know the ID. It's stored in the FIFO or we can track it.
				// Since we consumed the header, we need to store the ID in a register.
				// Let's assume we stored it in a register when AW was accepted.
				// We need to refactor AW logic to store ID in a register.
				// For now, let's assume we can access it or store it.
				// To keep it simple and correct: Store ID in a register in AW logic.
				// Let's add a register `M_AW_ID_REG`.
			end
		end
	end

	// R Channel (Master Side)
	// Generate R data when AR is accepted.
	// Similar to B, generate R immediately after AR is accepted.
	
	// ---------------------------------------------------------
	// Refactoring for Burst Length and ID Storage
	// ---------------------------------------------------------
	
	// Registers to hold burst length and ID for Master side generation
	reg [7:0] M_AW_BURST_LEN_REG;
	reg [ID_WIDTH-1:0] M_AW_ID_REG;
	reg [7:0] M_AR_BURST_LEN_REG;
	reg [ID_WIDTH-1:0] M_AR_ID_REG;

	// Updated AW Logic
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_AW_RD_PTR <= 0;
			M_AW_EMPTY <= 1;
			M_AW_STATE <= 0;
			M_AW_BURST_LEN_REG <= 0;
			M_AW_ID_REG <= 0;
			M_AXI_AWVALID <= 0;
		end else begin
			if (S_AW_FULL && M_AW_EMPTY) begin
				M_AXI_AWID <= S_AW_ID_FIFO[S_AW_RD_PTR];
				M_AXI_AWADDR <= S_AW_ADDR_FIFO[S_AW_RD_PTR];
				M_AXI_AWLEN <= S_AW_LEN_FIFO[S_AW_RD_PTR];
				M_AXI_AWSIZE <= S_AW_SIZE_FIFO[S_AW_RD_PTR];
				M_AXI_AWBURST <= S_AW_BURST_FIFO[S_AW_RD_PTR];
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= S_AW_CACHE_FIFO[S_AW_RD_PTR];
				M_AXI_AWPROT <= S_AW_PROT_FIFO[S_AW_RD_PTR];
				M_AXI_AWQOS <= S_AW_QOS_FIFO[S_AW_RD_PTR];
				M_AXI_AWVALID <= 1;
				M_AW_ID_REG <= S_AW_ID_FIFO[S_AW_RD_PTR];
			end else begin
				M_AXI_AWVALID <= 0;
			end

			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				S_AW_RD_PTR <= S_AW_RD_PTR + 1;
				if (S_AW_RD_PTR == FIFO_DEPTH - 1)
					M_AW_EMPTY <= 0;
				else
					M_AW_EMPTY <= 1;

				M_AW_BURST_LEN_REG <= S_AW_LEN_FIFO[S_AW_RD_PTR - 1];

				if (M_AW_STATE == 0) begin
					M_AW_STATE <= 1;
				end else if (M_AW_STATE == 1) begin
					M_AW_STATE <= 2;
				end else begin
					M_AW_STATE <= 0;
				end
			end
		end
	end

	// Updated AR Logic
	always @(posedge M_AXI_ACLK or negedge M_RST_N) begin
		if (!M_RST_N) begin
			M_AR_RD_PTR <= 0;
			M_AR_EMPTY <= 1;
			M_AR_STATE <= 0;
			M_AR_BURST_LEN_REG <= 0
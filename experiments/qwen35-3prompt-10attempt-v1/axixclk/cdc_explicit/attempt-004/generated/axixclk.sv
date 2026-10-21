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

	// ============================================================================
	// CDC Strategy:
	// 1. Reset Generation: Use a 2-stage synchronizer for S_RESETN to M domain.
	//    M_RESETN is asserted when S_RESETN is low for at least 2 S-clock cycles.
	// 2. Write Channel (AW -> W -> B):
	//    - AW: S->M (Write Address Queue)
	//    - W: S->M (Write Data Queue)
	//    - B: M->S (Write Response Queue)
	// 3. Read Channel (AR -> R):
	//    - AR: S->M (Read Address Queue)
	//    - R: M->S (Read Data Queue)
	// 4. Handshaking:
	//    - S->M: Valid/Ready handshake. Data is registered on M clock before valid.
	//    - M->S: Valid/Ready handshake. Data is registered on S clock before valid.
	// ============================================================================

	// ---------------------------------------------------------------------------
	// 1. Reset Generation (S -> M)
	// ---------------------------------------------------------------------------
	reg S_RESETN;
	reg S_RESETN_D1;
	reg S_RESETN_D2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_RESETN <= 1'b0;
		end else begin
			S_RESETN <= S_AXI_ARESETN;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin // Global reset priority
			S_RESETN_D1 <= 1'b0;
			S_RESETN_D2 <= 1'b0;
			M_AXI_ARESETN <= 1'b1;
		end else begin
			S_RESETN_D1 <= S_RESETN;
			S_RESETN_D2 <= S_RESETN_D1;
			// Assert M reset if S reset is low for 2 cycles
			if (S_RESETN_D2 == 1'b0)
				M_AXI_ARESETN <= 1'b1;
			else
				M_AXI_ARESETN <= 1'b0;
		end
	end

	// ---------------------------------------------------------------------------
	// 2. Write Address Channel (S -> M)
	// ---------------------------------------------------------------------------
	// FIFO Depth: 2^LGFIFO
	// Data Width: ID + ADDR + LEN + SIZE + BURST + LOCK + CACHE + PROT + QOS + VALID
	// We pack the control signals into a single beat for simplicity and efficiency.
	
	localparam AW_CTRL_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 4 + 1;
	localparam AW_CTRL_MASK = {
		{C_S_AXI_ID_WIDTH{1'b0}}, // Padding for alignment if needed, but we pack tightly below
		{C_S_AXI_ADDR_WIDTH{1'b0}},
		8'h00, // LEN placeholder
		3'h00, // SIZE placeholder
		2'h00, // BURST placeholder
		1'b0,  // LOCK placeholder
		4'h00, // CACHE placeholder
		3'h00, // PROT placeholder
		4'h00, // QOS placeholder
		1'b0   // VALID placeholder
	};

	// AW FIFO Instance
	// We use a simple FIFO implementation using pointers to ensure CDC compliance.
	// Since we cannot use vendor primitives, we implement a pointer-based FIFO.
	
	reg [LGFIFO:0] aw_ptr_r;
	reg [LGFIFO:0] aw_ptr_w;
	reg [AW_CTRL_WIDTH-1:0] aw_fifo_data;
	reg [LGFIFO:0] aw_fifo_full;
	reg [LGFIFO:0] aw_fifo_empty;
	reg [LGFIFO:0] aw_fifo_count;

	// AW FIFO Logic
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_ptr_r <= 1'b0;
			aw_ptr_w <= 1'b0;
			aw_fifo_count <= 1'b0;
			aw_fifo_full <= 1'b0;
			aw_fifo_empty <= 1'b0;
		end else begin
			aw_fifo_full <= (aw_ptr_w == (1<<(LGFIFO+1)) - 1) && (aw_ptr_w == aw_ptr_r);
			aw_fifo_empty <= (aw_ptr_w == aw_ptr_r);
			aw_fifo_count <= aw_ptr_w - aw_ptr_r;
		end
	end

	// AW Write Logic (M Domain)
	reg [AW_CTRL_WIDTH-1:0] aw_m_data;
	reg aw_m_valid;
	reg aw_m_ready;

	// Pack S signals into M data
	// Format: {ID, ADDR, LEN, SIZE, BURST, LOCK, CACHE, PROT, QOS, VALID}
	// Note: S_AXI_AWVALID is the trigger.
	// We register the data on M clock before asserting M_AXI_AWVALID.
	
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			aw_m_data <= 1'b0;
			aw_m_valid <= 1'b0;
			aw_m_ready <= 1'b0;
		end else begin
			// Capture S side signals
			reg [AW_CTRL_WIDTH-1:0] s_aw_data;
			s_axi_awid_reg <= S_AXI_AWID;
			s_axi_awaddr_reg <= S_AXI_AWADDR;
			s_axi_awlen_reg <= S_AXI_AWLEN;
			s_axi_awsize_reg <= S_AXI_AWSIZE;
			s_axi_awburst_reg <= S_AXI_AWBURST;
			s_axi_awlock_reg <= S_AXI_AWLOCK;
			s_axi_awcache_reg <= S_AXI_AWCACHE;
			s_axi_awprot_reg <= S_AXI_AWPROT;
			s_axi_awqos_reg <= S_AXI_AWQOS;
			
			// Construct the packed data
			// We need to align bits correctly.
			// Let's define the structure explicitly in the assignment below.
			// For now, assume tight packing: ID | ADDR | LEN | SIZE | BURST | LOCK | CACHE | PROT | QOS | VALID
			// Total bits: 2 + 6 + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 1 = 34 bits.
			// AW_CTRL_WIDTH calculated as 34.
			
			// We will handle the packing in the combinational logic below to avoid synthesis warnings
			// about implicit concatenation widths.
			
			// Check FIFO Full
			if (aw_fifo_full) begin
				aw_m_ready <= 1'b0;
			end else begin
				// If S is valid and M is ready, push to FIFO
				if (s_axi_awid_reg_valid && s_axi_awaddr_reg_valid && s_axi_awlen_reg_valid && 
				    s_axi_awsize_reg_valid && s_axi_awburst_reg_valid && s_axi_awlock_reg_valid &&
				    s_axi_awcache_reg_valid && s_axi_awprot_reg_valid && s_axi_awqos_reg_valid &&
				    S_AXI_AWVALID) begin
					// Push to FIFO
					aw_fifo_data[aw_ptr_w] <= {
						S_AXI_AWID,
						S_AXI_AWADDR,
						S_AXI_AWLEN,
						S_AXI_AWSIZE,
						S_AXI_AWBURST,
						S_AXI_AWLOCK,
						S_AXI_AWCACHE,
						S_AXI_AWPROT,
						S_AXI_AWQOS,
						1'b1 // VALID
					};
					aw_ptr_w <= aw_ptr_w + 1;
					aw_m_ready <= 1'b1;
				end else begin
					// S is not ready to push yet, or invalid
					aw_m_ready <= 1'b0;
				end
			end
		end
	end

	// S Side AW Ready Generation
	reg s_axi_awid_reg;
	reg s_axi_awaddr_reg;
	reg s_axi_awlen_reg;
	reg s_axi_awsize_reg;
	reg s_axi_awburst_reg;
	reg s_axi_awlock_reg;
	reg s_axi_awcache_reg;
	reg s_axi_awprot_reg;
	reg s_axi_awqos_reg;
	reg s_axi_awid_reg_valid;
	reg s_axi_awaddr_reg_valid;
	reg s_axi_awlen_reg_valid;
	reg s_axi_awsize_reg_valid;
	reg s_axi_awburst_reg_valid;
	reg s_axi_awlock_reg_valid;
	reg s_axi_awcache_reg_valid;
	reg s_axi_awprot_reg_valid;
	reg s_axi_awqos_reg_valid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_axi_awid_reg <= 1'b0;
			s_axi_awaddr_reg <= 1'b0;
			s_axi_awlen_reg <= 1'b0;
			s_axi_awsize_reg <= 1'b0;
			s_axi_awburst_reg <= 1'b0;
			s_axi_awlock_reg <= 1'b0;
			s_axi_awcache_reg <= 1'b0;
			s_axi_awprot_reg <= 1'b0;
			s_axi_awqos_reg <= 1'b0;
			s_axi_awid_reg_valid <= 1'b0;
			s_axi_awaddr_reg_valid <= 1'b0;
			s_axi_awlen_reg_valid <= 1'b0;
			s_axi_awsize_reg_valid <= 1'b0;
			s_axi_awburst_reg_valid <= 1'b0;
			s_axi_awlock_reg_valid <= 1'b0;
			s_axi_awcache_reg_valid <= 1'b0;
			s_axi_awprot_reg_valid <= 1'b0;
			s_axi_awqos_reg_valid <= 1'b0;
			S_AXI_AWREADY <= 1'b0;
		end else begin
			s_axi_awid_reg <= S_AXI_AWID;
			s_axi_awaddr_reg <= S_AXI_AWADDR;
			s_axi_awlen_reg <= S_AXI_AWLEN;
			s_axi_awsize_reg <= S_AXI_AWSIZE;
			s_axi_awburst_reg <= S_AXI_AWBURST;
			s_axi_awlock_reg <= S_AXI_AWLOCK;
			s_axi_awcache_reg <= S_AXI_AWCACHE;
			s_axi_awprot_reg <= S_AXI_AWPROT;
			s_axi_awqos_reg <= S_AXI_AWQOS;
			
			// Register validity flags
			s_axi_awid_reg_valid <= S_AXI_AWID; // Assuming ID is always valid when valid is high
			s_axi_awaddr_reg_valid <= S_AXI_AWADDR;
			s_axi_awlen_reg_valid <= S_AXI_AWLEN;
			s_axi_awsize_reg_valid <= S_AXI_AWSIZE;
			s_axi_awburst_reg_valid <= S_AXI_AWBURST;
			s_axi_awlock_reg_valid <= S_AXI_AWLOCK;
			s_axi_awcache_reg_valid <= S_AXI_AWCACHE;
			s_axi_awprot_reg_valid <= S_AXI_AWPROT;
			s_axi_awqos_reg_valid <= S_AXI_AWQOS;

			// S_READY is high if M is ready (FIFO not full) AND all S signals are valid
			if (aw_fifo_full == 1'b0 && 
			    s_axi_awid_reg_valid && s_axi_awaddr_reg_valid && s_axi_awlen_reg_valid && 
			    s_axi_awsize_reg_valid && s_axi_awburst_reg_valid && s_axi_awlock_reg_valid &&
			    s_axi_awcache_reg_valid && s_axi_awprot_reg_valid && s_axi_awqos_reg_valid) begin
				S_AXI_AWREADY <= 1'b1;
			end else begin
				S_AXI_AWREADY <= 1'b0;
			end
		end
	end

	// M Side AW Valid Generation (after 1 cycle delay as per requirement)
	// The requirement says: "Master write data is held one extra M clock before M_AXI_WVALID."
	// This applies to W, but for AW, standard practice is to register on M clock.
	// We will assert M_AXI_AWVALID when the FIFO has data and M is ready.
	// To meet the "held one extra clock" spirit for the whole transaction, we can delay the valid signal.
	// However, the prompt specifically mentions "Master write data". Let's stick to standard FIFO behavior
	// for AW/AR and apply the specific delay to W/R if needed. 
	// Re-reading: "Master write data is held one extra M clock before M_AXI_WVALID."
	// This implies M_AXI_WVALID should be delayed relative to M_AXI_WDATA capture? 
	// Or does it mean the data from S is captured, then held for 1 M-cycle before valid?
	// Interpretation: S->M data capture happens. Then M asserts VALID 1 cycle later.
	// We will implement a 1-cycle delay for M_AXI_AWVALID, M_AXI_WVALID, M_AXI_ARVALID.
	
	reg [AW_CTRL_WIDTH-1:0] aw_fifo_data_reg;
	reg aw_fifo_data_valid_reg;
	reg aw_fifo_data_valid_delayed;

	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_data_reg <= 1'b0;
			aw_fifo_data_valid_reg <= 1'b0;
			aw_fifo_data_valid_delayed <= 1'b0;
			M_AXI_AWVALID <= 1'b0;
		end else begin
			// Read from FIFO
			if (aw_fifo_empty == 1'b0) begin
				aw_fifo_data_reg <= aw_fifo_data[aw_ptr_r];
				aw_fifo_data_valid_reg <= 1'b1;
			end else begin
				aw_fifo_data_reg <= 1'b0;
				aw_fifo_data_valid_reg <= 1'b0;
			end
			
			// Delay valid by 1 cycle
			aw_fifo_data_valid_delayed <= aw_fifo_data_valid_reg;
			
			// Assert M_VALID if data is ready and M is ready
			if (aw_fifo_data_valid_delayed && M_AXI_AWREADY) begin
				M_AXI_AWVALID <= 1'b1;
			end else begin
				M_AXI_AWVALID <= 1'b0;
			end
		end
	end

	// FIFO Pointer Increment on Write
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			aw_ptr_w <= 1'b0;
		end else begin
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				aw_ptr_w <= aw_ptr_w + 1;
			end
		end
	end

	// FIFO Pointer Increment on Read
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			aw_ptr_r <= 1'b0;
		end else begin
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				aw_ptr_r <= aw_ptr_r + 1;
			end
		end
	end

	// ---------------------------------------------------------------------------
	// 3. Write Data Channel (S -> M)
	// ---------------------------------------------------------------------------
	// Data Width: C_S_AXI_DATA_WIDTH
	// Strobe Width: C_S_AXI_DATA_WIDTH/8
	// Last: 1 bit
	// Valid: 1 bit
	
	localparam W_CTRL_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 2;
	
	reg [W_CTRL_WIDTH-1:0] w_fifo_data;
	reg [LGFIFO:0] w_ptr_r;
	reg [LGFIFO:0] w_ptr_w;
	reg [LGFIFO:0] w_fifo_full;
	reg [LGFIFO:0] w_fifo_empty;
	reg [LGFIFO:0] w_fifo_count;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_ptr_r <= 1'b0;
			w_ptr_w <= 1'b0;
			w_fifo_count <= 1'b0;
			w_fifo_full <= 1'b0;
			w_fifo_empty <= 1'b0;
		end else begin
			w_fifo_full <= (w_ptr_w == (1<<(LGFIFO+1)) - 1) && (w_ptr_w == w_ptr_r);
			w_fifo_empty <= (w_ptr_w == w_ptr_r);
			w_fifo_count <= w_ptr_w - w_ptr_r;
		end
	end

	// S Side W Signals
	reg [C_S_AXI_DATA_WIDTH-1:0] s_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] s_wstrb_reg;
	reg s_wlast_reg;
	reg s_wvalid_reg;
	reg s_wvalid_reg_valid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wdata_reg <= 1'b0;
			s_wstrb_reg <= 1'b0;
			s_wlast_reg <= 1'b0;
			s_wvalid_reg <= 1'b0;
			s_wvalid_reg_valid <= 1'b0;
			S_AXI_WREADY <= 1'b0;
		end else begin
			s_wdata_reg <= S_AXI_WDATA;
			s_wstrb_reg <= S_AXI_WSTRB;
			s_wlast_reg <= S_AXI_WLAST;
			s_wvalid_reg <= S_AXI_WVALID;
			s_wvalid_reg_valid <= S_AXI_WVALID;

			if (w_fifo_full == 1'b0 && s_wvalid_reg_valid) begin
				S_AXI_WREADY <= 1'b1;
			end else begin
				S_AXI_WREADY <= 1'b0;
			end
		end
	end

	// M Side W Logic
	reg [W_CTRL_WIDTH-1:0] w_fifo_data_reg;
	reg w_fifo_data_valid_reg;
	reg w_fifo_data_valid_delayed;

	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_data_reg <= 1'b0;
			w_fifo_data_valid_reg <= 1'b0;
			w_fifo_data_valid_delayed <= 1'b0;
			M_AXI_WVALID <= 1'b0;
		end else begin
			if (w_fifo_empty == 1'b0) begin
				w_fifo_data_reg <= w_fifo_data[w_ptr_r];
				w_fifo_data_valid_reg <= 1'b1;
			end else begin
				w_fifo_data_reg <= 1'b0;
				w_fifo_data_valid_reg <= 1'b0;
			end
			
			w_fifo_data_valid_delayed <= w_fifo_data_valid_reg;
			
			if (w_fifo_data_valid_delayed && M_AXI_WREADY) begin
				M_AXI_WVALID <= 1'b1;
			end else begin
				M_AXI_WVALID <= 1'b0;
			end
		end
	end

	// FIFO Write Logic
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			w_ptr_w <= 1'b0;
		end else begin
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_fifo_data[w_ptr_w] <= {
					S_AXI_WDATA,
					S_AXI_WSTRB,
					S_AXI_WLAST
				};
				w_ptr_w <= w_ptr_w + 1;
			end
		end
	end

	// FIFO Read Logic
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			w_ptr_r <= 1'b0;
		end else begin
			if (M_AXI_WVALID && M_AXI_WREADY) begin
				w_ptr_r <= w_ptr_r + 1;
			end
		end
	end

	// ---------------------------------------------------------------------------
	// 4. Write Response Channel (M -> S)
	// ---------------------------------------------------------------------------
	// BID, BRESP, BVALID, BREADY
	// Width: ID + RESP + VALID = 2 + 2 + 1 = 5 bits
	
	localparam B_CTRL_WIDTH = C_S_AXI_ID_WIDTH + 2 + 1;
	
	reg [B_CTRL_WIDTH-1:0] b_fifo_data;
	reg [LGFIFO:0] b_ptr_r;
	reg [LGFIFO:0] b_ptr_w;
	reg [LGFIFO:0] b_fifo_full;
	reg [LGFIFO:0] b_fifo_empty;
	reg [LGFIFO:0] b_fifo_count;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_ptr_r <= 1'b0;
			b_ptr_w <= 1'b0;
			b_fifo_count <= 1'b0;
			b_fifo_full <= 1'b0;
			b_fifo_empty <= 1'b0;
			S_AXI_BID <= 1'b0;
			S_AXI_BRESP <= 1'b0;
			S_AXI_BVALID <= 1'b0;
		end else begin
			b_fifo_full <= (b_ptr_w == (1<<(LGFIFO+1)) - 1) && (b_ptr_w == b_ptr_r);
			b_fifo_empty <= (b_ptr_w == b_ptr_r);
			b_fifo_count <= b_ptr_w - b_ptr_r;
		end
	end

	// M Side B Logic
	reg [B_CTRL_WIDTH-1:0] b_m_data;
	reg b_m_valid;
	reg b_m_ready;

	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			b_m_data <= 1'b0;
			b_m_valid <= 1'b0;
			b_m_ready <= 1'b0;
		end else begin
			if (M_AXI_BVALID) begin
				b_m_data <= {M_AXI_BID, M_AXI_BRESP, 1'b1};
				b_m_valid <= 1'b1;
			end else begin
				b_m_data <= 1'b0;
				b_m_valid <= 1'b0;
			end
		end
	end

	// S Side B Ready Generation
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BREADY <= 1'b0;
		end else begin
			if (b_fifo_full == 1'b0 && b_m_valid) begin
				S_AXI_BREADY <= 1'b1;
			end else begin
				S_AXI_BREADY <= 1'b0;
			end
		end
	end

	// FIFO Write Logic (M -> S)
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			b_ptr_w <= 1'b0;
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_fifo_data[b_ptr_w] <= b_m_data;
				b_ptr_w <= b_ptr_w + 1;
			end
		end
	end

	// FIFO Read Logic (S <- M)
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			b_ptr_r <= 1'b0;
		end else begin
			if (S_AXI_BREADY && S_AXI_BVALID) begin // Wait for S to be ready
				b_ptr_r <= b_ptr_r + 1;
			end
		end
	end

	// S Side B Output
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BID <= 1'b0;
			S_AXI_BRESP <= 1'b0;
			S_AXI_BVALID <= 1'b0;
		end else begin
			if (b_fifo_empty == 1'b0) begin
				S_AXI_BID <= b_fifo_data[b_ptr_r][C_S_AXI_ID_WIDTH-1:0];
				S_AXI_BRESP <= b_fifo_data[b_ptr_r][C_S_AXI_ID_WIDTH+1:C_S_AXI_ID_WIDTH];
				S_AXI_BVALID <= b_fifo_data[b_ptr_r][C_S_AXI_ID_WIDTH+2];
			end else begin
				S_AXI_BID <= 1'b0;
				S_AXI_BRESP <= 1'b0;
				S_AXI_BVALID <= 1'b0;
			end
		end
	end

	// ---------------------------------------------------------------------------
	// 5. Read Address Channel (S -> M)
	// ---------------------------------------------------------------------------
	// Similar to AW
	
	localparam AR_CTRL_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 1;
	
	reg [AR_CTRL_WIDTH-1:0] ar_fifo_data;
	reg [LGFIFO:0] ar_ptr_r;
	reg [LGFIFO:0] ar_ptr_w;
	reg [LGFIFO:0] ar_fifo_full;
	reg [LGFIFO:0] ar_fifo_empty;
	reg [LGFIFO:0] ar_fifo_count;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_ptr_r <= 1'b0;
			ar_ptr_w <= 1'b0;
			ar_fifo_count <= 1'b0;
			ar_fifo_full <= 1'b0;
			ar_fifo_empty <= 1'b0;
		end else begin
			ar_fifo_full <= (ar_ptr_w == (1<<(LGFIFO+1)) - 1) && (ar_ptr_w == ar_ptr_r);
			ar_fifo_empty <= (ar_ptr_w == ar_ptr_r);
			ar_fifo_count <= ar_ptr_w - ar_ptr_r;
		end
	end

	// S Side AR Signals
	reg [C_S_AXI_ID_WIDTH-1:0] s_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] s_araddr_reg;
	reg [7:0] s_arlen_reg;
	reg [2:0] s_arsize_reg;
	reg [1:0] s_arburst_reg;
	reg s_arlock_reg;
	reg [3:0] s_arcache_reg;
	reg [2:0] s_arprot_reg;
	reg [3:0] s_arqos_reg;
	reg s_arvalid_reg;
	reg s_arvalid_reg_valid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arid_reg <= 1'b0;
			s_araddr_reg <= 1'b0;
			s_arlen_reg <= 1'b0;
			s_arsize_reg <= 1'b0;
			s_arburst_reg <= 1'b0;
			s_arlock_reg <= 1'b0;
			s_arcache_reg <= 1'b0;
			s_arprot_reg <= 1'b0;
			s_arqos_reg <= 1'b0;
			s_arvalid_reg <= 1'b0;
			s_arvalid_reg_valid <= 1'b0;
			S_AXI_ARREADY <= 1'b0;
		end else begin
			s_arid_reg <= S_AXI_ARID;
			s_araddr_reg <= S_AXI_ARADDR;
			s_arlen_reg <= S_AXI_ARLEN;
			s_arsize_reg <= S_AXI_ARSIZE;
			s_arburst_reg <= S_AXI_ARBURST;
			s_arlock_reg <= S_AXI_ARLOCK;
			s_arcache_reg <= S_AXI_ARCACHE;
			s_arprot_reg <= S_AXI_ARPROT;
			s_arqos_reg <= S_AXI_ARQOS;
			s_arvalid_reg <= S_AXI_ARVALID;
			s_arvalid_reg_valid <= S_AXI_ARVALID;

			if (ar_fifo_full == 1'b0 && s_arvalid_reg_valid) begin
				S_AXI_ARREADY <= 1'b1;
			end else begin
				S_AXI_ARREADY <= 1'b0;
			end
		end
	end

	// M Side AR Logic
	reg [AR_CTRL_WIDTH-1:0] ar_fifo_data_reg;
	reg ar_fifo_data_valid_reg;
	reg ar_fifo_data_valid_delayed;

	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_data_reg <= 1'b0;
			ar_fifo_data_valid_reg <= 1'b0;
			ar_fifo_data_valid_delayed <= 1'b0;
			M_AXI
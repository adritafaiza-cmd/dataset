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

	// Local parameters
	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer FFS_STAGES = XCLOCK_FFS;

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1:0] aw_id_m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_m;
	wire [7:0] aw_len_m;
	wire [2:0] aw_size_m;
	wire [1:0] aw_burst_m;
	wire aw_lock_m;
	wire [3:0] aw_cache_m;
	wire [2:0] aw_prot_m;
	wire [3:0] aw_qos_m;
	wire aw_valid_m;
	wire aw_ready_m;

	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_m;
	wire w_last_m;
	wire w_valid_m;
	wire w_ready_m;

	wire [C_S_AXI_ID_WIDTH-1:0] b_id_s;
	wire [1:0] b_resp_s;
	wire b_valid_s;
	wire b_ready_s;

	wire [C_S_AXI_ID_WIDTH-1:0] ar_id_m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_m;
	wire [7:0] ar_len_m;
	wire [2:0] ar_size_m;
	wire [1:0] ar_burst_m;
	wire ar_lock_m;
	wire [3:0] ar_cache_m;
	wire [2:0] ar_prot_m;
	wire [3:0] ar_qos_m;
	wire ar_valid_m;
	wire ar_ready_m;

	wire [C_S_AXI_ID_WIDTH-1:0] r_id_s;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_s;
	wire [1:0] r_resp_s;
	wire r_last_s;
	wire r_valid_s;
	wire r_ready_s;

	// Reset synchronization for M_AXI_ACLK domain
	reg [FFS_STAGES-1:0] m_reset_sync;
	reg m_reset_n;

	always @(posedge M_AXI_ACLK) begin
		if (FFS_STAGES > 1) begin
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], S_AXI_ARESETN};
		end else begin
			m_reset_sync <= S_AXI_ARESETN;
		end
	end

	always @(*) begin
		if (FFS_STAGES > 1)
			m_reset_n = m_reset_sync[FFS_STAGES-1];
		else
			m_reset_n = m_reset_sync[0];
	end

	assign M_AXI_ARESETN = m_reset_n;

	// AW Channel: S -> M
	// FIFO for AW channel
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_count;

	wire aw_fifo_full = (aw_fifo_count == FIFO_DEPTH);
	wire aw_fifo_empty = (aw_fifo_count == 0);

	// Write to AW FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_wr_ptr <= 0;
			aw_fifo_count <= 0;
		end else if (S_AXI_AWVALID && !aw_fifo_full) begin
			aw_fifo_id[aw_fifo_wr_ptr] <= S_AXI_AWID;
			aw_fifo_addr[aw_fifo_wr_ptr] <= S_AXI_AWADDR;
			aw_fifo_len[aw_fifo_wr_ptr] <= S_AXI_AWLEN;
			aw_fifo_size[aw_fifo_wr_ptr] <= S_AXI_AWSIZE;
			aw_fifo_burst[aw_fifo_wr_ptr] <= S_AXI_AWBURST;
			aw_fifo_lock[aw_fifo_wr_ptr] <= S_AXI_AWLOCK;
			aw_fifo_cache[aw_fifo_wr_ptr] <= S_AXI_AWCACHE;
			aw_fifo_prot[aw_fifo_wr_ptr] <= S_AXI_AWPROT;
			aw_fifo_qos[aw_fifo_wr_ptr] <= S_AXI_AWQOS;
			aw_fifo_wr_ptr <= aw_fifo_wr_ptr + 1;
			aw_fifo_count <= aw_fifo_count + 1;
		end else if (aw_fifo_rd_ptr == aw_fifo_wr_ptr && aw_fifo_count > 0) begin
			// This case shouldn't happen with proper counting, but handle it
		end
	end

	// Read from AW FIFO in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_rd_ptr <= 0;
		end else if (!aw_fifo_empty && aw_ready_m) begin
			aw_fifo_rd_ptr <= aw_fifo_rd_ptr + 1;
		end
	end

	// AW FIFO count update in M_AXI_ACLK domain (for read side)
	// We need to synchronize the count or use a different approach
	// Let's use a simpler approach: synchronize the pointers

	// Actually, let's use a proper async FIFO with Gray code pointers
	// For simplicity, let's use a different approach:
	// Synchronize the write pointer to M domain and read pointer to S domain

	// Let's redo this with proper async FIFO using Gray code

	// AW Channel Async FIFO
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_gray_m;
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_gray_s;

	// Convert binary to Gray code
	function [FIFO_ADDR_WIDTH:0] bin2gray;
		input [FIFO_ADDR_WIDTH:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Write pointer in S domain
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_bin;
	// Read pointer in M domain
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_bin;

	// Gray code versions
	assign aw_fifo_wr_ptr_gray = bin2gray(aw_fifo_wr_ptr_bin);
	assign aw_fifo_rd_ptr_gray = bin2gray(aw_fifo_rd_ptr_bin);

	// Synchronize write pointer to M domain
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_gray_m_r1;
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_gray_m_r2;
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_gray_m_r3;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_wr_ptr_gray_m_r1 <= 0;
			aw_fifo_wr_ptr_gray_m_r2 <= 0;
			aw_fifo_wr_ptr_gray_m_r3 <= 0;
		end else begin
			aw_fifo_wr_ptr_gray_m_r1 <= aw_fifo_wr_ptr_gray;
			aw_fifo_wr_ptr_gray_m_r2 <= aw_fifo_wr_ptr_gray_m_r1;
			aw_fifo_wr_ptr_gray_m_r3 <= aw_fifo_wr_ptr_gray_m_r2;
		end
	end

	assign aw_fifo_wr_ptr_gray_m = aw_fifo_wr_ptr_gray_m_r3;

	// Synchronize read pointer to S domain
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_gray_s_r1;
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_gray_s_r2;
	reg [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_gray_s_r3;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_rd_ptr_gray_s_r1 <= 0;
			aw_fifo_rd_ptr_gray_s_r2 <= 0;
			aw_fifo_rd_ptr_gray_s_r3 <= 0;
		end else begin
			aw_fifo_rd_ptr_gray_s_r1 <= aw_fifo_rd_ptr_gray;
			aw_fifo_rd_ptr_gray_s_r2 <= aw_fifo_rd_ptr_gray_s_r1;
			aw_fifo_rd_ptr_gray_s_r3 <= aw_fifo_rd_ptr_gray_s_r2;
		end
	end

	assign aw_fifo_rd_ptr_gray_s = aw_fifo_rd_ptr_gray_s_r3;

	// Convert Gray code back to binary
	function [FIFO_ADDR_WIDTH:0] gray2bin;
		input [FIFO_ADDR_WIDTH:0] gray;
		reg [FIFO_ADDR_WIDTH:0] bin;
		begin
			bin[FIFO_ADDR_WIDTH] = gray[FIFO_ADDR_WIDTH];
			for (integer i = FIFO_ADDR_WIDTH-1; i >= 0; i = i-1) begin
				bin[i] = gray[i] ^ bin[i+1];
			end
			gray2bin = bin;
		end
	endfunction

	// Full/Empty detection
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_wr_ptr_bin_m;
	wire [FIFO_ADDR_WIDTH:0] aw_fifo_rd_ptr_bin_s;

	assign aw_fifo_wr_ptr_bin_m = gray2bin(aw_fifo_wr_ptr_gray_m);
	assign aw_fifo_rd_ptr_bin_s = gray2bin(aw_fifo_rd_ptr_gray_s);

	// Full: write pointer has lapped read pointer by FIFO_DEPTH
	wire aw_fifo_full_s;
	wire aw_fifo_empty_m;

	assign aw_fifo_full_s = (aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH] != aw_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH]) && 
	                         (aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0] == aw_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH-1:0]);
	assign aw_fifo_empty_m = (aw_fifo_wr_ptr_bin_m == aw_fifo_rd_ptr_bin);

	// Write to AW FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_wr_ptr_bin <= 0;
		end else if (S_AXI_AWVALID && !aw_fifo_full_s) begin
			aw_fifo_id[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWID;
			aw_fifo_addr[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWADDR;
			aw_fifo_len[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWLEN;
			aw_fifo_size[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWSIZE;
			aw_fifo_burst[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWBURST;
			aw_fifo_lock[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWLOCK;
			aw_fifo_cache[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWCACHE;
			aw_fifo_prot[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWPROT;
			aw_fifo_qos[aw_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWQOS;
			aw_fifo_wr_ptr_bin <= aw_fifo_wr_ptr_bin + 1;
		end
	end

	// Read from AW FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_rd_ptr_bin <= 0;
		end else if (!aw_fifo_empty_m && aw_ready_m) begin
			aw_fifo_rd_ptr_bin <= aw_fifo_rd_ptr_bin + 1;
		end
	end

	// AW output from FIFO
	assign aw_id_m = aw_fifo_id[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_addr_m = aw_fifo_addr[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_len_m = aw_fifo_len[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_size_m = aw_fifo_size[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_burst_m = aw_fifo_burst[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_lock_m = aw_fifo_lock[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_cache_m = aw_fifo_cache[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_prot_m = aw_fifo_prot[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_qos_m = aw_fifo_qos[aw_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign aw_valid_m = !aw_fifo_empty_m;
	assign aw_ready_m = M_AXI_AWREADY;

	// S_AXI_AWREADY
	assign S_AXI_AWREADY = !aw_fifo_full_s;

	// W Channel: S -> M
	// FIFO for W channel
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_bin;
	reg [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_bin;

	wire [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_gray_m;
	wire [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_gray_s;

	assign w_fifo_wr_ptr_gray = bin2gray(w_fifo_wr_ptr_bin);
	assign w_fifo_rd_ptr_gray = bin2gray(w_fifo_rd_ptr_bin);

	reg [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_gray_m_r1;
	reg [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_gray_m_r2;
	reg [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_gray_m_r3;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_wr_ptr_gray_m_r1 <= 0;
			w_fifo_wr_ptr_gray_m_r2 <= 0;
			w_fifo_wr_ptr_gray_m_r3 <= 0;
		end else begin
			w_fifo_wr_ptr_gray_m_r1 <= w_fifo_wr_ptr_gray;
			w_fifo_wr_ptr_gray_m_r2 <= w_fifo_wr_ptr_gray_m_r1;
			w_fifo_wr_ptr_gray_m_r3 <= w_fifo_wr_ptr_gray_m_r2;
		end
	end

	assign w_fifo_wr_ptr_gray_m = w_fifo_wr_ptr_gray_m_r3;

	reg [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_gray_s_r1;
	reg [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_gray_s_r2;
	reg [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_gray_s_r3;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_rd_ptr_gray_s_r1 <= 0;
			w_fifo_rd_ptr_gray_s_r2 <= 0;
			w_fifo_rd_ptr_gray_s_r3 <= 0;
		end else begin
			w_fifo_rd_ptr_gray_s_r1 <= w_fifo_rd_ptr_gray;
			w_fifo_rd_ptr_gray_s_r2 <= w_fifo_rd_ptr_gray_s_r1;
			w_fifo_rd_ptr_gray_s_r3 <= w_fifo_rd_ptr_gray_s_r2;
		end
	end

	assign w_fifo_rd_ptr_gray_s = w_fifo_rd_ptr_gray_s_r3;

	wire [FIFO_ADDR_WIDTH:0] w_fifo_wr_ptr_bin_m;
	wire [FIFO_ADDR_WIDTH:0] w_fifo_rd_ptr_bin_s;

	assign w_fifo_wr_ptr_bin_m = gray2bin(w_fifo_wr_ptr_gray_m);
	assign w_fifo_rd_ptr_bin_s = gray2bin(w_fifo_rd_ptr_gray_s);

	wire w_fifo_full_s;
	wire w_fifo_empty_m;

	assign w_fifo_full_s = (w_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH] != w_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH]) && 
	                       (w_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0] == w_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH-1:0]);
	assign w_fifo_empty_m = (w_fifo_wr_ptr_bin_m == w_fifo_rd_ptr_bin);

	// Write to W FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_wr_ptr_bin <= 0;
		end else if (S_AXI_WVALID && !w_fifo_full_s) begin
			w_fifo_data[w_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WDATA;
			w_fifo_strb[w_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WSTRB;
			w_fifo_last[w_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WLAST;
			w_fifo_wr_ptr_bin <= w_fifo_wr_ptr_bin + 1;
		end
	end

	// Read from W FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_rd_ptr_bin <= 0;
		end else if (!w_fifo_empty_m && w_ready_m) begin
			w_fifo_rd_ptr_bin <= w_fifo_rd_ptr_bin + 1;
		end
	end

	// W output from FIFO
	assign w_data_m = w_fifo_data[w_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign w_strb_m = w_fifo_strb[w_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign w_last_m = w_fifo_last[w_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign w_valid_m = !w_fifo_empty_m;
	assign w_ready_m = M_AXI_WREADY;

	// S_AXI_WREADY
	assign S_AXI_WREADY = !w_fifo_full_s;

	// B Channel: M -> S
	// FIFO for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_bin;
	reg [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_bin;

	wire [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_gray_s;
	wire [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_gray_m;

	assign b_fifo_wr_ptr_gray = bin2gray(b_fifo_wr_ptr_bin);
	assign b_fifo_rd_ptr_gray = bin2gray(b_fifo_rd_ptr_bin);

	reg [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_gray_s_r1;
	reg [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_gray_s_r2;
	reg [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_gray_s_r3;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_wr_ptr_gray_s_r1 <= 0;
			b_fifo_wr_ptr_gray_s_r2 <= 0;
			b_fifo_wr_ptr_gray_s_r3 <= 0;
		end else begin
			b_fifo_wr_ptr_gray_s_r1 <= b_fifo_wr_ptr_gray;
			b_fifo_wr_ptr_gray_s_r2 <= b_fifo_wr_ptr_gray_s_r1;
			b_fifo_wr_ptr_gray_s_r3 <= b_fifo_wr_ptr_gray_s_r2;
		end
	end

	assign b_fifo_wr_ptr_gray_s = b_fifo_wr_ptr_gray_s_r3;

	reg [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_gray_m_r1;
	reg [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_gray_m_r2;
	reg [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_gray_m_r3;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_rd_ptr_gray_m_r1 <= 0;
			b_fifo_rd_ptr_gray_m_r2 <= 0;
			b_fifo_rd_ptr_gray_m_r3 <= 0;
		end else begin
			b_fifo_rd_ptr_gray_m_r1 <= b_fifo_rd_ptr_gray;
			b_fifo_rd_ptr_gray_m_r2 <= b_fifo_rd_ptr_gray_m_r1;
			b_fifo_rd_ptr_gray_m_r3 <= b_fifo_rd_ptr_gray_m_r2;
		end
	end

	assign b_fifo_rd_ptr_gray_m = b_fifo_rd_ptr_gray_m_r3;

	wire [FIFO_ADDR_WIDTH:0] b_fifo_wr_ptr_bin_s;
	wire [FIFO_ADDR_WIDTH:0] b_fifo_rd_ptr_bin_m;

	assign b_fifo_wr_ptr_bin_s = gray2bin(b_fifo_wr_ptr_gray_s);
	assign b_fifo_rd_ptr_bin_m = gray2bin(b_fifo_rd_ptr_gray_m);

	wire b_fifo_full_m;
	wire b_fifo_empty_s;

	assign b_fifo_full_m = (b_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH] != b_fifo_rd_ptr_bin_m[FIFO_ADDR_WIDTH]) && 
	                       (b_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0] == b_fifo_rd_ptr_bin_m[FIFO_ADDR_WIDTH-1:0]);
	assign b_fifo_empty_s = (b_fifo_wr_ptr_bin_s == b_fifo_rd_ptr_bin);

	// Write to B FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_wr_ptr_bin <= 0;
		end else if (M_AXI_BVALID && !b_fifo_full_m) begin
			b_fifo_id[b_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_BID;
			b_fifo_resp[b_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_BRESP;
			b_fifo_wr_ptr_bin <= b_fifo_wr_ptr_bin + 1;
		end
	end

	// Read from B FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_rd_ptr_bin <= 0;
		end else if (!b_fifo_empty_s && b_ready_s) begin
			b_fifo_rd_ptr_bin <= b_fifo_rd_ptr_bin + 1;
		end
	end

	// B output from FIFO
	assign b_id_s = b_fifo_id[b_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign b_resp_s = b_fifo_resp[b_fifo_rd_ptr_bin[FIFO_ADDR_WIDTH-1:0]];
	assign b_valid_s = !b_fifo_empty_s;
	assign b_ready_s = S_AXI_BREADY;

	// M_AXI_BREADY
	assign M_AXI_BREADY = !b_fifo_full_m;

	// AR Channel: S -> M
	// FIFO for AR channel
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_bin;
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_bin;

	wire [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_gray;
	wire [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_gray_m;
	wire [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_gray_s;

	assign ar_fifo_wr_ptr_gray = bin2gray(ar_fifo_wr_ptr_bin);
	assign ar_fifo_rd_ptr_gray = bin2gray(ar_fifo_rd_ptr_bin);

	reg [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_gray_m_r1;
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_gray_m_r2;
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_gray_m_r3;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_wr_ptr_gray_m_r1 <= 0;
			ar_fifo_wr_ptr_gray_m_r2 <= 0;
			ar_fifo_wr_ptr_gray_m_r3 <= 0;
		end else begin
			ar_fifo_wr_ptr_gray_m_r1 <= ar_fifo_wr_ptr_gray;
			ar_fifo_wr_ptr_gray_m_r2 <= ar_fifo_wr_ptr_gray_m_r1;
			ar_fifo_wr_ptr_gray_m_r3 <= ar_fifo_wr_ptr_gray_m_r2;
		end
	end

	assign ar_fifo_wr_ptr_gray_m = ar_fifo_wr_ptr_gray_m_r3;

	reg [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_gray_s_r1;
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_gray_s_r2;
	reg [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_gray_s_r3;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_rd_ptr_gray_s_r1 <= 0;
			ar_fifo_rd_ptr_gray_s_r2 <= 0;
			ar_fifo_rd_ptr_gray_s_r3 <= 0;
		end else begin
			ar_fifo_rd_ptr_gray_s_r1 <= ar_fifo_rd_ptr_gray;
			ar_fifo_rd_ptr_gray_s_r2 <= ar_fifo_rd_ptr_gray_s_r1;
			ar_fifo_rd_ptr_gray_s_r3 <= ar_fifo_rd_ptr_gray_s_r2;
		end
	end

	assign ar_fifo_rd_ptr_gray_s = ar_fifo_rd_ptr_gray_s_r3;

	wire [FIFO_ADDR_WIDTH:0] ar_fifo_wr_ptr_bin_m;
	wire [FIFO_ADDR_WIDTH:0] ar_fifo_rd_ptr_bin_s;

	assign ar_fifo_wr_ptr_bin_m = gray2bin(ar_fifo_wr_ptr_gray_m);
	assign ar_fifo_rd_ptr_bin_s = gray2bin(ar_fifo_rd_ptr_gray_s);

	wire ar_fifo_full_s;
	wire ar_fifo_empty_m;

	assign ar_fifo_full_s = (ar_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH] != ar_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH]) && 
	                         (ar_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0] == ar_fifo_rd_ptr_bin_s[FIFO_ADDR_WIDTH-1:0]);
	assign ar_fifo_empty_m = (ar_fifo_wr_ptr_bin_m == ar_fifo_rd_ptr_bin);

	// Write to AR FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_wr_ptr_bin <= 0;
		end else if (S_AXI_ARVALID && !ar_fifo_full_s) begin
			ar_fifo_id[ar_fifo_wr_ptr_bin[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARID;
			ar_fifo_addr
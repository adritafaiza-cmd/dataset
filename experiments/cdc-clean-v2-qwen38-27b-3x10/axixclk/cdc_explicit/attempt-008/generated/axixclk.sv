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
	localparam integer FIFO_PTR_W = LGFIFO;
	localparam integer AW_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_W = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_W = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Internal signals
	wire [AW_FIFO_W-1:0] aw_fifo_data;
	wire [AR_FIFO_W-1:0] ar_fifo_data;
	wire [W_FIFO_W-1:0] w_fifo_data;
	wire [B_FIFO_W-1:0] b_fifo_data;
	wire [R_FIFO_W-1:0] r_fifo_data;

	wire aw_fifo_full, aw_fifo_empty, aw_fifo_wr_en, aw_fifo_rd_en;
	wire ar_fifo_full, ar_fifo_empty, ar_fifo_wr_en, ar_fifo_rd_en;
	wire w_fifo_full, w_fifo_empty, w_fifo_wr_en, w_fifo_rd_en;
	wire b_fifo_full, b_fifo_empty, b_fifo_wr_en, b_fifo_rd_en;
	wire r_fifo_full, r_fifo_empty, r_fifo_wr_en, r_fifo_rd_en;

	// Reset synchronization
	reg [1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK) begin
		m_reset_sync <= {m_reset_sync[0], S_AXI_ARESETN};
	end
	assign M_AXI_ARESETN = m_reset_sync[1];

	// AW channel: S to M
	assign aw_fifo_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	assign S_AXI_AWREADY = !aw_fifo_full;

	// Pack AW data
	wire [AW_FIFO_W-1:0] aw_packed;
	assign aw_packed = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};

	// AW FIFO
	// Write in S clock domain, read in M clock domain
	// We use a simple async FIFO with gray code pointers

	// AW FIFO implementation
	reg [FIFO_DEPTH-1:0][AW_FIFO_W-1:0] aw_mem;
	reg [FIFO_PTR_W:0] aw_wr_ptr, aw_rd_ptr;
	reg [FIFO_PTR_W:0] aw_wr_ptr_gray, aw_rd_ptr_gray;
	reg [FIFO_PTR_W:0] aw_wr_ptr_gray_m, aw_rd_ptr_gray_s;

	// Gray code conversion
	function [FIFO_PTR_W:0] bin2gray;
		input [FIFO_PTR_W:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	function [FIFO_PTR_W:0] gray2bin;
		input [FIFO_PTR_W:0] gray;
		reg [FIFO_PTR_W:0] bin;
		begin
			bin[FIFO_PTR_W] = gray[FIFO_PTR_W];
			for (integer i = FIFO_PTR_W-1; i >= 0; i = i-1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= 0;
		end else if (aw_fifo_wr_en) begin
			aw_wr_ptr <= aw_wr_ptr + 1;
		end
	end

	// Read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr <= 0;
		end else if (aw_fifo_rd_en) begin
			aw_rd_ptr <= aw_rd_ptr + 1;
		end
	end

	// Gray code pointers
	assign aw_wr_ptr_gray = bin2gray(aw_wr_ptr);
	assign aw_rd_ptr_gray = bin2gray(aw_rd_ptr);

	// Synchronize read pointer to S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_rd_ptr_gray_s <= 0;
		end else begin
			aw_rd_ptr_gray_s <= aw_rd_ptr_gray;
		end
	end

	// Synchronize write pointer to M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_wr_ptr_gray_m <= 0;
		end else begin
			aw_wr_ptr_gray_m <= aw_wr_ptr_gray;
		end
	end

	// Full/empty detection
	wire [FIFO_PTR_W:0] aw_rd_ptr_gray_s_bin = gray2bin(aw_rd_ptr_gray_s);
	wire [FIFO_PTR_W:0] aw_wr_ptr_gray_m_bin = gray2bin(aw_wr_ptr_gray_m);

	assign aw_fifo_full = (aw_wr_ptr[FIFO_PTR_W-1:0] == aw_rd_ptr_gray_s_bin[FIFO_PTR_W-1:0]) &&
	                      (aw_wr_ptr[FIFO_PTR_W] != aw_rd_ptr_gray_s_bin[FIFO_PTR_W]);
	assign aw_fifo_empty = (aw_wr_ptr_gray_m_bin == aw_rd_ptr_gray_m);

	// Memory write in S domain
	always @(posedge S_AXI_ACLK) begin
		if (aw_fifo_wr_en) begin
			aw_mem[aw_wr_ptr[FIFO_PTR_W-1:0]] <= aw_packed;
		end
	end

	// Memory read in M domain
	assign aw_fifo_data = aw_mem[aw_rd_ptr[FIFO_PTR_W-1:0]];

	// Unpack AW data
	assign M_AXI_AWID = aw_fifo_data[AW_FIFO_W-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign M_AXI_AWSIZE = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign M_AXI_AWBURST = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign M_AXI_AWLOCK = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign M_AXI_AWCACHE = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign M_AXI_AWPROT = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign M_AXI_AWQOS = aw_fifo_data[AW_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : 0];

	assign M_AXI_AWVALID = !aw_fifo_empty;
	assign aw_fifo_rd_en = M_AXI_AWVALID && M_AXI_AWREADY;

	// AR channel: S to M
	assign ar_fifo_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	assign S_AXI_ARREADY = !ar_fifo_full;

	wire [AR_FIFO_W-1:0] ar_packed;
	assign ar_packed = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};

	reg [FIFO_DEPTH-1:0][AR_FIFO_W-1:0] ar_mem;
	reg [FIFO_PTR_W:0] ar_wr_ptr, ar_rd_ptr;
	reg [FIFO_PTR_W:0] ar_wr_ptr_gray, ar_rd_ptr_gray;
	reg [FIFO_PTR_W:0] ar_wr_ptr_gray_m, ar_rd_ptr_gray_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= 0;
		end else if (ar_fifo_wr_en) begin
			ar_wr_ptr <= ar_wr_ptr + 1;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr <= 0;
		end else if (ar_fifo_rd_en) begin
			ar_rd_ptr <= ar_rd_ptr + 1;
		end
	end

	assign ar_wr_ptr_gray = bin2gray(ar_wr_ptr);
	assign ar_rd_ptr_gray = bin2gray(ar_rd_ptr);

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_rd_ptr_gray_s <= 0;
		end else begin
			ar_rd_ptr_gray_s <= ar_rd_ptr_gray;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_wr_ptr_gray_m <= 0;
		end else begin
			ar_wr_ptr_gray_m <= ar_wr_ptr_gray;
		end
	end

	wire [FIFO_PTR_W:0] ar_rd_ptr_gray_s_bin = gray2bin(ar_rd_ptr_gray_s);
	wire [FIFO_PTR_W:0] ar_wr_ptr_gray_m_bin = gray2bin(ar_wr_ptr_gray_m);

	assign ar_fifo_full = (ar_wr_ptr[FIFO_PTR_W-1:0] == ar_rd_ptr_gray_s_bin[FIFO_PTR_W-1:0]) &&
	                      (ar_wr_ptr[FIFO_PTR_W] != ar_rd_ptr_gray_s_bin[FIFO_PTR_W]);
	assign ar_fifo_empty = (ar_wr_ptr_gray_m_bin == ar_rd_ptr_gray_m);

	always @(posedge S_AXI_ACLK) begin
		if (ar_fifo_wr_en) begin
			ar_mem[ar_wr_ptr[FIFO_PTR_W-1:0]] <= ar_packed;
		end
	end

	assign ar_fifo_data = ar_mem[ar_rd_ptr[FIFO_PTR_W-1:0]];

	assign M_AXI_ARID = ar_fifo_data[AR_FIFO_W-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign M_AXI_ARSIZE = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign M_AXI_ARBURST = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign M_AXI_ARLOCK = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign M_AXI_ARCACHE = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign M_AXI_ARPROT = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign M_AXI_ARQOS = ar_fifo_data[AR_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : 0];

	assign M_AXI_ARVALID = !ar_fifo_empty;
	assign ar_fifo_rd_en = M_AXI_ARVALID && M_AXI_ARREADY;

	// W channel: S to M
	assign w_fifo_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	assign S_AXI_WREADY = !w_fifo_full;

	wire [W_FIFO_W-1:0] w_packed;
	assign w_packed = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};

	reg [FIFO_DEPTH-1:0][W_FIFO_W-1:0] w_mem;
	reg [FIFO_PTR_W:0] w_wr_ptr, w_rd_ptr;
	reg [FIFO_PTR_W:0] w_wr_ptr_gray, w_rd_ptr_gray;
	reg [FIFO_PTR_W:0] w_wr_ptr_gray_m, w_rd_ptr_gray_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= 0;
		end else if (w_fifo_wr_en) begin
			w_wr_ptr <= w_wr_ptr + 1;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr <= 0;
		end else if (w_fifo_rd_en) begin
			w_rd_ptr <= w_rd_ptr + 1;
		end
	end

	assign w_wr_ptr_gray = bin2gray(w_wr_ptr);
	assign w_rd_ptr_gray = bin2gray(w_rd_ptr);

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_rd_ptr_gray_s <= 0;
		end else begin
			w_rd_ptr_gray_s <= w_rd_ptr_gray;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_wr_ptr_gray_m <= 0;
		end else begin
			w_wr_ptr_gray_m <= w_wr_ptr_gray;
		end
	end

	wire [FIFO_PTR_W:0] w_rd_ptr_gray_s_bin = gray2bin(w_rd_ptr_gray_s);
	wire [FIFO_PTR_W:0] w_wr_ptr_gray_m_bin = gray2bin(w_wr_ptr_gray_m);

	assign w_fifo_full = (w_wr_ptr[FIFO_PTR_W-1:0] == w_rd_ptr_gray_s_bin[FIFO_PTR_W-1:0]) &&
	                     (w_wr_ptr[FIFO_PTR_W] != w_rd_ptr_gray_s_bin[FIFO_PTR_W]);
	assign w_fifo_empty = (w_wr_ptr_gray_m_bin == w_rd_ptr_gray_m);

	always @(posedge S_AXI_ACLK) begin
		if (w_fifo_wr_en) begin
			w_mem[w_wr_ptr[FIFO_PTR_W-1:0]] <= w_packed;
		end
	end

	assign w_fifo_data = w_mem[w_rd_ptr[FIFO_PTR_W-1:0]];

	// Hold W data one extra M_AXI clock before M_AXI_WVALID
	reg [W_FIFO_W-1:0] w_hold;
	reg w_hold_valid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_hold <= 0;
			w_hold_valid <= 0;
		end else begin
			if (!w_fifo_empty) begin
				w_hold <= w_fifo_data;
				w_hold_valid <= 1;
			end else if (w_hold_valid && M_AXI_WREADY) begin
				w_hold_valid <= 0;
			end
		end
	end

	assign M_AXI_WDATA = w_hold[C_S_AXI_DATA_WIDTH-1:0];
	assign M_AXI_WSTRB = w_hold[C_S_AXI_DATA_WIDTH-1 : C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST = w_hold[C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)-1];
	assign M_AXI_WVALID = w_hold_valid;
	assign w_fifo_rd_en = w_hold_valid && M_AXI_WREADY;

	// B channel: M to S
	assign b_fifo_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	assign M_AXI_BREADY = !b_fifo_full;

	wire [B_FIFO_W-1:0] b_packed;
	assign b_packed = {M_AXI_BID, M_AXI_BRESP};

	reg [FIFO_DEPTH-1:0][B_FIFO_W-1:0] b_mem;
	reg [FIFO_PTR_W:0] b_wr_ptr, b_rd_ptr;
	reg [FIFO_PTR_W:0] b_wr_ptr_gray, b_rd_ptr_gray;
	reg [FIFO_PTR_W:0] b_wr_ptr_gray_s, b_rd_ptr_gray_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= 0;
		end else if (b_fifo_wr_en) begin
			b_wr_ptr <= b_wr_ptr + 1;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= 0;
		end else if (b_fifo_rd_en) begin
			b_rd_ptr <= b_rd_ptr + 1;
		end
	end

	assign b_wr_ptr_gray = bin2gray(b_wr_ptr);
	assign b_rd_ptr_gray = bin2gray(b_rd_ptr);

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_rd_ptr_gray_m <= 0;
		end else begin
			b_rd_ptr_gray_m <= b_rd_ptr_gray;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_wr_ptr_gray_s <= 0;
		end else begin
			b_wr_ptr_gray_s <= b_wr_ptr_gray;
		end
	end

	wire [FIFO_PTR_W:0] b_rd_ptr_gray_m_bin = gray2bin(b_rd_ptr_gray_m);
	wire [FIFO_PTR_W:0] b_wr_ptr_gray_s_bin = gray2bin(b_wr_ptr_gray_s);

	assign b_fifo_full = (b_wr_ptr[FIFO_PTR_W-1:0] == b_rd_ptr_gray_m_bin[FIFO_PTR_W-1:0]) &&
	                     (b_wr_ptr[FIFO_PTR_W] != b_rd_ptr_gray_m_bin[FIFO_PTR_W]);
	assign b_fifo_empty = (b_wr_ptr_gray_s_bin == b_rd_ptr_gray_s);

	always @(posedge M_AXI_ACLK) begin
		if (b_fifo_wr_en) begin
			b_mem[b_wr_ptr[FIFO_PTR_W-1:0]] <= b_packed;
		end
	end

	assign b_fifo_data = b_mem[b_rd_ptr[FIFO_PTR_W-1:0]];

	assign S_AXI_BID = b_fifo_data[B_FIFO_W-1 : B_FIFO_W-C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP = b_fifo_data[B_FIFO_W-C_S_AXI_ID_WIDTH-1 : 0];
	assign S_AXI_BVALID = !b_fifo_empty;
	assign b_fifo_rd_en = S_AXI_BVALID && S_AXI_BREADY;

	// R channel: M to S
	assign r_fifo_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	assign M_AXI_RREADY = !r_fifo_full;

	wire [R_FIFO_W-1:0] r_packed;
	assign r_packed = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};

	reg [FIFO_DEPTH-1:0][R_FIFO_W-1:0] r_mem;
	reg [FIFO_PTR_W:0] r_wr_ptr, r_rd_ptr;
	reg [FIFO_PTR_W:0] r_wr_ptr_gray, r_rd_ptr_gray;
	reg [FIFO_PTR_W:0] r_wr_ptr_gray_s, r_rd_ptr_gray_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= 0;
		end else if (r_fifo_wr_en) begin
			r_wr_ptr <= r_wr_ptr + 1;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= 0;
		end else if (r_fifo_rd_en) begin
			r_rd_ptr <= r_rd_ptr + 1;
		end
	end

	assign r_wr_ptr_gray = bin2gray(r_wr_ptr);
	assign r_rd_ptr_gray = bin2gray(r_rd_ptr);

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_rd_ptr_gray_m <= 0;
		end else begin
			r_rd_ptr_gray_m <= r_rd_ptr_gray;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_wr_ptr_gray_s <= 0;
		end else begin
			r_wr_ptr_gray_s <= r_wr_ptr_gray;
		end
	end

	wire [FIFO_PTR_W:0] r_rd_ptr_gray_m_bin = gray2bin(r_rd_ptr_gray_m);
	wire [FIFO_PTR_W:0] r_wr_ptr_gray_s_bin = gray2bin(r_wr_ptr_gray_s);

	assign r_fifo_full = (r_wr_ptr[FIFO_PTR_W-1:0] == r_rd_ptr_gray_m_bin[FIFO_PTR_W-1:0]) &&
	                     (r_wr_ptr[FIFO_PTR_W] != r_rd_ptr_gray_m_bin[FIFO_PTR_W]);
	assign r_fifo_empty = (r_wr_ptr_gray_s_bin == r_rd_ptr_gray_s);

	always @(posedge M_AXI_ACLK) begin
		if (r_fifo_wr_en) begin
			r_mem[r_wr_ptr[FIFO_PTR_W-1:0]] <= r_packed;
		end
	end

	assign r_fifo_data = r_mem[r_rd_ptr[FIFO_PTR_W-1:0]];

	assign S_AXI_RID = r_fifo_data[R_FIFO_W-1 : R_FIFO_W-C_S_AXI_ID_WIDTH];
	assign S_AXI_RDATA = r_fifo_data[R_FIFO_W-C_S_AXI_ID_WIDTH-1 : R_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP = r_fifo_data[R_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-1 : R_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2];
	assign S_AXI_RLAST = r_fifo_data[R_FIFO_W-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2-1];
	assign S_AXI_RVALID = !r_fifo_empty;
	assign r_fifo_rd_en = S_AXI_RVALID && S_AXI_RREADY;

endmodule

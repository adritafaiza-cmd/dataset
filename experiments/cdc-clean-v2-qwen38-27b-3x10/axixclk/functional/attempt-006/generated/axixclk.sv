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

	// Reset synchronization for M_AXI_ACLK domain
	reg [FFS_STAGES-1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
	end
	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// ========================================================================
	// AW Channel: S -> M
	// ========================================================================
	// S-side: capture AW when valid and ready
	// M-side: FIFO-based CDC

	// AW data width
	localparam integer AW_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	reg [AW_DATA_WIDTH-1:0] s_aw_data;
	reg s_aw_valid;
	reg s_aw_ready;

	// S-side AW handshake
	assign S_AXI_AWREADY = s_aw_ready;

	// Capture AW on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_aw_valid <= 1'b0;
			s_aw_data  <= {AW_DATA_WIDTH{1'b0}};
		end else begin
			if (S_AXI_AWVALID && s_aw_ready) begin
				s_aw_valid <= 1'b1;
				s_aw_data  <= {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST,
								S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
			end else begin
				s_aw_valid <= 1'b0;
			end
		end
	end

	// AW FIFO: S-side write, M-side read
	// Use a simple async FIFO with gray-code pointers

	// S-side write pointer
	reg [FIFO_ADDR_WIDTH:0] s_aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] s_aw_wr_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] m_aw_rd_ptr_gray_s;

	// M-side read pointer
	reg [FIFO_ADDR_WIDTH:0] m_aw_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] m_aw_rd_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] s_aw_wr_ptr_gray_m;

	// Gray code conversion
	function [FIFO_ADDR_WIDTH:0] bin2gray;
		input [FIFO_ADDR_WIDTH:0] bin;
	begin
		bin2gray = bin ^ (bin >> 1);
	end
	endfunction

	function [FIFO_ADDR_WIDTH:0] gray2bin;
		input [FIFO_ADDR_WIDTH:0] gray;
		reg [FIFO_ADDR_WIDTH:0] bin;
	begin
		bin[FIFO_ADDR_WIDTH] = gray[FIFO_ADDR_WIDTH];
		for (integer i = FIFO_ADDR_WIDTH-1; i >= 0; i = i-1)
			bin[i] = gray[i] ^ bin[i+1];
		gray2bin = bin;
	end
	endfunction

	// S-side write pointer update
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_aw_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (s_aw_valid && s_aw_ready) begin
				s_aw_wr_ptr <= s_aw_wr_ptr + 1'b1;
			end
		end
	end

	assign s_aw_wr_ptr_gray = bin2gray(s_aw_wr_ptr);

	// S-side: read M's read pointer (synchronized)
	reg [FIFO_ADDR_WIDTH:0] m_aw_rd_ptr_gray_s_r1, m_aw_rd_ptr_gray_s_r2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_aw_rd_ptr_gray_s_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			m_aw_rd_ptr_gray_s_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_aw_rd_ptr_gray_s_r1 <= m_aw_rd_ptr_gray;
			m_aw_rd_ptr_gray_s_r2 <= m_aw_rd_ptr_gray_s_r1;
		end
	end
	assign m_aw_rd_ptr_gray_s = m_aw_rd_ptr_gray_s_r2;

	// S-side: FIFO not full
	wire s_aw_not_full = (s_aw_wr_ptr_gray != m_aw_rd_ptr_gray_s);
	assign s_aw_ready = s_aw_not_full;

	// AW FIFO storage
	reg [AW_DATA_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];

	// S-side write to FIFO
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// No action
		end else begin
			if (s_aw_valid && s_aw_ready) begin
				aw_fifo_mem[s_aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= s_aw_data;
			end
		end
	end

	// M-side read pointer update
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_aw_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (m_aw_valid && M_AXI_AWREADY) begin
				m_aw_rd_ptr <= m_aw_rd_ptr + 1'b1;
			end
		end
	end

	assign m_aw_rd_ptr_gray = bin2gray(m_aw_rd_ptr);

	// M-side: read S's write pointer (synchronized)
	reg [FIFO_ADDR_WIDTH:0] s_aw_wr_ptr_gray_m_r1, s_aw_wr_ptr_gray_m_r2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_aw_wr_ptr_gray_m_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			s_aw_wr_ptr_gray_m_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_aw_wr_ptr_gray_m_r1 <= s_aw_wr_ptr_gray;
			s_aw_wr_ptr_gray_m_r2 <= s_aw_wr_ptr_gray_m_r1;
		end
	end
	assign s_aw_wr_ptr_gray_m = s_aw_wr_ptr_gray_m_r2;

	// M-side: FIFO not empty
	wire m_aw_not_empty = (m_aw_rd_ptr_gray != s_aw_wr_ptr_gray_m);

	// M-side AW output
	reg [AW_DATA_WIDTH-1:0] m_aw_data;
	wire m_aw_valid = m_aw_not_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_aw_data <= {AW_DATA_WIDTH{1'b0}};
		end else begin
			if (m_aw_valid) begin
				m_aw_data <= aw_fifo_mem[m_aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	// Decode AW data
	assign M_AXI_AWID    = m_aw_data[AW_DATA_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR  = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN   = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 -: 8];
	assign M_AXI_AWSIZE  = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-9 -: 3];
	assign M_AXI_AWBURST = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-12 -: 2];
	assign M_AXI_AWLOCK  = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-14];
	assign M_AXI_AWCACHE = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-15 -: 4];
	assign M_AXI_AWPROT  = m_aw_data[AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-19 -: 3];
	assign M_AXI_AWQOS   = m_aw_data[AW_DATA_WIDTH-4-: 4];

	assign M_AXI_AWVALID = m_aw_valid;

	// ========================================================================
	// W Channel: S -> M
	// ========================================================================
	// W data width
	localparam integer W_DATA_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;

	reg [W_DATA_WIDTH-1:0] s_w_data;
	reg s_w_valid;
	reg s_w_ready;

	assign S_AXI_WREADY = s_w_ready;

	// Capture W on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_w_valid <= 1'b0;
			s_w_data  <= {W_DATA_WIDTH{1'b0}};
		end else begin
			if (S_AXI_WVALID && s_w_ready) begin
				s_w_valid <= 1'b1;
				s_w_data  <= {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
			end else begin
				s_w_valid <= 1'b0;
			end
		end
	end

	// W FIFO: S-side write, M-side read
	reg [FIFO_ADDR_WIDTH:0] s_w_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] s_w_wr_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] m_w_rd_ptr_gray_s;

	reg [FIFO_ADDR_WIDTH:0] m_w_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] m_w_rd_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] s_w_wr_ptr_gray_m;

	// S-side write pointer update
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_w_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (s_w_valid && s_w_ready) begin
				s_w_wr_ptr <= s_w_wr_ptr + 1'b1;
			end
		end
	end

	assign s_w_wr_ptr_gray = bin2gray(s_w_wr_ptr);

	// S-side: read M's read pointer
	reg [FIFO_ADDR_WIDTH:0] m_w_rd_ptr_gray_s_r1, m_w_rd_ptr_gray_s_r2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_w_rd_ptr_gray_s_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			m_w_rd_ptr_gray_s_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_w_rd_ptr_gray_s_r1 <= m_w_rd_ptr_gray;
			m_w_rd_ptr_gray_s_r2 <= m_w_rd_ptr_gray_s_r1;
		end
	end
	assign m_w_rd_ptr_gray_s = m_w_rd_ptr_gray_s_r2;

	wire s_w_not_full = (s_w_wr_ptr_gray != m_w_rd_ptr_gray_s);
	assign s_w_ready = s_w_not_full;

	// W FIFO storage
	reg [W_DATA_WIDTH-1:0] w_fifo_mem [0:FIFO_DEPTH-1];

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// No action
		end else begin
			if (s_w_valid && s_w_ready) begin
				w_fifo_mem[s_w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= s_w_data;
			end
		end
	end

	// M-side read pointer update
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_w_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (m_w_valid && M_AXI_WREADY) begin
				m_w_rd_ptr <= m_w_rd_ptr + 1'b1;
			end
		end
	end

	assign m_w_rd_ptr_gray = bin2gray(m_w_rd_ptr);

	// M-side: read S's write pointer
	reg [FIFO_ADDR_WIDTH:0] s_w_wr_ptr_gray_m_r1, s_w_wr_ptr_gray_m_r2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_w_wr_ptr_gray_m_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			s_w_wr_ptr_gray_m_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_w_wr_ptr_gray_m_r1 <= s_w_wr_ptr_gray;
			s_w_wr_ptr_gray_m_r2 <= s_w_wr_ptr_gray_m_r1;
		end
	end
	assign s_w_wr_ptr_gray_m = s_w_wr_ptr_gray_m_r2;

	wire m_w_not_empty = (m_w_rd_ptr_gray != s_w_wr_ptr_gray_m);

	// M-side W output with one extra clock delay
	reg [W_DATA_WIDTH-1:0] m_w_data_r1;
	reg m_w_valid_r1;
	reg [W_DATA_WIDTH-1:0] m_w_data_r2;
	reg m_w_valid_r2;

	wire m_w_valid = m_w_valid_r2;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_w_data_r1 <= {W_DATA_WIDTH{1'b0}};
			m_w_valid_r1 <= 1'b0;
			m_w_data_r2 <= {W_DATA_WIDTH{1'b0}};
			m_w_valid_r2 <= 1'b0;
		end else begin
			// First stage: read from FIFO
			if (m_w_not_empty) begin
				m_w_data_r1 <= w_fifo_mem[m_w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				m_w_valid_r1 <= 1'b1;
			end else begin
				m_w_valid_r1 <= 1'b0;
			end

			// Second stage: hold for one extra clock
			m_w_data_r2 <= m_w_data_r1;
			m_w_valid_r2 <= m_w_valid_r1;
		end
	end

	assign M_AXI_WDATA  = m_w_data_r2[W_DATA_WIDTH-1 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB  = m_w_data_r2[C_S_AXI_DATA_WIDTH-1 -: (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST  = m_w_data_r2[0];
	assign M_AXI_WVALID = m_w_valid;

	// ========================================================================
	// B Channel: M -> S
	// ========================================================================
	// B data width
	localparam integer B_DATA_WIDTH = C_S_AXI_ID_WIDTH + 2;

	reg [B_DATA_WIDTH-1:0] m_b_data;
	reg m_b_valid;
	reg m_b_ready;

	assign M_AXI_BREADY = m_b_ready;

	// Capture B on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_b_valid <= 1'b0;
			m_b_data  <= {B_DATA_WIDTH{1'b0}};
		end else begin
			if (M_AXI_BVALID && m_b_ready) begin
				m_b_valid <= 1'b1;
				m_b_data  <= {M_AXI_BID, M_AXI_BRESP};
			end else begin
				m_b_valid <= 1'b0;
			end
		end
	end

	// B FIFO: M-side write, S-side read
	reg [FIFO_ADDR_WIDTH:0] m_b_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] m_b_wr_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] s_b_rd_ptr_gray_m;

	reg [FIFO_ADDR_WIDTH:0] s_b_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] s_b_rd_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] m_b_wr_ptr_gray_s;

	// M-side write pointer update
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_b_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (m_b_valid && m_b_ready) begin
				m_b_wr_ptr <= m_b_wr_ptr + 1'b1;
			end
		end
	end

	assign m_b_wr_ptr_gray = bin2gray(m_b_wr_ptr);

	// M-side: read S's read pointer
	reg [FIFO_ADDR_WIDTH:0] s_b_rd_ptr_gray_m_r1, s_b_rd_ptr_gray_m_r2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_b_rd_ptr_gray_m_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			s_b_rd_ptr_gray_m_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_b_rd_ptr_gray_m_r1 <= s_b_rd_ptr_gray;
			s_b_rd_ptr_gray_m_r2 <= s_b_rd_ptr_gray_m_r1;
		end
	end
	assign s_b_rd_ptr_gray_m = s_b_rd_ptr_gray_m_r2;

	wire m_b_not_full = (m_b_wr_ptr_gray != s_b_rd_ptr_gray_m);
	assign m_b_ready = m_b_not_full;

	// B FIFO storage
	reg [B_DATA_WIDTH-1:0] b_fifo_mem [0:FIFO_DEPTH-1];

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// No action
		end else begin
			if (m_b_valid && m_b_ready) begin
				b_fifo_mem[m_b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= m_b_data;
			end
		end
	end

	// S-side read pointer update
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_b_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (s_b_valid && S_AXI_BREADY) begin
				s_b_rd_ptr <= s_b_rd_ptr + 1'b1;
			end
		end
	end

	assign s_b_rd_ptr_gray = bin2gray(s_b_rd_ptr);

	// S-side: read M's write pointer
	reg [FIFO_ADDR_WIDTH:0] m_b_wr_ptr_gray_s_r1, m_b_wr_ptr_gray_s_r2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_b_wr_ptr_gray_s_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			m_b_wr_ptr_gray_s_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_b_wr_ptr_gray_s_r1 <= m_b_wr_ptr_gray;
			m_b_wr_ptr_gray_s_r2 <= m_b_wr_ptr_gray_s_r1;
		end
	end
	assign m_b_wr_ptr_gray_s = m_b_wr_ptr_gray_s_r2;

	wire s_b_not_empty = (s_b_rd_ptr_gray != m_b_wr_ptr_gray_s);

	// S-side B output
	reg [B_DATA_WIDTH-1:0] s_b_data;
	wire s_b_valid = s_b_not_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_b_data <= {B_DATA_WIDTH{1'b0}};
		end else begin
			if (s_b_valid) begin
				s_b_data <= b_fifo_mem[s_b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign S_AXI_BID    = s_b_data[B_DATA_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP  = s_b_data[C_S_AXI_ID_WIDTH-1 -: 2];
	assign S_AXI_BVALID = s_b_valid;

	// ========================================================================
	// AR Channel: S -> M
	// ========================================================================
	// AR data width
	localparam integer AR_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	reg [AR_DATA_WIDTH-1:0] s_ar_data;
	reg s_ar_valid;
	reg s_ar_ready;

	assign S_AXI_ARREADY = s_ar_ready;

	// Capture AR on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_ar_valid <= 1'b0;
			s_ar_data  <= {AR_DATA_WIDTH{1'b0}};
		end else begin
			if (S_AXI_ARVALID && s_ar_ready) begin
				s_ar_valid <= 1'b1;
				s_ar_data  <= {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST,
								S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
			end else begin
				s_ar_valid <= 1'b0;
			end
		end
	end

	// AR FIFO: S-side write, M-side read
	reg [FIFO_ADDR_WIDTH:0] s_ar_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] s_ar_wr_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] m_ar_rd_ptr_gray_s;

	reg [FIFO_ADDR_WIDTH:0] m_ar_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] m_ar_rd_ptr_gray;
	reg [FIFO_ADDR_WIDTH:0] s_ar_wr_ptr_gray_m;

	// S-side write pointer update
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_ar_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (s_ar_valid && s_ar_ready) begin
				s_ar_wr_ptr <= s_ar_wr_ptr + 1'b1;
			end
		end
	end

	assign s_ar_wr_ptr_gray = bin2gray(s_ar_wr_ptr);

	// S-side: read M's read pointer
	reg [FIFO_ADDR_WIDTH:0] m_ar_rd_ptr_gray_s_r1, m_ar_rd_ptr_gray_s_r2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_ar_rd_ptr_gray_s_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			m_ar_rd_ptr_gray_s_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_ar_rd_ptr_gray_s_r1 <= m_ar_rd_ptr_gray;
			m_ar_rd_ptr_gray_s_r2 <= m_ar_rd_ptr_gray_s_r1;
		end
	end
	assign m_ar_rd_ptr_gray_s = m_ar_rd_ptr_gray_s_r2;

	wire s_ar_not_full = (s_ar_wr_ptr_gray != m_ar_rd_ptr_gray_s);
	assign s_ar_ready = s_ar_not_full;

	// AR FIFO storage
	reg [AR_DATA_WIDTH-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// No action
		end else begin
			if (s_ar_valid && s_ar_ready) begin
				ar_fifo_mem[s_ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= s_ar_data;
			end
		end
	end

	// M-side read pointer update
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_ar_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (m_ar_valid && M_AXI_ARREADY) begin
				m_ar_rd_ptr <= m_ar_rd_ptr + 1'b1;
			end
		end
	end

	assign m_ar_rd_ptr_gray = bin2gray(m_ar_rd_ptr);

	// M-side: read S's write pointer
	reg [FIFO_ADDR_WIDTH:0] s_ar_wr_ptr_gray_m_r1, s_ar_wr_ptr_gray_m_r2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_ar_wr_ptr_gray_m_r1 <= {FIFO_ADDR_WIDTH+1{1'b0}};
			s_ar_wr_ptr_gray_m_r2 <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_ar_wr_ptr_gray_m_r1 <= s_ar_wr_ptr_gray;
			s_ar_wr_ptr_gray_m_r2 <= s_ar_wr_ptr_gray_m_r1;
		end
	end
	assign s_ar_wr_ptr_gray_m = s_ar_wr_ptr_gray_m_r2;

	wire m_ar_not_empty = (m_ar_rd_ptr_gray != s_ar_wr_ptr_gray_m);

	// M-side AR output
	reg [AR_DATA_WIDTH-1:0] m_ar_data;
	wire m_ar_valid = m_ar_not_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_ar_data <= {AR_DATA_WIDTH{1'b0}};
		end else begin
			if (m_ar_valid) begin
				m_ar_data <= ar_fifo_mem[m_ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign M_AXI_ARID    = m_ar_data[AR_DATA_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR  = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN   = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 -: 8];
	assign M_AXI_ARSIZE  = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-9 -: 3];
	assign M_AXI_ARBURST = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-12 -: 2];
	assign M_AXI_ARLOCK  = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-14];
	assign M_AXI_ARCACHE = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-15 -: 4];
	assign M_AXI_ARPROT  = m_ar_data[AR_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-19 -: 3];
	assign M_AXI_ARQOS   = m_ar_data[AR_DATA_WIDTH-4-: 4];

	assign M_AXI_ARVALID = m_ar_valid;

	// ========================================================================
	// R Channel: M -> S
	// ========================================================================
	// R data width
	localparam integer R_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	reg [R_DATA_WIDTH-1:0] m_r_data;
	reg m_r_valid;
	reg m_r_ready;

	assign M_AXI_RREADY = m_r_ready;

	// Capture R on M clock

module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 4,
	parameter	LGLEN = C_AXI_ADDR_WIDTH,
	parameter [0:0]	OPT_LOWPOWER = 1'b0,
	parameter [0:0]	OPT_CLKGATE = OPT_LOWPOWER,
	parameter	[C_AXI_ID_WIDTH-1:0]	AXI_READ_ID = 0,
	parameter	[C_AXI_ID_WIDTH-1:0]	AXI_WRITE_ID = 0,
	parameter	[7:0]			ABORT_KEY  = 8'h6d,
	localparam	ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
	localparam	AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
	localparam	LGLENW= LGLEN-ADDRLSB
) (
	input	wire	S_AXI_ACLK,
	input	wire	S_AXI_ARESETN,
	input	wire				S_AXIL_AWVALID,
	output	wire				S_AXIL_AWREADY,
	input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_AWADDR,
	input	wire 	[2:0]			S_AXIL_AWPROT,
	input	wire				S_AXIL_WVALID,
	output	wire				S_AXIL_WREADY,
	input	wire [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_WDATA,
	input	wire [C_AXIL_DATA_WIDTH/8-1:0]	S_AXIL_WSTRB,
	output	reg				S_AXIL_BVALID,
	input	wire				S_AXIL_BREADY,
	output	wire	[1:0]			S_AXIL_BRESP,
	input	wire				S_AXIL_ARVALID,
	output	wire				S_AXIL_ARREADY,
	input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_ARADDR,
	input	wire 	[2:0]			S_AXIL_ARPROT,
	output	reg				S_AXIL_RVALID,
	input	wire				S_AXIL_RREADY,
	output	reg [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_RDATA,
	output	wire	[1:0]			S_AXIL_RRESP,
	output	reg				M_AXI_AWVALID,
	input	wire				M_AXI_AWREADY,
	output	reg	[C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
	output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
	output	reg	[2:0]			M_AXI_AWSIZE,
	output	reg	[1:0]			M_AXI_AWBURST,
	output	reg				M_AXI_AWLOCK,
	output	reg	[3:0]			M_AXI_AWCACHE,
	output	reg	[2:0]			M_AXI_AWPROT,
	output	reg	[3:0]			M_AXI_AWQOS,
	output	reg				M_AXI_WVALID,
	input	wire				M_AXI_WREADY,
	output	reg	[C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
	output	reg [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
	output	reg				M_AXI_WLAST,
	input	wire				M_AXI_BVALID,
	output	reg				M_AXI_BREADY,
	input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
	input	wire	[1:0]			M_AXI_BRESP,
	output	reg				M_AXI_ARVALID,
	input	wire				M_AXI_ARREADY,
	output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
	output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
	output	wire	[2:0]			M_AXI_ARSIZE,
	output	wire	[1:0]			M_AXI_ARBURST,
	output	wire				M_AXI_ARLOCK,
	output	wire	[3:0]			M_AXI_ARCACHE,
	output	wire	[2:0]			M_AXI_ARPROT,
	output	wire	[3:0]			M_AXI_ARQOS,
	input	wire				M_AXI_RVALID,
	output	wire				M_AXI_RREADY,
	input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
	input	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
	input	wire				M_AXI_RLAST,
	input	wire	[1:0]			M_AXI_RRESP,
	output	reg				o_int
);

	// Register definitions
	localparam REG_SRC_ADDR = 0;
	localparam REG_DST_ADDR = 1;
	localparam REG_LENGTH   = 2;
	localparam REG_CONTROL  = 3;
	localparam REG_STATUS   = 4;
	localparam REG_DOORBELL = 5;

	// Control register bits
	localparam CTRL_START = 0;
	localparam CTRL_ABORT = 1;

	// Status register bits
	localparam STATUS_BUSY  = 0;
	localparam STATUS_DONE  = 1;
	localparam STATUS_ERROR = 2;

	// State machine states
	localparam ST_IDLE    = 3'd0;
	localparam ST_READ    = 3'd1;
	localparam ST_WRITE   = 3'd2;
	localparam ST_DONE    = 3'd3;
	localparam ST_ERROR   = 3'd4;

	// Internal signals
	reg [C_AXIL_DATA_WIDTH-1:0] reg_file [0:5];
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_wdata;
	reg [C_AXIL_DATA_WIDTH/8-1:0] reg_wstrb;
	reg reg_write;
	reg reg_read;
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_raddr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_rdata;
	reg reg_rvalid;

	// DMA control signals
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
	reg [LGLEN-1:0] length;
	reg [LGLEN-1:0] remaining;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [LGLEN-1:0] cur_len;
	reg [LGLEN-1:0] cur_remaining;
	reg [2:0] state;
	reg abort_req;
	reg done_flag;
	reg error_flag;

	// AXI write address channel
	reg [C_AXI_ADDR_WIDTH-1:0] aw_addr_reg;
	reg [2:0] aw_size_reg;
	reg [1:0] aw_burst_reg;
	reg [2:0] aw_prot_reg;
	reg aw_valid_reg;

	// AXI write data channel
	reg [C_AXI_DATA_WIDTH-1:0] wdata_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
	reg wlast_reg;
	reg wvalid_reg;

	// AXI write response channel
	reg bready_reg;

	// AXI read address channel
	reg [C_AXI_ADDR_WIDTH-1:0] ar_addr_reg;
	reg [2:0] ar_size_reg;
	reg [1:0] ar_burst_reg;
	reg [2:0] ar_prot_reg;
	reg ar_valid_reg;

	// AXI read data channel
	reg rready_reg;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_reg;
	reg rlast_reg;
	reg rvalid_reg;

	// FIFO for read data
	localparam FIFO_DEPTH = 1 << LGFIFO;
	reg [C_AXI_DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] fifo_wr_ptr;
	reg [LGFIFO:0] fifo_rd_ptr;
	reg fifo_wr_en;
	reg fifo_rd_en;
	wire fifo_full;
	wire fifo_empty;
	wire fifo_almost_full;
	wire fifo_almost_empty;

	assign fifo_full = (fifo_wr_ptr[LGFIFO] != fifo_rd_ptr[LGFIFO]) && 
	                   (fifo_wr_ptr[LGFIFO-1:0] == fifo_rd_ptr[LGFIFO-1:0]);
	assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);
	assign fifo_almost_full = (fifo_wr_ptr[LGFIFO] != fifo_rd_ptr[LGFIFO]) && 
	                          (fifo_wr_ptr[LGFIFO-1:0] == (fifo_rd_ptr[LGFIFO-1:0] + FIFO_DEPTH - 2));
	assign fifo_almost_empty = (fifo_wr_ptr[LGFIFO] == fifo_rd_ptr[LGFIFO]) && 
	                           (fifo_wr_ptr[LGFIFO-1:0] == (fifo_rd_ptr[LGFIFO-1:0] + 1));

	// AXI4-Lite write address channel
	reg awready_reg;
	reg awvalid_reg;

	// AXI4-Lite write data channel
	reg wready_reg;
	reg wvalid_reg_lite;

	// AXI4-Lite write response channel
	reg bvalid_reg;
	reg [1:0] bresp_reg;

	// AXI4-Lite read address channel
	reg arready_reg;
	reg arvalid_reg;

	// AXI4-Lite read data channel
	reg rvalid_reg_lite;
	reg [1:0] rresp_reg;

	// Interrupt
	reg int_reg;

	// Synchronous reset
	reg reset_sync;
	reg reset_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reset_sync <= 1'b1;
			reset_sync2 <= 1'b1;
		end else begin
			reset_sync <= 1'b0;
			reset_sync2 <= reset_sync;
		end
	end

	wire rst = reset_sync2;

	// Register file write
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			reg_file[REG_SRC_ADDR] <= 0;
			reg_file[REG_DST_ADDR] <= 0;
			reg_file[REG_LENGTH]   <= 0;
			reg_file[REG_CONTROL]  <= 0;
			reg_file[REG_STATUS]   <= 0;
			reg_file[REG_DOORBELL] <= 0;
		end else if (reg_write) begin
			case (reg_addr[C_AXIL_ADDR_WIDTH-1:0])
				0: reg_file[REG_SRC_ADDR] <= reg_wdata;
				1: reg_file[REG_DST_ADDR] <= reg_wdata;
				2: reg_file[REG_LENGTH]   <= reg_wdata;
				3: reg_file[REG_CONTROL]  <= reg_wdata;
				4: ; // Status is read-only
				5: reg_file[REG_DOORBELL] <= reg_wdata;
				default: ;
			endcase
		end
	end

	// Register file read
	always @(*) begin
		case (reg_raddr[C_AXIL_ADDR_WIDTH-1:0])
			0: reg_rdata = reg_file[REG_SRC_ADDR];
			1: reg_rdata = reg_file[REG_DST_ADDR];
			2: reg_rdata = reg_file[REG_LENGTH];
			3: reg_rdata = reg_file[REG_CONTROL];
			4: reg_rdata = {28'b0, error_flag, done_flag, state == ST_READ || state == ST_WRITE};
			5: reg_rdata = reg_file[REG_DOORBELL];
			default: reg_rdata = 0;
		endcase
	end

	// AXI4-Lite write address channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			awready_reg <= 1'b1;
			awvalid_reg <= 1'b0;
		end else begin
			if (awvalid_reg && S_AXIL_AWREADY) begin
				awvalid_reg <= 1'b0;
			end else if (!awvalid_reg && S_AXIL_AWVALID) begin
				awvalid_reg <= 1'b1;
				reg_addr <= S_AXIL_AWADDR;
			end
		end
	end

	assign S_AXIL_AWREADY = awready_reg;

	// AXI4-Lite write data channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			wready_reg <= 1'b0;
			wvalid_reg_lite <= 1'b0;
		end else begin
			if (wvalid_reg_lite && S_AXIL_WREADY) begin
				wvalid_reg_lite <= 1'b0;
				wready_reg <= 1'b0;
			end else if (!wvalid_reg_lite && S_AXIL_WVALID && awvalid_reg) begin
				wvalid_reg_lite <= 1'b1;
				wready_reg <= 1'b1;
				reg_wdata <= S_AXIL_WDATA;
				reg_wstrb <= S_AXIL_WSTRB;
			end
		end
	end

	assign S_AXIL_WREADY = wready_reg;

	// AXI4-Lite write response channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			S_AXIL_BVALID <= 1'b0;
			bresp_reg <= 2'b00;
		end else begin
			if (S_AXIL_BVALID && S_AXIL_BREADY) begin
				S_AXIL_BVALID <= 1'b0;
			end else if (!S_AXIL_BVALID && wvalid_reg_lite && S_AXIL_WREADY) begin
				S_AXIL_BVALID <= 1'b1;
				bresp_reg <= 2'b00;
				reg_write <= 1'b1;
			end else begin
				reg_write <= 1'b0;
			end
		end
	end

	assign S_AXIL_BRESP = bresp_reg;

	// AXI4-Lite read address channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			arready_reg <= 1'b1;
			arvalid_reg <= 1'b0;
		end else begin
			if (arvalid_reg && S_AXIL_ARREADY) begin
				arvalid_reg <= 1'b0;
			end else if (!arvalid_reg && S_AXIL_ARVALID) begin
				arvalid_reg <= 1'b1;
				reg_raddr <= S_AXIL_ARADDR;
			end
		end
	end

	assign S_AXIL_ARREADY = arready_reg;

	// AXI4-Lite read data channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			S_AXIL_RVALID <= 1'b0;
			S_AXIL_RDATA <= 0;
			rresp_reg <= 2'b00;
		end else begin
			if (S_AXIL_RVALID && S_AXIL_RREADY) begin
				S_AXIL_RVALID <= 1'b0;
			end else if (!S_AXIL_RVALID && arvalid_reg && S_AXIL_ARREADY) begin
				S_AXIL_RVALID <= 1'b1;
				S_AXIL_RDATA <= reg_rdata;
				rresp_reg <= 2'b00;
			end
		end
	end

	assign S_AXIL_RRESP = rresp_reg;

	// DMA state machine
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			state <= ST_IDLE;
			src_addr <= 0;
			dst_addr <= 0;
			length <= 0;
			remaining <= 0;
			cur_src_addr <= 0;
			cur_dst_addr <= 0;
			cur_len <= 0;
			cur_remaining <= 0;
			abort_req <= 1'b0;
			done_flag <= 1'b0;
			error_flag <= 1'b0;
			int_reg <= 1'b0;
		end else begin
			case (state)
				ST_IDLE: begin
					if (reg_file[REG_CONTROL][CTRL_START] && !done_flag && !error_flag) begin
						src_addr <= reg_file[REG_SRC_ADDR];
						dst_addr <= reg_file[REG_DST_ADDR];
						length <= reg_file[REG_LENGTH];
						remaining <= reg_file[REG_LENGTH];
						cur_src_addr <= reg_file[REG_SRC_ADDR];
						cur_dst_addr <= reg_file[REG_DST_ADDR];
						cur_len <= reg_file[REG_LENGTH];
						cur_remaining <= reg_file[REG_LENGTH];
						done_flag <= 1'b0;
						error_flag <= 1'b0;
						state <= ST_READ;
					end
					if (reg_file[REG_CONTROL][CTRL_ABORT]) begin
						abort_req <= 1'b1;
					end else begin
						abort_req <= 1'b0;
					end
				end
				ST_READ: begin
					if (abort_req) begin
						state <= ST_ERROR;
						error_flag <= 1'b1;
					end else if (cur_remaining == 0) begin
						state <= ST_WRITE;
					end else begin
						// Issue read
						ar_valid_reg <= 1'b1;
						ar_addr_reg <= cur_src_addr;
						ar_size_reg <= 3'b000; // Single beat
						ar_burst_reg <= 2'b01; // INCR
						ar_prot_reg <= 3'b000;
						rready_reg <= 1'b1;
					end
				end
				ST_WRITE: begin
					if (abort_req) begin
						state <= ST_ERROR;
						error_flag <= 1'b1;
					end else if (cur_remaining == 0) begin
						state <= ST_DONE;
						done_flag <= 1'b1;
						int_reg <= 1'b1;
					end else begin
						// Issue write
						aw_valid_reg <= 1'b1;
						aw_addr_reg <= cur_dst_addr;
						aw_size_reg <= 3'b000; // Single beat
						aw_burst_reg <= 2'b01; // INCR
						aw_prot_reg <= 3'b000;
						wvalid_reg <= 1'b1;
						wdata_reg <= fifo_mem[fifo_rd_ptr[LGFIFO-1:0]];
						wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
						wlast_reg <= 1'b1;
					end
				end
				ST_DONE: begin
					if (reg_file[REG_CONTROL][CTRL_START]) begin
						done_flag <= 1'b0;
						error_flag <= 1'b0;
						int_reg <= 1'b0;
						state <= ST_IDLE;
					end
				end
				ST_ERROR: begin
					if (reg_file[REG_CONTROL][CTRL_START]) begin
						done_flag <= 1'b0;
						error_flag <= 1'b0;
						int_reg <= 1'b0;
						state <= ST_IDLE;
					end
				end
				default: state <= ST_IDLE;
			endcase
		end
	end

	// AXI write address channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWID <= 0;
			M_AXI_AWADDR <= 0;
			M_AXI_AWSIZE <= 0;
			M_AXI_AWBURST <= 0;
			M_AXI_AWLOCK <= 0;
			M_AXI_AWCACHE <= 0;
			M_AXI_AWPROT <= 0;
			M_AXI_AWQOS <= 0;
		end else begin
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				M_AXI_AWVALID <= 1'b0;
			end else if (!M_AXI_AWVALID && aw_valid_reg) begin
				M_AXI_AWVALID <= 1'b1;
				M_AXI_AWID <= AXI_WRITE_ID;
				M_AXI_AWADDR <= aw_addr_reg;
				M_AXI_AWSIZE <= aw_size_reg;
				M_AXI_AWBURST <= aw_burst_reg;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'b0000;
				M_AXI_AWPROT <= aw_prot_reg;
				M_AXI_AWQOS <= 4'b0000;
			end
		end
	end

	// AXI write data channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA <= 0;
			M_AXI_WSTRB <= 0;
			M_AXI_WLAST <= 1'b0;
		end else begin
			if (M_AXI_WVALID && M_AXI_WREADY) begin
				M_AXI_WVALID <= 1'b0;
			end else if (!M_AXI_WVALID && wvalid_reg) begin
				M_AXI_WVALID <= 1'b1;
				M_AXI_WDATA <= wdata_reg;
				M_AXI_WSTRB <= wstrb_reg;
				M_AXI_WLAST <= wlast_reg;
			end
		end
	end

	// AXI write response channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			M_AXI_BREADY <= 1'b1;
		end else begin
			M_AXI_BREADY <= 1'b1;
		end
	end

	// AXI read address channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARID <= 0;
			M_AXI_ARADDR <= 0;
			M_AXI_ARSIZE <= 0;
			M_AXI_ARBURST <= 0;
			M_AXI_ARLOCK <= 0;
			M_AXI_ARCACHE <= 0;
			M_AXI_ARPROT <= 0;
			M_AXI_ARQOS <= 0;
		end else begin
			if (M_AXI_ARVALID && M_AXI_ARREADY) begin
				M_AXI_ARVALID <= 1'b0;
			end else if (!M_AXI_ARVALID && ar_valid_reg) begin
				M_AXI_ARVALID <= 1'b1;
				M_AXI_ARID <= AXI_READ_ID;
				M_AXI_ARADDR <= ar_addr_reg;
				M_AXI_ARSIZE <= ar_size_reg;
				M_AXI_ARBURST <= ar_burst_reg;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'b0000;
				M_AXI_ARPROT <= ar_prot_reg;
				M_AXI_ARQOS <= 4'b0000;
			end
		end
	end

	// AXI read data channel
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			M_AXI_RREADY <= 1'b0;
		end else begin
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				// Store data in FIFO
				fifo_mem[fifo_wr_ptr[LGFIFO-1:0]] <= M_AXI_RDATA;
				fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
				M_AXI_RREADY <= 1'b0;
			end else if (!M_AXI_RREADY && state == ST_READ && !fifo_full) begin
				M_AXI_RREADY <= 1'b1;
			end
		end
	end

	// FIFO read
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			fifo_rd_ptr <= 0;
		end else begin
			if (state == ST_WRITE && !fifo_empty && M_AXI_WVALID && M_AXI_WREADY) begin
				fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
			end
		end
	end

	// Update addresses and remaining count
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			cur_src_addr <= 0;
			cur_dst_addr <= 0;
			cur_remaining <= 0;
		end else begin
			if (state == ST_READ && M_AXI_RVALID && M_AXI_RREADY) begin
				cur_src_addr <= cur_src_addr + C_AXI_DATA_WIDTH/8;
				cur_remaining <= cur_remaining - 1;
			end
			if (state == ST_WRITE && M_AXI_WVALID && M_AXI_WREADY) begin
				cur_dst_addr <= cur_dst_addr + C_AXI_DATA_WIDTH/8;
				cur_remaining <= cur_remaining - 1;
			end
		end
	end

	// Clear valid flags after handshake
	always @(posedge S_AXI_ACLK or posedge rst) begin
		if (rst) begin
			aw_valid_reg <= 1'b0;
			wvalid_reg <= 1'b0;
			ar_valid_reg <= 1'b0;
		end else begin
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				aw_valid_reg <= 1'b0;
			end
			if (M_AXI_WVALID && M_AXI_WREADY) begin
				wvalid_reg <= 1'b0;
			end
			if (M_AXI_ARVALID && M_AXI_ARREADY) begin
				ar_valid_reg <= 1'b0;
			end
		end
	end

	// Interrupt output
	assign o_int = int_reg;

endmodule

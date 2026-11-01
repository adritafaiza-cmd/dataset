```verilog
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
	localparam REG_LEN      = 2;
	localparam REG_CONTROL  = 3;
	localparam REG_STATUS   = 4;
	localparam REG_ABORT    = 5;

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
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0] len_reg;
	reg [31:0] control_reg;
	reg [31:0] status_reg;

	reg [2:0] state;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [LGLEN-1:0] remaining_len;
	reg [LGLEN-1:0] burst_len;
	reg [LGLEN-1:0] burst_count;

	// FIFO for read data
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = C_AXI_DATA_WIDTH;
	reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] fifo_wr_ptr;
	reg [LGFIFO:0] fifo_rd_ptr;
	reg fifo_full;
	reg fifo_empty;

	// AXI write channel signals
	reg [C_AXI_DATA_WIDTH-1:0] wdata_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
	reg wlast_reg;

	// AXI read channel signals
	reg rdata_reg;
	reg rlast_reg;

	// AXI write address channel
	reg awvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] awid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] awaddr_reg;
	reg [2:0] awsize_reg;
	reg [1:0] awburst_reg;
	reg awlock_reg;
	reg [3:0] awcache_reg;
	reg [2:0] awprot_reg;
	reg [3:0] awqos_reg;

	// AXI read address channel
	reg arvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] arid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] araddr_reg;
	reg [2:0] arsize_reg;
	reg [1:0] arburst_reg;
	reg arlock_reg;
	reg [3:0] arcache_reg;
	reg [2:0] arprot_reg;
	reg [3:0] arqos_reg;

	// AXI write data channel
	reg wvalid_reg;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_out;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_out;
	reg wlast_out;

	// AXI write response channel
	reg bready_reg;

	// AXI read data channel
	reg rready_reg;

	// AXI read response
	reg [C_AXI_DATA_WIDTH-1:0] rdata_out;
	reg rlast_out;

	// AXI write response
	reg bvalid_reg;
	reg [1:0] bresp_reg;

	// AXI read response
	reg rvalid_reg;
	reg [1:0] rresp_reg;

	// AXI IDs
	wire [C_AXI_ID_WIDTH-1:0] axi_read_id = AXI_READ_ID;
	wire [C_AXI_ID_WIDTH-1:0] axi_write_id = AXI_WRITE_ID;

	// AXI size calculation
	wire [2:0] axi_size = $clog2(C_AXI_DATA_WIDTH) - 3;

	// AXI burst type
	wire [1:0] axi_burst = 2'b01; // INCR

	// AXI cache
	wire [3:0] axi_cache = 4'b0000;

	// AXI lock
	wire axi_lock = 1'b0;

	// AXI QoS
	wire [3:0] axi_qos = 4'b0000;

	// AXI prot
	wire [2:0] axi_prot = 3'b000;

	// FIFO full/empty
	assign fifo_full = (fifo_wr_ptr[LGFIFO] != fifo_rd_ptr[LGFIFO]) && 
	                   (fifo_wr_ptr[LGFIFO-1:0] == fifo_rd_ptr[LGFIFO-1:0]);
	assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);

	// AXI write address channel
	assign M_AXI_AWVALID = awvalid_reg;
	assign M_AXI_AWID = awid_reg;
	assign M_AXI_AWADDR = awaddr_reg;
	assign M_AXI_AWSIZE = awsize_reg;
	assign M_AXI_AWBURST = awburst_reg;
	assign M_AXI_AWLOCK = awlock_reg;
	assign M_AXI_AWCACHE = awcache_reg;
	assign M_AXI_AWPROT = awprot_reg;
	assign M_AXI_AWQOS = awqos_reg;

	// AXI write data channel
	assign M_AXI_WVALID = wvalid_reg;
	assign M_AXI_WDATA = wdata_out;
	assign M_AXI_WSTRB = wstrb_out;
	assign M_AXI_WLAST = wlast_out;

	// AXI write response channel
	assign M_AXI_BREADY = bready_reg;

	// AXI read address channel
	assign M_AXI_ARVALID = arvalid_reg;
	assign M_AXI_ARID = arid_reg;
	assign M_AXI_ARADDR = araddr_reg;
	assign M_AXI_ARSIZE = arsize_reg;
	assign M_AXI_ARBURST = arburst_reg;
	assign M_AXI_ARLOCK = arlock_reg;
	assign M_AXI_ARCACHE = arcache_reg;
	assign M_AXI_ARPROT = arprot_reg;
	assign M_AXI_ARQOS = arqos_reg;

	// AXI read data channel
	assign M_AXI_RREADY = rready_reg;

	// AXI read response
	assign S_AXIL_RDATA = rdata_out;
	assign S_AXIL_RRESP = rresp_reg;

	// AXI write response
	assign S_AXIL_BRESP = bresp_reg;

	// AXI Lite control port
	assign S_AXIL_AWREADY = (state == ST_IDLE) && !S_AXIL_AWVALID;
	assign S_AXIL_WREADY = (state == ST_IDLE) && !S_AXIL_WVALID;
	assign S_AXIL_ARREADY = (state == ST_IDLE) && !S_AXIL_ARVALID;

	// Interrupt
	assign o_int = status_reg[STATUS_DONE] || status_reg[STATUS_ERROR];

	// AXI Lite write address
	reg [C_AXIL_ADDR_WIDTH-1:0] awaddr_l;
	reg [2:0] awprot_l;

	// AXI Lite write data
	reg [C_AXIL_DATA_WIDTH-1:0] wdata_l;
	reg [C_AXIL_DATA_WIDTH/8-1:0] wstrb_l;

	// AXI Lite read address
	reg [C_AXIL_ADDR_WIDTH-1:0] araddr_l;
	reg [2:0] arprot_l;

	// AXI Lite read data
	reg [C_AXIL_DATA_WIDTH-1:0] rdata_l;
	reg [1:0] rresp_l;

	// AXI Lite write response
	reg bvalid_l;
	reg [1:0] bresp_l;

	// AXI Lite read response
	reg rvalid_l;

	// Register file
	reg [31:0] reg_file [0:7];

	// AXI Lite write address decode
	wire [C_AXIL_ADDR_WIDTH-1:0] awaddr_dec = S_AXIL_AWADDR;
	wire [2:0] awreg_sel = awaddr_dec[4:2];

	// AXI Lite read address decode
	wire [C_AXIL_ADDR_WIDTH-1:0] araddr_dec = S_AXIL_ARADDR;
	wire [2:0] arreg_sel = araddr_dec[4:2];

	// AXI Lite write data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_file[0] <= 32'b0;
			reg_file[1] <= 32'b0;
			reg_file[2] <= 32'b0;
			reg_file[3] <= 32'b0;
			reg_file[4] <= 32'b0;
			reg_file[5] <= 32'b0;
			reg_file[6] <= 32'b0;
			reg_file[7] <= 32'b0;
		end else if (S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY) begin
			case (awreg_sel)
				0: begin
					if (S_AXIL_WSTRB[0]) reg_file[0][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[0][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[0][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[0][31:24] <= S_AXIL_WDATA[31:24];
				end
				1: begin
					if (S_AXIL_WSTRB[0]) reg_file[1][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[1][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[1][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[1][31:24] <= S_AXIL_WDATA[31:24];
				end
				2: begin
					if (S_AXIL_WSTRB[0]) reg_file[2][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[2][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[2][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[2][31:24] <= S_AXIL_WDATA[31:24];
				end
				3: begin
					if (S_AXIL_WSTRB[0]) reg_file[3][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[3][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[3][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[3][31:24] <= S_AXIL_WDATA[31:24];
				end
				4: begin
					if (S_AXIL_WSTRB[0]) reg_file[4][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[4][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[4][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[4][31:24] <= S_AXIL_WDATA[31:24];
				end
				5: begin
					if (S_AXIL_WSTRB[0]) reg_file[5][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[5][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[5][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[5][31:24] <= S_AXIL_WDATA[31:24];
				end
				6: begin
					if (S_AXIL_WSTRB[0]) reg_file[6][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[6][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[6][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[6][31:24] <= S_AXIL_WDATA[31:24];
				end
				7: begin
					if (S_AXIL_WSTRB[0]) reg_file[7][7:0] <= S_AXIL_WDATA[7:0];
					if (S_AXIL_WSTRB[1]) reg_file[7][15:8] <= S_AXIL_WDATA[15:8];
					if (S_AXIL_WSTRB[2]) reg_file[7][23:16] <= S_AXIL_WDATA[23:16];
					if (S_AXIL_WSTRB[3]) reg_file[7][31:24] <= S_AXIL_WDATA[31:24];
				end
			endcase
		end
	end

	// AXI Lite read data
	always @(*) begin
		case (arreg_sel)
			0: rdata_l = reg_file[0];
			1: rdata_l = reg_file[1];
			2: rdata_l = reg_file[2];
			3: rdata_l = reg_file[3];
			4: rdata_l = reg_file[4];
			5: rdata_l = reg_file[5];
			6: rdata_l = reg_file[6];
			7: rdata_l = reg_file[7];
			default: rdata_l = 32'b0;
		endcase
	end

	// AXI Lite read response
	assign S_AXIL_RVALID = S_AXIL_ARVALID && S_AXIL_ARREADY;
	assign S_AXIL_RDATA = rdata_l;
	assign S_AXIL_RRESP = 2'b00;

	// AXI Lite write response
	assign S_AXIL_BVALID = S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY;
	assign S_AXIL_BRESP = 2'b00;

	// State machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= ST_IDLE;
			cur_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining_len <= {LGLEN{1'b0}};
			burst_len <= {LGLEN{1'b0}};
			burst_count <= {LGLEN{1'b0}};
			fifo_wr_ptr <= {LGFIFO+1{1'b0}};
			fifo_rd_ptr <= {LGFIFO+1{1'b0}};
			awvalid_reg <= 1'b0;
			awid_reg <= {C_AXI_ID_WIDTH{1'b0}};
			awaddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			awsize_reg <= 3'b0;
			awburst_reg <= 2'b0;
			awlock_reg <= 1'b0;
			awcache_reg <= 4'b0;
			awprot_reg <= 3'b0;
			awqos_reg <= 4'b0;
			arvalid_reg <= 1'b0;
			arid_reg <= {C_AXI_ID_WIDTH{1'b0}};
			araddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			arsize_reg <= 3'b0;
			arburst_reg <= 2'b0;
			arlock_reg <= 1'b0;
			arcache_reg <= 4'b0;
			arprot_reg <= 3'b0;
			arqos_reg <= 4'b0;
			wvalid_reg <= 1'b0;
			wdata_out <= {C_AXI_DATA_WIDTH{1'b0}};
			wstrb_out <= {C_AXI_DATA_WIDTH/8{1'b0}};
			wlast_out <= 1'b0;
			bready_reg <= 1'b0;
			rready_reg <= 1'b0;
			rdata_out <= {C_AXI_DATA_WIDTH{1'b0}};
			rlast_out <= 1'b0;
			bvalid_reg <= 1'b0;
			bresp_reg <= 2'b0;
			rvalid_reg <= 1'b0;
			rresp_reg <= 2'b0;
			status_reg <= 32'b0;
			o_int <= 1'b0;
		end else begin
			case (state)
				ST_IDLE: begin
					awvalid_reg <= 1'b0;
					arvalid_reg <= 1'b0;
					wvalid_reg <= 1'b0;
					bready_reg <= 1'b0;
					rready_reg <= 1'b0;
					bvalid_reg <= 1'b0;
					rvalid_reg <= 1'b0;
					
					// Check for start command
					if (reg_file[3][CTRL_START]) begin
						// Clear start bit
						reg_file[3][CTRL_START] <= 1'b0;
						// Initialize
						cur_src_addr <= reg_file[0];
						cur_dst_addr <= reg_file[1];
						remaining_len <= reg_file[2][LGLEN-1:0];
						burst_len <= reg_file[2][LGLEN-1:0];
						burst_count <= {LGLEN{1'b0}};
						fifo_wr_ptr <= {LGFIFO+1{1'b0}};
						fifo_rd_ptr <= {LGFIFO+1{1'b0}};
						status_reg[STATUS_BUSY] <= 1'b1;
						status_reg[STATUS_DONE] <= 1'b0;
						status_reg[STATUS_ERROR] <= 1'b0;
						o_int <= 1'b0;
						state <= ST_READ;
					end
				end
				ST_READ: begin
					// Issue read address
					if (!arvalid_reg && !fifo_full) begin
						arvalid_reg <= 1'b1;
						arid_reg <= axi_read_id;
						araddr_reg <= cur_src_addr;
						arsize_reg <= axi_size;
						arburst_reg <= axi_burst;
						arlock_reg <= axi_lock;
						arcache_reg <= axi_cache;
						arprot_reg <= axi_prot;
						arqos_reg <= axi_qos;
					end
					
					// Handle read data
					if (M_AXI_RVALID && rready_reg) begin
						// Store in FIFO
						fifo_mem[fifo_wr_ptr[LGFIFO-1:0]] <= M_AXI_RDATA;
						fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
						cur_src_addr <= cur_src_addr + C_AXI_DATA_WIDTH/8;
						remaining_len <= remaining_len - 1'b1;
						burst_count <= burst_count + 1'b1;
						
						// Check if burst complete
						if (M_AXI_RLAST) begin
							arvalid_reg <= 1'b0;
							rready_reg <= 1'b0;
							
							// Check if all data transferred
							if (remaining_len == 1'b0) begin
								state <= ST_DONE;
								status_reg[STATUS_BUSY] <= 1'b0;
								status_reg[STATUS_DONE] <= 1'b1;
								o_int <= 1'b1;
							end else begin
								state <= ST_WRITE;
							end
						end
					end else if (M_AXI_RVALID) begin
						rready_reg <= 1'b1;
					end
				end
				ST_WRITE: begin
					// Issue write address
					if (!awvalid_reg && !fifo_empty) begin
						awvalid_reg <= 1'b1;
						awid_reg <= axi_write_id;
						awaddr_reg <= cur_dst_addr;
						awsize_reg <= axi_size;
						awburst_reg <= axi_burst;
						awlock_reg <= axi_lock;
						awcache_reg <= axi_cache;
						awprot_reg <= axi_prot;
						awqos_reg <= axi_qos;
					end
					
					// Handle write data
					if (!wvalid_reg && !fifo_empty) begin
						wvalid_reg <= 1'b1;
						wdata_out <= fifo_mem[fifo_rd_ptr[LGFIFO-1:0]];
						wstrb_out <= {C_AXI_DATA_WIDTH/8{1'b1}};
						wlast_out <= 1'b0;
					end
					
					if (M_AXI_WREADY && wvalid_reg) begin
						fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
						cur_dst_addr <= cur_dst_addr + C_AXI_DATA_WIDTH/8;
						wvalid_reg <= 1'b0;
						
						// Check if burst complete
						if (burst_count == burst_len - 1'b1) begin
							wlast_out <= 1'b1;
							awvalid_reg <= 1'b0;
							
							// Check if all data transferred
							if (remaining_len == 1'b0) begin
								state <= ST_DONE;
								status_reg[STATUS_BUSY] <= 1'b0;
								status_reg[STATUS_DONE] <= 1'b1;
								o_int <= 1'b1;
							end else begin
								state <= ST_READ;
								burst_count <= {LGLEN{1'b0}};
							end
						end
					end
					
					// Handle write response
					if (M_AXI_BVALID && bready_reg) begin
						bvalid_reg <= 1'b0;
						bresp_reg <= M_AXI_BRESP;
						bready_reg <= 1'b0;
					end else if (M_AXI_BVALID) begin
						bready_reg <= 1'b1;
					end
				end
				ST_DONE: begin
					// Wait for interrupt to be cleared
					if (reg_file[3][CTRL_ABORT]) begin
						reg_file[3][CTRL_ABORT] <= 1'b0;
						state <= ST_IDLE;
						status_reg[STATUS_BUSY] <= 1'b0;
						status_reg[STATUS_DONE] <= 1'b0;
						status_reg[STATUS_ERROR] <= 1'b0;
						o_int <= 1'b0;
					end
				end
				ST_ERROR: begin
					// Wait for interrupt to be cleared
					if (reg_file[3][CTRL_ABORT]) begin
						reg_file[3][CTRL_ABORT] <= 1'b0;
						state <= ST_IDLE;
						status_reg[STATUS_BUSY] <= 1'b0;
						status_reg[STATUS_DONE] <= 1'b0;
						status_reg[STATUS_ERROR] <= 1'b0;
						o_int <= 1'b0;
					end
				end
				default: state <= ST_IDLE;
			endcase
		end
	end

	// AXI Lite write address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awaddr_l <= {C_AXIL_ADDR_WIDTH{1'b0}};
			awprot_l <= 3'b0;
		end else if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
			awaddr_l <= S_AXIL_AWADDR;
			awprot_l <= S_AXIL_AWPROT;
		end
	end

	// AXI Lite write data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			wdata_l <= {C_AXIL_DATA_WIDTH{1'b0}};
			wstrb_l <= {C_AXIL_DATA_WIDTH/8{1'b0}};
		end else if (S_AXIL_WVALID && S_AXIL_WREADY) begin
			wdata_l <= S_AXIL_WDATA;
			wstrb_l <= S_AXIL_WSTRB;
		end
	end

	// AXI Lite read address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			araddr_l <= {C_AXIL_ADDR_WIDTH{1'b0}};
			arprot_l <= 3'b0;
		end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
			araddr_l <= S_AXIL_ARADDR;
			arprot_l <= S_AXIL_ARPROT;
		end
	end

	// AXI Lite read data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			rdata_l <= {C_AXIL_DATA_WIDTH{1'b0}};
			rresp_l <= 2'b0;
		end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
			rdata_l <= rdata_l;
			rresp_l <= 2'b0;
		end
	end

	// AXI Lite write response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			bvalid_l <= 1'b0;
			bresp_l <= 2'b0;
		end else if (S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY) begin
			bvalid_l <= 1'b1;
			bresp_l <= 2'b0;
		end else if (S_AXIL_BREADY) begin
			bvalid_l <= 1'b0;
		end
	end

	// AXI Lite read response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			rvalid_l <= 1'b0;
		end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
			rvalid_l <= 1'b1;
		end else if (S_AXIL_RREADY) begin
			rvalid_l <= 1'b0;
		end
	end

	// AXI write address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awvalid_reg <= 1'b0;
			awid_reg <= {C_AXI_ID_WIDTH{1'b0}};
			awaddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			awsize_reg <= 3'b0;
			awburst_reg <= 2'b0;
			awlock_reg <= 1'b0;
			awcache_reg <= 4'b0;
			awprot_reg <= 3'b0;
			awqos_reg <= 4'b0;
		end else begin
			if (M_AXI_AWREADY && awvalid_reg) begin
				awvalid_reg <= 1'b0;
			end
		end
	end

	// AXI read address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			arvalid_reg <= 1'b0;
			arid_reg <= {C_AXI_ID_WIDTH{1'b0}};
			araddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			arsize_reg <= 3'b0;
			arburst_reg <= 2'b0;
			arlock_reg <= 1'b0;
			arcache_reg <= 4'b0;
			arprot_reg <= 3'b0;
			arqos_reg <= 4'b0;
		end else begin
			if (M_AXI_ARREADY && arvalid_reg) begin
				arvalid_reg <= 1'b0;
			end
		end
	end

	// AXI write data channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AX
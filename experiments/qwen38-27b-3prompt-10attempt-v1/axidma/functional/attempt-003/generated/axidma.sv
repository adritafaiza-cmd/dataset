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
	localparam REG_ABORT    = 5;

	// Control register bits
	localparam CTRL_START = 0;
	localparam CTRL_ABORT = 1;

	// Status register bits
	localparam STAT_BUSY  = 0;
	localparam STAT_DONE  = 1;
	localparam STAT_ERROR = 2;

	// State machine states
	localparam ST_IDLE    = 3'd0;
	localparam ST_READ    = 3'd1;
	localparam ST_WRITE   = 3'd2;
	localparam ST_DONE    = 3'd3;
	localparam ST_ERROR   = 3'd4;

	// Internal signals
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0]            length_reg;
	reg [31:0]                 control_reg;
	reg [31:0]                 status_reg;

	reg [2:0]  state;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [LGLEN-1:0]            remaining;

	// AXI write channel
	reg  [C_AXI_ADDR_WIDTH-1:0] aw_addr;
	reg  [2:0]                  aw_size;
	reg  [1:0]                  aw_burst;
	reg  [2:0]                  aw_prot;
	reg  [C_AXI_DATA_WIDTH-1:0] w_data;
	reg  [C_AXI_DATA_WIDTH/8-1:0] w_strb;
	reg                         w_last;
	reg                         b_ready;

	// AXI read channel
	reg  [C_AXI_ADDR_WIDTH-1:0] ar_addr;
	reg  [2:0]                  ar_size;
	reg  [1:0]                  ar_burst;
	reg  [2:0]                  ar_prot;
	reg                         r_ready;

	// FIFO for read data
	localparam FIFO_DEPTH = 1 << LGFIFO;
	reg [C_AXI_DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO-1:0] fifo_wr_ptr;
	reg [LGFIFO-1:0] fifo_rd_ptr;
	reg [LGFIFO:0]   fifo_count;

	// AXI handshake signals
	wire aw_handshake = M_AXI_AWVALID & M_AXI_AWREADY;
	wire w_handshake  = M_AXI_WVALID & M_AXI_WREADY;
	wire b_handshake  = M_AXI_BVALID & M_AXI_BREADY;
	wire ar_handshake = M_AXI_ARVALID & M_AXI_ARREADY;
	wire r_handshake  = M_AXI_RVALID & M_AXI_RREADY;

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

	// AXI IDs
	wire [C_AXI_ID_WIDTH-1:0] axi_aw_id = AXI_WRITE_ID;
	wire [C_AXI_ID_WIDTH-1:0] axi_ar_id = AXI_READ_ID;

	// AXI response
	wire [1:0] axi_bresp = M_AXI_BRESP;
	wire [1:0] axi_rresp = M_AXI_RRESP;

	// AXI Lite response
	assign S_AXIL_BRESP = 2'b00;
	assign S_AXIL_RRESP = 2'b00;

	// AXI Lite ready signals
	assign S_AXIL_AWREADY = 1'b1;
	assign S_AXIL_WREADY  = 1'b1;
	assign S_AXIL_ARREADY = 1'b1;

	// AXI Lite valid signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXIL_BVALID <= 1'b0;
			S_AXIL_RVALID <= 1'b0;
			S_AXIL_RDATA  <= {C_AXIL_DATA_WIDTH{1'b0}};
		end else begin
			// Handle AXI Lite writes
			if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
				case (S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:2])
					REG_SRC_ADDR: src_addr_reg <= S_AXIL_WDATA[C_AXI_ADDR_WIDTH-1:0];
					REG_DST_ADDR: dst_addr_reg <= S_AXIL_WDATA[C_AXI_ADDR_WIDTH-1:0];
					REG_LENGTH:   length_reg   <= S_AXIL_WDATA[LGLEN-1:0];
					REG_CONTROL:  control_reg  <= S_AXIL_WDATA;
					REG_ABORT:    begin
						if (S_AXIL_WDATA[7:0] == ABORT_KEY) begin
							control_reg[CTRL_ABORT] <= 1'b1;
						end
					end
					default: ;
				endcase
			end

			// Handle AXI Lite reads
			if (S_AXIL_ARVALID) begin
				S_AXIL_RVALID <= 1'b1;
				case (S_AXIL_ARADDR[C_AXIL_ADDR_WIDTH-1:2])
					REG_SRC_ADDR: S_AXIL_RDATA <= {C_AXIL_DATA_WIDTH{1'b0}} | src_addr_reg;
					REG_DST_ADDR: S_AXIL_RDATA <= {C_AXIL_DATA_WIDTH{1'b0}} | dst_addr_reg;
					REG_LENGTH:   S_AXIL_RDATA <= {C_AXIL_DATA_WIDTH{1'b0}} | length_reg;
					REG_CONTROL:  S_AXIL_RDATA <= control_reg;
					REG_STATUS:   S_AXIL_RDATA <= status_reg;
					default:      S_AXIL_RDATA <= {C_AXIL_DATA_WIDTH{1'b0}};
				endcase
			end else begin
				S_AXIL_RVALID <= 1'b0;
			end

			// Handle AXI Lite write response
			if (S_AXIL_BREADY) begin
				S_AXIL_BVALID <= 1'b0;
			end else if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
				S_AXIL_BVALID <= 1'b1;
			end
		end
	end

	// DMA state machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state        <= ST_IDLE;
			cur_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining    <= {LGLEN{1'b0}};
			o_int        <= 1'b0;
			status_reg   <= {32{1'b0}};
		end else begin
			// Check for abort
			if (control_reg[CTRL_ABORT]) begin
				state      <= ST_IDLE;
				o_int      <= 1'b0;
				status_reg <= {31{1'b0}} | (1'b1 << STAT_ERROR);
				control_reg[CTRL_ABORT] <= 1'b0;
			end else begin
				case (state)
					ST_IDLE: begin
						if (control_reg[CTRL_START]) begin
							state        <= ST_READ;
							cur_src_addr <= src_addr_reg;
							cur_dst_addr <= dst_addr_reg;
							remaining    <= length_reg;
							status_reg   <= {31{1'b0}} | (1'b1 << STAT_BUSY);
							o_int        <= 1'b0;
							control_reg[CTRL_START] <= 1'b0;
						end
					end

					ST_READ: begin
						// Issue read request
						if (M_AXI_ARREADY && remaining > 0) begin
							M_AXI_ARVALID <= 1'b1;
							M_AXI_ARADDR  <= cur_src_addr;
						end

						if (ar_handshake) begin
							M_AXI_ARVALID <= 1'b0;
							cur_src_addr  <= cur_src_addr + C_AXI_DATA_WIDTH/8;
						end

						// Receive read data
						if (r_handshake) begin
							fifo_mem[fifo_wr_ptr] <= M_AXI_RDATA;
							fifo_wr_ptr           <= fifo_wr_ptr + 1'b1;
							fifo_count            <= fifo_count + 1'b1;
						end

						// Check if read burst is complete
						if (M_AXI_RLAST && r_handshake) begin
							// Move to write state
							state <= ST_WRITE;
						end
					end

					ST_WRITE: begin
						// Issue write request
						if (M_AXI_AWREADY && fifo_count > 0) begin
							M_AXI_AWVALID <= 1'b1;
							M_AXI_AWADDR  <= cur_dst_addr;
						end

						if (aw_handshake) begin
							M_AXI_AWVALID <= 1'b0;
						end

						// Send write data
						if (M_AXI_WREADY && fifo_count > 0) begin
							M_AXI_WVALID <= 1'b1;
							M_AXI_WDATA  <= fifo_mem[fifo_rd_ptr];
							M_AXI_WSTRB  <= {C_AXI_DATA_WIDTH/8{1'b1}};
							M_AXI_WLAST  <= (fifo_count == 1'b1);
						end

						if (w_handshake) begin
							M_AXI_WVALID <= 1'b0;
							fifo_rd_ptr  <= fifo_rd_ptr + 1'b1;
							fifo_count   <= fifo_count - 1'b1;
							cur_dst_addr <= cur_dst_addr + C_AXI_DATA_WIDTH/8;
						end

						// Check if write burst is complete
						if (b_handshake) begin
							// Check if all data is transferred
							if (remaining <= C_AXI_DATA_WIDTH/8) begin
								state      <= ST_DONE;
								o_int      <= 1'b1;
								status_reg <= {30{1'b0}} | (1'b1 << STAT_DONE);
							end else begin
								remaining <= remaining - C_AXI_DATA_WIDTH/8;
								state     <= ST_READ;
							end
						end
					end

					ST_DONE: begin
						o_int <= 1'b0;
						state <= ST_IDLE;
					end

					ST_ERROR: begin
						o_int <= 1'b0;
						state <= ST_IDLE;
					end

					default: state <= ST_IDLE;
				endcase
			end
		end
	end

	// AXI write address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWID    <= {C_AXI_ID_WIDTH{1'b0}};
			M_AXI_AWADDR  <= {C_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWSIZE  <= {3{1'b0}};
			M_AXI_AWBURST <= {2{1'b0}};
			M_AXI_AWLOCK  <= 1'b0;
			M_AXI_AWCACHE <= {4{1'b0}};
			M_AXI_AWPROT  <= {3{1'b0}};
			M_AXI_AWQOS   <= {4{1'b0}};
		end else begin
			M_AXI_AWID    <= axi_aw_id;
			M_AXI_AWSIZE  <= axi_size;
			M_AXI_AWBURST <= axi_burst;
			M_AXI_AWLOCK  <= axi_lock;
			M_AXI_AWCACHE <= axi_cache;
			M_AXI_AWPROT  <= ar_prot;
			M_AXI_AWQOS   <= axi_qos;
		end
	end

	// AXI write data channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA  <= {C_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB  <= {C_AXI_DATA_WIDTH/8{1'b0}};
			M_AXI_WLAST  <= 1'b0;
		end
	end

	// AXI write response channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_BREADY <= 1'b0;
		end else begin
			M_AXI_BREADY <= (state == ST_WRITE);
		end
	end

	// AXI read address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARADDR  <= {C_AXI_ADDR_WIDTH{1'b0}};
		end else begin
			M_AXI_ARID    <= axi_ar_id;
			M_AXI_ARSIZE  <= axi_size;
			M_AXI_ARBURST <= axi_burst;
			M_AXI_ARLOCK  <= axi_lock;
			M_AXI_ARCACHE <= axi_cache;
			M_AXI_ARPROT  <= ar_prot;
			M_AXI_ARQOS   <= axi_qos;
		end
	end

	// AXI read data channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_RREADY <= 1'b0;
		end else begin
			M_AXI_RREADY <= (state == ST_READ);
		end
	end

	// FIFO pointer reset
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			fifo_wr_ptr <= {LGFIFO{1'b0}};
			fifo_rd_ptr <= {LGFIFO{1'b0}};
			fifo_count  <= {(LGFIFO+1){1'b0}};
		end
	end

endmodule

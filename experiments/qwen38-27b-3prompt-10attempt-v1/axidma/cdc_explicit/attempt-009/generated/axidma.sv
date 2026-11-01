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

	// Register map
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
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0]            length_reg;
	reg [1:0]                  ctrl_reg;
	reg [2:0]                  status_reg;

	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [LGLEN-1:0]            remaining_len;

	reg [2:0] state;
	reg       dma_active;
	reg       abort_req;

	// AXI4-Lite write address channel
	reg       awaddr_valid;
	reg [C_AXIL_ADDR_WIDTH-1:0] awaddr_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] wdata_reg;
	reg [C_AXIL_DATA_WIDTH/8-1:0] wstrb_reg;
	reg       wdata_valid;
	reg       bvalid_reg;
	reg [1:0] bresp_reg;

	// AXI4-Lite read address channel
	reg       araddr_valid;
	reg [C_AXIL_ADDR_WIDTH-1:0] araddr_reg;
	reg       rvalid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;
	reg [1:0] rresp_reg;

	// AXI4 master write address channel
	reg       awvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] awid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] awaddr_reg_m;
	reg [2:0] awsize_reg;
	reg [1:0] awburst_reg;
	reg       awlock_reg;
	reg [3:0] awcache_reg;
	reg [2:0] awprot_reg;
	reg [3:0] awqos_reg;

	// AXI4 master write data channel
	reg       wvalid_reg;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_reg_m;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg_m;
	reg       wlast_reg;

	// AXI4 master write response channel
	reg       bready_reg;
	reg       bvalid_pending;
	reg [1:0] bresp_pending;

	// AXI4 master read address channel
	reg       arvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] arid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] araddr_reg_m;
	reg [2:0] arsize_reg;
	reg [1:0] arburst_reg;
	reg       arlock_reg;
	reg [3:0] arcache_reg;
	reg [2:0] arprot_reg;
	reg [3:0] arqos_reg;

	// AXI4 master read data channel
	reg       rready_reg;
	reg       rvalid_pending;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_pending;
	reg       rlast_pending;
	reg [1:0] rresp_pending;

	// Burst tracking
	reg [3:0] burst_beats;
	reg [3:0] burst_beat_count;
	reg       burst_last_beat;

	// FIFO for read data (simple shift register based)
	reg [C_AXI_DATA_WIDTH-1:0] fifo_mem [0:(1<<LGFIFO)-1];
	reg [LGFIFO:0] fifo_wr_ptr;
	reg [LGFIFO:0] fifo_rd_ptr;
	reg [LGFIFO:0] fifo_count;
	reg       fifo_wr_en;
	reg       fifo_rd_en;
	reg       fifo_full;
	reg       fifo_empty;

	// AXI4-Lite ready signals
	wire s_axil_awready;
	wire s_axil_wready;
	wire s_axil_arready;

	// AXI4-Lite write address decode
	wire [C_AXIL_ADDR_WIDTH-1:0] awaddr_dec = S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:0];
	wire [1:0] awreg_sel = awaddr_dec[1:0];

	// AXI4-Lite read address decode
	wire [C_AXIL_ADDR_WIDTH-1:0] araddr_dec = S_AXIL_ARADDR[C_AXIL_ADDR_WIDTH-1:0];
	wire [1:0] arreg_sel = araddr_dec[1:0];

	// FIFO logic
	assign fifo_full  = (fifo_count == (1<<LGFIFO));
	assign fifo_empty = (fifo_count == 0);

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			fifo_wr_ptr <= 0;
			fifo_rd_ptr <= 0;
			fifo_count  <= 0;
		end else begin
			if (fifo_wr_en && !fifo_rd_en) begin
				fifo_count <= fifo_count + 1;
			end else if (!fifo_wr_en && fifo_rd_en) begin
				fifo_count <= fifo_count - 1;
			end
			if (fifo_wr_en) begin
				fifo_wr_ptr <= fifo_wr_ptr + 1;
			end
			if (fifo_rd_en) begin
				fifo_rd_ptr <= fifo_rd_ptr + 1;
			end
		end
	end

	// AXI4-Lite write address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awaddr_valid <= 0;
			awaddr_reg   <= 0;
			wdata_valid  <= 0;
			wdata_reg    <= 0;
			wstrb_reg    <= 0;
			bvalid_reg   <= 0;
			bresp_reg    <= 0;
		end else begin
			if (S_AXIL_AWVALID && s_axil_awready) begin
				awaddr_valid <= 1;
				awaddr_reg   <= S_AXIL_AWADDR;
			end else if (awaddr_valid && wdata_valid) begin
				awaddr_valid <= 0;
			end

			if (S_AXIL_WVALID && s_axil_wready) begin
				wdata_valid <= 1;
				wdata_reg   <= S_AXIL_WDATA;
				wstrb_reg   <= S_AXIL_WSTRB;
			end else if (awaddr_valid && wdata_valid) begin
				wdata_valid <= 0;
			end

			if (awaddr_valid && wdata_valid) begin
				case (awreg_sel)
					2'd0: src_addr_reg <= wdata_reg;
					2'd1: dst_addr_reg <= wdata_reg;
					2'd2: length_reg   <= wdata_reg[LGLEN-1:0];
					2'd3: begin
						if (wstrb_reg[0]) ctrl_reg[CTRL_START] <= wdata_reg[CTRL_START];
						if (wstrb_reg[0]) ctrl_reg[CTRL_ABORT] <= wdata_reg[CTRL_ABORT];
					end
					default: ;
				endcase
				bvalid_reg <= 1;
				bresp_reg  <= 2'b00;
			end

			if (bvalid_reg && S_AXIL_BREADY) begin
				bvalid_reg <= 0;
			end
		end
	end

	assign s_axil_awready = !awaddr_valid;
	assign s_axil_wready  = !wdata_valid;
	assign S_AXIL_BVALID  = bvalid_reg;
	assign S_AXIL_BRESP   = bresp_reg;

	// AXI4-Lite read address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			araddr_valid <= 0;
			araddr_reg   <= 0;
			rvalid_reg   <= 0;
			rdata_reg    <= 0;
			rresp_reg    <= 0;
		end else begin
			if (S_AXIL_ARVALID && s_axil_arready) begin
				araddr_valid <= 1;
				araddr_reg   <= S_AXIL_ARADDR;
			end else if (araddr_valid && rvalid_reg) begin
				araddr_valid <= 0;
			end

			if (araddr_valid) begin
				case (arreg_sel)
					2'd0: rdata_reg <= src_addr_reg;
					2'd1: rdata_reg <= dst_addr_reg;
					2'd2: rdata_reg <= {16'h0, length_reg};
					2'd3: rdata_reg <= {28'h0, status_reg, ctrl_reg};
					2'd4: rdata_reg <= {28'h0, status_reg};
					default: rdata_reg <= 0;
				endcase
				rvalid_reg <= 1;
				rresp_reg  <= 2'b00;
			end

			if (rvalid_reg && S_AXIL_RREADY) begin
				rvalid_reg <= 0;
			end
		end
	end

	assign s_axil_arready = !araddr_valid;
	assign S_AXIL_RVALID  = rvalid_reg;
	assign S_AXIL_RDATA   = rdata_reg;
	assign S_AXIL_RRESP   = rresp_reg;

	// DMA state machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state          <= ST_IDLE;
			dma_active     <= 0;
			abort_req      <= 0;
			cur_src_addr   <= 0;
			cur_dst_addr   <= 0;
			remaining_len  <= 0;
			status_reg     <= 0;
			o_int          <= 0;
			awvalid_reg    <= 0;
			awid_reg       <= 0;
			awaddr_reg_m   <= 0;
			awsize_reg     <= 0;
			awburst_reg    <= 0;
			awlock_reg     <= 0;
			awcache_reg    <= 0;
			awprot_reg     <= 0;
			awqos_reg      <= 0;
			wvalid_reg     <= 0;
			wdata_reg_m    <= 0;
			wstrb_reg_m    <= 0;
			wlast_reg      <= 0;
			bready_reg     <= 0;
			bvalid_pending <= 0;
			bresp_pending  <= 0;
			arvalid_reg    <= 0;
			arid_reg       <= 0;
			araddr_reg_m   <= 0;
			arsize_reg     <= 0;
			arburst_reg    <= 0;
			arlock_reg     <= 0;
			arcache_reg    <= 0;
			arprot_reg     <= 0;
			arqos_reg      <= 0;
			rready_reg     <= 0;
			rvalid_pending <= 0;
			rdata_pending  <= 0;
			rlast_pending  <= 0;
			rresp_pending  <= 0;
			burst_beats    <= 0;
			burst_beat_count <= 0;
			burst_last_beat <= 0;
			fifo_wr_en     <= 0;
			fifo_rd_en     <= 0;
		end else begin
			// Default assignments
			fifo_wr_en <= 0;
			fifo_rd_en <= 0;

			case (state)
				ST_IDLE: begin
					dma_active <= 0;
					abort_req  <= 0;
					status_reg <= 0;
					o_int      <= 0;
					awvalid_reg <= 0;
					wvalid_reg  <= 0;
					bready_reg  <= 0;
					arvalid_reg <= 0;
					rready_reg  <= 0;

					if (ctrl_reg[CTRL_START] && !dma_active) begin
						state        <= ST_READ;
						dma_active   <= 1;
						cur_src_addr <= src_addr_reg;
						cur_dst_addr <= dst_addr_reg;
						remaining_len <= length_reg;
						status_reg   <= status_reg | (1 << STATUS_BUSY);
						// Start first read burst
						arvalid_reg  <= 1;
						arid_reg     <= AXI_READ_ID;
						araddr_reg_m <= cur_src_addr;
						arsize_reg   <= $clog2(C_AXI_DATA_WIDTH)-3;
						arburst_reg  <= 2'b01; // INCR
						arlock_reg   <= 0;
						arcache_reg  <= 4'b0011;
						arprot_reg   <= 3'b000;
						arqos_reg    <= 4'b0000;
						burst_beats  <= 4;
						burst_beat_count <= 0;
						burst_last_beat  <= 0;
					end
				end

				ST_READ: begin
					// Handle read address handshake
					if (arvalid_reg && M_AXI_ARREADY) begin
						arvalid_reg <= 0;
					end

					// Handle read data
					if (M_AXI_RVALID && rready_reg) begin
						// Store data in FIFO
						fifo_wr_en <= 1;
						fifo_mem[fifo_wr_ptr[LGFIFO-1:0]] <= M_AXI_RDATA;

						burst_beat_count <= burst_beat_count + 1;

						if (M_AXI_RLAST) begin
							// Burst complete
							burst_beat_count <= 0;
							burst_last_beat  <= 1;

							// Check if more data to read
							if (remaining_len > 0) begin
								// Move to next burst
								cur_src_addr <= cur_src_addr + (burst_beats * (C_AXI_DATA_WIDTH/8));
								remaining_len <= (remaining_len > burst_beats * (C_AXI_DATA_WIDTH/8)) ?
									(remaining_len - burst_beats * (C_AXI_DATA_WIDTH/8)) : 0;

								// Start next read burst
								arvalid_reg  <= 1;
								arid_reg     <= AXI_READ_ID;
								araddr_reg_m <= cur_src_addr;
								arsize_reg   <= $clog2(C_AXI_DATA_WIDTH)-3;
								arburst_reg  <= 2'b01;
								arlock_reg   <= 0;
								arcache_reg  <= 4'b0011;
								arprot_reg   <= 3'b000;
								arqos_reg    <= 4'b0000;
								burst_beats  <= 4;
								burst_beat_count <= 0;
								burst_last_beat  <= 0;
							end else begin
								// All data read, move to write state
								state <= ST_WRITE;
							end
						end
					end

					// Keep rready high when FIFO is not full
					rready_reg <= !fifo_full;

					// Check for abort
					if (abort_req) begin
						state <= ST_ERROR;
						status_reg <= status_reg | (1 << STATUS_ERROR);
					end
				end

				ST_WRITE: begin
					// Read from FIFO and write to memory
					if (!fifo_empty) begin
						fifo_rd_en <= 1;
						wvalid_reg <= 1;
						wdata_reg_m <= fifo_mem[fifo_rd_ptr[LGFIFO-1:0]];
						wstrb_reg_m <= {C_AXI_DATA_WIDTH/8{1'b1}};

						// Check if this is the last beat of the burst
						if (burst_beat_count == burst_beats - 1) begin
							wlast_reg <= 1;
							burst_beat_count <= 0;
						end else begin
							wlast_reg <= 0;
							burst_beat_count <= burst_beat_count + 1;
						end

						// Handle write address handshake
						if (burst_beat_count == 0 && !awvalid_reg) begin
							awvalid_reg  <= 1;
							awid_reg     <= AXI_WRITE_ID;
							awaddr_reg_m <= cur_dst_addr;
							awsize_reg   <= $clog2(C_AXI_DATA_WIDTH)-3;
							awburst_reg  <= 2'b01;
							awlock_reg   <= 0;
							awcache_reg  <= 4'b0011;
							awprot_reg   <= 3'b000;
							awqos_reg    <= 4'b0000;
						end

						if (awvalid_reg && M_AXI_AWREADY) begin
							awvalid_reg <= 0;
						end

						// Handle write data handshake
						if (wvalid_reg && M_AXI_WREADY) begin
							wvalid_reg <= 0;
						end

						// Handle write response
						if (M_AXI_BVALID && bready_reg) begin
							bvalid_pending <= 0;
							bresp_pending  <= 0;
						end
						bready_reg <= 1;

						// Update destination address
						cur_dst_addr <= cur_dst_addr + (C_AXI_DATA_WIDTH/8);

						// Check if all data written
						if (burst_beat_count == burst_beats - 1 && fifo_empty) begin
							state <= ST_DONE;
							status_reg <= status_reg | (1 << STATUS_DONE);
							o_int <= 1;
						end
					end else begin
						wvalid_reg <= 0;
						awvalid_reg <= 0;
						bready_reg <= 0;
					end

					// Check for abort
					if (abort_req) begin
						state <= ST_ERROR;
						status_reg <= status_reg | (1 << STATUS_ERROR);
					end
				end

				ST_DONE: begin
					dma_active <= 0;
					status_reg <= status_reg & ~(1 << STATUS_BUSY);
					o_int      <= 1;
					state      <= ST_IDLE;
				end

				ST_ERROR: begin
					dma_active <= 0;
					status_reg <= status_reg & ~(1 << STATUS_BUSY);
					o_int      <= 1;
					state      <= ST_IDLE;
				end

				default: state <= ST_IDLE;
			endcase

			// Handle abort request
			if (ctrl_reg[CTRL_ABORT] && dma_active) begin
				abort_req <= 1;
			end else begin
				abort_req <= 0;
			end
		end
	end

	// AXI4 master output assignments
	assign M_AXI_AWVALID = awvalid_reg;
	assign M_AXI_AWID    = awid_reg;
	assign M_AXI_AWADDR  = awaddr_reg_m;
	assign M_AXI_AWSIZE  = awsize_reg;
	assign M_AXI_AWBURST = awburst_reg;
	assign M_AXI_AWLOCK  = awlock_reg;
	assign M_AXI_AWCACHE = awcache_reg;
	assign M_AXI_AWPROT  = awprot_reg;
	assign M_AXI_AWQOS   = awqos_reg;

	assign M_AXI_WVALID  = wvalid_reg;
	assign M_AXI_WDATA   = wdata_reg_m;
	assign M_AXI_WSTRB   = wstrb_reg_m;
	assign M_AXI_WLAST   = wlast_reg;
	assign M_AXI_BREADY  = bready_reg;

	assign M_AXI_ARVALID = arvalid_reg;
	assign M_AXI_ARID    = arid_reg;
	assign M_AXI_ARADDR  = araddr_reg_m;
	assign M_AXI_ARSIZE  = arsize_reg;
	assign M_AXI_ARBURST = arburst_reg;
	assign M_AXI_ARLOCK  = arlock_reg;
	assign M_AXI_ARCACHE = arcache_reg;
	assign M_AXI_ARPROT  = arprot_reg;
	assign M_AXI_ARQOS   = arqos_reg;
	assign M_AXI_RREADY  = rready_reg;

endmodule

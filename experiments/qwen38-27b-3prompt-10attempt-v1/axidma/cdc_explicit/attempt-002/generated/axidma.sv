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

	// Register offsets
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
	localparam STAT_BUSY  = 0;
	localparam STAT_DONE  = 1;
	localparam STAT_ERROR = 2;

	// Internal signals
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0]            length_reg;
	reg [1:0]                  control_reg;
	reg [2:0]                  status_reg;

	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_cur;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_cur;
	reg [LGLEN-1:0]            length_cur;

	reg                        dma_active;
	reg                        dma_done;
	reg                        dma_error;

	// AXI write address channel
	reg                        aw_valid_int;
	reg [C_AXI_ID_WIDTH-1:0]   aw_id_int;
	reg [C_AXI_ADDR_WIDTH-1:0] aw_addr_int;
	reg [2:0]                  aw_size_int;
	reg [1:0]                  aw_burst_int;
	reg                        aw_lock_int;
	reg [3:0]                  aw_cache_int;
	reg [2:0]                  aw_prot_int;
	reg [3:0]                  aw_qos_int;

	// AXI write data channel
	reg                        w_valid_int;
	reg [C_AXI_DATA_WIDTH-1:0] w_data_int;
	reg [C_AXI_DATA_WIDTH/8-1:0] w_strb_int;
	reg                        w_last_int;

	// AXI write response channel
	reg                        b_ready_int;

	// AXI read address channel
	reg                        ar_valid_int;
	reg [C_AXI_ID_WIDTH-1:0]   ar_id_int;
	reg [C_AXI_ADDR_WIDTH-1:0] ar_addr_int;
	reg [2:0]                  ar_size_int;
	reg [1:0]                  ar_burst_int;
	reg                        ar_lock_int;
	reg [3:0]                  ar_cache_int;
	reg [2:0]                  ar_prot_int;
	reg [3:0]                  ar_qos_int;

	// AXI read data channel
	reg                        r_ready_int;

	// AXI4-Lite write address channel
	reg                        s_aw_ready_int;
	reg                        s_w_ready_int;
	reg                        s_b_valid_int;
	reg [1:0]                  s_b_resp_int;

	// AXI4-Lite read address channel
	reg                        s_ar_ready_int;
	reg                        s_r_valid_int;
	reg [C_AXIL_DATA_WIDTH-1:0] s_r_data_int;
	reg [1:0]                  s_r_resp_int;

	// State machine states
	localparam ST_IDLE = 2'b00;
	localparam ST_READ = 2'b01;
	localparam ST_WRITE = 2'b10;
	localparam ST_DONE = 2'b11;

	reg [1:0] state;
	reg [1:0] state_next;

	// Burst length calculation
	wire [2:0] burst_size = 3'b100; // 4 beats
	wire [1:0] burst_type = 2'b01;  // INCR

	// Calculate number of beats for current burst
	reg [2:0] beats_remaining;
	reg [2:0] beats_total;

	// Assign outputs
	assign S_AXIL_AWREADY = s_aw_ready_int;
	assign S_AXIL_WREADY = s_w_ready_int;
	assign S_AXIL_BVALID = s_b_valid_int;
	assign S_AXIL_BRESP = s_b_resp_int;
	assign S_AXIL_ARREADY = s_ar_ready_int;
	assign S_AXIL_RVALID = s_r_valid_int;
	assign S_AXIL_RDATA = s_r_data_int;
	assign S_AXIL_RRESP = s_r_resp_int;

	assign M_AXI_AWVALID = aw_valid_int;
	assign M_AXI_AWID = aw_id_int;
	assign M_AXI_AWADDR = aw_addr_int;
	assign M_AXI_AWSIZE = aw_size_int;
	assign M_AXI_AWBURST = aw_burst_int;
	assign M_AXI_AWLOCK = aw_lock_int;
	assign M_AXI_AWCACHE = aw_cache_int;
	assign M_AXI_AWPROT = aw_prot_int;
	assign M_AXI_AWQOS = aw_qos_int;

	assign M_AXI_WVALID = w_valid_int;
	assign M_AXI_WDATA = w_data_int;
	assign M_AXI_WSTRB = w_strb_int;
	assign M_AXI_WLAST = w_last_int;
	assign M_AXI_BREADY = b_ready_int;

	assign M_AXI_ARVALID = ar_valid_int;
	assign M_AXI_ARID = ar_id_int;
	assign M_AXI_ARADDR = ar_addr_int;
	assign M_AXI_ARSIZE = ar_size_int;
	assign M_AXI_ARBURST = ar_burst_int;
	assign M_AXI_ARLOCK = ar_lock_int;
	assign M_AXI_ARCACHE = ar_cache_int;
	assign M_AXI_ARPROT = ar_prot_int;
	assign M_AXI_ARQOS = ar_qos_int;

	assign M_AXI_RREADY = r_ready_int;

	assign o_int = status_reg[STAT_DONE] | status_reg[STAT_ERROR];

	// AXI4-Lite register file
	reg [C_AXIL_DATA_WIDTH-1:0] reg_file [0:7];
	reg [C_AXIL_ADDR_WIDTH-1:0] s_aw_addr_reg;
	reg                         s_aw_valid_reg;
	reg                         s_w_valid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] s_w_data_reg;
	reg [C_AXIL_DATA_WIDTH/8-1:0] s_w_strb_reg;
	reg                         s_b_valid_reg;
	reg [1:0]                   s_b_resp_reg;
	reg                         s_ar_valid_reg;
	reg [C_AXIL_ADDR_WIDTH-1:0] s_ar_addr_reg;
	reg                         s_r_valid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] s_r_data_reg;
	reg [1:0]                   s_r_resp_reg;

	// AXI4-Lite write address handshake
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_aw_valid_reg <= 1'b0;
			s_aw_addr_reg <= {C_AXIL_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXIL_AWVALID && s_aw_ready_int) begin
				s_aw_valid_reg <= 1'b1;
				s_aw_addr_reg <= S_AXIL_AWADDR;
			end else if (s_aw_valid_reg && s_w_valid_reg) begin
				s_aw_valid_reg <= 1'b0;
			end
		end
	end

	// AXI4-Lite write data handshake
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_w_valid_reg <= 1'b0;
			s_w_data_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
			s_w_strb_reg <= {C_AXIL_DATA_WIDTH/8{1'b0}};
		end else begin
			if (S_AXIL_WVALID && s_w_ready_int) begin
				s_w_valid_reg <= 1'b1;
				s_w_data_reg <= S_AXIL_WDATA;
				s_w_strb_reg <= S_AXIL_WSTRB;
			end else if (s_aw_valid_reg && s_w_valid_reg) begin
				s_w_valid_reg <= 1'b0;
			end
		end
	end

	// AXI4-Lite write response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_b_valid_reg <= 1'b0;
			s_b_resp_reg <= 2'b00;
		end else begin
			if (s_aw_valid_reg && s_w_valid_reg) begin
				s_b_valid_reg <= 1'b1;
				s_b_resp_reg <= 2'b00;
			end else if (s_b_valid_reg && S_AXIL_BREADY) begin
				s_b_valid_reg <= 1'b0;
			end
		end
	end

	// AXI4-Lite read address handshake
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_ar_valid_reg <= 1'b0;
			s_ar_addr_reg <= {C_AXIL_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXIL_ARVALID && s_ar_ready_int) begin
				s_ar_valid_reg <= 1'b1;
				s_ar_addr_reg <= S_AXIL_ARADDR;
			end else if (s_ar_valid_reg && s_r_valid_reg) begin
				s_ar_valid_reg <= 1'b0;
			end
		end
	end

	// AXI4-Lite read data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_r_valid_reg <= 1'b0;
			s_r_data_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
			s_r_resp_reg <= 2'b00;
		end else begin
			if (s_ar_valid_reg) begin
				s_r_valid_reg <= 1'b1;
				case (s_ar_addr_reg[C_AXIL_ADDR_WIDTH-1:2])
					2'd0: s_r_data_reg <= reg_file[0];
					2'd1: s_r_data_reg <= reg_file[1];
					2'd2: s_r_data_reg <= reg_file[2];
					2'd3: s_r_data_reg <= reg_file[3];
					2'd4: s_r_data_reg <= reg_file[4];
					2'd5: s_r_data_reg <= reg_file[5];
					default: s_r_data_reg <= 32'h0;
				endcase
				s_r_resp_reg <= 2'b00;
			end else if (s_r_valid_reg && S_AXIL_RREADY) begin
				s_r_valid_reg <= 1'b0;
			end
		end
	end

	// Register file write
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_file[0] <= 32'h0;
			reg_file[1] <= 32'h0;
			reg_file[2] <= 32'h0;
			reg_file[3] <= 32'h0;
			reg_file[4] <= 32'h0;
			reg_file[5] <= 32'h0;
		end else begin
			if (s_aw_valid_reg && s_w_valid_reg) begin
				case (s_aw_addr_reg[C_AXIL_ADDR_WIDTH-1:2])
					2'd0: reg_file[0] <= s_w_data_reg;
					2'd1: reg_file[1] <= s_w_data_reg;
					2'd2: reg_file[2] <= s_w_data_reg;
					2'd3: reg_file[3] <= s_w_data_reg;
					2'd4: reg_file[4] <= s_w_data_reg;
					2'd5: reg_file[5] <= s_w_data_reg;
					default: ;
				endcase
			end
		end
	end

	// Register file read
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_file[4] <= 32'h0;
		end else begin
			reg_file[4] <= {28'h0, status_reg[2:0]};
		end
	end

	// DMA control logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_reg <= {LGLEN{1'b0}};
			control_reg <= 2'b00;
			status_reg <= 3'b000;
			src_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_cur <= {LGLEN{1'b0}};
			dma_active <= 1'b0;
			dma_done <= 1'b0;
			dma_error <= 1'b0;
			state <= ST_IDLE;
			beats_remaining <= 3'b000;
			beats_total <= 3'b000;
		end else begin
			// Update status register
			status_reg[STAT_BUSY] <= dma_active;
			status_reg[STAT_DONE] <= dma_done;
			status_reg[STAT_ERROR] <= dma_error;

			// Handle control register
			if (control_reg[CTRL_START] && !dma_active) begin
				src_addr_cur <= src_addr_reg;
				dst_addr_cur <= dst_addr_reg;
				length_cur <= length_reg;
				dma_active <= 1'b1;
				dma_done <= 1'b0;
				dma_error <= 1'b0;
				state <= ST_READ;
				beats_total <= 3'b100; // 4 beats
				beats_remaining <= 3'b100;
			end

			if (control_reg[CTRL_ABORT] && dma_active) begin
				dma_active <= 1'b0;
				dma_error <= 1'b1;
				state <= ST_IDLE;
			end

			// State machine
			case (state)
				ST_IDLE: begin
					if (control_reg[CTRL_START] && !dma_active) begin
						state <= ST_READ;
					end
				end
				ST_READ: begin
					if (ar_valid_int && M_AXI_ARREADY) begin
						beats_remaining <= beats_remaining - 1'b1;
						src_addr_cur <= src_addr_cur + C_AXI_DATA_WIDTH;
						if (beats_remaining == 3'b001) begin
							if (length_cur == {LGLEN{1'b0}}) begin
								state <= ST_DONE;
								dma_active <= 1'b0;
								dma_done <= 1'b1;
							end else begin
								length_cur <= length_cur - C_AXI_DATA_WIDTH;
								state <= ST_WRITE;
							end
						end
					end
				end
				ST_WRITE: begin
					if (aw_valid_int && M_AXI_AWREADY) begin
						beats_remaining <= beats_remaining - 1'b1;
						dst_addr_cur <= dst_addr_cur + C_AXI_DATA_WIDTH;
						if (beats_remaining == 3'b001) begin
							if (length_cur == {LGLEN{1'b0}}) begin
								state <= ST_DONE;
								dma_active <= 1'b0;
								dma_done <= 1'b1;
							end else begin
								length_cur <= length_cur - C_AXI_DATA_WIDTH;
								state <= ST_READ;
							end
						end
					end
				end
				ST_DONE: begin
					state <= ST_IDLE;
				end
				default: state <= ST_IDLE;
			endcase
		end
	end

	// AXI read address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_valid_int <= 1'b0;
			ar_id_int <= {C_AXI_ID_WIDTH{1'b0}};
			ar_addr_int <= {C_AXI_ADDR_WIDTH{1'b0}};
			ar_size_int <= 3'b000;
			ar_burst_int <= 2'b00;
			ar_lock_int <= 1'b0;
			ar_cache_int <= 4'b0000;
			ar_prot_int <= 3'b000;
			ar_qos_int <= 4'b0000;
		end else begin
			if (state == ST_READ && !ar_valid_int) begin
				ar_valid_int <= 1'b1;
				ar_id_int <= AXI_READ_ID;
				ar_addr_int <= src_addr_cur;
				ar_size_int <= burst_size;
				ar_burst_int <= burst_type;
				ar_lock_int <= 1'b0;
				ar_cache_int <= 4'b0000;
				ar_prot_int <= 3'b000;
				ar_qos_int <= 4'b0000;
			end else if (ar_valid_int && M_AXI_ARREADY) begin
				ar_valid_int <= 1'b0;
			end
		end
	end

	// AXI write address channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_valid_int <= 1'b0;
			aw_id_int <= {C_AXI_ID_WIDTH{1'b0}};
			aw_addr_int <= {C_AXI_ADDR_WIDTH{1'b0}};
			aw_size_int <= 3'b000;
			aw_burst_int <= 2'b00;
			aw_lock_int <= 1'b0;
			aw_cache_int <= 4'b0000;
			aw_prot_int <= 3'b000;
			aw_qos_int <= 4'b0000;
		end else begin
			if (state == ST_WRITE && !aw_valid_int) begin
				aw_valid_int <= 1'b1;
				aw_id_int <= AXI_WRITE_ID;
				aw_addr_int <= dst_addr_cur;
				aw_size_int <= burst_size;
				aw_burst_int <= burst_type;
				aw_lock_int <= 1'b0;
				aw_cache_int <= 4'b0000;
				aw_prot_int <= 3'b000;
				aw_qos_int <= 4'b0000;
			end else if (aw_valid_int && M_AXI_AWREADY) begin
				aw_valid_int <= 1'b0;
			end
		end
	end

	// AXI write data channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_valid_int <= 1'b0;
			w_data_int <= {C_AXI_DATA_WIDTH{1'b0}};
			w_strb_int <= {C_AXI_DATA_WIDTH/8{1'b0}};
			w_last_int <= 1'b0;
		end else begin
			if (state == ST_WRITE && M_AXI_RVALID) begin
				w_valid_int <= 1'b1;
				w_data_int <= M_AXI_RDATA;
				w_strb_int <= {C_AXI_DATA_WIDTH/8{1'b1}};
				w_last_int <= M_AXI_RLAST;
			end else if (w_valid_int && M_AXI_WREADY) begin
				w_valid_int <= 1'b0;
			end
		end
	end

	// AXI write response channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_ready_int <= 1'b0;
		end else begin
			b_ready_int <= 1'b1;
		end
	end

	// AXI read data channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_ready_int <= 1'b0;
		end else begin
			r_ready_int <= (state == ST_READ) ? 1'b1 : 1'b0;
		end
	end

	// AXI4-Lite ready signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_aw_ready_int <= 1'b0;
			s_w_ready_int <= 1'b0;
			s_ar_ready_int <= 1'b0;
		end else begin
			s_aw_ready_int <= !s_aw_valid_reg;
			s_w_ready_int <= !s_w_valid_reg;
			s_ar_ready_int <= !s_ar_valid_reg;
		end
	end

	// AXI4-Lite valid signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_b_valid_int <= 1'b0;
			s_b_resp_int <= 2'b00;
			s_r_valid_int <= 1'b0;
			s_r_data_int <= {C_AXIL_DATA_WIDTH{1'b0}};
			s_r_resp_int <= 2'b00;
		end else begin
			s_b_valid_int <= s_b_valid_reg;
			s_b_resp_int <= s_b_resp_reg;
			s_r_valid_int <= s_r_valid_reg;
			s_r_data_int <= s_r_data_reg;
			s_r_resp_int <= s_r_resp_reg;
		end
	end

endmodule

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

	// Register addresses
	localparam REG_SRC_ADDR = 4'h0;
	localparam REG_DST_ADDR = 4'h4;
	localparam REG_LENGTH   = 4'h8;
	localparam REG_CONTROL  = 4'hC;
	localparam REG_STATUS   = 4'h10;
	localparam REG_DOORBELL = 4'h14;

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
	reg [31:0]                 control_reg;
	reg [31:0]                 status_reg;

	reg                        start_pulse;
	reg                        abort_pulse;

	// DMA state machine
	localparam S_IDLE = 2'd0;
	localparam S_READ = 2'd1;
	localparam S_WRITE = 2'd2;
	localparam S_DONE = 2'd3;

	reg [1:0] dma_state;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [LGLEN-1:0]            remaining_len;
	reg [LGLEN-1:0]            burst_len;
	reg                        dma_busy;
	reg                        dma_done;
	reg                        dma_error;

	// AXI write channel
	reg                        aw_pending;
	reg [C_AXI_ADDR_WIDTH-1:0] aw_addr;
	reg [LGLEN-1:0]            aw_len;
	reg                        w_pending;
	reg [C_AXI_DATA_WIDTH-1:0] w_data;
	reg [C_AXI_DATA_WIDTH/8-1:0] w_strb;
	reg                        w_last;
	reg                        b_pending;

	// AXI read channel
	reg                        ar_pending;
	reg [C_AXI_ADDR_WIDTH-1:0] ar_addr;
	reg [LGLEN-1:0]            ar_len;
	reg                        r_pending;
	reg [C_AXI_DATA_WIDTH-1:0] r_data;
	reg                        r_last;

	// FIFO for read data
	reg [C_AXI_DATA_WIDTH-1:0] fifo_mem [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] fifo_wr_ptr;
	reg [LGFIFO-1:0] fifo_rd_ptr;
	reg [LGFIFO:0]   fifo_count;
	reg              fifo_full;
	reg              fifo_empty;

	// AXI size calculation
	wire [2:0] axi_size = $clog2(C_AXI_DATA_WIDTH) - 3;

	// AXI burst type
	wire [1:0] axi_burst = 2'b01; // INCR

	// AXI cache
	wire [3:0] axi_cache = 4'b0011;

	// AXI lock
	wire axi_lock = 1'b0;

	// AXI QoS
	wire [3:0] axi_qos = 4'h0;

	// AXI prot
	wire [2:0] axi_prot = 3'b000;

	// AXI IDs
	wire [C_AXI_ID_WIDTH-1:0] axi_aw_id = AXI_WRITE_ID;
	wire [C_AXI_ID_WIDTH-1:0] axi_ar_id = AXI_READ_ID;

	// AXI write address channel
	assign M_AXI_AWID    = axi_aw_id;
	assign M_AXI_AWADDR  = aw_addr;
	assign M_AXI_AWSIZE  = axi_size;
	assign M_AXI_AWBURST = axi_burst;
	assign M_AXI_AWLOCK  = axi_lock;
	assign M_AXI_AWCACHE = axi_cache;
	assign M_AXI_AWPROT  = axi_prot;
	assign M_AXI_AWQOS   = axi_qos;

	// AXI write data channel
	assign M_AXI_WDATA = w_data;
	assign M_AXI_WSTRB = w_strb;
	assign M_AXI_WLAST = w_last;

	// AXI write response channel
	assign M_AXI_BREADY = b_pending;

	// AXI read address channel
	assign M_AXI_ARID    = axi_ar_id;
	assign M_AXI_ARADDR  = ar_addr;
	assign M_AXI_ARSIZE  = axi_size;
	assign M_AXI_ARBURST = axi_burst;
	assign M_AXI_ARLOCK  = axi_lock;
	assign M_AXI_ARCACHE = axi_cache;
	assign M_AXI_ARPROT  = axi_prot;
	assign M_AXI_ARQOS   = axi_qos;

	// AXI read data channel
	assign M_AXI_RREADY = r_pending;

	// AXI Lite write address channel
	assign S_AXIL_AWREADY = 1'b1;

	// AXI Lite write data channel
	assign S_AXIL_WREADY = 1'b1;

	// AXI Lite write response channel
	assign S_AXIL_BRESP = 2'b00;

	// AXI Lite read address channel
	assign S_AXIL_ARREADY = 1'b1;

	// AXI Lite read data channel
	assign S_AXIL_RRESP = 2'b00;

	// Interrupt
	assign o_int = dma_done | dma_error;

	// FIFO full/empty
	assign fifo_full  = (fifo_count == (1<<LGFIFO));
	assign fifo_empty = (fifo_count == 0);

	// AXI write valid
	assign M_AXI_AWVALID = aw_pending;
	assign M_AXI_WVALID  = w_pending;

	// AXI read valid
	assign M_AXI_ARVALID = ar_pending;

	// AXI Lite read valid
	assign S_AXIL_RVALID = r_pending;

	// AXI Lite read data
	assign S_AXIL_RDATA = r_data;

	// AXI Lite write response
	assign S_AXIL_BVALID = 1'b0;

	// Register file write
	reg reg_write_en;
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_write_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_write_data;
	reg [C_AXIL_DATA_WIDTH/8-1:0] reg_write_strb;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_write_en <= 1'b0;
			reg_write_addr <= {C_AXIL_ADDR_WIDTH{1'b0}};
			reg_write_data <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_write_strb <= {C_AXIL_DATA_WIDTH/8{1'b0}};
		end else begin
			reg_write_en <= S_AXIL_AWVALID && S_AXIL_WVALID;
			reg_write_addr <= S_AXIL_AWADDR;
			reg_write_data <= S_AXIL_WDATA;
			reg_write_strb <= S_AXIL_WSTRB;
		end
	end

	// Register file
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_reg   <= {LGLEN{1'b0}};
			control_reg  <= 32'h0;
			status_reg   <= 32'h0;
			start_pulse  <= 1'b0;
			abort_pulse  <= 1'b0;
		end else begin
			start_pulse <= 1'b0;
			abort_pulse <= 1'b0;

			if (reg_write_en) begin
				case (reg_write_addr)
					REG_SRC_ADDR: begin
						if (reg_write_strb[3]) src_addr_reg[31:24] <= reg_write_data[31:24];
						if (reg_write_strb[2]) src_addr_reg[23:16] <= reg_write_data[23:16];
						if (reg_write_strb[1]) src_addr_reg[15:8]  <= reg_write_data[15:8];
						if (reg_write_strb[0]) src_addr_reg[7:0]   <= reg_write_data[7:0];
					end
					REG_DST_ADDR: begin
						if (reg_write_strb[3]) dst_addr_reg[31:24] <= reg_write_data[31:24];
						if (reg_write_strb[2]) dst_addr_reg[23:16] <= reg_write_data[23:16];
						if (reg_write_strb[1]) dst_addr_reg[15:8]  <= reg_write_data[15:8];
						if (reg_write_strb[0]) dst_addr_reg[7:0]   <= reg_write_data[7:0];
					end
					REG_LENGTH: begin
						if (reg_write_strb[3]) length_reg[31:24] <= reg_write_data[31:24];
						if (reg_write_strb[2]) length_reg[23:16] <= reg_write_data[23:16];
						if (reg_write_strb[1]) length_reg[15:8]  <= reg_write_data[15:8];
						if (reg_write_strb[0]) length_reg[7:0]   <= reg_write_data[7:0];
					end
					REG_CONTROL: begin
						if (reg_write_strb[3]) control_reg[31:24] <= reg_write_data[31:24];
						if (reg_write_strb[2]) control_reg[23:16] <= reg_write_data[23:16];
						if (reg_write_strb[1]) control_reg[15:8]  <= reg_write_data[15:8];
						if (reg_write_strb[0]) control_reg[7:0]   <= reg_write_data[7:0];
						if (control_reg[CTRL_START]) start_pulse <= 1'b1;
						if (control_reg[CTRL_ABORT]) abort_pulse <= 1'b1;
					end
					default: ;
				endcase
			end

			// Update status register
			status_reg[STAT_BUSY]  <= dma_busy;
			status_reg[STAT_DONE]  <= dma_done;
			status_reg[STAT_ERROR] <= dma_error;
		end
	end

	// DMA state machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			dma_state      <= S_IDLE;
			cur_src_addr   <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_dst_addr   <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining_len  <= {LGLEN{1'b0}};
			burst_len      <= {LGLEN{1'b0}};
			dma_busy       <= 1'b0;
			dma_done       <= 1'b0;
			dma_error      <= 1'b0;
			aw_pending     <= 1'b0;
			aw_addr        <= {C_AXI_ADDR_WIDTH{1'b0}};
			aw_len         <= {LGLEN{1'b0}};
			w_pending      <= 1'b0;
			w_data         <= {C_AXI_DATA_WIDTH{1'b0}};
			w_strb         <= {C_AXI_DATA_WIDTH/8{1'b0}};
			w_last         <= 1'b0;
			b_pending      <= 1'b0;
			ar_pending     <= 1'b0;
			ar_addr        <= {C_AXI_ADDR_WIDTH{1'b0}};
			ar_len         <= {LGLEN{1'b0}};
			r_pending      <= 1'b0;
			r_data         <= {C_AXI_DATA_WIDTH{1'b0}};
			r_last         <= 1'b0;
			fifo_wr_ptr    <= {LGFIFO{1'b0}};
			fifo_rd_ptr    <= {LGFIFO{1'b0}};
			fifo_count     <= {(LGFIFO+1){1'b0}};
		end else begin
			// Default assignments
			aw_pending <= 1'b0;
			w_pending  <= 1'b0;
			b_pending  <= 1'b0;
			ar_pending <= 1'b0;
			r_pending  <= 1'b0;

			case (dma_state)
				S_IDLE: begin
					dma_busy <= 1'b0;
					dma_done <= 1'b0;
					dma_error <= 1'b0;

					if (start_pulse && !abort_pulse) begin
						dma_state     <= S_READ;
						dma_busy      <= 1'b1;
						cur_src_addr  <= src_addr_reg;
						cur_dst_addr  <= dst_addr_reg;
						remaining_len <= length_reg;
						burst_len     <= length_reg;
					end
				end

				S_READ: begin
					if (abort_pulse) begin
						dma_state <= S_IDLE;
						dma_busy  <= 1'b0;
						dma_error <= 1'b1;
					end else if (remaining_len > 0) begin
						// Issue read address
						if (!ar_pending) begin
							ar_pending <= 1'b1;
							ar_addr    <= cur_src_addr;
							ar_len     <= burst_len;
						end

						// Handle read data
						if (M_AXI_RVALID && M_AXI_RREADY) begin
							// Write to FIFO
							fifo_mem[fifo_wr_ptr] <= M_AXI_RDATA;
							fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
							fifo_count  <= fifo_count + 1'b1;

							// Update addresses and length
							cur_src_addr <= cur_src_addr + C_AXI_DATA_WIDTH/8;
							remaining_len <= remaining_len - 1'b1;

							if (M_AXI_RLAST) begin
								// Burst complete, switch to write state
								dma_state <= S_WRITE;
							end
						end
					end else begin
						dma_state <= S_DONE;
					end
				end

				S_WRITE: begin
					if (abort_pulse) begin
						dma_state <= S_IDLE;
						dma_busy  <= 1'b0;
						dma_error <= 1'b1;
					end else if (!fifo_empty) begin
						// Issue write address if needed
						if (!aw_pending && !w_pending) begin
							aw_pending <= 1'b1;
							aw_addr    <= cur_dst_addr;
							aw_len     <= burst_len;
						end

						// Issue write data
						if (aw_pending && M_AXI_AWREADY) begin
							aw_pending <= 1'b0;
							w_pending  <= 1'b1;
							w_data     <= fifo_mem[fifo_rd_ptr];
							w_strb     <= {C_AXI_DATA_WIDTH/8{1'b1}};
							w_last     <= (fifo_count == 1'b1);
						end

						if (w_pending && M_AXI_WREADY) begin
							w_pending <= 1'b0;
							fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
							fifo_count  <= fifo_count - 1'b1;

							// Update destination address
							cur_dst_addr <= cur_dst_addr + C_AXI_DATA_WIDTH/8;

							if (w_last) begin
								// Burst complete, wait for write response
								b_pending <= 1'b1;
							end
						end

						// Handle write response
						if (b_pending && M_AXI_BVALID && M_AXI_BREADY) begin
							b_pending <= 1'b0;

							// Check for more data
							if (remaining_len > 0) begin
								dma_state <= S_READ;
							end else begin
								dma_state <= S_DONE;
							end
						end
					end else begin
						// FIFO empty, wait for more read data or complete
						if (remaining_len == 0) begin
							dma_state <= S_DONE;
						end
					end
				end

				S_DONE: begin
					dma_state <= S_IDLE;
					dma_busy  <= 1'b0;
					dma_done  <= 1'b1;
				end

				default: begin
					dma_state <= S_IDLE;
				end
			endcase
		end
	end

	// AXI Lite read data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXIL_RVALID <= 1'b0;
			S_AXIL_RDATA  <= {C_AXIL_DATA_WIDTH{1'b0}};
		end else begin
			S_AXIL_RVALID <= 1'b0;
			if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
				S_AXIL_RVALID <= 1'b1;
				case (S_AXIL_ARADDR)
					REG_SRC_ADDR: S_AXIL_RDATA <= {32'h0, src_addr_reg[C_AXIL_DATA_WIDTH-1:0]};
					REG_DST_ADDR: S_AXIL_RDATA <= {32'h0, dst_addr_reg[C_AXIL_DATA_WIDTH-1:0]};
					REG_LENGTH:   S_AXIL_RDATA <= {32'h0, length_reg[C_AXIL_DATA_WIDTH-1:0]};
					REG_CONTROL:  S_AXIL_RDATA <= control_reg;
					REG_STATUS:   S_AXIL_RDATA <= status_reg;
					default:      S_AXIL_RDATA <= 32'h0;
				endcase
			end
		end
	end

	// AXI Lite write response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXIL_BVALID <= 1'b0;
		end else begin
			S_AXIL_BVALID <= 1'b0;
			if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
				S_AXIL_BVALID <= 1'b1;
			end
		end
	end

endmodule

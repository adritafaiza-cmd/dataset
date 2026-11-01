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

	// Internal signals
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0] length_reg;
	reg [1:0] control_reg;
	reg [2:0] status_reg;

	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_cur;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_cur;
	reg [LGLEN-1:0] length_cur;
	reg [LGLEN-1:0] bytes_done;

	reg dma_active;
	reg dma_done;
	reg dma_error;

	// AXI write channel signals
	reg aw_valid_int;
	reg [C_AXI_ADDR_WIDTH-1:0] aw_addr_int;
	reg [2:0] aw_size_int;
	reg [1:0] aw_burst_int;
	reg aw_last_int;

	reg w_valid_int;
	reg [C_AXI_DATA_WIDTH-1:0] w_data_int;
	reg [C_AXI_DATA_WIDTH/8-1:0] w_strb_int;
	reg w_last_int;

	reg b_ready_int;

	// AXI read channel signals
	reg ar_valid_int;
	reg [C_AXI_ADDR_WIDTH-1:0] ar_addr_int;
	reg [2:0] ar_size_int;
	reg [1:0] ar_burst_int;
	reg ar_last_int;

	reg r_ready_int;
	reg [C_AXI_DATA_WIDTH-1:0] r_data_reg;
	reg r_last_reg;

	// FIFO for read data
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = C_AXI_DATA_WIDTH;
	reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] fifo_wr_ptr;
	reg [LGFIFO:0] fifo_rd_ptr;
	reg fifo_wr_en;
	reg fifo_rd_en;

	wire fifo_full = (fifo_wr_ptr[LGFIFO] != fifo_rd_ptr[LGFIFO]) && 
	                 (fifo_wr_ptr[LGFIFO-1:0] == fifo_rd_ptr[LGFIFO-1:0]);
	wire fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);
	wire fifo_not_empty = ~fifo_empty;

	// AXI4-Lite write address channel
	reg aw_ready_int;
	reg [C_AXIL_ADDR_WIDTH-1:0] aw_addr_latch;
	reg [2:0] aw_prot_latch;

	// AXI4-Lite write data channel
	reg w_ready_int;
	reg [C_AXIL_DATA_WIDTH-1:0] w_data_latch;
	reg [C_AXIL_DATA_WIDTH/8-1:0] w_strb_latch;

	// AXI4-Lite write response
	reg b_valid_int;
	reg [1:0] b_resp_int;

	// AXI4-Lite read address channel
	reg ar_ready_int;
	reg [C_AXIL_ADDR_WIDTH-1:0] ar_addr_latch;
	reg [2:0] ar_prot_latch;

	// AXI4-Lite read data channel
	reg r_valid_int;
	reg [C_AXIL_DATA_WIDTH-1:0] r_data_latch;
	reg [1:0] r_resp_latch;

	// Register file write logic
	reg reg_write_en;
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_write_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_write_data;

	// Register file read logic
	reg reg_read_en;
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_read_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_read_data;

	// AXI4-Lite write address handshake
	assign S_AXIL_AWREADY = aw_ready_int;
	assign S_AXIL_WREADY = w_ready_int;
	assign S_AXIL_BVALID = b_valid_int;
	assign S_AXIL_BRESP = b_resp_int;
	assign S_AXIL_ARREADY = ar_ready_int;
	assign S_AXIL_RVALID = r_valid_int;
	assign S_AXIL_RDATA = r_data_latch;
	assign S_AXIL_RRESP = r_resp_latch;

	// AXI4 master write address channel
	assign M_AXI_AWVALID = aw_valid_int;
	assign M_AXI_AWID = AXI_WRITE_ID;
	assign M_AXI_AWADDR = aw_addr_int;
	assign M_AXI_AWSIZE = aw_size_int;
	assign M_AXI_AWBURST = aw_burst_int;
	assign M_AXI_AWLOCK = 1'b0;
	assign M_AXI_AWCACHE = 4'b0000;
	assign M_AXI_AWPROT = aw_prot_latch;
	assign M_AXI_AWQOS = 4'b0000;

	// AXI4 master write data channel
	assign M_AXI_WVALID = w_valid_int;
	assign M_AXI_WDATA = w_data_int;
	assign M_AXI_WSTRB = w_strb_int;
	assign M_AXI_WLAST = w_last_int;
	assign M_AXI_BREADY = b_ready_int;

	// AXI4 master read address channel
	assign M_AXI_ARVALID = ar_valid_int;
	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARADDR = ar_addr_int;
	assign M_AXI_ARSIZE = ar_size_int;
	assign M_AXI_ARBURST = ar_burst_int;
	assign M_AXI_ARLOCK = 1'b0;
	assign M_AXI_ARCACHE = 4'b0000;
	assign M_AXI_ARPROT = ar_prot_latch;
	assign M_AXI_ARQOS = 4'b0000;

	// AXI4 master read data channel
	assign M_AXI_RREADY = r_ready_int;

	// Interrupt output
	assign o_int = dma_done || dma_error;

	// AXI4-Lite write address channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_ready_int <= 1'b1;
			aw_addr_latch <= {C_AXIL_ADDR_WIDTH{1'b0}};
			aw_prot_latch <= 3'b000;
		end else begin
			if (S_AXIL_AWVALID && aw_ready_int) begin
				aw_addr_latch <= S_AXIL_AWADDR;
				aw_prot_latch <= S_AXIL_AWPROT;
				aw_ready_int <= 1'b0;
			end else if (!S_AXIL_AWVALID) begin
				aw_ready_int <= 1'b1;
			end
		end
	end

	// AXI4-Lite write data channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_ready_int <= 1'b1;
			w_data_latch <= {C_AXIL_DATA_WIDTH{1'b0}};
			w_strb_latch <= {C_AXIL_DATA_WIDTH/8{1'b0}};
		end else begin
			if (S_AXIL_WVALID && w_ready_int) begin
				w_data_latch <= S_AXIL_WDATA;
				w_strb_latch <= S_AXIL_WSTRB;
				w_ready_int <= 1'b0;
			end else if (!S_AXIL_WVALID) begin
				w_ready_int <= 1'b1;
			end
		end
	end

	// Register write logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_write_en <= 1'b0;
			reg_write_addr <= {C_AXIL_ADDR_WIDTH{1'b0}};
			reg_write_data <= {C_AXIL_DATA_WIDTH{1'b0}};
		end else begin
			reg_write_en <= 1'b0;
			if (S_AXIL_AWVALID && S_AXIL_WVALID && aw_ready_int && w_ready_int) begin
				reg_write_en <= 1'b1;
				reg_write_addr <= S_AXIL_AWADDR;
				reg_write_data <= S_AXIL_WDATA;
			end
		end
	end

	// Register file update
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_reg <= {LGLEN{1'b0}};
			control_reg <= 2'b00;
			status_reg <= 3'b000;
		end else begin
			if (reg_write_en) begin
				case (reg_write_addr[C_AXIL_ADDR_WIDTH-1:2])
					REG_SRC_ADDR: src_addr_reg <= reg_write_data;
					REG_DST_ADDR: dst_addr_reg <= reg_write_data;
					REG_LENGTH:   length_reg <= reg_write_data[LGLEN-1:0];
					REG_CONTROL:  control_reg <= reg_write_data[1:0];
					default: ;
				endcase
			end
		end
	end

	// DMA start logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			dma_active <= 1'b0;
			dma_done <= 1'b0;
			dma_error <= 1'b0;
			src_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_cur <= {LGLEN{1'b0}};
			bytes_done <= {LGLEN{1'b0}};
		end else begin
			// Start DMA
			if (control_reg[CTRL_START] && !dma_active && length_reg > 0) begin
				dma_active <= 1'b1;
				dma_done <= 1'b0;
				dma_error <= 1'b0;
				src_addr_cur <= src_addr_reg;
				dst_addr_cur <= dst_addr_reg;
				length_cur <= length_reg;
				bytes_done <= {LGLEN{1'b0}};
				control_reg[CTRL_START] <= 1'b0;
			end

			// Abort DMA
			if (control_reg[CTRL_ABORT] && dma_active) begin
				dma_active <= 1'b0;
				dma_error <= 1'b1;
				control_reg[CTRL_ABORT] <= 1'b0;
			end

			// DMA complete
			if (dma_active && bytes_done >= length_cur) begin
				dma_active <= 1'b0;
				dma_done <= 1'b1;
			end

			// Clear done/error on new start
			if (control_reg[CTRL_START] && !dma_active) begin
				dma_done <= 1'b0;
				dma_error <= 1'b0;
			end
		end
	end

	// Status register
	always @(*) begin
		status_reg = 3'b000;
		if (dma_active) status_reg[STAT_BUSY] = 1'b1;
		if (dma_done) status_reg[STAT_DONE] = 1'b1;
		if (dma_error) status_reg[STAT_ERROR] = 1'b1;
	end

	// AXI4-Lite read address channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_ready_int <= 1'b1;
			ar_addr_latch <= {C_AXIL_ADDR_WIDTH{1'b0}};
			ar_prot_latch <= 3'b000;
			reg_read_en <= 1'b0;
			reg_read_addr <= {C_AXIL_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXIL_ARVALID && ar_ready_int) begin
				ar_addr_latch <= S_AXIL_ARADDR;
				ar_prot_latch <= S_AXIL_ARPROT;
				ar_ready_int <= 1'b0;
				reg_read_en <= 1'b1;
				reg_read_addr <= S_AXIL_ARADDR;
			end else if (!S_AXIL_ARVALID) begin
				ar_ready_int <= 1'b1;
			end
		end
	end

	// Register read data
	always @(*) begin
		reg_read_data = {C_AXIL_DATA_WIDTH{1'b0}};
		case (reg_read_addr[C_AXIL_ADDR_WIDTH-1:2])
			REG_SRC_ADDR: reg_read_data = src_addr_reg;
			REG_DST_ADDR: reg_read_data = dst_addr_reg;
			REG_LENGTH:   reg_read_data = length_reg;
			REG_CONTROL:  reg_read_data = control_reg;
			REG_STATUS:   reg_read_data = status_reg;
			default:      reg_read_data = {C_AXIL_DATA_WIDTH{1'b0}};
		endcase
	end

	// AXI4-Lite read data channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_valid_int <= 1'b0;
			r_data_latch <= {C_AXIL_DATA_WIDTH{1'b0}};
			r_resp_latch <= 2'b00;
		end else begin
			if (reg_read_en) begin
				r_valid_int <= 1'b1;
				r_data_latch <= reg_read_data;
				r_resp_latch <= 2'b00;
			end else if (S_AXIL_RREADY && r_valid_int) begin
				r_valid_int <= 1'b0;
			end
		end
	end

	// AXI4-Lite write response logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_valid_int <= 1'b0;
			b_resp_int <= 2'b00;
		end else begin
			if (reg_write_en) begin
				b_valid_int <= 1'b1;
				b_resp_int <= 2'b00;
			end else if (S_AXIL_BREADY && b_valid_int) begin
				b_valid_int <= 1'b0;
			end
		end
	end

	// DMA read logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_valid_int <= 1'b0;
			ar_addr_int <= {C_AXI_ADDR_WIDTH{1'b0}};
			ar_size_int <= 3'b000;
			ar_burst_int <= 2'b00;
			ar_last_int <= 1'b0;
			r_ready_int <= 1'b0;
			fifo_wr_en <= 1'b0;
			fifo_wr_ptr <= {LGFIFO+1{1'b0}};
		end else begin
			// Issue read request
			if (dma_active && !ar_valid_int && !fifo_full && bytes_done < length_cur) begin
				ar_valid_int <= 1'b1;
				ar_addr_int <= src_addr_cur;
				ar_size_int <= $clog2(C_AXI_DATA_WIDTH) - 3;
				ar_burst_int <= 2'b00; // FIXED
				ar_last_int <= 1'b0;
			end else if (ar_valid_int && M_AXI_ARREADY) begin
				ar_valid_int <= 1'b0;
			end

			// Receive read data
			if (M_AXI_RVALID && r_ready_int) begin
				fifo_wr_en <= 1'b1;
				fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
			end

			// Ready for read data
			if (dma_active && !fifo_full) begin
				r_ready_int <= 1'b1;
			end else begin
				r_ready_int <= 1'b0;
			end
		end
	end

	// FIFO write
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// Initialize FIFO
		end else begin
			if (fifo_wr_en) begin
				fifo_mem[fifo_wr_ptr[LGFIFO-1:0]] <= M_AXI_RDATA;
			end
		end
	end

	// DMA write logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_valid_int <= 1'b0;
			aw_addr_int <= {C_AXI_ADDR_WIDTH{1'b0}};
			aw_size_int <= 3'b000;
			aw_burst_int <= 2'b00;
			aw_last_int <= 1'b0;
			w_valid_int <= 1'b0;
			w_data_int <= {C_AXI_DATA_WIDTH{1'b0}};
			w_strb_int <= {C_AXI_DATA_WIDTH/8{1'b0}};
			w_last_int <= 1'b0;
			b_ready_int <= 1'b0;
			fifo_rd_en <= 1'b0;
			fifo_rd_ptr <= {LGFIFO+1{1'b0}};
		end else begin
			// Issue write address
			if (dma_active && !aw_valid_int && fifo_not_empty && bytes_done < length_cur) begin
				aw_valid_int <= 1'b1;
				aw_addr_int <= dst_addr_cur;
				aw_size_int <= $clog2(C_AXI_DATA_WIDTH) - 3;
				aw_burst_int <= 2'b00; // FIXED
				aw_last_int <= 1'b0;
			end else if (aw_valid_int && M_AXI_AWREADY) begin
				aw_valid_int <= 1'b0;
			end

			// Issue write data
			if (dma_active && !w_valid_int && fifo_not_empty && bytes_done < length_cur) begin
				w_valid_int <= 1'b1;
				w_data_int <= fifo_mem[fifo_rd_ptr[LGFIFO-1:0]];
				w_strb_int <= {C_AXI_DATA_WIDTH/8{1'b1}};
				w_last_int <= 1'b0;
			end else if (w_valid_int && M_AXI_WREADY) begin
				w_valid_int <= 1'b0;
				fifo_rd_en <= 1'b1;
				fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
				bytes_done <= bytes_done + C_AXI_DATA_WIDTH/8;
				src_addr_cur <= src_addr_cur + C_AXI_DATA_WIDTH/8;
				dst_addr_cur <= dst_addr_cur + C_AXI_DATA_WIDTH/8;
			end

			// Ready for write response
			if (dma_active) begin
				b_ready_int <= 1'b1;
			end else begin
				b_ready_int <= 1'b0;
			end
		end
	end

endmodule

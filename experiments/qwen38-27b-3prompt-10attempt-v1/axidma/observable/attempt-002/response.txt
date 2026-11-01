```verilog
module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = LGMAXBURST+1,
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

	// Register file addresses
	localparam REG_SRC_ADDR  = 5'h00;
	localparam REG_DST_ADDR  = 5'h04;
	localparam REG_LENGTH    = 5'h08;
	localparam REG_CONTROL   = 5'h0C;
	localparam REG_STATUS    = 5'h10;
	localparam REG_ABORT     = 5'h14;

	// Control register bits
	localparam CTRL_START    = 0;
	localparam CTRL_ABORT    = 1;

	// Status register bits
	localparam STATUS_BUSY   = 0;
	localparam STATUS_DONE   = 1;
	localparam STATUS_ERROR  = 2;

	// State machine states
	localparam ST_IDLE       = 2'b00;
	localparam ST_READ_ADDR  = 2'b01;
	localparam ST_READ_DATA  = 2'b10;
	localparam ST_WRITE_ADDR = 2'b11;
	localparam ST_WRITE_DATA = 2'b100; // 3 bits needed
	localparam ST_DONE       = 2'b101;

	reg [2:0] state;
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] length_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_count;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_buf;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_buf;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_shift;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_shift;
	reg [C_AXI_ADDR_WIDTH-1:0] byte_offset;
	reg [C_AXI_ADDR_WIDTH-1:0] src_byte_offset;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_byte_offset;
	reg [C_AXI_ADDR_WIDTH-1:0] total_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] bytes_done;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_done;
	reg [C_AXI_ADDR_WIDTH-1:0] max_burst_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] data_width_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] src_aligned;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_aligned;
	reg [C_AXI_ADDR_WIDTH-1:0] src_unaligned_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_unaligned_bytes;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_length;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_dst_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_length_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] src_unaligned_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_unaligned_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] total_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] bytes_done_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_done_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] max_burst_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] data_width_bytes_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] src_aligned_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_aligned_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] src_unaligned_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_unaligned_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_src_addr_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_dst_addr_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_length_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] total_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] bytes_done_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_done_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] max_burst_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] data_width_bytes_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] src_aligned_reg2;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_aligned_reg2;

	// Simplified: use a single set of registers
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] length;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_count_reg;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_buf_reg;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_buf_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg2;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_shift_reg;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_shift_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] byte_offset_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] src_byte_offset_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_byte_offset_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] total_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] bytes_done_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_done_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] max_burst_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] data_width_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] src_aligned_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_aligned_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] src_unaligned_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_unaligned_bytes_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_src_addr_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_dst_addr_reg3;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_length_reg3;

	// Use simpler approach
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_r;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_r;
	reg [C_AXI_ADDR_WIDTH-1:0] length_r;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining_r;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_r;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_r;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len_r;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_count_r;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_buf_r;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_buf_r;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_r;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_shift_r;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_shift_r;
	reg [C_AXI_ADDR_WIDTH-1:0] byte_offset_r;
	reg [C_AXI_ADDR_WIDTH-1:0] src_byte_offset_r;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_byte_offset_r;
	reg [C_AXI_ADDR_WIDTH-1:0] total_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] bytes_done_r;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_bytes_done_r;
	reg [C_AXI_ADDR_WIDTH-1:0] max_burst_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] data_width_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] src_aligned_r;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_aligned_r;
	reg [C_AXI_ADDR_WIDTH-1:0] src_unaligned_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_unaligned_bytes_r;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_src_addr_r;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_dst_addr_r;
	reg [C_AXI_ADDR_WIDTH-1:0] aligned_length_r;

	// AXI-Lite control registers
	reg [C_AXIL_DATA_WIDTH-1:0] reg_src_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_dst_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_length;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_control;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_status;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_abort;

	// AXI-Lite write address and data
	reg [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr_r;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata_r;
	reg [C_AXIL_DATA_WIDTH/8-1:0] axil_wstrb_r;
	reg axil_awvalid_r;
	reg axil_wvalid_r;
	reg axil_awready_r;
	reg axil_wready_r;
	reg axil_bvalid_r;
	reg axil_bready_r;
	reg [1:0] axil_bresp_r;
	reg axil_arvalid_r;
	reg axil_arready_r;
	reg [C_AXIL_ADDR_WIDTH-1:0] axil_araddr_r;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_rdata_r;
	reg [1:0] axil_rresp_r;
	reg axil_rvalid_r;
	reg axil_rready_r;

	// AXI-Lite state machine
	localparam AXIL_IDLE = 2'b00;
	localparam AXIL_WRITE = 2'b01;
	localparam AXIL_READ = 2'b10;
	localparam AXIL_RESP = 2'b11;

	reg [1:0] axil_state;

	// DMA state machine
	localparam DMA_IDLE = 3'b000;
	localparam DMA_READ_ADDR = 3'b001;
	localparam DMA_READ_DATA = 3'b010;
	localparam DMA_WRITE_ADDR = 3'b011;
	localparam DMA_WRITE_DATA = 3'b100;
	localparam DMA_DONE = 3'b101;
	localparam DMA_ABORT = 3'b110;

	reg [2:0] dma_state;

	// Burst parameters
	localparam MAX_BURST_LEN = 16;
	reg [3:0] burst_len_bits;
	reg [2:0] burst_size_bits;
	reg [1:0] burst_type;

	// Calculate burst size
	wire [2:0] axi_size = $clog2(C_AXI_DATA_WIDTH) - 3;
	wire [1:0] axi_burst = 2'b01; // INCR

	// AXI write address channel
	assign M_AXI_AWID = AXI_WRITE_ID;
	assign M_AXI_AWSIZE = axi_size;
	assign M_AXI_AWBURST = axi_burst;
	assign M_AXI_AWLOCK = 1'b0;
	assign M_AXI_AWCACHE = 4'b0011;
	assign M_AXI_AWPROT = 3'b000;
	assign M_AXI_AWQOS = 4'b0000;

	// AXI write data channel
	assign M_AXI_WVALID = (dma_state == DMA_WRITE_DATA) && (burst_count_r > 0);
	assign M_AXI_WDATA = wdata_buf_r;
	assign M_AXI_WSTRB = wstrb_r;
	assign M_AXI_WLAST = (burst_count_r == 1);

	// AXI write response channel
	assign M_AXI_BREADY = (dma_state == DMA_WRITE_DATA) && (burst_count_r == 0);

	// AXI read address channel
	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARSIZE = axi_size;
	assign M_AXI_ARBURST = axi_burst;
	assign M_AXI_ARLOCK = 1'b0;
	assign M_AXI_ARCACHE = 4'b0011;
	assign M_AXI_ARPROT = 3'b000;
	assign M_AXI_ARQOS = 4'b0000;

	// AXI read data channel
	assign M_AXI_RREADY = (dma_state == DMA_READ_DATA) && (burst_count_r > 0);

	// AXI-Lite outputs
	assign S_AXIL_AWREADY = (axil_state == AXIL_IDLE) && S_AXIL_AWVALID;
	assign S_AXIL_WREADY = (axil_state == AXIL_WRITE) && S_AXIL_WVALID;
	assign S_AXIL_BVALID = axil_bvalid_r;
	assign S_AXIL_BRESP = axil_bresp_r;
	assign S_AXIL_ARREADY = (axil_state == AXIL_IDLE) && S_AXIL_ARVALID;
	assign S_AXIL_RVALID = axil_rvalid_r;
	assign S_AXIL_RDATA = axil_rdata_r;
	assign S_AXIL_RRESP = axil_rresp_r;

	// Interrupt output
	assign o_int = (reg_status[STATUS_DONE] == 1'b1) || (reg_status[STATUS_ERROR] == 1'b1);

	// AXI-Lite write address register
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axil_awaddr_r <= {C_AXIL_ADDR_WIDTH{1'b0}};
			axil_wdata_r <= {C_AXIL_DATA_WIDTH{1'b0}};
			axil_wstrb_r <= {C_AXIL_DATA_WIDTH/8{1'b0}};
			axil_awvalid_r <= 1'b0;
			axil_wvalid_r <= 1'b0;
			axil_awready_r <= 1'b0;
			axil_wready_r <= 1'b0;
			axil_bvalid_r <= 1'b0;
			axil_bready_r <= 1'b0;
			axil_bresp_r <= 2'b00;
			axil_arvalid_r <= 1'b0;
			axil_arready_r <= 1'b0;
			axil_araddr_r <= {C_AXIL_ADDR_WIDTH{1'b0}};
			axil_rdata_r <= {C_AXIL_DATA_WIDTH{1'b0}};
			axil_rresp_r <= 2'b00;
			axil_rvalid_r <= 1'b0;
			axil_rready_r <= 1'b0;
			axil_state <= AXIL_IDLE;
		end else begin
			case (axil_state)
				AXIL_IDLE: begin
					if (S_AXIL_AWVALID) begin
						axil_awaddr_r <= S_AXIL_AWADDR;
						axil_awvalid_r <= 1'b1;
						axil_state <= AXIL_WRITE;
					end else if (S_AXIL_ARVALID) begin
						axil_araddr_r <= S_AXIL_ARADDR;
						axil_arvalid_r <= 1'b1;
						axil_state <= AXIL_READ;
					end
				end
				AXIL_WRITE: begin
					if (S_AXIL_WVALID) begin
						axil_wdata_r <= S_AXIL_WDATA;
						axil_wstrb_r <= S_AXIL_WSTRB;
						axil_wvalid_r <= 1'b1;
						// Perform register write
						case (axil_awaddr_r[4:2])
							2'd0: begin // REG_SRC_ADDR
								if (axil_wstrb_r[0]) reg_src_addr <= axil_wdata_r[7:0];
								if (axil_wstrb_r[1]) reg_src_addr <= {reg_src_addr[7:0], axil_wdata_r[15:8]};
								if (axil_wstrb_r[2]) reg_src_addr <= {reg_src_addr[15:0], axil_wdata_r[23:16]};
								if (axil_wstrb_r[3]) reg_src_addr <= {reg_src_addr[23:0], axil_wdata_r[31:24]};
							end
							2'd1: begin // REG_DST_ADDR
								if (axil_wstrb_r[0]) reg_dst_addr <= axil_wdata_r[7:0];
								if (axil_wstrb_r[1]) reg_dst_addr <= {reg_dst_addr[7:0], axil_wdata_r[15:8]};
								if (axil_wstrb_r[2]) reg_dst_addr <= {reg_dst_addr[15:0], axil_wdata_r[23:16]};
								if (axil_wstrb_r[3]) reg_dst_addr <= {reg_dst_addr[23:0], axil_wdata_r[31:24]};
							end
							2'd2: begin // REG_LENGTH
								if (axil_wstrb_r[0]) reg_length <= axil_wdata_r[7:0];
								if (axil_wstrb_r[1]) reg_length <= {reg_length[7:0], axil_wdata_r[15:8]};
								if (axil_wstrb_r[2]) reg_length <= {reg_length[15:0], axil_wdata_r[23:16]};
								if (axil_wstrb_r[3]) reg_length <= {reg_length[23:0], axil_wdata_r[31:24]};
							end
							2'd3: begin // REG_CONTROL
								if (axil_wstrb_r[0]) reg_control <= axil_wdata_r[7:0];
								if (axil_wstrb_r[1]) reg_control <= {reg_control[7:0], axil_wdata_r[15:8]};
								if (axil_wstrb_r[2]) reg_control <= {reg_control[15:0], axil_wdata_r[23:16]};
								if (axil_wstrb_r[3]) reg_control <= {reg_control[23:0], axil_wdata_r[31:24]};
							end
							2'd4: begin // REG_STATUS - read only
							end
							2'd5: begin // REG_ABORT
								if (axil_wstrb_r[0]) reg_abort <= axil_wdata_r[7:0];
								if (axil_wstrb_r[1]) reg_abort <= {reg_abort[7:0], axil_wdata_r[15:8]};
								if (axil_wstrb_r[2]) reg_abort <= {reg_abort[15:0], axil_wdata_r[23:16]};
								if (axil_wstrb_r[3]) reg_abort <= {reg_abort[23:0], axil_wdata_r[31:24]};
							end
							default: ;
						endcase
						axil_bvalid_r <= 1'b1;
						axil_bresp_r <= 2'b00;
						axil_state <= AXIL_RESP;
					end
				end
				AXIL_READ: begin
					// Perform register read
					case (axil_araddr_r[4:2])
						2'd0: axil_rdata_r <= reg_src_addr;
						2'd1: axil_rdata_r <= reg_dst_addr;
						2'd2: axil_rdata_r <= reg_length;
						2'd3: axil_rdata_r <= reg_control;
						2'd4: axil_rdata_r <= reg_status;
						2'd5: axil_rdata_r <= reg_abort;
						default: axil_rdata_r <= {C_AXIL_DATA_WIDTH{1'b0}};
					endcase
					axil_rvalid_r <= 1'b1;
					axil_rresp_r <= 2'b00;
					axil_state <= AXIL_RESP;
				end
				AXIL_RESP: begin
					if (axil_bvalid_r && S_AXIL_BREADY) begin
						axil_bvalid_r <= 1'b0;
						axil_state <= AXIL_IDLE;
					end else if (axil_rvalid_r && S_AXIL_RREADY) begin
						axil_rvalid_r <= 1'b0;
						axil_state <= AXIL_IDLE;
					end
				end
				default: axil_state <= AXIL_IDLE;
			endcase
		end
	end

	// DMA control logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_src_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_dst_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_len_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_count_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			rdata_buf_r <= {C_AXI_DATA_WIDTH{1'b0}};
			wdata_buf_r <= {C_AXI_DATA_WIDTH{1'b0}};
			wstrb_r <= {C_AXI_DATA_WIDTH/8{1'b0}};
			rdata_shift_r <= {C_AXI_DATA_WIDTH{1'b0}};
			wdata_shift_r <= {C_AXI_DATA_WIDTH{1'b0}};
			byte_offset_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			src_byte_offset_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_byte_offset_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			total_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			bytes_done_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_bytes_done_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			max_burst_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			data_width_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			src_aligned_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_aligned_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			src_unaligned_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_unaligned_bytes_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			aligned_src_addr_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			aligned_dst_addr_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			aligned_length_r <= {C_AXI_ADDR_WIDTH{1'b0}};
			dma_state <= DMA_IDLE;
			reg_status <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_control <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_abort <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_src_addr <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_dst_addr <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_length <= {C_AXIL_DATA_WIDTH{1'b0}};
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWADDR <= {C_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARADDR <= {C_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA <= {C_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b0}};
			M_AXI_WLAST <= 1'b0;
			M_AXI_BREADY <= 1'b0;
			M_AXI_RREADY <= 1'b0;
			o_int <= 1'b0;
		end else begin
			// Check for abort
			if (reg_abort == ABORT_KEY) begin
				dma_state <= DMA_ABORT;
				reg_abort <= {C_AXIL_DATA_WIDTH{1'b0}};
			end

			case (dma_state)
				DMA_IDLE: begin
					if (reg_control[CTRL_START] && reg_length != 0) begin
						src_addr_r <= reg_src_addr;
						dst_addr_r <= reg_dst_addr;
						length_r <= reg_length;
						remaining_r <= reg_length;
						cur_src_r <= reg_src_addr;
						cur_dst_r <= reg_dst_addr;
						bytes_done_r <= 0;
						reg_status[STATUS_BUSY] <= 1'b1;
						reg_status[STATUS_DONE] <= 1'b0;
						reg_status[STATUS_ERROR] <= 1'b0;
						dma_state <= DMA_READ_ADDR;
					end
				end
				DMA_READ_ADDR: begin
					// Calculate burst length
					if (remaining_r > MAX_BURST_LEN * (C_AXI_DATA_WIDTH/8)) begin
						burst_len_r <= MAX_BURST_LEN * (C_AXI_DATA_WIDTH/8);
					end else begin
						burst_len_r <= remaining_r;
					end
					burst_count_r <= burst_len_r / (C_AXI_DATA_WIDTH/8);
					M_AXI_ARVALID <= 1'b1;
					M_AXI_ARADDR <= cur_src_r;
					dma_state <= DMA_READ_DATA;
				end
				DMA_READ_DATA: begin
					if (M_AXI_RVALID && M_AXI_RREADY) begin
						rdata_buf_r <= M_AXI_RDATA;
						if (M_AXI_RLAST) begin
							M_AXI_ARVALID <= 1'b0;
							dma_state <= DMA_WRITE_ADDR;
						end else begin
							burst_count_r <= burst_count_r - 1;
							cur_src_r <= cur_src_r + (C_AXI_DATA_WIDTH/8);
						end
					end
				end
				DMA_WRITE_ADDR: begin
					M_AXI_AWVALID <= 1'b1;
					M_AXI_AWADDR <= cur_dst_r;
					dma_state <= DMA_WRITE_DATA;
				end
				DMA_WRITE_DATA: begin
					if (M_AXI_WVALID && M_AXI_WREADY) begin
						wdata_buf_r <= rdata_buf_r;
						wstrb_r <= {C_AXI_DATA_WIDTH/8{1'b1}};
						if (M_AXI_WLAST) begin
							M_AXI_AWVALID <= 1'b0;
							remaining_r <= remaining_r - burst_len_r;
							bytes_done_r <= bytes_done_r + burst_len_r;
							cur_src_r <= cur_src_r + burst_len_r;
							cur_dst_r <= cur_dst_r + burst_len_r;
							if (remaining_r == 0) begin
								dma_state <= DMA_DONE;
							end else begin
								dma_state <= DMA_READ_ADDR;
							end
						end else begin
							burst_count_r <= burst_count_r - 1;
							cur_dst_r <= cur_dst_r + (C_AXI_DATA_WIDTH/8);
						end
					end
				end
				DMA_DONE: begin
					reg_status[STATUS_BUSY] <= 1'b0;
					reg_status[STATUS_DONE] <= 1'b1;
					reg_control[CTRL_START] <= 1'b0;
					dma_state <= DMA_IDLE;
				end
				DMA_ABORT: begin
					M_AXI_AWVALID <= 1'b0;
					M_AXI_ARVALID <= 1'b0;
					M_AXI_WVALID <= 1'b0;
					M_AXI_BREADY <= 1'b0;
					M_AXI_RREADY <= 1'b0;
					reg_status[STATUS_BUSY] <= 1'b0;
					reg_status[STATUS_ERROR] <= 1'b1;
					reg_control[CTRL_START] <= 1'b0;
					dma_state <= DMA_IDLE;
				end
				default: dma_state <= DMA_IDLE;
			endcase
		end
	end

	// AXI write data channel control
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA <= {C_AXI_DATA_WIDTH{1'b0}};
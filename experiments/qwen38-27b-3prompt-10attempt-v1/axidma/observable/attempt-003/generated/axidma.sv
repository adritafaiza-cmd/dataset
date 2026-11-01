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

	// AXI-Lite register map
	// 0x00: Control/Status (RW)
	// 0x04: Source Address (RW)
	// 0x08: Destination Address (RW)
	// 0x0C: Transfer Length (RW)
	// 0x10: Interrupt Status (RC)
	// 0x14: Interrupt Enable (RW)

	localparam REG_CTRL = 5'h00;
	localparam REG_SRC_ADDR = 5'h04;
	localparam REG_DST_ADDR = 5'h08;
	localparam REG_LEN = 5'h0C;
	localparam REG_INT_STATUS = 5'h10;
	localparam REG_INT_ENABLE = 5'h14;

	// Control register bits
	localparam CTRL_START = 1'b1;
	localparam CTRL_ABORT = 1'b1;
	localparam STATUS_BUSY = 1'b1;
	localparam STATUS_DONE = 1'b1;
	localparam STATUS_ERROR = 1'b1;

	// State machine states
	localparam S_IDLE = 2'd0;
	localparam S_READ_ADDR = 2'd1;
	localparam S_READ_DATA = 2'd2;
	localparam S_WRITE_ADDR = 2'd3;
	localparam S_WRITE_DATA = 2'd4;
	localparam S_WRITE_RESP = 2'd5;
	localparam S_DONE = 2'd6;

	reg [1:0] state;
	reg [1:0] next_state;

	// Configuration registers
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] transfer_len;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining_len;
	reg [C_AXI_ADDR_WIDTH-1:0] current_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] current_dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_remaining;
	reg [C_AXI_ADDR_WIDTH-1:0] read_data_count;
	reg [C_AXI_ADDR_WIDTH-1:0] write_data_count;

	// Control/Status
	reg ctrl_start;
	reg ctrl_abort;
	reg status_busy;
	reg status_done;
	reg status_error;

	// Interrupt
	reg int_status_done;
	reg int_status_error;
	reg [1:0] int_enable;

	// AXI-Lite write address/data
	reg [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata;
	reg [C_AXIL_DATA_WIDTH/8-1:0] axil_wstrb;
	reg axil_awvalid_reg;
	reg axil_wvalid_reg;
	reg axil_bvalid_reg;
	reg [1:0] axil_bresp_reg;

	// AXI-Lite read address
	reg [C_AXIL_ADDR_WIDTH-1:0] axil_araddr;
	reg axil_arvalid_reg;
	reg axil_rvalid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_rdata_reg;
	reg [1:0] axil_rresp_reg;

	// AXI write address
	reg [C_AXI_ID_WIDTH-1:0] axi_awid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
	reg [2:0] axi_awsize_reg;
	reg [1:0] axi_awburst_reg;
	reg axi_awlock_reg;
	reg [3:0] axi_awcache_reg;
	reg [2:0] axi_awprot_reg;
	reg [3:0] axi_awqos_reg;
	reg axi_awvalid_reg;

	// AXI write data
	reg [C_AXI_DATA_WIDTH-1:0] axi_wdata_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] axi_wstrb_reg;
	reg axi_wlast_reg;
	reg axi_wvalid_reg;
	reg axi_bready_reg;

	// AXI read address
	reg [C_AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
	reg axi_arvalid_reg;

	// AXI read data
	reg axi_rready_reg;

	// FIFO for read data
	localparam FIFO_DEPTH = 16;
	localparam FIFO_WIDTH = C_AXI_DATA_WIDTH;
	reg [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	reg [4:0] fifo_wr_ptr;
	reg [4:0] fifo_rd_ptr;
	reg [4:0] fifo_count;

	// Read data buffer
	reg [FIFO_WIDTH-1:0] read_data_buf;
	reg read_data_valid;

	// Write data buffer
	reg [FIFO_WIDTH-1:0] write_data_buf;
	reg write_data_valid;

	// AXI-Lite ready signals
	wire axil_awready = (state == S_IDLE) && !axil_awvalid_reg && !axil_wvalid_reg && !axil_bvalid_reg;
	wire axil_wready = (state == S_IDLE) && axil_awvalid_reg && !axil_wvalid_reg && !axil_bvalid_reg;
	wire axil_arready = (state == S_IDLE) && !axil_arvalid_reg && !axil_rvalid_reg;

	// AXI-Lite response
	assign S_AXIL_AWREADY = axil_awready;
	assign S_AXIL_WREADY = axil_wready;
	assign S_AXIL_ARREADY = axil_arready;
	assign S_AXIL_BVALID = axil_bvalid_reg;
	assign S_AXIL_BRESP = axil_bresp_reg;
	assign S_AXIL_RVALID = axil_rvalid_reg;
	assign S_AXIL_RDATA = axil_rdata_reg;
	assign S_AXIL_RRESP = axil_rresp_reg;

	// AXI write address
	assign M_AXI_AWVALID = axi_awvalid_reg;
	assign M_AXI_AWID = axi_awid_reg;
	assign M_AXI_AWADDR = axi_awaddr_reg;
	assign M_AXI_AWSIZE = axi_awsize_reg;
	assign M_AXI_AWBURST = axi_awburst_reg;
	assign M_AXI_AWLOCK = axi_awlock_reg;
	assign M_AXI_AWCACHE = axi_awcache_reg;
	assign M_AXI_AWPROT = axi_awprot_reg;
	assign M_AXI_AWQOS = axi_awqos_reg;

	// AXI write data
	assign M_AXI_WVALID = axi_wvalid_reg;
	assign M_AXI_WDATA = axi_wdata_reg;
	assign M_AXI_WSTRB = axi_wstrb_reg;
	assign M_AXI_WLAST = axi_wlast_reg;
	assign M_AXI_BREADY = axi_bready_reg;

	// AXI read address
	assign M_AXI_ARVALID = axi_arvalid_reg;
	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARADDR = axi_araddr_reg;
	assign M_AXI_ARSIZE = axi_awsize_reg;
	assign M_AXI_ARBURST = axi_awburst_reg;
	assign M_AXI_ARLOCK = axi_awlock_reg;
	assign M_AXI_ARCACHE = axi_awcache_reg;
	assign M_AXI_ARPROT = axi_awprot_reg;
	assign M_AXI_ARQOS = axi_awqos_reg;

	// AXI read data
	assign M_AXI_RREADY = axi_rready_reg;

	// Interrupt output
	assign o_int = (int_status_done & int_enable[0]) | (int_status_error & int_enable[1]);

	// AXI size calculation
	wire [2:0] axi_size = $clog2(C_AXI_DATA_WIDTH) - 2;

	// Burst length calculation (max 256)
	function [C_AXI_ADDR_WIDTH-1:0] calc_burst_len;
		input [C_AXI_ADDR_WIDTH-1:0] len;
		begin
			if (len > 256)
				calc_burst_len = 256;
			else
				calc_burst_len = len;
		end
	endfunction

	// AXI burst type
	wire [1:0] axi_burst_type = 2'b01; // INCR

	// Reset
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= S_IDLE;
			src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			transfer_len <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining_len <= {C_AXI_ADDR_WIDTH{1'b0}};
			current_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			current_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_len <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_remaining <= {C_AXI_ADDR_WIDTH{1'b0}};
			read_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
			write_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
			ctrl_start <= 1'b0;
			ctrl_abort <= 1'b0;
			status_busy <= 1'b0;
			status_done <= 1'b0;
			status_error <= 1'b0;
			int_status_done <= 1'b0;
			int_status_error <= 1'b0;
			int_enable <= 2'b00;
			axil_awaddr <= {C_AXIL_ADDR_WIDTH{1'b0}};
			axil_wdata <= {C_AXIL_DATA_WIDTH{1'b0}};
			axil_wstrb <= {C_AXIL_DATA_WIDTH/8{1'b0}};
			axil_awvalid_reg <= 1'b0;
			axil_wvalid_reg <= 1'b0;
			axil_bvalid_reg <= 1'b0;
			axil_bresp_reg <= 2'b00;
			axil_araddr <= {C_AXIL_ADDR_WIDTH{1'b0}};
			axil_arvalid_reg <= 1'b0;
			axil_rvalid_reg <= 1'b0;
			axil_rdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
			axil_rresp_reg <= 2'b00;
			axi_awid_reg <= {C_AXI_ID_WIDTH{1'b0}};
			axi_awaddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			axi_awsize_reg <= 3'b000;
			axi_awburst_reg <= 2'b00;
			axi_awlock_reg <= 1'b0;
			axi_awcache_reg <= 4'b0000;
			axi_awprot_reg <= 3'b000;
			axi_awqos_reg <= 4'b0000;
			axi_awvalid_reg <= 1'b0;
			axi_wdata_reg <= {C_AXI_DATA_WIDTH{1'b0}};
			axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b0}};
			axi_wlast_reg <= 1'b0;
			axi_wvalid_reg <= 1'b0;
			axi_bready_reg <= 1'b0;
			axi_araddr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			axi_arvalid_reg <= 1'b0;
			axi_rready_reg <= 1'b0;
			fifo_wr_ptr <= 5'd0;
			fifo_rd_ptr <= 5'd0;
			fifo_count <= 5'd0;
			read_data_buf <= {FIFO_WIDTH{1'b0}};
			read_data_valid <= 1'b0;
			write_data_buf <= {FIFO_WIDTH{1'b0}};
			write_data_valid <= 1'b0;
		end else begin
			// AXI-Lite write address
			if (S_AXIL_AWVALID && axil_awready) begin
				axil_awaddr <= S_AXIL_AWADDR;
				axil_awvalid_reg <= 1'b1;
			end

			// AXI-Lite write data
			if (S_AXIL_WVALID && axil_wready) begin
				axil_wdata <= S_AXIL_WDATA;
				axil_wstrb <= S_AXIL_WSTRB;
				axil_wvalid_reg <= 1'b1;
			end

			// AXI-Lite write response
			if (axil_awvalid_reg && axil_wvalid_reg) begin
				// Perform register write
				case (axil_awaddr)
					REG_CTRL: begin
						ctrl_start <= axil_wdata[0];
						ctrl_abort <= axil_wdata[1];
						if (axil_wdata[0]) begin
							remaining_len <= transfer_len;
							current_src_addr <= src_addr;
							current_dst_addr <= dst_addr;
							status_busy <= 1'b1;
							status_done <= 1'b0;
							status_error <= 1'b0;
							int_status_done <= 1'b0;
							int_status_error <= 1'b0;
							read_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
							write_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
							fifo_wr_ptr <= 5'd0;
							fifo_rd_ptr <= 5'd0;
							fifo_count <= 5'd0;
							read_data_valid <= 1'b0;
							write_data_valid <= 1'b0;
						end
					end
					REG_SRC_ADDR: src_addr <= axil_wdata;
					REG_DST_ADDR: dst_addr <= axil_wdata;
					REG_LEN: transfer_len <= axil_wdata;
					REG_INT_STATUS: begin
						if (axil_wdata[0]) int_status_done <= 1'b0;
						if (axil_wdata[1]) int_status_error <= 1'b0;
					end
					REG_INT_ENABLE: int_enable <= axil_wdata[1:0];
					default: ;
				endcase
				axil_awvalid_reg <= 1'b0;
				axil_wvalid_reg <= 1'b0;
				axil_bvalid_reg <= 1'b1;
				axil_bresp_reg <= 2'b00;
			end

			// AXI-Lite write response ready
			if (axil_bvalid_reg && S_AXIL_BREADY) begin
				axil_bvalid_reg <= 1'b0;
			end

			// AXI-Lite read address
			if (S_AXIL_ARVALID && axil_arready) begin
				axil_araddr <= S_AXIL_ARADDR;
				axil_arvalid_reg <= 1'b1;
			end

			// AXI-Lite read data
			if (axil_arvalid_reg) begin
				case (axil_araddr)
					REG_CTRL: begin
						axil_rdata_reg <= {31'b0, status_error, status_done, status_busy, ctrl_abort, ctrl_start};
					end
					REG_SRC_ADDR: axil_rdata_reg <= src_addr;
					REG_DST_ADDR: axil_rdata_reg <= dst_addr;
					REG_LEN: axil_rdata_reg <= transfer_len;
					REG_INT_STATUS: axil_rdata_reg <= {30'b0, int_status_error, int_status_done};
					REG_INT_ENABLE: axil_rdata_reg <= {30'b0, int_enable};
					default: axil_rdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
				endcase
				axil_arvalid_reg <= 1'b0;
				axil_rvalid_reg <= 1'b1;
				axil_rresp_reg <= 2'b00;
			end

			// AXI-Lite read data ready
			if (axil_rvalid_reg && S_AXIL_RREADY) begin
				axil_rvalid_reg <= 1'b0;
			end

			// State machine
			case (state)
				S_IDLE: begin
					if (ctrl_start && !status_busy) begin
						if (transfer_len > 0) begin
							burst_len <= calc_burst_len(remaining_len);
							burst_remaining <= burst_len;
							axi_awid_reg <= AXI_WRITE_ID;
							axi_awaddr_reg <= current_dst_addr;
							axi_awsize_reg <= axi_size;
							axi_awburst_reg <= axi_burst_type;
							axi_awlock_reg <= 1'b0;
							axi_awcache_reg <= 4'b0000;
							axi_awprot_reg <= 3'b000;
							axi_awqos_reg <= 4'b0000;
							axi_awvalid_reg <= 1'b1;
							axi_araddr_reg <= current_src_addr;
							axi_arvalid_reg <= 1'b1;
							axi_rready_reg <= 1'b1;
							state <= S_READ_DATA;
						end else begin
							status_done <= 1'b1;
							int_status_done <= 1'b1;
							status_busy <= 1'b0;
							state <= S_DONE;
						end
					end
				end

				S_READ_DATA: begin
					// Wait for read data
					if (M_AXI_RVALID && axi_rready_reg) begin
						// Store read data in FIFO
						fifo_mem[fifo_wr_ptr] <= M_AXI_RDATA;
						fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
						fifo_count <= fifo_count + 1'b1;
						read_data_count <= read_data_count + 1'b1;
						burst_remaining <= burst_remaining - 1'b1;
						current_src_addr <= current_src_addr + C_AXI_DATA_WIDTH/8;

						if (M_AXI_RLAST) begin
							// Burst complete
							if (remaining_len > burst_len) begin
								remaining_len <= remaining_len - burst_len;
								burst_len <= calc_burst_len(remaining_len);
								burst_remaining <= burst_len;
								axi_awid_reg <= AXI_WRITE_ID;
								axi_awaddr_reg <= current_dst_addr;
								axi_awsize_reg <= axi_size;
								axi_awburst_reg <= axi_burst_type;
								axi_awlock_reg <= 1'b0;
								axi_awcache_reg <= 4'b0000;
								axi_awprot_reg <= 3'b000;
								axi_awqos_reg <= 4'b0000;
								axi_awvalid_reg <= 1'b1;
								axi_araddr_reg <= current_src_addr;
								axi_arvalid_reg <= 1'b1;
								state <= S_READ_DATA;
							end else begin
								// All data read
								state <= S_WRITE_DATA;
							end
						end
					end
				end

				S_WRITE_DATA: begin
					// Wait for write address ready
					if (M_AXI_AWREADY) begin
						axi_awvalid_reg <= 1'b0;
						// Start sending write data
						if (fifo_count > 0) begin
							write_data_buf <= fifo_mem[fifo_rd_ptr];
							write_data_valid <= 1'b1;
							axi_wdata_reg <= fifo_mem[fifo_rd_ptr];
							axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
							axi_wlast_reg <= (burst_remaining == 1'b1);
							axi_wvalid_reg <= 1'b1;
							state <= S_WRITE_DATA;
						end else begin
							// No more data to write
							state <= S_WRITE_RESP;
						end
					end
				end

				S_WRITE_RESP: begin
					// Wait for write response
					if (M_AXI_BVALID && axi_bready_reg) begin
						axi_bready_reg <= 1'b0;
						write_data_count <= write_data_count + 1'b1;
						burst_remaining <= burst_remaining - 1'b1;
						current_dst_addr <= current_dst_addr + C_AXI_DATA_WIDTH/8;

						if (M_AXI_BRESP != 2'b00) begin
							status_error <= 1'b1;
							int_status_error <= 1'b1;
							status_busy <= 1'b0;
							state <= S_DONE;
						end else if (remaining_len > burst_len) begin
							remaining_len <= remaining_len - burst_len;
							burst_len <= calc_burst_len(remaining_len);
							burst_remaining <= burst_len;
							axi_awid_reg <= AXI_WRITE_ID;
							axi_awaddr_reg <= current_dst_addr;
							axi_awsize_reg <= axi_size;
							axi_awburst_reg <= axi_burst_type;
							axi_awlock_reg <= 1'b0;
							axi_awcache_reg <= 4'b0000;
							axi_awprot_reg <= 3'b000;
							axi_awqos_reg <= 4'b0000;
							axi_awvalid_reg <= 1'b1;
							axi_araddr_reg <= current_src_addr;
							axi_arvalid_reg <= 1'b1;
							axi_rready_reg <= 1'b1;
							state <= S_READ_DATA;
						end else begin
							status_done <= 1'b1;
							int_status_done <= 1'b1;
							status_busy <= 1'b0;
							state <= S_DONE;
						end
					end
				end

				S_DONE: begin
					// Wait for interrupt to be cleared or new start
					if (ctrl_start && !status_busy) begin
						if (transfer_len > 0) begin
							remaining_len <= transfer_len;
							current_src_addr <= src_addr;
							current_dst_addr <= dst_addr;
							status_busy <= 1'b1;
							status_done <= 1'b0;
							status_error <= 1'b0;
							int_status_done <= 1'b0;
							int_status_error <= 1'b0;
							read_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
							write_data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
							fifo_wr_ptr <= 5'd0;
							fifo_rd_ptr <= 5'd0;
							fifo_count <= 5'd0;
							read_data_valid <= 1'b0;
							write_data_valid <= 1'b0;
							burst_len <= calc_burst_len(remaining_len);
							burst_remaining <= burst_len;
							axi_awid_reg <= AXI_WRITE_ID;
							axi_awaddr_reg <= current_dst_addr;
							axi_awsize_reg <= axi_size;
							axi_awburst_reg <= axi_burst_type;
							axi_awlock_reg <= 1'b0;
							axi_awcache_reg <= 4'b0000;
							axi_awprot_reg <= 3'b000;
							axi_awqos_reg <= 4'b0000;
							axi_awvalid_reg <= 1'b1;
							axi_araddr_reg <= current_src_addr;
							axi_arvalid_reg <= 1'b1;
							axi_rready_reg <= 1'b1;
							state <= S_READ_DATA;
						end
					end
				end

				default: state <= S_IDLE;
			endcase

			// Handle abort
			if (ctrl_abort && status_busy) begin
				status_busy <= 1'b0;
				status_error <= 1'b1;
				int_status_error <= 1'b1;
				state <= S_DONE;
			end

			// Handle write data
			if (axi_wvalid_reg && M_AXI_WREADY) begin
				fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
				fifo_count <= fifo_count - 1'b1;
				if (axi_wlast_reg) begin
					axi_wvalid_reg <= 1'b0;
					axi_bready_reg <= 1'b1;
				end else begin
					if (fifo_count > 1) begin
						axi_wdata_reg <= fifo_mem[fifo_rd_ptr + 1'b1];
						axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
						axi_wlast_reg <= (burst_remaining == 2'b1);
					end else begin
						axi_wvalid_reg <= 1'b0;
						axi_bready_reg <= 1'b1;
					end
				end
			end
		end
	end

endmodule

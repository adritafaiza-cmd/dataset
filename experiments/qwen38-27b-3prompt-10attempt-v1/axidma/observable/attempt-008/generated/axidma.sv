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
	localparam ST_IDLE       = 3'd0;
	localparam ST_READ_ADDR  = 3'd1;
	localparam ST_READ_DATA  = 3'd2;
	localparam ST_WRITE_ADDR = 3'd3;
	localparam ST_WRITE_DATA = 3'd4;
	localparam ST_WRITE_RESP = 3'd5;
	localparam ST_DONE       = 3'd6;

	// Internal signals
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] length_reg;
	reg [1:0] control_reg;
	reg [2:0] status_reg;

	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_cur;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_cur;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining;

	reg [2:0] state;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len;
	reg [C_AXI_ADDR_WIDTH-1:0] beat_count;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_buf;
	reg [C_AXI_DATA_WIDTH-1:0] wdata_buf;
	reg wdata_valid;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;

	// AXI-Lite control
	reg axil_awaddr_reg;
	reg axil_araddr_reg;
	reg axil_write_pending;
	reg axil_read_pending;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata_reg;
	reg [C_AXIL_DATA_WIDTH/8-1:0] axil_wstrb_reg;

	// AXI-Lite ready signals
	wire axil_awready = (state == ST_IDLE) && !axil_write_pending && !axil_read_pending;
	wire axil_wready  = axil_awready && axil_write_pending;
	wire axil_arready = (state == ST_IDLE) && !axil_write_pending && !axil_read_pending;

	// AXI-Lite response
	assign S_AXIL_BRESP = 2'b00;
	assign S_AXIL_RRESP = 2'b00;

	// AXI master signals
	assign M_AXI_ARID    = AXI_READ_ID;
	assign M_AXI_ARSIZE  = $clog2(C_AXI_DATA_WIDTH) - 2;
	assign M_AXI_ARBURST = 2'b01; // INCR
	assign M_AXI_ARLOCK  = 1'b0;
	assign M_AXI_ARCACHE = 4'b0011;
	assign M_AXI_ARPROT  = 3'b000;
	assign M_AXI_ARQOS   = 4'b0000;

	assign M_AXI_RREADY  = (state == ST_READ_DATA) && !wdata_valid;

	// Write channel
	assign M_AXI_AWID    = AXI_WRITE_ID;
	assign M_AXI_AWSIZE  = $clog2(C_AXI_DATA_WIDTH) - 2;
	assign M_AXI_AWBURST = 2'b01; // INCR
	assign M_AXI_AWLOCK  = 1'b0;
	assign M_AXI_AWCACHE = 4'b0011;
	assign M_AXI_AWPROT  = 3'b000;
	assign M_AXI_AWQOS   = 4'b0000;

	assign M_AXI_BREADY  = (state == ST_WRITE_RESP);

	// Interrupt
	assign o_int = status_reg[STATUS_DONE] || status_reg[STATUS_ERROR];

	// AXI-Lite write address decode
	wire [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr = S_AXIL_AWADDR;
	wire [C_AXIL_ADDR_WIDTH-1:0] axil_araddr = S_AXIL_ARADDR;

	// AXI-Lite write data handling
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axil_awaddr_reg   <= 1'b0;
			axil_araddr_reg   <= 1'b0;
			axil_write_pending <= 1'b0;
			axil_read_pending  <= 1'b0;
			axil_wdata_reg    <= {C_AXIL_DATA_WIDTH{1'b0}};
			axil_wstrb_reg    <= {C_AXIL_DATA_WIDTH/8{1'b0}};
			S_AXIL_BVALID     <= 1'b0;
			S_AXIL_RVALID     <= 1'b0;
			S_AXIL_RDATA      <= {C_AXIL_DATA_WIDTH{1'b0}};
		end else begin
			// Write address phase
			if (S_AXIL_AWVALID && axil_awready) begin
				axil_awaddr_reg    <= axil_awaddr;
				axil_write_pending <= 1'b1;
			end

			// Write data phase
			if (S_AXIL_WVALID && axil_wready) begin
				axil_wdata_reg <= S_AXIL_WDATA;
				axil_wstrb_reg <= S_AXIL_WSTRB;
				axil_write_pending <= 1'b0;
				S_AXIL_BVALID    <= 1'b1;
			end

			// Write response
			if (S_AXIL_BVALID && S_AXIL_BREADY) begin
				S_AXIL_BVALID <= 1'b0;
			end

			// Read address phase
			if (S_AXIL_ARVALID && axil_arready) begin
				axil_araddr_reg   <= axil_araddr;
				axil_read_pending <= 1'b1;
			end

			// Read data phase
			if (axil_read_pending) begin
				case (axil_araddr_reg)
					REG_SRC_ADDR:  S_AXIL_RDATA <= {16'b0, src_addr_reg};
					REG_DST_ADDR:  S_AXIL_RDATA <= {16'b0, dst_addr_reg};
					REG_LENGTH:    S_AXIL_RDATA <= {16'b0, length_reg};
					REG_CONTROL:   S_AXIL_RDATA <= {30'b0, control_reg};
					REG_STATUS:    S_AXIL_RDATA <= {29'b0, status_reg};
					REG_ABORT:     S_AXIL_RDATA <= {32'b0};
					default:       S_AXIL_RDATA <= {32'b0};
				endcase
				S_AXIL_RVALID     <= 1'b1;
				axil_read_pending <= 1'b0;
			end

			// Read response
			if (S_AXIL_RVALID && S_AXIL_RREADY) begin
				S_AXIL_RVALID <= 1'b0;
			end
		end
	end

	// Register file write
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_reg    <= {C_AXI_ADDR_WIDTH{1'b0}};
			control_reg   <= 2'b00;
			status_reg    <= 3'b000;
		end else begin
			// Write to registers
			if (S_AXIL_WVALID && axil_wready) begin
				case (axil_awaddr)
					REG_SRC_ADDR:  src_addr_reg  <= {16'b0, S_AXIL_WDATA};
					REG_DST_ADDR:  dst_addr_reg  <= {16'b0, S_AXIL_WDATA};
					REG_LENGTH:    length_reg    <= {16'b0, S_AXIL_WDATA};
					REG_CONTROL:   control_reg   <= S_AXIL_WDATA[1:0];
					REG_ABORT:     begin
						if (S_AXIL_WDATA[7:0] == ABORT_KEY) begin
							control_reg[CTRL_ABORT] <= 1'b1;
						end
					end
					default: ;
				endcase
			end

			// Clear control bits after use
			if (state != ST_IDLE) begin
				control_reg <= 2'b00;
			end

			// Status updates
			case (state)
				ST_IDLE: begin
					if (control_reg[CTRL_START] && length_reg > 0) begin
						status_reg[STATUS_BUSY] <= 1'b1;
						status_reg[STATUS_DONE] <= 1'b0;
						status_reg[STATUS_ERROR] <= 1'b0;
					end
				end
				ST_DONE: begin
					status_reg[STATUS_BUSY] <= 1'b0;
					status_reg[STATUS_DONE] <= 1'b1;
				end
				default: ;
			endcase
		end
	end

	// DMA state machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state        <= ST_IDLE;
			src_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_cur <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining    <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_len    <= {C_AXI_ADDR_WIDTH{1'b0}};
			beat_count   <= {C_AXI_ADDR_WIDTH{1'b0}};
			rdata_buf    <= {C_AXI_DATA_WIDTH{1'b0}};
			wdata_buf    <= {C_AXI_DATA_WIDTH{1'b0}};
			wdata_valid  <= 1'b0;
			wstrb_reg    <= {C_AXI_DATA_WIDTH/8{1'b0}};
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARADDR  <= {C_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWADDR  <= {C_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_WVALID  <= 1'b0;
			M_AXI_WDATA   <= {C_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB   <= {C_AXI_DATA_WIDTH/8{1'b0}};
			M_AXI_WLAST   <= 1'b0;
		end else begin
			// Default: deassert valids
			M_AXI_ARVALID <= 1'b0;
			M_AXI_AWVALID <= 1'b0;
			M_AXI_WVALID  <= 1'b0;
			M_AXI_WLAST   <= 1'b0;

			case (state)
				ST_IDLE: begin
					if (control_reg[CTRL_START] && length_reg > 0) begin
						src_addr_cur <= src_addr_reg;
						dst_addr_cur <= dst_addr_reg;
						remaining    <= length_reg;
						state        <= ST_READ_ADDR;
					end
				end

				ST_READ_ADDR: begin
					// Calculate burst length
					if (remaining >= 16) begin
						burst_len <= 16;
					end else begin
						burst_len <= remaining;
					end
					beat_count <= 0;
					M_AXI_ARVALID <= 1'b1;
					M_AXI_ARADDR  <= src_addr_cur;
					state         <= ST_READ_DATA;
				end

				ST_READ_DATA: begin
					if (M_AXI_ARVALID && M_AXI_ARREADY) begin
						M_AXI_ARVALID <= 1'b0;
					end
					if (M_AXI_RVALID && M_AXI_RREADY) begin
						rdata_buf   <= M_AXI_RDATA;
						wdata_buf   <= M_AXI_RDATA;
						wdata_valid <= 1'b1;
						beat_count  <= beat_count + 1;
						if (M_AXI_RLAST) begin
							src_addr_cur <= src_addr_cur + (burst_len << ADDRLSB);
							remaining    <= remaining - burst_len;
							state        <= ST_WRITE_ADDR;
						end
					end
				end

				ST_WRITE_ADDR: begin
					M_AXI_AWVALID <= 1'b1;
					M_AXI_AWADDR  <= dst_addr_cur;
					state         <= ST_WRITE_DATA;
				end

				ST_WRITE_DATA: begin
					if (M_AXI_AWVALID && M_AXI_AWREADY) begin
						M_AXI_AWVALID <= 1'b0;
					end
					if (wdata_valid) begin
						M_AXI_WVALID <= 1'b1;
						M_AXI_WDATA  <= wdata_buf;
						M_AXI_WSTRB  <= {C_AXI_DATA_WIDTH/8{1'b1}};
						if (beat_count == burst_len - 1) begin
							M_AXI_WLAST <= 1'b1;
						end
						wdata_valid <= 1'b0;
						if (M_AXI_WVALID && M_AXI_WREADY) begin
							beat_count <= beat_count + 1;
							if (M_AXI_WLAST) begin
								dst_addr_cur <= dst_addr_cur + (burst_len << ADDRLSB);
								state        <= ST_WRITE_RESP;
							end
						end
					end
				end

				ST_WRITE_RESP: begin
					if (M_AXI_BVALID && M_AXI_BREADY) begin
						if (remaining == 0) begin
							state <= ST_DONE;
						end else begin
							state <= ST_READ_ADDR;
						end
					end
				end

				ST_DONE: begin
					state <= ST_IDLE;
				end

				default: begin
					state <= ST_IDLE;
				end
			endcase
		end
	end

endmodule

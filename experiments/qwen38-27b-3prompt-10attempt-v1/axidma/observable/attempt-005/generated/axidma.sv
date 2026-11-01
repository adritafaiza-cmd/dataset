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
	localparam REG_SRC_ADDR  = 4'h0;
	localparam REG_DST_ADDR  = 4'h4;
	localparam REG_LENGTH    = 4'h8;
	localparam REG_CONTROL   = 4'hC;
	localparam REG_STATUS    = 4'h10;
	localparam REG_DOORBELL  = 4'h14;

	// Control register bits
	localparam CTRL_START    = 1'b1;
	localparam CTRL_ABORT    = 1'b0; // Bit 1 reserved, use bit 0 for start

	// Status register bits
	localparam STATUS_BUSY   = 1'b1;
	localparam STATUS_DONE   = 1'b1;
	localparam STATUS_ERROR  = 1'b1;

	// State machine states
	localparam ST_IDLE       = 2'd0;
	localparam ST_READ_ADDR  = 2'd1;
	localparam ST_READ_DATA  = 2'd2;
	localparam ST_WRITE_ADDR = 2'd3;
	localparam ST_WRITE_DATA = 2'd4;
	localparam ST_WRITE_RESP = 2'd5;
	localparam ST_DONE       = 2'd6;

	reg [1:0] state;
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] length_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] cur_dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_len;
	reg [C_AXI_ADDR_WIDTH-1:0] burst_count;
	reg [C_AXI_ADDR_WIDTH-1:0] data_count;
	reg [C_AXI_DATA_WIDTH-1:0] data_buf;
	reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
	reg start_pulse;
	reg abort_pulse;
	reg busy;
	reg done;
	reg error;
	reg [C_AXI_ADDR_WIDTH-1:0] axi_len;
	reg [2:0] axi_size;
	reg [1:0] axi_burst;
	reg [C_AXI_DATA_WIDTH-1:0] rdata_buf;
	reg rlast_seen;
	reg wlast_seen;
	reg bvalid_seen;
	reg [C_AXI_ADDR_WIDTH-1:0] next_src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] next_dst_addr;

	// AXI-Lite control interface
	reg [C_AXIL_DATA_WIDTH-1:0] reg_file [0:3];
	reg [C_AXIL_ADDR_WIDTH-1:0] awaddr_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] wdata_reg;
	reg [C_AXIL_DATA_WIDTH/8-1:0] wstrb_reg_axil;
	reg awvalid_reg;
	reg wvalid_reg;
	reg bvalid_reg;
	reg arvalid_reg;
	reg rvalid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;
	reg [1:0] bresp_reg;
	reg [1:0] rresp_reg;

	assign S_AXIL_AWREADY = ~awvalid_reg & S_AXI_ARESETN;
	assign S_AXIL_WREADY = ~wvalid_reg & S_AXI_ARESETN;
	assign S_AXIL_BVALID = bvalid_reg;
	assign S_AXIL_BRESP = bresp_reg;
	assign S_AXIL_ARREADY = ~arvalid_reg & S_AXI_ARESETN;
	assign S_AXIL_RVALID = rvalid_reg;
	assign S_AXIL_RDATA = rdata_reg;
	assign S_AXIL_RRESP = rresp_reg;

	// AXI master interface
	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARSIZE = axi_size;
	assign M_AXI_ARBURST = axi_burst;
	assign M_AXI_ARLOCK = 1'b0;
	assign M_AXI_ARCACHE = 4'b0000;
	assign M_AXI_ARPROT = 3'b000;
	assign M_AXI_ARQOS = 4'b0000;
	assign M_AXI_RREADY = (state == ST_READ_DATA) & ~M_AXI_RVALID;

	// AXI write address channel
	assign M_AXI_AWID = AXI_WRITE_ID;
	assign M_AXI_AWSIZE = axi_size;
	assign M_AXI_AWBURST = axi_burst;
	assign M_AXI_AWLOCK = 1'b0;
	assign M_AXI_AWCACHE = 4'b0000;
	assign M_AXI_AWPROT = 3'b000;
	assign M_AXI_AWQOS = 4'b0000;

	// AXI write data channel
	assign M_AXI_WVALID = (state == ST_WRITE_DATA) & ~wlast_seen;
	assign M_AXI_WDATA = data_buf;
	assign M_AXI_WSTRB = wstrb_reg;
	assign M_AXI_WLAST = (burst_count == burst_len - 1);
	assign M_AXI_BREADY = (state == ST_WRITE_RESP) & ~bvalid_seen;

	// AXI read address channel
	assign M_AXI_ARVALID = (state == ST_READ_ADDR) & ~M_AXI_ARREADY;
	assign M_AXI_ARADDR = cur_src_addr;

	// AXI write address channel
	assign M_AXI_AWVALID = (state == ST_WRITE_ADDR) & ~M_AXI_AWREADY;
	assign M_AXI_AWADDR = cur_dst_addr;

	// AXI read data channel
	assign M_AXI_RREADY = (state == ST_READ_DATA);

	// AXI write response channel
	assign M_AXI_BREADY = (state == ST_WRITE_RESP);

	// Compute AXI parameters
	always @* begin
		axi_size = $clog2(C_AXI_DATA_WIDTH) - 2;
		axi_burst = 2'b01; // INCR
		axi_len = burst_len - 1;
	end

	// AXI-Lite write address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awvalid_reg <= 1'b0;
			awaddr_reg <= {C_AXIL_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
				awvalid_reg <= 1'b1;
				awaddr_reg <= S_AXIL_AWADDR;
			end else if (wvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				awvalid_reg <= 1'b0;
			end
		end
	end

	// AXI-Lite write data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			wvalid_reg <= 1'b0;
			wdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
			wstrb_reg_axil <= {C_AXIL_DATA_WIDTH/8{1'b0}};
		end else begin
			if (awvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				wvalid_reg <= 1'b1;
				wdata_reg <= S_AXIL_WDATA;
				wstrb_reg_axil <= S_AXIL_WSTRB;
			end else if (wvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				wvalid_reg <= 1'b0;
			end
		end
	end

	// AXI-Lite write response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			bvalid_reg <= 1'b0;
			bresp_reg <= 2'b00;
		end else begin
			if (wvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				bvalid_reg <= 1'b1;
				bresp_reg <= 2'b00;
			end else if (bvalid_reg && S_AXIL_BREADY) begin
				bvalid_reg <= 1'b0;
			end
		end
	end

	// AXI-Lite read address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			arvalid_reg <= 1'b0;
		end else begin
			if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
				arvalid_reg <= 1'b1;
			end else if (rvalid_reg && S_AXIL_RREADY) begin
				arvalid_reg <= 1'b0;
			end
		end
	end

	// AXI-Lite read data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			rvalid_reg <= 1'b0;
			rdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
			rresp_reg <= 2'b00;
		end else begin
			if (arvalid_reg && S_AXIL_ARVALID && S_AXIL_ARREADY) begin
				rvalid_reg <= 1'b1;
				case (S_AXIL_ARADDR[4:2])
					4'h0: rdata_reg <= reg_file[0];
					4'h1: rdata_reg <= reg_file[1];
					4'h2: rdata_reg <= reg_file[2];
					4'h3: rdata_reg <= reg_file[3];
					default: rdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
				endcase
				rresp_reg <= 2'b00;
			end else if (rvalid_reg && S_AXIL_RREADY) begin
				rvalid_reg <= 1'b0;
			end
		end
	end

	// Register file write
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			reg_file[0] <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_file[1] <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_file[2] <= {C_AXIL_DATA_WIDTH{1'b0}};
			reg_file[3] <= {C_AXIL_DATA_WIDTH{1'b0}};
		end else begin
			if (wvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				case (awaddr_reg[4:2])
					4'h0: begin
						if (wstrb_reg_axil[0]) reg_file[0][7:0] <= wdata_reg[7:0];
						if (wstrb_reg_axil[1]) reg_file[0][15:8] <= wdata_reg[15:8];
						if (wstrb_reg_axil[2]) reg_file[0][23:16] <= wdata_reg[23:16];
						if (wstrb_reg_axil[3]) reg_file[0][31:24] <= wdata_reg[31:24];
					end
					4'h1: begin
						if (wstrb_reg_axil[0]) reg_file[1][7:0] <= wdata_reg[7:0];
						if (wstrb_reg_axil[1]) reg_file[1][15:8] <= wdata_reg[15:8];
						if (wstrb_reg_axil[2]) reg_file[1][23:16] <= wdata_reg[23:16];
						if (wstrb_reg_axil[3]) reg_file[1][31:24] <= wdata_reg[31:24];
					end
					4'h2: begin
						if (wstrb_reg_axil[0]) reg_file[2][7:0] <= wdata_reg[7:0];
						if (wstrb_reg_axil[1]) reg_file[2][15:8] <= wdata_reg[15:8];
						if (wstrb_reg_axil[2]) reg_file[2][23:16] <= wdata_reg[23:16];
						if (wstrb_reg_axil[3]) reg_file[2][31:24] <= wdata_reg[31:24];
					end
					4'h3: begin
						if (wstrb_reg_axil[0]) reg_file[3][7:0] <= wdata_reg[7:0];
						if (wstrb_reg_axil[1]) reg_file[3][15:8] <= wdata_reg[15:8];
						if (wstrb_reg_axil[2]) reg_file[3][23:16] <= wdata_reg[23:16];
						if (wstrb_reg_axil[3]) reg_file[3][31:24] <= wdata_reg[31:24];
					end
					default: ;
				endcase
			end
		end
	end

	// Start and abort detection
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			start_pulse <= 1'b0;
			abort_pulse <= 1'b0;
		end else begin
			start_pulse <= 1'b0;
			abort_pulse <= 1'b0;
			if (wvalid_reg && S_AXIL_WVALID && S_AXIL_WREADY) begin
				if (awaddr_reg[4:2] == 4'h3) begin
					if (wstrb_reg_axil[0] && wdata_reg[0]) start_pulse <= 1'b1;
					if (wstrb_reg_axil[0] && wdata_reg[1]) abort_pulse <= 1'b1;
				end
			end
		end
	end

	// Main state machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= ST_IDLE;
			src_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			dst_addr_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			length_reg <= {C_AXI_ADDR_WIDTH{1'b0}};
			remaining <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			cur_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_len <= {C_AXI_ADDR_WIDTH{1'b0}};
			burst_count <= {C_AXI_ADDR_WIDTH{1'b0}};
			data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
			data_buf <= {C_AXI_DATA_WIDTH{1'b0}};
			wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b0}};
			busy <= 1'b0;
			done <= 1'b0;
			error <= 1'b0;
			rlast_seen <= 1'b0;
			wlast_seen <= 1'b0;
			bvalid_seen <= 1'b0;
			next_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			next_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
			o_int <= 1'b0;
		end else begin
			// Default: clear one-shot flags
			rlast_seen <= 1'b0;
			wlast_seen <= 1'b0;
			bvalid_seen <= 1'b0;

			case (state)
				ST_IDLE: begin
					busy <= 1'b0;
					done <= 1'b0;
					error <= 1'b0;
					o_int <= 1'b0;
					if (start_pulse) begin
						src_addr_reg <= reg_file[0];
						dst_addr_reg <= reg_file[1];
						length_reg <= reg_file[2];
						remaining <= reg_file[2];
						cur_src_addr <= reg_file[0];
						cur_dst_addr <= reg_file[1];
						data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
						busy <= 1'b1;
						state <= ST_READ_ADDR;
					end
				end

				ST_READ_ADDR: begin
					if (M_AXI_ARREADY) begin
						// Calculate burst length
						if (remaining < 8) begin
							burst_len <= remaining;
						end else begin
							burst_len <= 8;
						end
						burst_count <= {C_AXI_ADDR_WIDTH{1'b0}};
						data_count <= {C_AXI_ADDR_WIDTH{1'b0}};
						state <= ST_READ_DATA;
					end
				end

				ST_READ_DATA: begin
					if (M_AXI_RVALID) begin
						data_buf <= M_AXI_RDATA;
						burst_count <= burst_count + 1;
						data_count <= data_count + 1;
						if (M_AXI_RLAST) begin
							rlast_seen <= 1'b1;
							state <= ST_WRITE_ADDR;
						end
					end
				end

				ST_WRITE_ADDR: begin
					if (M_AXI_AWREADY) begin
						burst_count <= {C_AXI_ADDR_WIDTH{1'b0}};
						state <= ST_WRITE_DATA;
					end
				end

				ST_WRITE_DATA: begin
					if (M_AXI_WREADY) begin
						burst_count <= burst_count + 1;
						if (burst_count == burst_len - 1) begin
							wlast_seen <= 1'b1;
							state <= ST_WRITE_RESP;
						end
					end
				end

				ST_WRITE_RESP: begin
					if (M_AXI_BVALID) begin
						bvalid_seen <= 1'b1;
						// Update addresses and remaining
						next_src_addr <= cur_src_addr + (burst_len * (C_AXI_DATA_WIDTH/8));
						next_dst_addr <= cur_dst_addr + (burst_len * (C_AXI_DATA_WIDTH/8));
						if (remaining <= burst_len) begin
							remaining <= {C_AXI_ADDR_WIDTH{1'b0}};
							done <= 1'b1;
							o_int <= 1'b1;
							state <= ST_DONE;
						end else begin
							remaining <= remaining - burst_len;
							cur_src_addr <= next_src_addr;
							cur_dst_addr <= next_dst_addr;
							state <= ST_READ_ADDR;
						end
					end
				end

				ST_DONE: begin
					busy <= 1'b0;
					state <= ST_IDLE;
				end

				default: state <= ST_IDLE;
			endcase

			// Abort handling
			if (abort_pulse && busy) begin
				state <= ST_IDLE;
				busy <= 1'b0;
				error <= 1'b1;
				o_int <= 1'b1;
			end
		end
	end

	// Status register read
	always @* begin
		if (arvalid_reg && S_AXIL_ARVALID && S_AXIL_ARREADY) begin
			if (S_AXIL_ARADDR[4:2] == 4'h4) begin
				rdata_reg[0] = busy;
				rdata_reg[1] = done;
				rdata_reg[2] = error;
			end
		end
	end

endmodule

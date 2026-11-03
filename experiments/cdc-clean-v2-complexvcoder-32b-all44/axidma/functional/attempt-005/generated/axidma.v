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

	// Internal Registers
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_src_addr;
	reg [C_AXIL_ADDR_WIDTH-1:0] reg_dst_addr;
	reg [LGLEN-1:0] reg_length;
	reg [1:0] reg_command;
	reg [1:0] reg_status;
	reg [C_AXIL_DATA_WIDTH-1:0] reg_control;

	// AXILite FSM States
	typedef enum reg [1:0] {IDLE, WRITE_REG, READ_REG, START_TRANSFER} axilite_state_t;
	axilite_state_t axilite_state, axilite_next_state;

	// AXI FSM States
	typedef enum reg [1:0] {IDLE, READ, WRITE} axi_state_t;
	axi_state_t axi_state, axi_next_state;

	// AXILite Control Register Map
	localparam CTRL_REG_OFFSET = 0;
	localparam SRC_ADDR_REG_OFFSET = 1;
	localparam DST_ADDR_REG_OFFSET = 2;
	localparam LENGTH_REG_OFFSET = 3;
	localparam STATUS_REG_OFFSET = 4;

	// AXILite FSM
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axilite_state <= IDLE;
			S_AXIL_AWREADY <= 0;
			S_AXIL_WREADY <= 0;
			S_AXIL_BVALID <= 0;
			S_AXIL_ARREADY <= 0;
			S_AXIL_RVALID <= 0;
		end else begin
			axilite_state <= axilite_next_state;
			case (axilite_state)
				IDLE: begin
					S_AXIL_AWREADY <= S_AXIL_AWVALID;
					S_AXIL_WREADY <= S_AXIL_WVALID & S_AXIL_AWREADY;
					if (S_AXIL_AWVALID & S_AXIL_AWREADY) begin
						case (S_AXIL_AWADDR)
							CTRL_REG_OFFSET*C_AXIL_DATA_WIDTH: axilite_next_state <= WRITE_REG;
							SRC_ADDR_REG_OFFSET*C_AXIL_DATA_WIDTH: axilite_next_state <= WRITE_REG;
							DST_ADDR_REG_OFFSET*C_AXIL_DATA_WIDTH: axilite_next_state <= WRITE_REG;
							LENGTH_REG_OFFSET*C_AXIL_DATA_WIDTH: axilite_next_state <= WRITE_REG;
							default: axilite_next_state <= IDLE;
						endcase
					end else if (S_AXIL_ARVALID) begin
						S_AXIL_ARREADY <= 1;
						case (S_AXIL_ARADDR)
							STATUS_REG_OFFSET*C_AXIL_DATA_WIDTH: axilite_next_state <= READ_REG;
							default: axilite_next_state <= IDLE;
						endcase
					end else begin
						S_AXIL_ARREADY <= 0;
						S_AXIL_AWREADY <= 0;
						S_AXIL_WREADY <= 0;
						S_AXIL_BVALID <= 0;
					end
				end
				WRITE_REG: begin
					if (S_AXIL_WVALID & S_AXIL_WREADY) begin
						case (S_AXIL_AWADDR)
							CTRL_REG_OFFSET*C_AXIL_DATA_WIDTH: reg_control <= S_AXIL_WDATA;
							SRC_ADDR_REG_OFFSET*C_AXIL_DATA_WIDTH: reg_src_addr <= S_AXIL_WDATA[C_AXIL_ADDR_WIDTH-1:0];
							DST_ADDR_REG_OFFSET*C_AXIL_DATA_WIDTH: reg_dst_addr <= S_AXIL_WDATA[C_AXIL_ADDR_WIDTH-1:0];
							LENGTH_REG_OFFSET*C_AXIL_DATA_WIDTH: reg_length <= S_AXIL_WDATA[LGLEN-1:0];
						endcase
						S_AXIL_BVALID <= 1;
						if (S_AXIL_BVALID & S_AXIL_BREADY) begin
							S_AXIL_BVALID <= 0;
							if (reg_control[1:0] == 2'b01) begin
								axilite_next_state <= START_TRANSFER;
							end else begin
								axilite_next_state <= IDLE;
							end
						end
					end
				end
				READ_REG: begin
					S_AXIL_RVALID <= 1;
					S_AXIL_RDATA <= reg_status;
					if (S_AXIL_RVALID & S_AXIL_RREADY) begin
						S_AXIL_RVALID <= 0;
						S_AXIL_ARREADY <= 0;
						axilite_next_state <= IDLE;
					end
				end
				START_TRANSFER: begin
					if (reg_control[1:0] == 2'b01) begin
						axilite_next_state <= START_TRANSFER;
					end else begin
						axilite_next_state <= IDLE;
					end
				end
			endcase
		end
	end

	// AXI FSM
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axi_state <= IDLE;
			M_AXI_AWVALID <= 0;
			M_AXI_WVALID <= 0;
			M_AXI_BREADY <= 0;
			M_AXI_ARVALID <= 0;
			M_AXI_RREADY <= 0;
			reg_length <= 0;
			reg_src_addr <= 0;
			reg_dst_addr <= 0;
			reg_status <= 0;
		end else begin
			axi_state <= axi_next_state;
			case (axi_state)
				IDLE: begin
					if (axilite_state == START_TRANSFER) begin
						if (reg_control[0]) begin
							M_AXI_ARADDR <= reg_src_addr;
							M_AXI_ARVALID <= 1;
							axi_next_state <= READ;
						end else begin
							M_AXI_AWADDR <= reg_dst_addr;
							M_AXI_AWVALID <= 1;
							axi_next_state <= WRITE;
						end
					end
				end
				READ: begin
					if (M_AXI_ARVALID & M_AXI_ARREADY) begin
						M_AXI_ARVALID <= 0;
						M_AXI_RREADY <= 1;
					end
					if (M_AXI_RVALID & M_AXI_RREADY) begin
						M_AXI_WDATA <= M_AXI_RDATA;
						M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
						M_AXI_WVALID <= 1;
						if (M_AXI_RLAST) begin
							M_AXI_RREADY <= 0;
							axi_next_state <= IDLE;
						end
					end
				end
				WRITE: begin
					if (M_AXI_AWVALID & M_AXI_AWREADY) begin
						M_AXI_AWVALID <= 0;
						M_AXI_WVALID <= 1;
					end
					if (M_AXI_WVALID & M_AXI_WREADY) begin
						if (reg_length == C_AXI_DATA_WIDTH/8) begin
							M_AXI_WLAST <= 1;
						end
						if (M_AXI_WLAST & M_AXI_WREADY) begin
							M_AXI_WVALID <= 0;
							M_AXI_BREADY <= 1;
							if (M_AXI_BVALID & M_AXI_BREADY) begin
								M_AXI_BREADY <= 0;
								axi_next_state <= IDLE;
							end
						end else begin
							reg_length <= reg_length - C_AXI_DATA_WIDTH/8;
						end
					end
				end
			endcase
		end
	end

	// AXILite Response
	assign S_AXIL_BRESP = 2'b00;
	assign S_AXIL_RRESP = 2'b00;

	// AXI Write Address Channel
	assign M_AXI_AWID = AXI_WRITE_ID;
	assign M_AXI_AWSIZE = 3'b010; // 4 bytes
	assign M_AXI_AWBURST = 2'b01; // INCR
	assign M_AXI_AWLOCK = 1'b0;
	assign M_AXI_AWCACHE = 4'b0011; // Non-cacheable, buffered, write allocate
	assign M_AXI_AWPROT = 3'b000; // Normal, non-secure, data
	assign M_AXI_AWQOS = 4'b0000;

	// AXI Read Address Channel
	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARSIZE = 3'b010; // 4 bytes
	assign M_AXI_ARBURST = 2'b01; // INCR
	assign M_AXI_ARLOCK = 1'b0;
	assign M_AXI_ARCACHE = 4'b0011; // Non-cacheable, buffered, write allocate
	assign M_AXI_ARPROT = 3'b000; // Normal, non-secure, data
	assign M_AXI_ARQOS = 4'b0000;

	// AXI Read Data Channel
	assign M_AXI_RREADY = 1'b1;

	// AXI Write Data Channel
	assign M_AXI_WLAST = (reg_length == C_AXI_DATA_WIDTH/8);

	// Interrupt Signal
	assign o_int = 0; // Placeholder for interrupt signal

endmodule

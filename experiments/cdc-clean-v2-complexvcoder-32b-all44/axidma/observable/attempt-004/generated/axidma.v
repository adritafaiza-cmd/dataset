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

	reg [C_AXIL_ADDR_WIDTH-1:0] src_addr, dst_addr;
	reg [LGLEN-1:0] length;
	reg dma_start, dma_done;

	axilite_control axilite_ctrl_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXIL_AWVALID(S_AXIL_AWVALID),
		.S_AXIL_AWREADY(S_AXIL_AWREADY),
		.S_AXIL_AWADDR(S_AXIL_AWADDR),
		.S_AXIL_AWPROT(S_AXIL_AWPROT),
		.S_AXIL_WVALID(S_AXIL_WVALID),
		.S_AXIL_WREADY(S_AXIL_WREADY),
		.S_AXIL_WDATA(S_AXIL_WDATA),
		.S_AXIL_WSTRB(S_AXIL_WSTRB),
		.S_AXIL_BVALID(S_AXIL_BVALID),
		.S_AXIL_BREADY(S_AXIL_BREADY),
		.S_AXIL_BRESP(S_AXIL_BRESP),
		.S_AXIL_ARVALID(S_AXIL_ARVALID),
		.S_AXIL_ARREADY(S_AXIL_ARREADY),
		.S_AXIL_ARADDR(S_AXIL_ARADDR),
		.S_AXIL_ARPROT(S_AXIL_ARPROT),
		.S_AXIL_RVALID(S_AXIL_RVALID),
		.S_AXIL_RREADY(S_AXIL_RREADY),
		.S_AXIL_RDATA(S_AXIL_RDATA),
		.S_AXIL_RRESP(S_AXIL_RRESP),
		.dma_start(dma_start),
		.src_addr(src_addr),
		.dst_addr(dst_addr),
		.length(length),
		.dma_done(dma_done)
	);

	dma_controller dma_ctrl_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.dma_start(dma_start),
		.src_addr(src_addr),
		.dst_addr(dst_addr),
		.length(length),
		.dma_done(dma_done),
		.M_AXI_AWVALID(M_AXI_AWVALID),
		.M_AXI_AWREADY(M_AXI_AWREADY),
		.M_AXI_AWID(M_AXI_AWID),
		.M_AXI_AWADDR(M_AXI_AWADDR),
		.M_AXI_AWSIZE(M_AXI_AWSIZE),
		.M_AXI_AWBURST(M_AXI_AWBURST),
		.M_AXI_AWLOCK(M_AXI_AWLOCK),
		.M_AXI_AWCACHE(M_AXI_AWCACHE),
		.M_AXI_AWPROT(M_AXI_AWPROT),
		.M_AXI_AWQOS(M_AXI_AWQOS),
		.M_AXI_WVALID(M_AXI_WVALID),
		.M_AXI_WREADY(M_AXI_WREADY),
		.M_AXI_WDATA(M_AXI_WDATA),
		.M_AXI_WSTRB(M_AXI_WSTRB),
		.M_AXI_WLAST(M_AXI_WLAST),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(M_AXI_BREADY),
		.M_AXI_BID(M_AXI_BID),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_ARVALID(M_AXI_ARVALID),
		.M_AXI_ARREADY(M_AXI_ARREADY),
		.M_AXI_ARID(M_AXI_ARID),
		.M_AXI_ARADDR(M_AXI_ARADDR),
		.M_AXI_ARSIZE(M_AXI_ARSIZE),
		.M_AXI_ARBURST(M_AXI_ARBURST),
		.M_AXI_ARLOCK(M_AXI_ARLOCK),
		.M_AXI_ARCACHE(M_AXI_ARCACHE),
		.M_AXI_ARPROT(M_AXI_ARPROT),
		.M_AXI_ARQOS(M_AXI_ARQOS),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(M_AXI_RREADY),
		.M_AXI_RID(M_AXI_RID),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RLAST(M_AXI_RLAST),
		.M_AXI_RRESP(M_AXI_RRESP),
		.o_int(o_int)
	);

endmodule

module axilite_control (
		input wire S_AXI_ACLK,
		input wire S_AXI_ARESETN,
		input wire S_AXIL_AWVALID,
		output reg S_AXIL_AWREADY,
		input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
		input wire [2:0] S_AXIL_AWPROT,
		input wire S_AXIL_WVALID,
		output reg S_AXIL_WREADY,
		input wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
		input wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
		output reg S_AXIL_BVALID,
		input wire S_AXIL_BREADY,
		output wire [1:0] S_AXIL_BRESP,
		input wire S_AXIL_ARVALID,
		output reg S_AXIL_ARREADY,
		input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
		input wire [2:0] S_AXIL_ARPROT,
		output reg S_AXIL_RVALID,
		input wire S_AXIL_RREADY,
		output reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
		output wire [1:0] S_AXIL_RRESP,
		output reg dma_start,
		output reg [C_AXI_ADDR_WIDTH-1:0] src_addr,
		output reg [C_AXI_ADDR_WIDTH-1:0] dst_addr,
		output reg [LGLEN-1:0] length,
		input wire dma_done
	);

	typedef enum reg [1:0] {IDLE, WRITE, READ} state_t;
	state_t state, next_state;

	reg [C_AXIL_ADDR_WIDTH-1:0] reg_addr;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= IDLE;
			S_AXIL_AWREADY <= 1'b0;
			S_AXIL_WREADY <= 1'b0;
			S_AXIL_BVALID <= 1'b0;
			S_AXIL_ARREADY <= 1'b0;
			S_AXIL_RVALID <= 1'b0;
			dma_start <= 1'b0;
		end else begin
			state <= next_state;
			case (next_state)
				IDLE: begin
					S_AXIL_AWREADY <= 1'b1;
					S_AXIL_WREADY <= 1'b0;
					S_AXIL_BVALID <= 1'b0;
					S_AXIL_ARREADY <= 1'b1;
					S_AXIL_RVALID <= 1'b0;
					dma_start <= 1'b0;
				end
				WRITE: begin
					if (S_AXIL_WVALID && S_AXIL_AWREADY) begin
						S_AXIL_WREADY <= 1'b1;
						if (S_AXIL_WVALID && S_AXIL_WREADY) begin
							S_AXIL_BVALID <= 1'b1;
							S_AXIL_AWREADY <= 1'b0;
						end
					end
				end
				READ: begin
					if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
						S_AXIL_ARREADY <= 1'b0;
						S_AXIL_RVALID <= 1'b1;
					end
					if (S_AXIL_RVALID && S_AXIL_RREADY) begin
						S_AXIL_RVALID <= 1'b0;
					end
				end
			endcase
		end
	end

	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
					next_state = WRITE;
					reg_addr = S_AXIL_AWADDR;
				end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
					next_state = READ;
				end
			end
			WRITE: begin
				if (S_AXIL_WVALID && S_AXIL_WREADY) begin
					next_state = IDLE;
					case (reg_addr)
						5'h00: src_addr = S_AXIL_WDATA;
						5'h04: dst_addr = S_AXIL_WDATA;
						5'h08: length = S_AXIL_WDATA;
						5'h0C: dma_start = 1'b1;
					endcase
				end
			end
			READ: begin
				if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
					next_state = READ;
					case (S_AXIL_ARADDR)
						5'h00: S_AXIL_RDATA = src_addr;
						5'h04: S_AXIL_RDATA = dst_addr;
						5'h08: S_AXIL_RDATA = length;
						5'h0C: S_AXIL_RDATA = {31'b0, dma_done};
					endcase
				end
			end
		endcase
	end

	assign S_AXIL_BRESP = 2'b00;
	assign S_AXIL_RRESP = 2'b00;

endmodule

module dma_controller (
		input wire S_AXI_ACLK,
		input wire S_AXI_ARESETN,
		input wire dma_start,
		input wire [C_AXI_ADDR_WIDTH-1:0] src_addr,
		input wire [C_AXI_ADDR_WIDTH-1:0] dst_addr,
		input wire [LGLEN-1:0] length,
		output reg dma_done,
		output reg M_AXI_AWVALID,
		input wire M_AXI_AWREADY,
		output reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
		output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
		output reg [2:0] M_AXI_AWSIZE,
		output reg [1:0] M_AXI_AWBURST,
		output reg M_AXI_AWLOCK,
		output reg [3:0] M_AXI_AWCACHE,
		output reg [2:0] M_AXI_AWPROT,
		output reg [3:0] M_AXI_AWQOS,
		output reg M_AXI_WVALID,
		input wire M_AXI_WREADY,
		output reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
		output reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
		output reg M_AXI_WLAST,
		input wire M_AXI_BVALID,
		output reg M_AXI_BREADY,
		input wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
		input wire [1:0] M_AXI_BRESP,
		output reg M_AXI_ARVALID,
		input wire M_AXI_ARREADY,
		output wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
		output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
		output wire [2:0] M_AXI_ARSIZE,
		output wire [1:0] M_AXI_ARBURST,
		output wire M_AXI_ARLOCK,
		output wire [3:0] M_AXI_ARCACHE,
		output wire [2:0] M_AXI_ARPROT,
		output wire [3:0] M_AXI_ARQOS,
		input wire M_AXI_RVALID,
		output wire M_AXI_RREADY,
		input wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
		input wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
		input wire M_AXI_RLAST,
		input wire [1:0] M_AXI_RRESP,
		output reg o_int
	);

	typedef enum reg [1:0] {IDLE, READ, WRITE} state_t;
	state_t state, next_state;

	reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
	reg [LGLEN-1:0] remaining_length;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= IDLE;
			M_AXI_AWVALID <= 1'b0;
			M_AXI_WVALID <= 1'b0;
			M_AXI_BREADY <= 1'b0;
			M_AXI_ARVALID <= 1'b0;
			M_AXI_RREADY <= 1'b0;
			dma_done <= 1'b0;
			current_addr <= 0;
			remaining_length <= 0;
			o_int <= 1'b0;
		end else begin
			state <= next_state;
			case (next_state)
				IDLE: begin
					M_AXI_AWVALID <= 1'b0;
					M_AXI_WVALID <= 1'b0;
					M_AXI_BREADY <= 1'b0;
					M_AXI_ARVALID <= 1'b0;
					M_AXI_RREADY <= 1'b0;
					dma_done <= 1'b0;
				end
				READ: begin
					if (dma_start) begin
						current_addr <= src_addr;
						remaining_length <= length;
						dma_start <= 1'b0;
						M_AXI_ARVALID <= 1'b1;
						M_AXI_ARADDR <= src_addr;
					end
					if (M_AXI_ARVALID && M_AXI_ARREADY) begin
						M_AXI_ARVALID <= 1'b0;
						M_AXI_RREADY <= 1'b1;
					end
					if (M_AXI_RVALID && M_AXI_RREADY) begin
						M_AXI_RREADY <= 1'b0;
						current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
						remaining_length <= remaining_length - C_AXI_DATA_WIDTH/8;
						M_AXI_WVALID <= 1'b1;
						M_AXI_WDATA <= M_AXI_RDATA;
						M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
						if (remaining_length <= C_AXI_DATA_WIDTH/8) begin
							M_AXI_WLAST <= 1'b1;
						end
					end
				end
				WRITE: begin
					if (M_AXI_WVALID && M_AXI_WREADY) begin
						current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
						remaining_length <= remaining_length - C_AXI_DATA_WIDTH/8;
						if (M_AXI_WLAST && M_AXI_WREADY) begin
							M_AXI_BREADY <= 1'b1;
						end
					end
					if (M_AXI_BVALID && M_AXI_BREADY) begin
						M_AXI_BREADY <= 1'b0;
						dma_done <= 1'b1;
						o_int <= 1'b1;
					end
				end
			endcase
		end
	end

	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (dma_start) begin
					next_state = READ;
				end
			end
			READ: begin
				if (remaining_length == 0) begin
					next_state = WRITE;
				end
			end
			WRITE: begin
				if (dma_done) begin
					next_state = IDLE;
				end
			end
		endcase
	end

	assign M_AXI_AWID = AXI_WRITE_ID;
	assign M_AXI_AWSIZE = 3'b010; // 4 bytes
	assign M_AXI_AWBURST = 2'b01; // INCR
	assign M_AXI_AWLOCK = 1'b0;
	assign M_AXI_AWCACHE = 4'b0011; // Normal Non-cacheable
	assign M_AXI_AWPROT = 3'b000;
	assign M_AXI_AWQOS = 4'b0000;
	assign M_AXI_AWADDR = current_addr;

	assign M_AXI_ARID = AXI_READ_ID;
	assign M_AXI_ARSIZE = 3'b010; // 4 bytes
	assign M_AXI_ARBURST = 2'b01; // INCR
	assign M_AXI_ARLOCK = 1'b0;
	assign M_AXI_ARCACHE = 4'b0011; // Normal Non-cacheable
	assign M_AXI_ARPROT = 3'b000;
	assign M_AXI_ARQOS = 4'b0000;

	assign M_AXI_RREADY = (state == READ) ? 1'b1 : 1'b0;

endmodule

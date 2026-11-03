module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// FIFO for AW channel
	wire [C_S_AXI_ID_WIDTH-1:0] awid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] awaddr_fifo_out;
	wire [7:0] awlen_fifo_out;
	wire [2:0] awsize_fifo_out;
	wire [1:0] awburst_fifo_out;
	wire awlock_fifo_out;
	wire [3:0] awcache_fifo_out;
	wire [2:0] awprot_fifo_out;
	wire [3:0] awqos_fifo_out;
	wire awvalid_fifo_out;
	wire awready_fifo_in;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID && S_AXI_AWREADY),
		.rd_en(awready_fifo_in),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.dout({awid_fifo_out, awaddr_fifo_out, awlen_fifo_out, awsize_fifo_out, awburst_fifo_out, awlock_fifo_out, awcache_fifo_out, awprot_fifo_out, awqos_fifo_out}),
		.full(),
		.empty(),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(),
		.rd_ack(awvalid_fifo_out)
	);

	// FIFO for W channel
	wire [C_S_AXI_DATA_WIDTH-1:0] wdata_fifo_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_fifo_out;
	wire wlast_fifo_out;
	wire wvalid_fifo_out;
	wire wready_fifo_in;

	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_WVALID && S_AXI_WREADY),
		.rd_en(wready_fifo_in),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.dout({wdata_fifo_out, wstrb_fifo_out, wlast_fifo_out}),
		.full(),
		.empty(),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(),
		.rd_ack(wvalid_fifo_out)
	);

	// FIFO for B channel
	wire [C_S_AXI_ID_WIDTH-1:0] bid_fifo_out;
	wire [1:0] bresp_fifo_out;
	wire bvalid_fifo_out;
	wire bready_fifo_in;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(1 << LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_BVALID && M_AXI_BREADY),
		.rd_en(bready_fifo_in),
		.din({M_AXI_BID, M_AXI_BRESP}),
		.dout({bid_fifo_out, bresp_fifo_out}),
		.full(),
		.empty(),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(),
		.rd_ack(bvalid_fifo_out)
	);

	// FIFO for AR channel
	wire [C_S_AXI_ID_WIDTH-1:0] arid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] araddr_fifo_out;
	wire [7:0] arlen_fifo_out;
	wire [2:0] arsize_fifo_out;
	wire [1:0] arburst_fifo_out;
	wire arlock_fifo_out;
	wire [3:0] arcache_fifo_out;
	wire [2:0] arprot_fifo_out;
	wire [3:0] arqos_fifo_out;
	wire arvalid_fifo_out;
	wire arready_fifo_in;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID && S_AXI_ARREADY),
		.rd_en(arready_fifo_in),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.dout({arid_fifo_out, araddr_fifo_out, arlen_fifo_out, arsize_fifo_out, arburst_fifo_out, arlock_fifo_out, arcache_fifo_out, arprot_fifo_out, arqos_fifo_out}),
		.full(),
		.empty(),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(),
		.rd_ack(arvalid_fifo_out)
	);

	// FIFO for R channel
	wire [C_S_AXI_ID_WIDTH-1:0] rid_fifo_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] rdata_fifo_out;
	wire [1:0] rresp_fifo_out;
	wire rlast_fifo_out;
	wire rvalid_fifo_out;
	wire rready_fifo_in;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID && M_AXI_RREADY),
		.rd_en(rready_fifo_in),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.dout({rid_fifo_out, rdata_fifo_out, rresp_fifo_out, rlast_fifo_out}),
		.full(),
		.empty(),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(),
		.rd_ack(rvalid_fifo_out)
	);

	// AW channel
	assign S_AXI_AWREADY = !awvalid_fifo_out;
	assign awready_fifo_in = M_AXI_AWREADY && awvalid_fifo_out;
	assign M_AXI_AWID = awid_fifo_out;
	assign M_AXI_AWADDR = awaddr_fifo_out;
	assign M_AXI_AWLEN = awlen_fifo_out;
	assign M_AXI_AWSIZE = awsize_fifo_out;
	assign M_AXI_AWBURST = awburst_fifo_out;
	assign M_AXI_AWLOCK = awlock_fifo_out;
	assign M_AXI_AWCACHE = awcache_fifo_out;
	assign M_AXI_AWPROT = awprot_fifo_out;
	assign M_AXI_AWQOS = awqos_fifo_out;
	assign M_AXI_AWVALID = awvalid_fifo_out;

	// W channel
	assign S_AXI_WREADY = !wvalid_fifo_out;
	assign wready_fifo_in = M_AXI_WREADY && wvalid_fifo_out;
	assign M_AXI_WDATA = wdata_fifo_out;
	assign M_AXI_WSTRB = wstrb_fifo_out;
	assign M_AXI_WLAST = wlast_fifo_out;
	assign M_AXI_WVALID = wvalid_fifo_out;

	// B channel
	assign M_AXI_BREADY = !bvalid_fifo_out;
	assign bready_fifo_in = S_AXI_BREADY && bvalid_fifo_out;
	assign S_AXI_BID = bid_fifo_out;
	assign S_AXI_BRESP = bresp_fifo_out;
	assign S_AXI_BVALID = bvalid_fifo_out;

	// AR channel
	assign S_AXI_ARREADY = !arvalid_fifo_out;
	assign arready_fifo_in = M_AXI_ARREADY && arvalid_fifo_out;
	assign M_AXI_ARID = arid_fifo_out;
	assign M_AXI_ARADDR = araddr_fifo_out;
	assign M_AXI_ARLEN = arlen_fifo_out;
	assign M_AXI_ARSIZE = arsize_fifo_out;
	assign M_AXI_ARBURST = arburst_fifo_out;
	assign M_AXI_ARLOCK = arlock_fifo_out;
	assign M_AXI_ARCACHE = arcache_fifo_out;
	assign M_AXI_ARPROT = arprot_fifo_out;
	assign M_AXI_ARQOS = arqos_fifo_out;
	assign M_AXI_ARVALID = arvalid_fifo_out;

	// R channel
	assign M_AXI_RREADY = !rvalid_fifo_out;
	assign rready_fifo_in = S_AXI_RREADY && rvalid_fifo_out;
	assign S_AXI_RID = rid_fifo_out;
	assign S_AXI_RDATA = rdata_fifo_out;
	assign S_AXI_RRESP = rresp_fifo_out;
	assign S_AXI_RLAST = rlast_fifo_out;
	assign S_AXI_RVALID = rvalid_fifo_out;

	// Master reset
	assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule

module fifo #(
		parameter WIDTH = 32,
		parameter DEPTH = 16
	) (
		input wire clk,
		input wire rst,
		input wire wr_en,
		input wire rd_en,
		input wire [WIDTH-1:0] din,
		output reg [WIDTH-1:0] dout,
		output reg full,
		output reg empty,
		output reg wr_rst_busy,
		output reg rd_rst_busy,
		output reg wr_ack,
		output reg rd_ack
	);

	localparam ADDR_WIDTH = $clog2(DEPTH);
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] count;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			count <= 0;
			full <= 0;
			empty <= 1;
			wr_rst_busy <= 1;
			rd_rst_busy <= 1;
			wr_ack <= 0;
			rd_ack <= 0;
		end else begin
			wr_rst_busy <= 0;
			rd_rst_busy <= 0;
			wr_ack <= 0;
			rd_ack <= 0;

			if (wr_en && !full) begin
				mem[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				count <= count + 1;
				wr_ack <= 1;
			end

			if (rd_en && !empty) begin
				dout <= mem[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				count <= count - 1;
				rd_ack <= 1;
			end

			full <= (count == DEPTH);
			empty <= (count == 0);
		end
	end

endmodule

```verilog
module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 8,
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

	// Internal State Machine and Control
	localparam STATE_IDLE = 2'b00;
	localparam STATE_CONFIG = 2'b01;
	localparam STATE_READ = 2'b10;
	localparam STATE_WRITE = 2'b11;

	reg [1:0] state;
	reg [31:0] src_addr, dst_addr, len;
	reg [31:0] src_addr_reg, dst_addr_reg, len_reg;
	reg [7:0] burst_count;
	reg [31:0] data_reg;
	reg [3:0] data_count;
	reg [31:0] last_data;
	reg [1:0] last_resp;
	reg [1:0] last_bresp;
	reg abort_flag;
	reg [7:0] abort_key;
	reg clk_gate;

	// AXI4-Lite Register Interface
	reg [31:0] ctrl_reg;
	reg [31:0] src_addr_reg_lite;
	reg [31:0] dst_addr_reg_lite;
	reg [31:0] len_reg_lite;
	reg [31:0] ctrl_reg_next;
	reg [31:0] src_addr_reg_lite_next;
	reg [31:0] dst_addr_reg_lite_next;
	reg [31:0] len_reg_lite_next;

	// AXI4 Master Signals
	reg [C_AXI_ID_WIDTH-1:0] m_axi_awid_next;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_awaddr_next;
	reg [2:0] m_axi_awsize_next;
	reg [1:0] m_axi_awburst_next;
	reg m_axi_awlock_next;
	reg [3:0] m_axi_awcache_next;
	reg [2:0] m_axi_awprot_next;
	reg [3:0] m_axi_awqos_next;
	reg [C_AXI_DATA_WIDTH-1:0] m_axi_wdata_next;
	reg [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb_next;
	reg m_axi_wlast_next;
	reg m_axi_bready_next;
	reg [C_AXI_ID_WIDTH-1:0] m_axi_arid_next;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_araddr_next;
	reg m_axi_arvalid_next;
	reg m_axi_arready_next;
	reg m_axi_rready_next;
	reg [C_AXI_DATA_WIDTH-1:0] m_axi_rdata_next;
	reg m_axi_rlast_next;
	reg [1:0] m_axi_rresp_next;
	reg [1:0] m_axi_bresp_next;
	reg m_axi_bvalid_next;

	// Clock Gating
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			clk_gate <= 1'b0;
		else if (state == STATE_IDLE)
			clk_gate <= 1'b0;
		else
			clk_gate <= 1'b1;
	end

	// State Machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			state <= STATE_IDLE;
		else
			case (state)
				STATE_IDLE: begin
					if (S_AXIL_AWVALID && S_AXIL_AWREADY)
						state <= STATE_CONFIG;
					else if (S_AXIL_ARVALID && S_AXIL_ARREADY)
						state <= STATE_CONFIG;
					else
						state <= STATE_IDLE;
				end
				STATE_CONFIG: begin
					if (S_AXIL_WVALID && S_AXIL_WREADY)
						state <= STATE_IDLE;
					else
						state <= STATE_CONFIG;
				end
				STATE_READ: begin
					if (M_AXI_BVALID && M_AXI_BREADY)
						state <= STATE_IDLE;
					else if (M_AXI_RVALID && M_AXI_RREADY)
						state <= STATE_READ;
					else
						state <= STATE_READ;
				end
				STATE_WRITE: begin
					if (M_AXI_BVALID && M_AXI_BREADY)
						state <= STATE_IDLE;
					else
						state <= STATE_WRITE;
				end
				default: state <= STATE_IDLE;
			endc
	end

	// Register Updates
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ctrl_reg <= 32'h0;
			src_addr_reg_lite <= 32'h0;
			dst_addr_reg_lite <= 32'h0;
			len_reg_lite <= 32'h0;
			abort_flag <= 1'b0;
			abort_key <= 8'h0;
		end
		else begin
			ctrl_reg <= ctrl_reg_next;
			src_addr_reg_lite <= src_addr_reg_lite_next;
			dst_addr_reg_lite <= dst_addr_reg_lite_next;
			len_reg_lite <= len_reg_lite_next;
			abort_flag <= abort_flag | (abort_key == ABORT_KEY);
			abort_key <= abort_key + 1;
		end
	end

	// AXI4-Lite Read/Write Logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXIL_AWREADY <= 1'b0;
			S_AXIL_WREADY <= 1'b0;
			S_AXIL_ARREADY <= 1'b0;
			S_AXIL_BVALID <= 1'b0;
			S_AXIL_RVALID <= 1'b0;
			S_AXIL_BRESP <= 2'b00;
			S_AXIL_RRESP <= 2'b00;
			S_AXIL_RDATA <= 32'h0;
			o_int <= 1'b0;
		end
		else begin
			S_AXIL_AWREADY <= 1'b1;
			S_AXIL_WREADY <= 1'b1;
			S_AXIL_ARREADY <= 1'b1;
			S_AXIL_BVALID <= 1'b0;
			S_AXIL_RVALID <= 1'b0;
			S_AXIL_BRESP <= 2'b00;
			S_AXIL_RRESP <= 2'b00;
			S_AXIL_RDATA <= 32'h0;
			o_int <= 1'b0;

			if (state == STATE_IDLE) begin
				if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
					ctrl_reg_next <= S_AXIL_AWADDR;
					src_addr_reg_lite_next <= S_AXIL_AWADDR;
					dst_addr_reg_lite_next <= S_AXIL_AWADDR;
					len_reg_lite_next <= 32'h0;
				end
				else if (S_AXIL_WVALID && S_AXIL_WREADY) begin
					ctrl_reg_next <= ctrl_reg;
					src_addr_reg_lite_next <= src_addr_reg_lite;
					dst_addr_reg_lite_next <= dst_addr_reg_lite;
					len_reg_lite_next <= S_AXIL_WDATA;
				end
				else begin
					ctrl_reg_next <= ctrl_reg;
					src_addr_reg_lite_next <= src_addr_reg_lite;
					dst_addr_reg_lite_next <= dst_addr_reg_lite;
					len_reg_lite_next <= len_reg_lite;
				end
			end
			else if (state == STATE_CONFIG) begin
				if (S_AXIL_WVALID && S_AXIL_WREADY) begin
					ctrl_reg_next <= ctrl_reg;
					src_addr_reg_lite_next <= src_addr_reg_lite;
					dst_addr_reg_lite_next <= dst_addr_reg_lite;
					len_reg_lite_next <= len_reg_lite;
				end
				else begin
					ctrl_reg_next <= ctrl_reg;
					src_addr_reg_lite_next <= src_addr_reg_lite;
					dst_addr_reg_lite_next <= dst_addr_reg_lite;
					len_reg_lite_next <= len_reg_lite;
				end
			end
			else begin
				ctrl_reg_next <= ctrl_reg;
				src_addr_reg_lite_next <= src_addr_reg_lite;
				dst_addr_reg_lite_next <= dst_addr_reg_lite;
				len_reg_lite_next <= len_reg_lite;
			end

			if (abort_flag) begin
				o_int <= 1'b1;
				S_AXIL_AWREADY <= 1'b0;
				S_AXIL_WREADY <= 1'b0;
				S_AXIL_ARREADY <= 1'b0;
			end
		end
	end

	// Address and Length Handling
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			src_addr <= 32'h0;
			dst_addr <= 32'h0;
			len <= 32'h0;
			burst_count <= 8'h0;
			data_reg <= 32'h0;
			data_count <= 4'h0;
			last_data <= 32'h0;
			last_resp <= 2'b00;
			last_bresp <= 2'b00;
		end
		else begin
			if (state == STATE_IDLE) begin
				src_addr <= src_addr_reg_lite;
				dst_addr <= dst_addr_reg_lite;
				len <= len_reg_lite;
				burst_count <= 8'h0;
				data_reg <= 32'h0;
				data_count <= 4'h0;
				last_data <= 32'h0;
				last_resp <= 2'b00;
				last_bresp <= 2'b00;
			end
			else if (state == STATE_CONFIG) begin
				src_addr <= src_addr_reg_lite;
				dst_addr <= dst_addr_reg_lite;
				len <= len_reg_lite;
				burst_count <= 8'h0;
				data_reg <= 32'h0;
				data_count <= 4'h0;
				last_data <= 32'h0;
				last_resp <= 2'b00;
				last_bresp <= 2'b00;
			end
			else begin
				// Address wrapping logic
				if (OPT_WRAPMEM) begin
					if (src_addr >= (1 << (C_AXI_ADDR_WIDTH - ADDRLSB))) begin
						src_addr <= src_addr - (1 << (C_AXI_ADDR_WIDTH - ADDRLSB));
					end
					if (dst_addr >= (1 << (C_AXI_ADDR_WIDTH - ADDRLSB))) begin
						dst_addr <= dst_addr - (1 << (C_AXI_ADDR_WIDTH - ADDRLSB));
					end
				end
			end
		end
	end

	// AXI4 Master Write Address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_awid_next <= AXI_WRITE_ID;
			m_axi_awaddr_next <= 32'h0;
			m_axi_awsize_next <= 3'b000;
			m_axi_awburst_next <= 2'b00;
			m_axi_awlock_next <= 1'b0;
			m_axi_awcache_next <= 4'h0;
			m_axi_awprot_next <= 3'b000;
			m_axi_awqos_next <= 4'h0;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_awid_next <= AXI_WRITE_ID;
				m_axi_awaddr_next <= src_addr;
				m_axi_awsize_next <= 3'b000;
				m_axi_awburst_next <= 2'b00;
				m_axi_awlock_next <= 1'b0;
				m_axi_awcache_next <= 4'h0;
				m_axi_awprot_next <= S_AXIL_AWPROT;
				m_axi_awqos_next <= 4'h0;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_awid_next <= AXI_WRITE_ID;
				m_axi_awaddr_next <= src_addr;
				m_axi_awsize_next <= 3'b000;
				m_axi_awburst_next <= 2'b00;
				m_axi_awlock_next <= 1'b0;
				m_axi_awcache_next <= 4'h0;
				m_axi_awprot_next <= S_AXIL_AWPROT;
				m_axi_awqos_next <= 4'h0;
			end
			else if (state == STATE_WRITE) begin
				m_axi_awid_next <= AXI_WRITE_ID;
				m_axi_awaddr_next <= src_addr;
				m_axi_awsize_next <= 3'b000;
				m_axi_awburst_next <= 2'b00;
				m_axi_awlock_next <= 1'b0;
				m_axi_awcache_next <= 4'h0;
				m_axi_awprot_next <= S_AXIL_AWPROT;
				m_axi_awqos_next <= 4'h0;
			end
			else begin
				m_axi_awid_next <= AXI_WRITE_ID;
				m_axi_awaddr_next <= src_addr;
				m_axi_awsize_next <= 3'b000;
				m_axi_awburst_next <= 2'b00;
				m_axi_awlock_next <= 1'b0;
				m_axi_awcache_next <= 4'h0;
				m_axi_awprot_next <= S_AXIL_AWPROT;
				m_axi_awqos_next <= 4'h0;
			end
		end
	end

	// AXI4 Master Write Data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_wdata_next <= 32'h0;
			m_axi_wstrb_next <= 4'hF;
			m_axi_wlast_next <= 1'b0;
			m_axi_bready_next <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_wdata_next <= 32'h0;
				m_axi_wstrb_next <= 4'hF;
				m_axi_wlast_next <= 1'b0;
				m_axi_bready_next <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_wdata_next <= 32'h0;
				m_axi_wstrb_next <= 4'hF;
				m_axi_wlast_next <= 1'b0;
				m_axi_bready_next <= 1'b0;
			end
			else if (state == STATE_WRITE) begin
				m_axi_wdata_next <= data_reg;
				m_axi_wstrb_next <= 4'hF;
				m_axi_wlast_next <= 1'b0;
				m_axi_bready_next <= 1'b0;
			end
			else begin
				m_axi_wdata_next <= 32'h0;
				m_axi_wstrb_next <= 4'hF;
				m_axi_wlast_next <= 1'b0;
				m_axi_bready_next <= 1'b0;
			end
		end
	end

	// AXI4 Master Read Address
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_arid_next <= AXI_READ_ID;
			m_axi_araddr_next <= 32'h0;
			m_axi_arsize_next <= 3'b000;
			m_axi_arburst_next <= 2'b00;
			m_axi_arlock_next <= 1'b0;
			m_axi_arcache_next <= 4'h0;
			m_axi_arprot_next <= 3'b000;
			m_axi_arqos_next <= 4'h0;
			m_axi_rready_next <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_arid_next <= AXI_READ_ID;
				m_axi_araddr_next <= dst_addr;
				m_axi_arsize_next <= 3'b000;
				m_axi_arburst_next <= 2'b00;
				m_axi_arlock_next <= 1'b0;
				m_axi_arcache_next <= 4'h0;
				m_axi_arprot_next <= S_AXIL_ARPROT;
				m_axi_arqos_next <= 4'h0;
				m_axi_rready_next <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_arid_next <= AXI_READ_ID;
				m_axi_araddr_next <= dst_addr;
				m_axi_arsize_next <= 3'b000;
				m_axi_arburst_next <= 2'b00;
				m_axi_arlock_next <= 1'b0;
				m_axi_arcache_next <= 4'h0;
				m_axi_arprot_next <= S_AXIL_ARPROT;
				m_axi_arqos_next <= 4'h0;
				m_axi_rready_next <= 1'b0;
			end
			else if (state == STATE_READ) begin
				m_axi_arid_next <= AXI_READ_ID;
				m_axi_araddr_next <= dst_addr;
				m_axi_arsize_next <= 3'b000;
				m_axi_arburst_next <= 2'b00;
				m_axi_arlock_next <= 1'b0;
				m_axi_arcache_next <= 4'h0;
				m_axi_arprot_next <= S_AXIL_ARPROT;
				m_axi_arqos_next <= 4'h0;
				m_axi_rready_next <= 1'b0;
			end
			else begin
				m_axi_arid_next <= AXI_READ_ID;
				m_axi_araddr_next <= dst_addr;
				m_axi_arsize_next <= 3'b000;
				m_axi_arburst_next <= 2'b00;
				m_axi_arlock_next <= 1'b0;
				m_axi_arcache_next <= 4'h0;
				m_axi_arprot_next <= S_AXIL_ARPROT;
				m_axi_arqos_next <= 4'h0;
				m_axi_rready_next <= 1'b0;
			end
		end
	end

	// AXI4 Master Read Data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_rdata_next <= 32'h0;
			m_axi_rlast_next <= 1'b0;
			m_axi_rresp_next <= 2'b00;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_rdata_next <= 32'h0;
				m_axi_rlast_next <= 1'b0;
				m_axi_rresp_next <= 2'b00;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_rdata_next <= 32'h0;
				m_axi_rlast_next <= 1'b0;
				m_axi_rresp_next <= 2'b00;
			end
			else if (state == STATE_READ) begin
				m_axi_rdata_next <= data_reg;
				m_axi_rlast_next <= 1'b0;
				m_axi_rresp_next <= 2'b00;
			end
			else begin
				m_axi_rdata_next <= 32'h0;
				m_axi_rlast_next <= 1'b0;
				m_axi_rresp_next <= 2'b00;
			end
		end
	end

	// AXI4 Master Write Response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_bresp_next <= 2'b00;
			m_axi_bvalid_next <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_bresp_next <= 2'b00;
				m_axi_bvalid_next <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_bresp_next <= 2'b00;
				m_axi_bvalid_next <= 1'b0;
			end
			else if (state == STATE_WRITE) begin
				m_axi_bresp_next <= 2'b00;
				m_axi_bvalid_next <= 1'b0;
			end
			else begin
				m_axi_bresp_next <= 2'b00;
				m_axi_bvalid_next <= 1'b0;
			end
		end
	end

	// AXI4 Master Read Response
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_rresp_next <= 2'b00;
			m_axi_rvalid_next <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				m_axi_rresp_next <= 2'b00;
				m_axi_rvalid_next <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				m_axi_rresp_next <= 2'b00;
				m_axi_rvalid_next <= 1'b0;
			end
			else if (state == STATE_READ) begin
				m_axi_rresp_next <= 2'b00;
				m_axi_rvalid_next <= 1'b0;
			end
			else begin
				m_axi_rresp_next <= 2'b00;
				m_axi_rvalid_next <= 1'b0;
			end
		end
	end

	// AXI4 Master Write Address Valid
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWID <= AXI_WRITE_ID;
			M_AXI_AWADDR <= 32'h0;
			M_AXI_AWSIZE <= 3'b000;
			M_AXI_AWBURST <= 2'b00;
			M_AXI_AWLOCK <= 1'b0;
			M_AXI_AWCACHE <= 4'h0;
			M_AXI_AWPROT <= 3'b000;
			M_AXI_AWQOS <= 4'h0;
		end
		else begin
			if (state == STATE_IDLE) begin
				M_AXI_AWVALID <= 1'b0;
				M_AXI_AWID <= AXI_WRITE_ID;
				M_AXI_AWADDR <= 32'h0;
				M_AXI_AWSIZE <= 3'b000;
				M_AXI_AWBURST <= 2'b00;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'h0;
				M_AXI_AWPROT <= 3'b000;
				M_AXI_AWQOS <= 4'h0;
			end
			else if (state == STATE_CONFIG) begin
				M_AXI_AWVALID <= 1'b0;
				M_AXI_AWID <= AXI_WRITE_ID;
				M_AXI_AWADDR <= 32'h0;
				M_AXI_AWSIZE <= 3'b000;
				M_AXI_AWBURST <= 2'b00;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'h0;
				M_AXI_AWPROT <= 3'b000;
				M_AXI_AWQOS <= 4'h0;
			end
			else if (state == STATE_WRITE) begin
				M_AXI_AWVALID <= 1'b0;
				M_AXI_AWID <= AXI_WRITE_ID;
				M_AXI_AWADDR <= 32'h0;
				M_AXI_AWSIZE <= 3'b000;
				M_AXI_AWBURST <= 2'b00;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'h0;
				M_AXI_AWPROT <= 3'b000;
				M_AXI_AWQOS <= 4'h0;
			end
			else begin
				M_AXI_AWVALID <= 1'b0;
				M_AXI_AWID <= AXI_WRITE_ID;
				M_AXI_AWADDR <= 32'h0;
				M_AXI_AWSIZE <= 3'b000;
				M_AXI_AWBURST <= 2'b00;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'h0;
				M_AXI_AWPROT <= 3'b000;
				M_AXI_AWQOS <= 4'h0;
			end
		end
	end

	// AXI4 Master Write Data Valid
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA <= 32'h0;
			M_AXI_WSTRB <= 4'hF;
			M_AXI_WLAST <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				M_AXI_WVALID <= 1'b0;
				M_AXI_WDATA <= 32'h0;
				M_AXI_WSTRB <= 4'hF;
				M_AXI_WLAST <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				M_AXI_WVALID <= 1'b0;
				M_AXI_WDATA <= 32'h0;
				M_AXI_WSTRB <= 4'hF;
				M_AXI_WLAST <= 1'b0;
			end
			else if (state == STATE_WRITE) begin
				M_AXI_WVALID <= 1'b0;
				M_AXI_WDATA <= 32'h0;
				M_AXI_WSTRB <= 4'hF;
				M_AXI_WLAST <= 1'b0;
			end
			else begin
				M_AXI_WVALID <= 1'b0;
				M_AXI_WDATA <= 32'h0;
				M_AXI_WSTRB <= 4'hF;
				M_AXI_WLAST <= 1'b0;
			end
		end
	end

	// AXI4 Master Write Response Ready
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_BREADY <= 1'b0;
		end
		else begin
			if (state == STATE_IDLE) begin
				M_AXI_BREADY <= 1'b0;
			end
			else if (state == STATE_CONFIG) begin
				M_AXI_BREADY <= 1'b0;
			end
			else if (state == STATE_WRITE) begin
				M_AXI_BREADY <= 1'b0;
			end
			else begin
				M_AXI_BREADY <= 1'b0;
			end
		end
	end

	// AXI4 Master Read Address Valid
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARID <= AXI_READ_ID;
			M_AXI_ARADDR <= 32'h0;
			M_AXI_ARSIZE <= 3'b000;
			M_AXI_ARBURST <= 2'b00;
			M_AXI_ARLOCK <= 1'b0;
			M_AXI_ARCACHE <= 4'h0;
			M_AXI_ARPROT <= 3'b000;
			M_AXI_ARQOS <= 4'h0;
		end
		else begin
			if (state == STATE_IDLE) begin
				M_AXI_ARVALID <= 1'b0;
				M_AXI_ARID <= AXI_READ_ID;
				M_AXI_ARADDR <= 32'h0;
				M_AXI_ARSIZE <= 3'b000;
				M_AXI_ARBURST <= 2'b00;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'h0;
				M_AXI_ARPROT <= 3'b000;
				M_AXI_ARQOS <= 4'h0;
			end
			else if (state == STATE_CONFIG) begin
				M_AXI_ARVALID <= 1'b0;
				M_AXI_ARID <= AXI_READ_ID;
				M_AXI_ARADDR <= 32'h0;
				M_AXI_ARSIZE <= 3'b000;
				M_AXI_ARBURST <= 2'b00;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'h0;
				M_AXI_ARPROT <= 3'b000;
				M_AXI_ARQOS <= 4'h0;
			end
			else if (state == STATE_READ) begin
				M_AXI_ARVALID <= 1'b0;
				M_AXI_ARID <= AXI_READ_ID;
				M_AXI_ARADDR <= 32'h0;
				M_AXI_ARSIZE <= 3'b000;
				M_AXI_ARBURST <= 2'b00;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'h0;
				M_AXI_ARPROT <= 3'b000;
				M_AXI_ARQOS <= 4'h0;
			end
			else begin
				M_AXI_ARVALID <= 1'b0;

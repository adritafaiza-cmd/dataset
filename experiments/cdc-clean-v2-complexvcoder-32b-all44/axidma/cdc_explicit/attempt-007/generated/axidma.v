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

	// Internal signals
	reg s_axil_awready_reg;
	reg s_axil_wready_reg;
	reg s_axil_bvalid_reg;
	reg [1:0] s_axil_bresp_reg;
	reg s_axil_arready_reg;
	reg s_axil_rvalid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] s_axil_rdata_reg;
	reg [1:0] s_axil_rresp_reg;
	reg m_axi_awvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] m_axi_awid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_awaddr_reg;
	reg [2:0] m_axi_awsize_reg;
	reg [1:0] m_axi_awburst_reg;
	reg m_axi_awlock_reg;
	reg [3:0] m_axi_awcache_reg;
	reg [2:0] m_axi_awprot_reg;
	reg [3:0] m_axi_awqos_reg;
	reg m_axi_wvalid_reg;
	reg [C_AXI_DATA_WIDTH-1:0] m_axi_wdata_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb_reg;
	reg m_axi_wlast_reg;
	reg m_axi_bready_reg;
	reg m_axi_arvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] m_axi_arid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_araddr_reg;
	reg [2:0] m_axi_arsize_reg;
	reg [1:0] m_axi_arburst_reg;
	reg m_axi_arlock_reg;
	reg [3:0] m_axi_arcache_reg;
	reg [2:0] m_axi_arprot_reg;
	reg [3:0] m_axi_arqos_reg;
	reg m_axi_rready_reg;
	reg o_int_reg;
	reg reset;
	reg [2:0] state;
	reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] destination_addr;
	reg [LGLEN-1:0] transfer_length;
	reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
	reg [LGLEN-1:0] remaining_length;
	reg [C_AXI_DATA_WIDTH-1:0] data_buffer;
	reg data_valid;
	reg [C_AXI_DATA_WIDTH/8-1:0] data_strobe;
	reg data_last;
	reg [C_AXI_DATA_WIDTH-1:0] read_data;
	reg [C_AXI_DATA_WIDTH-1:0] write_data;
	reg read_data_valid;
	reg write_data_valid;
	reg read_data_ready;
	reg write_data_ready;

	// States
	localparam IDLE = 3'b000;
	localparam READ = 3'b001;
	localparam WRITE = 3'b010;
	localparam DONE = 3'b100;

	// AXI Lite Control
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_axil_awready_reg <= 0;
			s_axil_wready_reg <= 0;
			s_axil_bvalid_reg <= 0;
			s_axil_bresp_reg <= 0;
			s_axil_arready_reg <= 0;
			s_axil_rvalid_reg <= 0;
			s_axil_rdata_reg <= 0;
			s_axil_rresp_reg <= 0;
		end else begin
			// AW Channel
			if (S_AXIL_AWVALID && s_axil_awready_reg) begin
				case (S_AXIL_AWADDR)
					5'h00: s_axil_awready_reg <= 1;
					5'h04: s_axil_awready_reg <= 1;
					5'h08: s_axil_awready_reg <= 1;
					default: s_axil_awready_reg <= 0;
				endcase
			end else begin
				s_axil_awready_reg <= 0;
			end

			// W Channel
			if (S_AXIL_WVALID && s_axil_wready_reg) begin
				case (S_AXIL_AWADDR)
					5'h00: begin
						source_addr <= S_AXIL_WDATA;
						s_axil_wready_reg <= 1;
					end
					5'h04: begin
						destination_addr <= S_AXIL_WDATA;
						s_axil_wready_reg <= 1;
					end
					5'h08: begin
						transfer_length <= S_AXIL_WDATA;
						s_axil_wready_reg <= 1;
					end
					default: s_axil_wready_reg <= 0;
				endcase
			end else begin
				s_axil_wready_reg <= 0;
			end

			// B Channel
			if (S_AXIL_BREADY && s_axil_bvalid_reg) begin
				s_axil_bvalid_reg <= 0;
			end

			// AR Channel
			if (S_AXIL_ARVALID && s_axil_arready_reg) begin
				s_axil_arready_reg <= 0;
			end else begin
				s_axil_arready_reg <= 0;
			end

			// R Channel
			if (S_AXIL_RREADY && s_axil_rvalid_reg) begin
				s_axil_rvalid_reg <= 0;
			end
		end
	end

	// AXI Lite Status
	assign S_AXIL_AWREADY = s_axil_awready_reg;
	assign S_AXIL_WREADY = s_axil_wready_reg;
	assign S_AXIL_BVALID = s_axil_bvalid_reg;
	assign S_AXIL_BRESP = s_axil_bresp_reg;
	assign S_AXIL_ARREADY = s_axil_arready_reg;
	assign S_AXIL_RVALID = s_axil_rvalid_reg;
	assign S_AXIL_RDATA = s_axil_rdata_reg;
	assign S_AXIL_RRESP = s_axil_rresp_reg;

	// AXI Master Control
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_awvalid_reg <= 0;
			m_axi_awid_reg <= 0;
			m_axi_awaddr_reg <= 0;
			m_axi_awsize_reg <= 3'b010; // 4 bytes
			m_axi_awburst_reg <= 2'b01; // INCR
			m_axi_awlock_reg <= 0;
			m_axi_awcache_reg <= 4'b0011; // Non-cacheable, no bufferable
			m_axi_awprot_reg <= 3'b000;
			m_axi_awqos_reg <= 4'b0000;
			m_axi_wvalid_reg <= 0;
			m_axi_wdata_reg <= 0;
			m_axi_wstrb_reg <= 0;
			m_axi_wlast_reg <= 0;
			m_axi_bready_reg <= 0;
			m_axi_arvalid_reg <= 0;
			m_axi_arid_reg <= 0;
			m_axi_araddr_reg <= 0;
			m_axi_arsize_reg <= 3'b010; // 4 bytes
			m_axi_arburst_reg <= 2'b01; // INCR
			m_axi_arlock_reg <= 0;
			m_axi_arcache_reg <= 4'b0011; // Non-cacheable, no bufferable
			m_axi_arprot_reg <= 3'b000;
			m_axi_arqos_reg <= 4'b0000;
			m_axi_rready_reg <= 0;
			o_int_reg <= 0;
			state <= IDLE;
			current_addr <= 0;
			remaining_length <= 0;
			data_valid <= 0;
			data_strobe <= 0;
			data_last <= 0;
			read_data_valid <= 0;
			write_data_valid <= 0;
			read_data_ready <= 0;
			write_data_ready <= 0;
		end else begin
			case (state)
				IDLE: begin
					if (transfer_length > 0) begin
						state <= READ;
						current_addr <= source_addr;
						remaining_length <= transfer_length;
						m_axi_arvalid_reg <= 1;
						m_axi_araddr_reg <= source_addr;
					end
				end
				READ: begin
					if (M_AXI_ARREADY && m_axi_arvalid_reg) begin
						m_axi_arvalid_reg <= 0;
						read_data_ready <= 1;
					end

					if (read_data_valid && read_data_ready) begin
						data_buffer <= read_data;
						data_valid <= 1;
						data_strobe <= {C_AXI_DATA_WIDTH/8{1'b1}};
						data_last <= (remaining_length == C_AXI_DATA_WIDTH/8);
						current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
						remaining_length <= remaining_length - C_AXI_DATA_WIDTH/8;
						read_data_ready <= 0;
						read_data_valid <= 0;

						if (remaining_length == C_AXI_DATA_WIDTH/8) begin
							state <= WRITE;
						end
					end
				end
				WRITE: begin
					if (data_valid) begin
						m_axi_awvalid_reg <= 1;
						m_axi_awaddr_reg <= destination_addr;
						m_axi_wvalid_reg <= 1;
						m_axi_wdata_reg <= data_buffer;
						m_axi_wstrb_reg <= data_strobe;
						m_axi_wlast_reg <= data_last;

						if (M_AXI_AWREADY && m_axi_awvalid_reg) begin
							m_axi_awvalid_reg <= 0;
						end

						if (M_AXI_WREADY && m_axi_wvalid_reg) begin
							m_axi_wvalid_reg <= 0;
							data_valid <= 0;
						end

						if (M_AXI_BVALID) begin
							m_axi_bready_reg <= 1;
							state <= DONE;
						end
					end
				end
				DONE: begin
					if (M_AXI_BREADY && s_axil_bvalid_reg) begin
						s_axil_bvalid_reg <= 0;
						s_axil_bresp_reg <= 2'b00; // OKAY
						state <= IDLE;
					end else if (S_AXIL_BREADY && s_axil_bvalid_reg) begin
						s_axil_bvalid_reg <= 0;
						s_axil_bresp_reg <= 2'b00; // OKAY
						state <= IDLE;
					end else begin
						s_axil_bvalid_reg <= 1;
						m_axi_bready_reg <= 0;
					end
				end
				default: state <= IDLE;
			endcase
		end
	end

	// AXI Master Status
	assign M_AXI_AWVALID = m_axi_awvalid_reg;
	assign M_AXI_AWID = m_axi_awid_reg;
	assign M_AXI_AWADDR = m_axi_awaddr_reg;
	assign M_AXI_AWSIZE = m_axi_awsize_reg;
	assign M_AXI_AWBURST = m_axi_awburst_reg;
	assign M_AXI_AWLOCK = m_axi_awlock_reg;
	assign M_AXI_AWCACHE = m_axi_awcache_reg;
	assign M_AXI_AWPROT = m_axi_awprot_reg;
	assign M_AXI_AWQOS = m_axi_awqos_reg;
	assign M_AXI_WVALID = m_axi_wvalid_reg;
	assign M_AXI_WDATA = m_axi_wdata_reg;
	assign M_AXI_WSTRB = m_axi_wstrb_reg;
	assign M_AXI_WLAST = m_axi_wlast_reg;
	assign M_AXI_BREADY = m_axi_bready_reg;
	assign M_AXI_ARVALID = m_axi_arvalid_reg;
	assign M_AXI_ARID = m_axi_arid_reg;
	assign M_AXI_ARADDR = m_axi_araddr_reg;
	assign M_AXI_ARSIZE = m_axi_arsize_reg;
	assign M_AXI_ARBURST = m_axi_arburst_reg;
	assign M_AXI_ARLOCK = m_axi_arlock_reg;
	assign M_AXI_ARCACHE = m_axi_arcache_reg;
	assign M_AXI_ARPROT = m_axi_arprot_reg;
	assign M_AXI_ARQOS = m_axi_arqos_reg;
	assign M_AXI_RREADY = m_axi_rready_reg;
	assign o_int = o_int_reg;

	// AXI Master Data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			read_data <= 0;
			read_data_valid <= 0;
			write_data <= 0;
			write_data_valid <= 0;
		end else begin
			if (M_AXI_RVALID) begin
				read_data <= M_AXI_RDATA;
				read_data_valid <= 1;
			end

			if (M_AXI_WVALID) begin
				write_data <= M_AXI_WDATA;
				write_data_valid <= 1;
			end
		end
	end

endmodule

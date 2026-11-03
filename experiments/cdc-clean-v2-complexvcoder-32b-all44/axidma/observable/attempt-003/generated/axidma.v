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

	// Internal registers
	reg [C_AXIL_DATA_WIDTH-1:0] ctrl_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
	reg [LGLEN-1:0] length_reg;
	reg [C_AXI_DATA_WIDTH-1:0] data_buffer;
	reg [LGLEN-1:0] addr_counter;
	reg [2:0] beat_counter;
	reg [2:0] state;
	reg [2:0] next_state;
	reg s_awready_reg;
	reg s_wready_reg;
	reg s_bvalid_reg;
	reg [1:0] s_bresp_reg;
	reg s_arready_reg;
	reg s_rvalid_reg;
	reg [C_AXIL_DATA_WIDTH-1:0] s_rdata_reg;
	reg [1:0] s_rresp_reg;
	reg m_awvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] m_awid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] m_awaddr_reg;
	reg [2:0] m_awsize_reg;
	reg [1:0] m_awburst_reg;
	reg m_awlock_reg;
	reg [3:0] m_awcache_reg;
	reg [2:0] m_awprot_reg;
	reg [3:0] m_awqos_reg;
	reg m_wvalid_reg;
	reg [C_AXI_DATA_WIDTH-1:0] m_wdata_reg;
	reg [C_AXI_DATA_WIDTH/8-1:0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_bready_reg;
	reg m_arvalid_reg;
	reg [C_AXI_ID_WIDTH-1:0] m_arid_reg;
	reg [C_AXI_ADDR_WIDTH-1:0] m_araddr_reg;
	reg [2:0] m_arsize_reg;
	reg [1:0] m_arburst_reg;
	reg m_arlock_reg;
	reg [3:0] m_arcache_reg;
	reg [2:0] m_arprot_reg;
	reg [3:0] m_arqos_reg;
	reg m_rready_reg;

	// State definitions
	localparam IDLE = 3'b000;
	localparam READ = 3'b001;
	localparam WRITE = 3'b010;
	localparam DONE = 3'b011;

	// AXI Lite Control
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXIL_AWREADY <= 0;
			S_AXIL_WREADY <= 0;
			S_AXIL_BVALID <= 0;
			S_AXIL_ARREADY <= 0;
			S_AXIL_RVALID <= 0;
			s_awready_reg <= 0;
			s_wready_reg <= 0;
			s_bvalid_reg <= 0;
			s_arready_reg <= 0;
			s_rvalid_reg <= 0;
			ctrl_reg <= 0;
			src_addr_reg <= 0;
			dst_addr_reg <= 0;
			length_reg <= 0;
			state <= IDLE;
		end else begin
			S_AXIL_AWREADY <= ~s_awready_reg & ~S_AXIL_AWREADY & S_AXIL_AWVALID;
			S_AXIL_WREADY <= ~s_wready_reg & ~S_AXIL_WREADY & S_AXIL_WVALID;
			S_AXIL_BVALID <= s_bvalid_reg & ~S_AXIL_BREADY & S_AXIL_BVALID;
			S_AXIL_ARREADY <= ~s_arready_reg & ~S_AXIL_ARREADY & S_AXIL_ARVALID;
			S_AXIL_RVALID <= s_rvalid_reg & ~S_AXIL_RREADY & S_AXIL_RVALID;

			if (S_AXIL_AWVALID & S_AXIL_AWREADY) begin
				s_awready_reg <= 1;
			end else if (S_AXIL_WVALID & S_AXIL_WREADY) begin
				s_wready_reg <= 1;
			end else if (S_AXIL_BVALID & S_AXIL_BREADY) begin
				s_bvalid_reg <= 0;
			end else if (S_AXIL_ARVALID & S_AXIL_ARREADY) begin
				s_arready_reg <= 1;
			end else if (S_AXIL_RVALID & S_AXIL_RREADY) begin
				s_rvalid_reg <= 0;
			end

			if (S_AXIL_AWVALID & S_AXIL_AWREADY) begin
				case (S_AXIL_AWADDR)
					5'b00000: src_addr_reg <= S_AXIL_WDATA;
					5'b00001: dst_addr_reg <= S_AXIL_WDATA;
					5'b00010: length_reg <= S_AXIL_WDATA[LGLEN-1:0];
					5'b00011: ctrl_reg <= S_AXIL_WDATA;
					default: ;
				endcase
			end

			if (S_AXIL_ARVALID & S_AXIL_ARREADY) begin
				case (S_AXIL_ARADDR)
					5'b00000: begin s_rdata_reg <= src_addr_reg; s_rvalid_reg <= 1; end
					5'b00001: begin s_rdata_reg <= dst_addr_reg; s_rvalid_reg <= 1; end
					5'b00010: begin s_rdata_reg <= length_reg; s_rvalid_reg <= 1; end
					5'b00011: begin s_rdata_reg <= ctrl_reg; s_rvalid_reg <= 1; end
					default: ;
				endcase
			end
		end
	end

	// State machine
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (ctrl_reg[0]) begin
					next_state = READ;
				end
			end
			READ: begin
				if (M_AXI_RVALID & M_AXI_RREADY & M_AXI_RLAST) begin
					next_state = WRITE;
				end
			end
			WRITE: begin
				if (M_AXI_BVALID & M_AXI_BREADY) begin
					if (addr_counter == length_reg) begin
						next_state = DONE;
					end else begin
						next_state = WRITE;
					end
				end
			end
			DONE: begin
				next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end

	// AXI Master Control
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_AWVALID <= 0;
			M_AXI_AWID <= 0;
			M_AXI_AWADDR <= 0;
			M_AXI_AWSIZE <= 2'b10; // 4 bytes
			M_AXI_AWBURST <= 2'b01; // INCR
			M_AXI_AWLOCK <= 0;
			M_AXI_AWCACHE <= 4'b0011; // Non-cacheable, bufferable, modifiable
			M_AXI_AWPROT <= 3'b000; // Normal
			M_AXI_AWQOS <= 4'b0000; // Default
			M_AXI_WVALID <= 0;
			M_AXI_WDATA <= 0;
			M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
			M_AXI_WLAST <= 0;
			M_AXI_BREADY <= 0;
			M_AXI_ARVALID <= 0;
			M_AXI_ARID <= 0;
			M_AXI_ARADDR <= 0;
			M_AXI_ARSIZE <= 2'b10; // 4 bytes
			M_AXI_ARBURST <= 2'b01; // INCR
			M_AXI_ARLOCK <= 0;
			M_AXI_ARCACHE <= 4'b0011; // Non-cacheable, bufferable, modifiable
			M_AXI_ARPROT <= 3'b000; // Normal
			M_AXI_ARQOS <= 4'b0000; // Default
			M_AXI_RREADY <= 0;
			m_awvalid_reg <= 0;
			m_arvalid_reg <= 0;
			m_rready_reg <= 0;
			addr_counter <= 0;
			beat_counter <= 0;
			data_buffer <= 0;
			o_int <= 0;
		end else begin
			case (state)
				IDLE: begin
					M_AXI_AWVALID <= 0;
					M_AXI_WVALID <= 0;
					M_AXI_BREADY <= 0;
					M_AXI_ARVALID <= 0;
					M_AXI_RREADY <= 0;
					m_awvalid_reg <= 0;
					m_arvalid_reg <= 0;
					m_rready_reg <= 0;
					addr_counter <= 0;
					beat_counter <= 0;
					data_buffer <= 0;
					o_int <= 0;
					if (ctrl_reg[0]) begin
						m_arvalid_reg <= 1;
						M_AXI_ARADDR <= src_addr_reg;
					end
				end
				READ: begin
					if (m_arvalid_reg & M_AXI_ARREADY) begin
						m_arvalid_reg <= 0;
						m_rready_reg <= 1;
					end
					if (M_AXI_RVALID & M_AXI_RREADY) begin
						data_buffer <= M_AXI_RDATA;
						addr_counter <= addr_counter + 1;
						if (M_AXI_RLAST) begin
							m_rready_reg <= 0;
						end
					end
				end
				WRITE: begin
					if (addr_counter < length_reg) begin
						if (!m_awvalid_reg) begin
							m_awvalid_reg <= 1;
							M_AXI_AWADDR <= dst_addr_reg + (addr_counter << ADDRLSB);
						end
						if (m_awvalid_reg & M_AXI_AWREADY) begin
							m_awvalid_reg <= 0;
							M_AXI_WVALID <= 1;
							M_AXI_WDATA <= data_buffer;
							if (addr_counter == (length_reg - 1)) begin
								M_AXI_WLAST <= 1;
							end
						end
						if (M_AXI_WVALID & M_AXI_WREADY) begin
							M_AXI_WVALID <= 0;
							M_AXI_WLAST <= 0;
						end
						if (M_AXI_BVALID & M_AXI_BREADY) begin
							M_AXI_BREADY <= 0;
						end
					end else begin
						M_AXI_AWVALID <= 0;
						M_AXI_WVALID <= 0;
						M_AXI_BREADY <= 0;
					end
				end
				DONE: begin
					o_int <= 1;
				end
				default: ;
			endcase
		end
	end

	assign S_AXIL_BRESP = s_bresp_reg;
	assign S_AXIL_RRESP = s_rresp_reg;
	assign M_AXI_AWID = m_awid_reg;
	assign M_AXI_ARID = m_arid_reg;

endmodule

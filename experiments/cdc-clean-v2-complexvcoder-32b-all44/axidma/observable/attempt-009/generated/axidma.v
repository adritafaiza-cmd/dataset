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

	// AXI Lite Control Register
	reg [C_AXIL_ADDR_WIDTH-1:0] axil_reg_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_data;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_src_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_dst_addr;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_len;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_ctrl;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_reg_status;

	// Control signals
	reg start_transfer;
	reg transfer_in_progress;
	reg transfer_complete;
	reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] len;
	reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
	reg [C_AXI_ADDR_WIDTH-1:0] remaining_len;

	// AXI Lite FSM states
	typedef enum reg [1:0] {IDLE, WRITE_REG, READ_REG} axil_state_t;
	axil_state_t axil_state, axil_next_state;

	// AXI Master FSM states
	typedef enum reg [2:0] {IDLE_M, READ_DATA, WRITE_DATA, WAIT_BRESP} axi_master_state_t;
	axi_master_state_t axi_master_state, axi_master_next_state;

	// AXI Lite FSM
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axil_state <= IDLE;
			S_AXIL_AWREADY <= 0;
			S_AXIL_WREADY <= 0;
			S_AXIL_BVALID <= 0;
			S_AXIL_ARREADY <= 0;
			S_AXIL_RVALID <= 0;
			S_AXIL_BRESP <= 2'b0;
			S_AXIL_RRESP <= 2'b0;
		end else begin
			case (axil_state)
				IDLE: begin
					S_AXIL_AWREADY <= S_AXIL_AWVALID;
					S_AXIL_WREADY <= S_AXIL_WVALID & S_AXIL_AWREADY;
					S_AXIL_BVALID <= 0;
					S_AXIL_ARREADY <= S_AXIL_ARVALID;
					S_AXIL_RVALID <= 0;
					if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_WREADY) begin
						axil_next_state <= WRITE_REG;
					end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
						axil_next_state <= READ_REG;
					end
				end
				WRITE_REG: begin
					if (S_AXIL_WVALID && S_AXIL_WREADY) begin
						case (S_AXIL_AWADDR)
							5'b00000: axil_reg_src_addr <= S_AXIL_WDATA;
							5'b00001: axil_reg_dst_addr <= S_AXIL_WDATA;
							5'b00010: axil_reg_len <= S_AXIL_WDATA;
							5'b00011: axil_reg_ctrl <= S_AXIL_WDATA;
							default: ;
						endcase
						S_AXIL_BVALID <= 1;
						S_AXIL_BRESP <= 2'b00; // OKAY
						if (S_AXIL_BREADY) begin
							axil_next_state <= IDLE;
						end
					end
				end
				READ_REG: begin
					if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
						case (S_AXIL_ARADDR)
							5'b00000: S_AXIL_RDATA <= axil_reg_src_addr;
							5'b00001: S_AXIL_RDATA <= axil_reg_dst_addr;
							5'b00010: S_AXIL_RDATA <= axil_reg_len;
							5'b00011: S_AXIL_RDATA <= axil_reg_ctrl;
							5'b00100: S_AXIL_RDATA <= axil_reg_status;
							default: S_AXIL_RDATA <= 32'b0;
						endcase
						S_AXIL_RVALID <= 1;
						S_AXIL_RRESP <= 2'b00; // OKAY
						if (S_AXIL_RREADY) begin
							axil_next_state <= IDLE;
						end
					end
				end
				default: axil_next_state <= IDLE;
			endcase
			axil_state <= axil_next_state;
		end
	end

	// AXI Master FSM
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axi_master_state <= IDLE_M;
			M_AXI_AWVALID <= 0;
			M_AXI_WVALID <= 0;
			M_AXI_BREADY <= 0;
			M_AXI_ARVALID <= 0;
			M_AXI_RREADY <= 0;
			start_transfer <= 0;
			transfer_in_progress <= 0;
			transfer_complete <= 0;
			src_addr <= 0;
			dst_addr <= 0;
			len <= 0;
			current_addr <= 0;
			remaining_len <= 0;
			o_int <= 0;
		end else begin
			case (axi_master_state)
				IDLE_M: begin
					if (axil_reg_ctrl[0] && !transfer_in_progress) begin
						start_transfer <= 1;
						src_addr <= axil_reg_src_addr;
						dst_addr <= axil_reg_dst_addr;
						len <= axil_reg_len;
						current_addr <= src_addr;
						remaining_len <= len;
						transfer_in_progress <= 1;
						transfer_complete <= 0;
						o_int <= 0;
						axi_master_next_state <= READ_DATA;
					end else begin
						start_transfer <= 0;
						axi_master_next_state <= IDLE_M;
					end
				end
				READ_DATA: begin
					if (start_transfer) begin
						M_AXI_ARVALID <= 1;
						M_AXI_ARADDR <= current_addr;
						M_AXI_ARID <= AXI_READ_ID;
						M_AXI_ARSIZE <= 3'b010; // 4 bytes
						M_AXI_ARBURST <= 2'b01; // INCR
						M_AXI_ARLOCK <= 0;
						M_AXI_ARCACHE <= 4'b0010; // MODIFIED
						M_AXI_ARPROT <= 3'b000;
						M_AXI_ARQOS <= 4'b0000;
						start_transfer <= 0;
					end
					if (M_AXI_ARVALID && M_AXI_ARREADY) begin
						M_AXI_ARVALID <= 0;
						axi_master_next_state <= WAIT_BRESP;
					end
				end
				WRITE_DATA: begin
					if (M_AXI_RVALID && M_AXI_RREADY) begin
						M_AXI_WVALID <= 1;
						M_AXI_WDATA <= M_AXI_RDATA;
						M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
						M_AXI_WLAST <= (remaining_len <= C_AXI_DATA_WIDTH/8);
						M_AXI_WID <= AXI_WRITE_ID;
						current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
						remaining_len <= remaining_len - C_AXI_DATA_WIDTH/8;
					end
					if (M_AXI_WVALID && M_AXI_WREADY) begin
						if (M_AXI_WLAST) begin
							M_AXI_BREADY <= 1;
							axi_master_next_state <= WAIT_BRESP;
						end else begin
							M_AXI_ARVALID <= 1;
							M_AXI_ARADDR <= current_addr;
							M_AXI_ARID <= AXI_READ_ID;
							M_AXI_ARSIZE <= 3'b010; // 4 bytes
							M_AXI_ARBURST <= 2'b01; // INCR
							M_AXI_ARLOCK <= 0;
							M_AXI_ARCACHE <= 4'b0010; // MODIFIED
							M_AXI_ARPROT <= 3'b000;
							M_AXI_ARQOS <= 4'b0000;
							axi_master_next_state <= READ_DATA;
						end
					end
				end
				WAIT_BRESP: begin
					if (M_AXI_BVALID && M_AXI_BREADY) begin
						M_AXI_BREADY <= 0;
						if (M_AXI_BRESP == 2'b00) begin
							if (remaining_len == 0) begin
								transfer_in_progress <= 0;
								transfer_complete <= 1;
								o_int <= 1;
							end else begin
								M_AXI_ARVALID <= 1;
								M_AXI_ARADDR <= current_addr;
								M_AXI_ARID <= AXI_READ_ID;
								M_AXI_ARSIZE <= 3'b010; // 4 bytes
								M_AXI_ARBURST <= 2'b01; // INCR
								M_AXI_ARLOCK <= 0;
								M_AXI_ARCACHE <= 4'b0010; // MODIFIED
								M_AXI_ARPROT <= 3'b000;
								M_AXI_ARQOS <= 4'b0000;
								axi_master_next_state <= READ_DATA;
							end
						end else begin
							// Error handling
							transfer_in_progress <= 0;
							transfer_complete <= 1;
							o_int <= 1;
						end
					end
				end
				default: axi_master_next_state <= IDLE_M;
			endcase
			axi_master_state <= axi_master_next_state;
		end
	end

endmodule

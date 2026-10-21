```verilog
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

	// Cross Clock FIFO Parameters
	localparam INTEGER FIFO_DEPTH = 2**LGFIFO;
	localparam INTEGER FIFO_ADDR_WIDTH = LGFIFO;
	localparam INTEGER WRITE_DEPTH = FIFO_DEPTH;
	localparam INTEGER READ_DEPTH = FIFO_DEPTH;
	localparam INTEGER WRITE_POINTER_WIDTH = FIFO_ADDR_WIDTH;
	localparam INTEGER READ_POINTER_WIDTH = FIFO_ADDR_WIDTH;
	localparam INTEGER FULL_MASK = (1'b1 << LGFIFO) - 1;
	localparam INTEGER EMPTY_MASK = (1'b1 << LGFIFO) - 1;

	// Generate Reset for Master Domain
	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Write Channel (AW + W + B)
	// AW Channel
	(* ram_style = "rom" *)
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] aw_addr_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] aw_id_reg;
	reg [7 : 0] aw_len_reg;
	reg [2 : 0] aw_size_reg;
	reg [1 : 0] aw_burst_reg;
	reg aw_lock_reg;
	reg [3 : 0] aw_cache_reg;
	reg [2 : 0] aw_prot_reg;
	reg [3 : 0] aw_qos_reg;
	reg aw_valid_reg;
	reg [WRITE_POINTER_WIDTH-1 : 0] aw_write_ptr;
	reg [READ_POINTER_WIDTH-1 : 0] aw_read_ptr;
	reg [1 : 0] aw_state; // 0: Idle, 1: Writing, 2: Waiting for B
	reg [WRITE_POINTER_WIDTH-1 : 0] aw_b_ptr;
	reg aw_b_valid;
	reg [C_S_AXI_ID_WIDTH-1 : 0] aw_b_id;
	reg [1 : 0] aw_b_resp;

	// W Channel
	reg [C_S_AXI_DATA_WIDTH-1 : 0] w_data_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_strb_reg;
	reg w_last_reg;
	reg [WRITE_POINTER_WIDTH-1 : 0] w_write_ptr;
	reg [READ_POINTER_WIDTH-1 : 0] w_read_ptr;
	reg [1 : 0] w_state; // 0: Idle, 1: Writing
	reg [WRITE_POINTER_WIDTH-1 : 0] w_b_ptr;
	reg w_b_valid;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] w_b_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_b_strb;
	reg w_b_last;

	// B Channel
	reg [C_S_AXI_ID_WIDTH-1 : 0] b_id_reg;
	reg [1 : 0] b_resp_reg;
	reg [READ_POINTER_WIDTH-1 : 0] b_read_ptr;
	reg [WRITE_POINTER_WIDTH-1 : 0] b_write_ptr;
	reg b_valid_reg;
	reg b_ready_reg;

	// Read Channel (AR + R)
	// AR Channel
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] ar_addr_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] ar_id_reg;
	reg [7 : 0] ar_len_reg;
	reg [2 : 0] ar_size_reg;
	reg [1 : 0] ar_burst_reg;
	reg ar_lock_reg;
	reg [3 : 0] ar_cache_reg;
	reg [2 : 0] ar_prot_reg;
	reg [3 : 0] ar_qos_reg;
	reg ar_valid_reg;
	reg [READ_POINTER_WIDTH-1 : 0] ar_read_ptr;
	reg [WRITE_POINTER_WIDTH-1 : 0] ar_write_ptr;
	reg [1 : 0] ar_state; // 0: Idle, 1: Reading
	reg [READ_POINTER_WIDTH-1 : 0] ar_r_ptr;
	reg ar_r_valid;
	reg [C_S_AXI_ID_WIDTH-1 : 0] ar_r_id;
	reg [1 : 0] ar_r_resp;

	// R Channel
	reg [C_S_AXI_DATA_WIDTH-1 : 0] r_data_reg;
	reg [1 : 0] r_resp_reg;
	reg r_last_reg;
	reg [READ_POINTER_WIDTH-1 : 0] r_read_ptr;
	reg [WRITE_POINTER_WIDTH-1 : 0] r_write_ptr;
	reg [1 : 0] r_state; // 0: Idle, 1: Reading
	reg [READ_POINTER_WIDTH-1 : 0] r_r_ptr;
	reg r_r_valid;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] r_r_data;
	reg [1 : 0] r_r_resp;
	reg r_r_last;

	// AXI4 FIFO Implementation
	// Write FIFO
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] aw_addr_fifo [FIFO_DEPTH-1 : 0];
	reg [C_S_AXI_ID_WIDTH-1 : 0] aw_id_fifo [FIFO_DEPTH-1 : 0];
	reg [7 : 0] aw_len_fifo [FIFO_DEPTH-1 : 0];
	reg [2 : 0] aw_size_fifo [FIFO_DEPTH-1 : 0];
	reg [1 : 0] aw_burst_fifo [FIFO_DEPTH-1 : 0];
	reg aw_lock_fifo [FIFO_DEPTH-1 : 0];
	reg [3 : 0] aw_cache_fifo [FIFO_DEPTH-1 : 0];
	reg [2 : 0] aw_prot_fifo [FIFO_DEPTH-1 : 0];
	reg [3 : 0] aw_qos_fifo [FIFO_DEPTH-1 : 0];
	reg aw_valid_fifo [FIFO_DEPTH-1 : 0];

	reg [C_S_AXI_DATA_WIDTH-1 : 0] w_data_fifo [FIFO_DEPTH-1 : 0];
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_strb_fifo [FIFO_DEPTH-1 : 0];
	reg w_last_fifo [FIFO_DEPTH-1 : 0];

	reg [C_S_AXI_ID_WIDTH-1 : 0] b_id_fifo [FIFO_DEPTH-1 : 0];
	reg [1 : 0] b_resp_fifo [FIFO_DEPTH-1 : 0];

	reg [C_S_AXI_ADDR_WIDTH-1 : 0] ar_addr_fifo [FIFO_DEPTH-1 : 0];
	reg [C_S_AXI_ID_WIDTH-1 : 0] ar_id_fifo [FIFO_DEPTH-1 : 0];
	reg [7 : 0] ar_len_fifo [FIFO_DEPTH-1 : 0];
	reg [2 : 0] ar_size_fifo [FIFO_DEPTH-1 : 0];
	reg [1 : 0] ar_burst_fifo [FIFO_DEPTH-1 : 0];
	reg ar_lock_fifo [FIFO_DEPTH-1 : 0];
	reg [3 : 0] ar_cache_fifo [FIFO_DEPTH-1 : 0];
	reg [2 : 0] ar_prot_fifo [FIFO_DEPTH-1 : 0];
	reg [3 : 0] ar_qos_fifo [FIFO_DEPTH-1 : 0];

	reg [C_S_AXI_DATA_WIDTH-1 : 0] r_data_fifo [FIFO_DEPTH-1 : 0];
	reg [1 : 0] r_resp_fifo [FIFO_DEPTH-1 : 0];
	reg r_last_fifo [FIFO_DEPTH-1 : 0];

	// Write Pointer Logic
	reg [WRITE_POINTER_WIDTH-1 : 0] aw_write_ptr_reg;
	reg [READ_POINTER_WIDTH-1 : 0] aw_read_ptr_reg;
	reg [WRITE_POINTER_WIDTH-1 : 0] w_write_ptr_reg;
	reg [READ_POINTER_WIDTH-1 : 0] w_read_ptr_reg;
	reg [READ_POINTER_WIDTH-1 : 0] ar_read_ptr_reg;
	reg [WRITE_POINTER_WIDTH-1 : 0] ar_write_ptr_reg;
	reg [READ_POINTER_WIDTH-1 : 0] r_read_ptr_reg;
	reg [WRITE_POINTER_WIDTH-1 : 0] r_write_ptr_reg;

	// Write Enable Logic
	reg aw_write_en;
	reg w_write_en;
	reg ar_write_en;
	reg r_write_en;

	// Read Enable Logic
	reg aw_read_en;
	reg w_read_en;
	reg ar_read_en;
	reg r_read_en;

	// State Machines
	reg aw_state_reg;
	reg w_state_reg;
	reg ar_state_reg;
	reg r_state_reg;

	// Cross Clock Logic
	// AW Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_addr_reg <= '0;
			aw_id_reg <= '0;
			aw_len_reg <= '0;
			aw_size_reg <= '0;
			aw_burst_reg <= '0;
			aw_lock_reg <= '0;
			aw_cache_reg <= '0;
			aw_prot_reg <= '0;
			aw_qos_reg <= '0;
			aw_valid_reg <= '0;
			aw_write_ptr <= '0;
			aw_read_ptr <= '0;
			aw_state <= 2'b00;
			aw_b_ptr <= '0;
			aw_b_valid <= '0;
			aw_b_id <= '0;
			aw_b_resp <= '0;
		end else begin
			aw_addr_reg <= S_AXI_AWADDR;
			aw_id_reg <= S_AXI_AWID;
			aw_len_reg <= S_AXI_AWLEN;
			aw_size_reg <= S_AXI_AWSIZE;
			aw_burst_reg <= S_AXI_AWBURST;
			aw_lock_reg <= S_AXI_AWLOCK;
			aw_cache_reg <= S_AXI_AWCACHE;
			aw_prot_reg <= S_AXI_AWPROT;
			aw_qos_reg <= S_AXI_AWQOS;
			aw_valid_reg <= S_AXI_AWVALID;
			aw_write_ptr <= aw_write_ptr_reg;
			aw_read_ptr <= aw_read_ptr_reg;
			aw_state <= aw_state_reg;
			aw_b_ptr <= aw_b_ptr_reg;
			aw_b_valid <= aw_b_valid_reg;
			aw_b_id <= aw_b_id_reg;
			aw_b_resp <= aw_b_resp_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_addr_reg <= '0;
			aw_id_reg <= '0;
			aw_len_reg <= '0;
			aw_size_reg <= '0;
			aw_burst_reg <= '0;
			aw_lock_reg <= '0;
			aw_cache_reg <= '0;
			aw_prot_reg <= '0;
			aw_qos_reg <= '0;
			aw_valid_reg <= '0;
			aw_write_ptr <= '0;
			aw_read_ptr <= '0;
			aw_state <= 2'b00;
			aw_b_ptr <= '0;
			aw_b_valid <= '0;
			aw_b_id <= '0;
			aw_b_resp <= '0;
		end else begin
			aw_addr_reg <= M_AXI_AWADDR;
			aw_id_reg <= M_AXI_AWID;
			aw_len_reg <= M_AXI_AWLEN;
			aw_size_reg <= M_AXI_AWSIZE;
			aw_burst_reg <= M_AXI_AWBURST;
			aw_lock_reg <= M_AXI_AWLOCK;
			aw_cache_reg <= M_AXI_AWCACHE;
			aw_prot_reg <= M_AXI_AWPROT;
			aw_qos_reg <= M_AXI_AWQOS;
			aw_valid_reg <= M_AXI_AWVALID;
			aw_write_ptr <= aw_write_ptr_reg;
			aw_read_ptr <= aw_read_ptr_reg;
			aw_state <= aw_state_reg;
			aw_b_ptr <= aw_b_ptr_reg;
			aw_b_valid <= aw_b_valid_reg;
			aw_b_id <= aw_b_id_reg;
			aw_b_resp <= aw_b_resp_reg;
		end
	end

	// W Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_data_reg <= '0;
			w_strb_reg <= '0;
			w_last_reg <= '0;
			w_write_ptr <= '0;
			w_read_ptr <= '0;
			w_state <= 2'b00;
			w_b_ptr <= '0;
			w_b_valid <= '0;
			w_b_data <= '0;
			w_b_strb <= '0;
			w_b_last <= '0;
		end else begin
			w_data_reg <= S_AXI_WDATA;
			w_strb_reg <= S_AXI_WSTRB;
			w_last_reg <= S_AXI_WLAST;
			w_write_ptr <= w_write_ptr_reg;
			w_read_ptr <= w_read_ptr_reg;
			w_state <= w_state_reg;
			w_b_ptr <= w_b_ptr_reg;
			w_b_valid <= w_b_valid_reg;
			w_b_data <= w_b_data_reg;
			w_b_strb <= w_b_strb_reg;
			w_b_last <= w_b_last_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_data_reg <= '0;
			w_strb_reg <= '0;
			w_last_reg <= '0;
			w_write_ptr <= '0;
			w_read_ptr <= '0;
			w_state <= 2'b00;
			w_b_ptr <= '0;
			w_b_valid <= '0;
			w_b_data <= '0;
			w_b_strb <= '0;
			w_b_last <= '0;
		end else begin
			w_data_reg <= M_AXI_WDATA;
			w_strb_reg <= M_AXI_WSTRB;
			w_last_reg <= M_AXI_WLAST;
			w_write_ptr <= w_write_ptr_reg;
			w_read_ptr <= w_read_ptr_reg;
			w_state <= w_state_reg;
			w_b_ptr <= w_b_ptr_reg;
			w_b_valid <= w_b_valid_reg;
			w_b_data <= w_b_data_reg;
			w_b_strb <= w_b_strb_reg;
			w_b_last <= w_b_last_reg;
		end
	end

	// AR Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_addr_reg <= '0;
			ar_id_reg <= '0;
			ar_len_reg <= '0;
			ar_size_reg <= '0;
			ar_burst_reg <= '0;
			ar_lock_reg <= '0;
			ar_cache_reg <= '0;
			ar_prot_reg <= '0;
			ar_qos_reg <= '0;
			ar_valid_reg <= '0;
			ar_read_ptr <= '0;
			ar_write_ptr <= '0;
			ar_state <= 2'b00;
			ar_r_ptr <= '0;
			ar_r_valid <= '0;
			ar_r_id <= '0;
			ar_r_resp <= '0;
		end else begin
			ar_addr_reg <= S_AXI_ARADDR;
			ar_id_reg <= S_AXI_ARID;
			ar_len_reg <= S_AXI_ARLEN;
			ar_size_reg <= S_AXI_ARSIZE;
			ar_burst_reg <= S_AXI_ARBURST;
			ar_lock_reg <= S_AXI_ARLOCK;
			ar_cache_reg <= S_AXI_ARCACHE;
			ar_prot_reg <= S_AXI_ARPROT;
			ar_qos_reg <= S_AXI_ARQOS;
			ar_valid_reg <= S_AXI_ARVALID;
			ar_read_ptr <= ar_read_ptr_reg;
			ar_write_ptr <= ar_write_ptr_reg;
			ar_state <= ar_state_reg;
			ar_r_ptr <= ar_r_ptr_reg;
			ar_r_valid <= ar_r_valid_reg;
			ar_r_id <= ar_r_id_reg;
			ar_r_resp <= ar_r_resp_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_addr_reg <= '0;
			ar_id_reg <= '0;
			ar_len_reg <= '0;
			ar_size_reg <= '0;
			ar_burst_reg <= '0;
			ar_lock_reg <= '0;
			ar_cache_reg <= '0;
			ar_prot_reg <= '0;
			ar_qos_reg <= '0;
			ar_valid_reg <= '0;
			ar_read_ptr <= '0;
			ar_write_ptr <= '0;
			ar_state <= 2'b00;
			ar_r_ptr <= '0;
			ar_r_valid <= '0;
			ar_r_id <= '0;
			ar_r_resp <= '0;
		end else begin
			ar_addr_reg <= M_AXI_ARADDR;
			ar_id_reg <= M_AXI_ARID;
			ar_len_reg <= M_AXI_ARLEN;
			ar_size_reg <= M_AXI_ARSIZE;
			ar_burst_reg <= M_AXI_ARBURST;
			ar_lock_reg <= M_AXI_ARLOCK;
			ar_cache_reg <= M_AXI_ARCACHE;
			ar_prot_reg <= M_AXI_ARPROT;
			ar_qos_reg <= M_AXI_ARQOS;
			ar_valid_reg <= M_AXI_ARVALID;
			ar_read_ptr <= ar_read_ptr_reg;
			ar_write_ptr <= ar_write_ptr_reg;
			ar_state <= ar_state_reg;
			ar_r_ptr <= ar_r_ptr_reg;
			ar_r_valid <= ar_r_valid_reg;
			ar_r_id <= ar_r_id_reg;
			ar_r_resp <= ar_r_resp_reg;
		end
	end

	// R Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_data_reg <= '0;
			r_resp_reg <= '0;
			r_last_reg <= '0;
			r_read_ptr <= '0;
			r_write_ptr <= '0;
			r_state <= 2'b00;
			r_r_ptr <= '0;
			r_r_valid <= '0;
			r_r_data <= '0;
			r_r_resp <= '0;
			r_r_last <= '0;
		end else begin
			r_data_reg <= S_AXI_RDATA;
			r_resp_reg <= S_AXI_RRESP;
			r_last_reg <= S_AXI_RLAST;
			r_read_ptr <= r_read_ptr_reg;
			r_write_ptr <= r_write_ptr_reg;
			r_state <= r_state_reg;
			r_r_ptr <= r_r_ptr_reg;
			r_r_valid <= r_r_valid_reg;
			r_r_data <= r_r_data_reg;
			r_r_resp <= r_r_resp_reg;
			r_r_last <= r_r_last_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_data_reg <= '0;
			r_resp_reg <= '0;
			r_last_reg <= '0;
			r_read_ptr <= '0;
			r_write_ptr <= '0;
			r_state <= 2'b00;
			r_r_ptr <= '0;
			r_r_valid <= '0;
			r_r_data <= '0;
			r_r_resp <= '0;
			r_r_last <= '0;
		end else begin
			r_data_reg <= M_AXI_RDATA;
			r_resp_reg <= M_AXI_RRESP;
			r_last_reg <= M_AXI_RLAST;
			r_read_ptr <= r_read_ptr_reg;
			r_write_ptr <= r_write_ptr_reg;
			r_state <= r_state_reg;
			r_r_ptr <= r_r_ptr_reg;
			r_r_valid <= r_r_valid_reg;
			r_r_data <= r_r_data_reg;
			r_r_resp <= r_r_resp_reg;
			r_r_last <= r_r_last_reg;
		end
	end

	// Write FIFO Logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_addr_fifo <= '0;
			aw_id_fifo <= '0;
			aw_len_fifo <= '0;
			aw_size_fifo <= '0;
			aw_burst_fifo <= '0;
			aw_lock_fifo <= '0;
			aw_cache_fifo <= '0;
			aw_prot_fifo <= '0;
			aw_qos_fifo <= '0;
			aw_valid_fifo <= '0;
			w_data_fifo <= '0;
			w_strb_fifo <= '0;
			w_last_fifo <= '0;
			b_id_fifo <= '0;
			b_resp_fifo <= '0;
			aw_write_ptr <= '0;
			aw_read_ptr <= '0;
			aw_write_en <= '0;
			aw_read_en <= '0;
			w_write_en <= '0;
			w_read_en <= '0;
			ar_write_en <= '0;
			ar_read_en <= '0;
			r_write_en <= '0;
			r_read_en <= '0;
		end else begin
			aw_addr_fifo[aw_write_ptr] <= S_AXI_AWADDR;
			aw_id_fifo[aw_write_ptr] <= S_AXI_AWID;
			aw_len_fifo[aw_write_ptr] <= S_AXI_AWLEN;
			aw_size_fifo[aw_write_ptr] <= S_AXI_AWSIZE;
			aw_burst_fifo[aw_write_ptr] <= S_AXI_AWBURST;
			aw_lock_fifo[aw_write_ptr] <= S_AXI_AWLOCK;
			aw_cache_fifo[aw_write_ptr] <= S_AXI_AWCACHE;
			aw_prot_fifo[aw_write_ptr] <= S_AXI_AWPROT;
			aw_qos_fifo[aw_write_ptr] <= S_AXI_AWQOS;
			aw_valid_fifo[aw_write_ptr] <= S_AXI_AWVALID;
			w_data_fifo[w_write_ptr] <= S_AXI_WDATA;
			w_strb_fifo[w_write_ptr] <= S_AXI_WSTRB;
			w_last_fifo[w_write_ptr] <= S_AXI_WLAST;
			b_id_fifo[b_write_ptr] <= S_AXI_BID;
			b_resp_fifo[b_write_ptr] <= S_AXI_BRESP;
			aw_write_ptr <= aw_write_ptr_reg;
			aw_read_ptr <= aw_read_ptr_reg;
			aw_write_en <= aw_write_en_reg;
			aw_read_en <= aw_read_en_reg;
			w_write_en <= w_write_en_reg;
			w_read_en <= w_read_en_reg;
			ar_write_en <= ar_write_en_reg;
			ar_read_en <= ar_read_en_reg;
			r_write_en <= r_write_en_reg;
			r_read_en <= r_read_en_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_addr_fifo <= '0;
			aw_id_fifo <= '0;
			aw_len_fifo <= '0;
			aw_size_fifo <= '0;
			aw_burst_fifo <= '0;
			aw_lock_fifo <= '0;
			aw_cache_fifo <= '0;
			aw_prot_fifo <= '0;
			aw_qos_fifo <= '0;
			aw_valid_fifo <= '0;
			w_data_fifo <= '0;
			w_strb_fifo <= '0;
			w_last_fifo <= '0;
			b_id_fifo <= '0;
			b_resp_fifo <= '0;
			aw_write_ptr <= '0;
			aw_read_ptr <= '0;
			aw_write_en <= '0;
			aw_read_en <= '0;
			w_write_en <= '0;
			w_read_en <= '0;
			ar_write_en <= '0;
			ar_read_en <= '0;
			r_write_en <= '0;
			r_read_en <= '0;
		end else begin
			aw_addr_fifo[aw_write_ptr] <= M_AXI_AWADDR;
			aw_id_fifo[aw_write_ptr] <= M_AXI_AWID;
			aw_len_fifo[aw_write_ptr] <= M_AXI_AWLEN;
			aw_size_fifo[aw_write_ptr] <= M_AXI_AWSIZE;
			aw_burst_fifo[aw_write_ptr] <= M_AXI_AWBURST;
			aw_lock_fifo[aw_write_ptr] <= M_AXI_AWLOCK;
			aw_cache_fifo[aw_write_ptr] <= M_AXI_AWCACHE;
			aw_prot_fifo[aw_write_ptr] <= M_AXI_AWPROT;
			aw_qos_fifo[aw_write_ptr] <= M_AXI_AWQOS;
			aw_valid_fifo[aw_write_ptr] <= M_AXI_AWVALID;
			w_data_fifo[w_write_ptr] <= M_AXI_WDATA;
			w_strb_fifo[w_write_ptr] <= M_AXI_WSTRB;
			w_last_fifo[w_write_ptr] <= M_AXI_WLAST;
			b_id_fifo[b_write_ptr] <= M_AXI_BID;
			b_resp_fifo[b_write_ptr] <= M_AXI_BRESP;
			aw_write_ptr <= aw_write_ptr_reg;
			aw_read_ptr <= aw_read_ptr_reg;
			aw_write_en <= aw_write_en_reg;
			aw_read_en <= aw_read_en_reg;
			w_write_en <= w_write_en_reg;
			w_read_en <= w_read_en_reg;
			ar_write_en <= ar_write_en_reg;
			ar_read_en <= ar_read_en_reg;
			r_write_en <= r_write_en_reg;
			r_read_en <= r_read_en_reg;
		end
	end

	// Read FIFO Logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_addr_fifo <= '0;
			ar_id_fifo <= '0;
			ar_len_fifo <= '0;
			ar_size_fifo <= '0;
			ar_burst_fifo <= '0;
			ar_lock_fifo <= '0;
			ar_cache_fifo <= '0;
			ar_prot_fifo <= '0;
			ar_qos_fifo <= '0;
			r_data_fifo <= '0;
			r_resp_fifo <= '0;
			r_last_fifo <= '0;
			ar_read_ptr <= '0;
			ar_write_ptr <= '0;
			ar_read_en <= '0;
			ar_write_en <= '0;
			r_read_en <= '0;
			r_write_en <= '0;
		end else begin
			ar_addr_fifo[ar_write_ptr] <= S_AXI_ARADDR;
			ar_id_fifo[ar_write_ptr] <= S_AXI_ARID;
			ar_len_fifo[ar_write_ptr] <= S_AXI_ARLEN;
			ar_size_fifo[ar_write_ptr] <= S_AXI_ARSIZE;
			ar_burst_fifo[ar_write_ptr] <= S_AXI_ARBURST;
			ar_lock_fifo[ar_write_ptr] <= S_AXI_ARLOCK;
			ar_cache_fifo[ar_write_ptr] <= S_AXI_ARCACHE;
			ar_prot_fifo[ar_write_ptr] <= S_AXI_ARPROT;
			ar_qos_fifo[ar_write_ptr] <= S_AXI_ARQOS;
			r_data_fifo[r_write_ptr] <= S_AXI_RDATA;
			r_resp_fifo[r_write_ptr] <= S_AXI_RRESP;
			r_last_fifo[r_write_ptr] <= S_AXI_RLAST;
			ar_read_ptr <= ar_read_ptr_reg;
			ar_write_ptr <= ar_write_ptr_reg;
			ar_read_en <= ar_read_en_reg;
			ar_write_en <= ar_write_en_reg;
			r_read_en <= r_read_en_reg;
			r_write_en <= r_write_en_reg;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_addr_fifo <= '0;
			ar_id_fifo <= '0;
			ar_len_fifo <= '0;
			ar_size_fifo <= '0;
			ar_burst_fifo <= '0;
			ar_lock_fifo <= '0;
			ar_cache_fifo <= '0;
			ar_prot_fifo <= '0;
			ar_qos_fifo <= '0;
			r_data_fifo <= '0;
			r_resp_fifo <= '0;
			r_last_fifo <= '0;
			ar_read_ptr <= '0;
			ar_write_ptr <= '0;
			ar_read_en <= '0;
			ar_write_en <= '0;
			r_read_en <= '0;
			r_write_en <= '0;
		end else begin
			ar_addr_fifo[ar_write_ptr] <= M_AXI_ARADDR;
			ar_id_fifo[ar_write_ptr] <= M_AXI_ARID;
			ar_len_fifo[ar_write_ptr] <= M_AXI_ARLEN;
			ar_size_fifo
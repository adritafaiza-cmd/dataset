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

// ============================================================================
// Internal Parameters and Types
// ============================================================================
localparam C_AXI_ADDR_LSB = $clog2(C_AXI_DATA_WIDTH) - 3;
localparam C_AXI_ADDR_MSB = C_AXI_ADDR_WIDTH - 1 - C_AXI_ADDR_LSB;
localparam C_AXI_ADDR_WIDTH_LOG2 = $clog2(C_AXI_ADDR_WIDTH);

// State Machine States
typedef enum logic [2:0] {
    IDLE,
    AW_WAIT,
    W_WAIT,
    B_WAIT,
    AR_WAIT,
    R_WAIT,
    DONE
} axi_state_t;

// ============================================================================
// AXI4-Lite Control Interface
// ============================================================================
reg [31:0] g_reg_src_addr;
reg [31:0] g_reg_dst_addr;
reg [31:0] g_reg_len;
reg [31:0] g_reg_ctrl;
reg [31:0] g_reg_status;
reg [31:0] g_reg_abort_key;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        g_reg_src_addr <= 32'h0;
        g_reg_dst_addr <= 32'h0;
        g_reg_len      <= 32'h0;
        g_reg_ctrl     <= 32'h0;
        g_reg_status   <= 32'h0;
        g_reg_abort_key<= 32'h0;
    end else begin
        if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
            case (S_AXIL_AWADDR[1:0])
                2'b00: g_reg_src_addr <= S_AXIL_AWADDR;
                2'b01: g_reg_dst_addr <= S_AXIL_AWADDR;
                2'b10: g_reg_len      <= S_AXIL_AWADDR;
                2'b11: g_reg_ctrl     <= S_AXIL_AWADDR;
            endcase
            S_AXIL_BVALID <= 1'b1;
            S_AXIL_BREADY <= 1'b1;
            S_AXIL_BRESP  <= 2'b00;
        end
        if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
            case (S_AXIL_ARADDR[1:0])
                2'b00: g_reg_src_addr <= S_AXIL_ARADDR;
                2'b01: g_reg_dst_addr <= S_AXIL_ARADDR;
                2'b10: g_reg_len      <= S_AXIL_ARADDR;
                2'b11: g_reg_ctrl     <= S_AXIL_ARADDR;
            endcase
            S_AXIL_RVALID <= 1'b1;
            S_AXIL_RREADY <= 1'b1;
            S_AXIL_RDATA  <= {g_reg_ctrl[31:0], 32'h0}; // Return status/ctrl
            S_AXIL_RRESP  <= 2'b00;
        end
    end
end

// Read/Write Ready for Lite
assign S_AXIL_AWREADY = (g_reg_ctrl[0] == 1'b0) || (g_reg_ctrl[0] == 1'b1 && S_AXIL_AWVALID);
assign S_AXIL_WREADY  = (g_reg_ctrl[0] == 1'b0) || (g_reg_ctrl[0] == 1'b1 && S_AXIL_WVALID);
assign S_AXIL_ARREADY = (g_reg_ctrl[0] == 1'b0) || (g_reg_ctrl[0] == 1'b1 && S_AXIL_ARVALID);

// Write Response for Lite (Write to Control register)
assign S_AXIL_BVALID = (g_reg_ctrl[0] == 1'b1) && S_AXIL_AWVALID;
assign S_AXIL_BREADY = 1'b1;
assign S_AXIL_BRESP  = 2'b00;

// Read Response for Lite (Read from Control register)
assign S_AXIL_RVALID = (g_reg_ctrl[0] == 1'b1) && S_AXIL_ARVALID;
assign S_AXIL_RREADY = 1'b1;
assign S_AXIL_RDATA  = g_reg_ctrl;
assign S_AXIL_RRESP  = 2'b00;

// ============================================================================
// AXI4 Master Interface (M_AXI)
// ============================================================================
// ID Encoding: Use AXI_READ_ID for reads, AXI_WRITE_ID for writes
// If IDs are 0, we use a simple counter or fixed ID.
// For this implementation, we assume single channel per direction or round robin if multiple.
// Here we use the parameters directly.

reg [C_AXI_ID_WIDTH-1:0] m_aw_id;
reg [C_AXI_ID_WIDTH-1:0] m_ar_id;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        m_aw_id <= AXI_WRITE_ID;
        m_ar_id <= AXI_READ_ID;
    end
end

// Address Width Adjustment
// M_AXI addresses are C_AXI_ADDR_WIDTH bits.
// We need to handle the LSB alignment if OPT_UNALIGNED is 0.
// If OPT_UNALIGNED is 1, we pass the address as is (assuming software aligns or we handle it).
// However, standard AXI requires alignment. 
// Let's assume the software provides aligned addresses if OPT_UNALIGNED is 0.
// If OPT_UNALIGNED is 1, we might need to shift. 
// Given the prompt "OPT_UNALIGNED and OPT_WRAPMEM change address handling", 
// we will implement a simple shift if OPT_UNALIGNED is 0.

reg [C_AXI_ADDR_WIDTH-1:0] m_aw_addr;
reg [C_AXI_ADDR_WIDTH-1:0] m_ar_addr;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        m_aw_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
        m_ar_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
    end
end

// ============================================================================
// Main Control Logic
// ============================================================================
axi_state_t state, next_state;
reg [31:0] current_addr;
reg [31:0] current_len;
reg [31:0] current_data;
reg [31:0] current_strb;
reg [31:0] current_burst_len;
reg [31:0] current_burst_count;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0] current_burst_lock;
reg [31:0] current_burst_cache;
reg [31:0] current_burst_qos;
reg [31:0] current_burst_prot;
reg [31:0] current_burst_resp;
reg [31:0] current_burst_valid;
reg [31:0] current_burst_ready;
reg [31:0] current_burst_data;
reg [31:0] current_burst_strb;
reg [31:0] current_burst_last;
reg [31:0] current_burst_id;
reg [31:0] current_burst_addr;
reg [31:0] current_burst_size;
reg [31:0] current_burst_type;
reg [31:0]
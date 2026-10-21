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
// Internal Parameters and Constants
// ============================================================================
localparam LG_FIFO = LGFIFO;
localparam FIFO_DEPTH = 1 << LG_FIFO;
localparam ADDR_WIDTH = C_AXI_ADDR_WIDTH;
localparam DATA_WIDTH = C_AXI_DATA_WIDTH;
localparam DATA_WIDTH_8 = DATA_WIDTH/8;
localparam ADDR_LSB = ADDRLSB;
localparam AXIL_ADDR_LSB = AXILLSB;

// State Machine States
localparam STATE_IDLE = 3'b000;
localparam STATE_CONFIG = 3'b001;
localparam STATE_READ_SETUP = 3'b010;
localparam STATE_READ_ACTIVE = 3'b011;
localparam STATE_WRITE_SETUP = 3'b100;
localparam STATE_WRITE_ACTIVE = 3'b101;
localparam STATE_DONE = 3'b110;
localparam STATE_ABORT = 3'b111;

// ============================================================================
// AXI4-Lite Control Interface
// ============================================================================
reg [C_AXIL_ADDR_WIDTH-1:0] cfg_addr;
reg [C_AXIL_DATA_WIDTH-1:0] cfg_data;
reg cfg_rdata_valid;
reg cfg_rdata_ready;
reg cfg_aw_valid;
reg cfg_aw_ready;
reg cfg_w_valid;
reg cfg_w_ready;
reg cfg_b_valid;
reg cfg_b_ready;
reg cfg_ar_valid;
reg cfg_ar_ready;
reg cfg_r_valid;
reg cfg_r_ready;

// AXI4-Lite Read/Write Handshakes
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        cfg_addr <= 0;
        cfg_data <= 0;
        cfg_rdata_valid <= 0;
        cfg_rdata_ready <= 1;
        cfg_aw_valid <= 0;
        cfg_aw_ready <= 1;
        cfg_w_valid <= 0;
        cfg_w_ready <= 1;
        cfg_b_valid <= 0;
        cfg_b_ready <= 1;
        cfg_ar_valid <= 0;
        cfg_ar_ready <= 1;
        cfg_r_valid <= 0;
        cfg_r_ready <= 1;
        o_int <= 0;
    end else begin
        // Read Data
        cfg_rdata_valid <= S_AXIL_RVALID & cfg_r_ready;
        cfg_rdata_ready <= cfg_r_valid & S_AXIL_RREADY;
        if (cfg_rdata_valid) cfg_data <= S_AXIL_RDATA;

        // Write Address
        cfg_aw_valid <= S_AXIL_AWVALID & cfg_aw_ready;
        cfg_aw_ready <= cfg_aw_valid & S_AXIL_AWREADY;
        if (cfg_aw_valid) cfg_addr <= S_AXIL_AWADDR;

        // Write Data
        cfg_w_valid <= S_AXIL_WVALID & cfg_w_ready;
        cfg_w_ready <= cfg_w_valid & S_AXIL_WREADY;
        if (cfg_w_valid) cfg_data <= {S_AXIL_WDATA, 32'd0}; // Assume 32-bit config for simplicity

        // Write Response
        cfg_b_valid <= S_AXIL_BVALID & cfg_b_ready;
        cfg_b_ready <= cfg_b_valid & S_AXIL_BREADY;
        if (cfg_b_valid) cfg_data[0] <= S_AXIL_BRESP;

        // Read Address
        cfg_ar_valid <= S_AXIL_ARVALID & cfg_ar_ready;
        cfg_ar_ready <= cfg_ar_valid & S_AXIL_ARREADY;
        if (cfg_ar_valid) cfg_addr <= S_AXIL_ARADDR;

        // Read Response
        cfg_r_valid <= S_AXIL_RVALID & cfg_r_ready;
        cfg_r_ready <= cfg_r_valid & S_AXIL_RREADY;
        if (cfg_r_valid) cfg_data[0] <= S_AXIL_RRESP;
    end
end

// Decode Configuration
reg [31:0] src_addr;
reg [31:0] dst_addr;
reg [31:0] length;
reg [31:0] stride;
reg [31:0] abort_key_reg;
reg [31:0] current_addr;
reg [31:0] current_dst_addr;
reg [31:0] remaining_length;
reg [31:0] burst_count;
reg [31:0] burst_size;
reg [31:0] burst_stride;
reg [31:0] burst_mask;
reg [31:0] burst_offset;
reg [31:0] burst_remain;
reg [31:0] burst_size_reg;
reg [31:0] burst_stride_reg;
reg [31:0] burst_mask_reg;
reg [31:0] burst_offset_reg;
reg [31:0] burst_remain_reg;
reg [31:0] burst_size_reg2;
reg [31:0] burst_stride_reg2;
reg [31:0] burst_mask_reg2;
reg [31:0] burst_offset_reg2;
reg [31:0] burst_remain_reg2;
reg [31:0] burst_size_reg3;
reg [31:0] burst_stride_reg3;
reg [31:0] burst_mask_reg3;
reg [31:0] burst_offset_reg3;
reg [31:0] burst_remain_reg3;
reg [31:0] burst_size_reg4;
reg [31:0] burst_stride_reg4;
reg [31:0] burst_mask_reg4;
reg [31:0] burst_offset_reg4;
reg [31:0] burst_remain_reg4;
reg [31:0] burst_size_reg5;
reg [31:0] burst_stride_reg5;
reg [31:0] burst_mask_reg5;
reg [31:0] burst_offset_reg5;
reg [31:0] burst_remain_reg5;
reg [31:0] burst_size_reg6;
reg [31:0] burst_stride_reg6;
reg [31:0] burst_mask_reg6;
reg [31:0] burst_offset_reg6;
reg [31:0] burst_remain_reg6;
reg [31:0] burst_size_reg7;
reg [31:0] burst_stride_reg7;
reg [31:0] burst_mask_reg7;
reg [31:0] burst_offset_reg7;
reg [31:0] burst_remain_reg7;
reg [31:0] burst_size_reg8;
reg [31:0] burst_stride_reg8;
reg [31:0] burst_mask_reg8;
reg [31:0] burst_offset_reg8;
reg [31:0] burst_remain_reg8;
reg [31:0] burst_size_reg9;
reg [31:0] burst_stride_reg9;
reg [31:0] burst_mask_reg9;
reg [31:0] burst_offset_reg9;
reg [31:0] burst_remain_reg9;
reg [31:0] burst_size_reg10;
reg [31:0] burst_stride_reg10;
reg [31:0] burst_mask_reg10;
reg [31:0] burst_offset_reg10;
reg [31:0] burst_remain_reg10;
reg [31:0] burst_size_reg11;
reg [31:0] burst_stride_reg11;
reg [31:0] burst_mask_reg11;
reg [31:0] burst_offset_reg11;
reg [31:0] burst_remain_reg11;
reg [31:0] burst_size_reg12;
reg [31:0] burst_stride_reg12;
reg [31:0] burst_mask_reg12;
reg [31:0] burst_offset_reg12;
reg [31:0] burst_remain_reg12;
reg [31:0] burst_size_reg13;
reg [31:0] burst_stride_reg13;
reg [31:0] burst_mask_reg13;
reg [31:0] burst_offset_reg13;
reg [31:0] burst_remain_reg13;
reg [31:0] burst_size_reg14;
reg [31:0] burst_stride_reg14;
reg [31:0] burst_mask_reg14;
reg [31:0] burst_offset_reg14;
reg [31:0] burst_remain_reg14;
reg [31:0] burst_size_reg15;
reg [31:0] burst_stride_reg15;
reg [31:0] burst_mask_reg15;
reg [31:0] burst_offset_reg15;
reg [31:0] burst_remain_reg15;
reg [31:0] burst_size_reg16;
reg [31:0] burst_stride_reg16;
reg [31:0] burst_mask_reg16;
reg [31:0] burst_offset_reg16;
reg [31:0] burst_remain_reg16;
reg [31:0] burst_size_reg17;
reg [31:0] burst_stride_reg17;
reg [31:0] burst_mask_reg17;
reg [31:0] burst_offset_reg17;
reg [31:0] burst_remain_reg17;
reg [31:0] burst_size_reg18;
reg [31:0] burst_stride_reg18;
reg [31:0] burst_mask_reg18;
reg [31:0] burst_offset_reg18;
reg [31:0] burst_remain_reg18;
reg [31:0] burst_size_reg19;
reg [31:0] burst_stride_reg19;
reg [31:0] burst_mask_reg19;
reg [31:0] burst_offset_reg19;
reg [31:0] burst_remain_reg19;
reg [31:0] burst_size_reg20;
reg [31:0] burst_stride_reg20;
reg [31:0] burst_mask_reg20;
reg [31:0] burst_offset_reg20;
reg [31:0] burst_remain_reg20;
reg [31:0] burst_size_reg21;
reg [31:0] burst_stride_reg21;
reg [31:0] burst_mask_reg21;
reg [31:0] burst_offset_reg21;
reg [31:0] burst_remain_reg21;
reg [31:0] burst_size_reg22;
reg [31:0] burst_stride_reg22;
reg [31:0] burst_mask_reg22;
reg [31:0] burst_offset_reg22;
reg [31:0] burst_remain_reg22;
reg [31:0] burst_size_reg23;
reg [31:0] burst_stride_reg23;
reg [31:0] burst_mask_reg23;
reg [31:0] burst_offset_reg23;
reg [31:0] burst_remain_reg23;
reg [31:0] burst_size_reg24;
reg [31:0] burst_stride_reg24;
reg [31:0] burst_mask_reg24;
reg [31:0] burst_offset_reg24;
reg [31:0] burst_remain_reg24;
reg [31:0] burst_size_reg25;
reg [31:0] burst_stride_reg25;
reg [31:0] burst_mask_reg25;
reg [31:0] burst_offset_reg25;
reg [31:0] burst_remain_reg25;
reg [31:0] burst_size_reg26;
reg [31:0] burst_stride_reg26;
reg [31:0] burst_mask_reg26;
reg [31:0] burst_offset_reg26;
reg [31:0] burst_remain_reg26;
reg [31:0] burst_size_reg27;
reg [31:0] burst_stride_reg27;
reg [31:0] burst_mask_reg27;
reg [31:0] burst_offset_reg27;
reg [31:0] burst_remain_reg27;
reg [31:0] burst_size_reg28;
reg [31:0] burst_stride_reg28;
reg [31:0] burst_mask_reg28;
reg [31:0] burst_offset_reg28;
reg [31:0] burst_remain_reg28;
reg [31:0] burst_size_reg29;
reg [31:0] burst_stride_reg29;
reg [31:0] burst_mask_reg29;
reg [31:0] burst_offset_reg29;
reg [31:0] burst_remain_reg29;
reg [31:0] burst_size_reg30;
reg [31:0] burst_stride_reg30;
reg [31:0] burst_mask_reg30;
reg [31:0] burst_offset_reg30;
reg [31:0] burst_remain_reg30;
reg [31:0] burst_size_reg31;
reg [31:0] burst_stride_reg31;
reg [31:0] burst_mask_reg31;
reg [31:0] burst_offset_reg31;
reg [31:0] burst_remain_reg31;
reg [31:0] burst_size_reg32;
reg [31:0] burst_stride_reg32;
reg [31:0] burst_mask_reg32;
reg [31:0] burst_offset_reg32;
reg [31:0] burst_remain_reg32;
reg [31:0] burst_size_reg33;
reg [31:0] burst_stride_reg33;
reg [31:0] burst_mask_reg33;
reg [31:0] burst_offset_reg33;
reg [31:0] burst_remain_reg33;
reg [31:0] burst_size_reg34;
reg [31:0] burst_stride_reg34;
reg [31:0] burst_mask_reg34;
reg [31:0] burst_offset_reg34;
reg [31:0] burst_remain_reg34;
reg [31:0] burst_size_reg35;
reg [31:0] burst_stride_reg35;
reg [31:0] burst_mask_reg35;
reg [31:0] burst_offset_reg35;
reg [31:0] burst_remain_reg35;
reg [31:0] burst_size_reg36;
reg [31:0] burst_stride_reg36;
reg [31:0] burst_mask_reg36;
reg [31:0] burst_offset_reg36;
reg [31:0] burst_remain_reg36;
reg [31:0] burst_size_reg37;
reg [31:0] burst_stride_reg37;
reg [31:0] burst_mask_reg37;
reg [31:0] burst_offset_reg37;
reg [31:0] burst_remain_reg37;
reg [31:0] burst_size_reg38;
reg [31:0] burst_stride_reg38;
reg [31:0] burst_mask_reg38;
reg [31:0] burst_offset_reg38;
reg [31:0] burst_remain_reg38;
reg [31:0] burst_size_reg39;
reg [31:0] burst_stride_reg39;
reg [31:0] burst_mask_reg39;
reg [31:0] burst_offset_reg39;
reg [31:0] burst_remain_reg39;
reg [31:0] burst_size_reg40;
reg [31:0] burst_stride_reg40;
reg [31:0] burst_mask_reg40;
reg [31:0] burst_offset_reg40;
reg [31:0] burst_remain_reg40;
reg [31:0] burst_size_reg41;
reg [31:0] burst_stride_reg41;
reg [31:0] burst_mask_reg41;
reg [31:0] burst_offset_reg41;
reg [31:0] burst_remain_reg41;
reg [31:0] burst_size_reg42;
reg [31:0] burst_stride_reg42;
reg [31:0] burst_mask_reg42;
reg [31:0] burst_offset_reg42;
reg [31:0] burst_remain_reg42;
reg [31:0] burst_size_reg43;
reg [31:0] burst_stride_reg43;
reg [31:0] burst_mask_reg43;
reg [31:0] burst_offset_reg43;
reg [31:0] burst_remain_reg43;
reg [31:0] burst_size_reg44;
reg [31:0] burst_stride_reg44;
reg [31:0] burst_mask_reg44;
reg [31:0] burst_offset_reg44;
reg [31:0] burst_remain_reg44;
reg [31:0] burst_size_reg45;
reg [31:0] burst_stride_reg45;
reg [31:0] burst_mask_reg45;
reg [31:0] burst_offset_reg45;
reg [31:0] burst_remain_reg45;
reg [31:0] burst_size_reg46;
reg [31:0] burst_stride_reg46;
reg [31:0] burst_mask_reg46;
reg [31:0] burst_offset_reg46;
reg [31:0] burst_remain_reg46;
reg [31:0] burst_size_reg47;
reg [31:0] burst_stride_reg47;
reg [31:0] burst_mask_reg47;
reg [31:0] burst_offset_reg47;
reg [31:0] burst_remain_reg47;
reg [31:0] burst_size_reg48;
reg [31:0] burst_stride_reg48;
reg [31:0] burst_mask_reg48;
reg [31:0] burst_offset_reg48;
reg [31:0] burst_remain_reg48;
reg [31:0] burst_size_reg49;
reg [31:0] burst_stride_reg49;
reg [31:0] burst_mask_reg49;
reg [31:0] burst_offset_reg49;
reg [31:0] burst_remain_reg49;
reg [31:0] burst_size_reg50;
reg [31:0] burst_stride_reg50;
reg [31:0] burst_mask_reg50;
reg [31:0] burst_offset_reg50;
reg [31:0] burst_remain_reg50;
reg [31:0] burst_size_reg51;
reg [31:0] burst_stride_reg51;
reg [31:0] burst_mask_reg51;
reg [31:0] burst_offset_reg51;
reg [31:0] burst_remain_reg51;
reg [31:0] burst_size_reg52;
reg [31:0] burst_stride_reg52;
reg [31:0] burst_mask_reg52;
reg [31:0] burst_offset_reg52;
reg [31:0] burst_remain_reg52;
reg [31:0] burst_size_reg53;
reg [31:0] burst_stride_reg53;
reg [31:0] burst_mask_reg53;
reg [31:0] burst_offset_reg53;
reg [31:0] burst_remain_reg53;
reg [31:0] burst_size_reg54;
reg [31:0] burst_stride_reg54;
reg [31:0] burst_mask_reg54;
reg [31:0] burst_offset_reg54;
reg [31:0] burst_remain_reg54;
reg [31:0] burst_size_reg55;
reg [31:0] burst_stride_reg55;
reg [31:0] burst_mask_reg55;
reg [31:0] burst_offset_reg55;
reg [31:0] burst_remain_reg55;
reg [31:0] burst_size_reg56;
reg [31:0] burst_stride_reg56;
reg [31:0] burst_mask_reg56;
reg [31:0] burst_offset_reg56;
reg [31:0] burst_remain_reg56;
reg [31:0] burst_size_reg57;
reg [31:0] burst_stride_reg57;
reg [31:0] burst_mask_reg57;
reg [31:0] burst_offset_reg57;
reg [31:0] burst_remain_reg57;
reg [31:0] burst_size_reg58;
reg [31:0] burst_stride_reg58;
reg [31:0] burst_mask_reg58;
reg [31:0] burst_offset_reg58;
reg [31:0] burst_remain_reg58;
reg [31:0] burst_size_reg59;
reg [31:0] burst_stride_reg59;
reg [31:0] burst_mask_reg59;
reg [31:0] burst_offset_reg59;
reg [31:0] burst_remain_reg59;
reg [31:0] burst_size_reg60;
reg [31:0] burst_stride_reg60;
reg [31:0] burst_mask_reg60;
reg [31:0] burst_offset_reg60;
reg [31:0] burst_remain_reg60;
reg [31:0] burst_size_reg61;
reg [31:0] burst_stride_reg61;
reg [31:0] burst_mask_reg61;
reg [31:0] burst_offset_reg61;
reg [31:0] burst_remain_reg61;
reg [31:0] burst_size_reg62;
reg [31:0] burst_stride_reg62;
reg [31:0] burst_mask_reg62;
reg [31:0] burst_offset_reg62;
reg [31:0] burst_remain_reg62;
reg [31:0] burst_size_reg63;
reg [31:0] burst_stride_reg63;
reg [31:0] burst_mask_reg63;
reg [31:0] burst_offset_reg63;
reg [31:0] burst_remain_reg63;
reg [31:0] burst_size_reg64;
reg [31:0] burst_stride_reg64;
reg [31:0] burst_mask_reg64;
reg [31:0] burst_offset_reg64;
reg [31:0] burst_remain_reg64;
reg [31:0] burst_size_reg65;
reg [31:0] burst_stride_reg65;
reg [31:0] burst_mask_reg65;
reg [31:0] burst_offset_reg65;
reg [31:0] burst_remain_reg65;
reg [31:0] burst_size_reg66;
reg [31:0] burst_stride_reg66;
reg [31:0] burst_mask_reg66;
reg [31:0] burst_offset_reg66;
reg [31:0] burst_remain_reg66;
reg [31:0] burst_size_reg67;
reg [31:0] burst_stride_reg67;
reg [31:0] burst_mask_reg67;
reg [31:0] burst_offset_reg67;
reg [31:0] burst_remain_reg67;
reg [31:0] burst_size_reg68;
reg [31:0] burst_stride_reg68;
reg [31:0] burst_mask_reg68;
reg [31:0] burst_offset_reg68;
reg [31:0] burst_remain_reg68;
reg [31:0] burst_size_reg69;
reg [31:0] burst_stride_reg69;
reg [31:0] burst_mask_reg69;
reg [31:0] burst_offset_reg69;
reg [31:0] burst_remain_reg69;
reg [31:0] burst_size_reg70;
reg [31:0] burst_stride_reg70;
reg [31:0] burst_mask_reg70;
reg [31:0] burst_offset_reg70;
reg [31:0] burst_remain_reg70;
reg [31:0] burst_size_reg71;
reg [31:0] burst_stride_reg71;
reg [31:0] burst_mask_reg71;
reg [31:0] burst_offset_reg71;
reg [31:0] burst_remain_reg71;
reg [31:0] burst_size_reg72;
reg [31:0] burst_stride_reg72;
reg [31:0] burst_mask_reg72;
reg [31:0] burst_offset_reg72;
reg [31:0] burst_remain_reg72;
reg [31:0] burst_size_reg73;
reg [31:0] burst_stride_reg73;
reg [31:0] burst_mask_reg73;
reg [31:0] burst_offset_reg73;
reg [31:0] burst_remain_reg73;
reg [31:0] burst_size_reg74;
reg [31:0] burst_stride_reg74;
reg [31:0] burst_mask_reg74;
reg [31:0] burst_offset_reg74;
reg [31:0] burst_remain_reg74;
reg [31:0] burst_size_reg75;
reg [31:0] burst_stride_reg75;
reg [31:0] burst_mask_reg75;
reg [31:0] burst_offset_reg75;
reg [31:0] burst_remain_reg75;
reg [31:0] burst_size_reg76;
reg [31:0] burst_stride_reg76;
reg [31:0] burst_mask_reg76;
reg [31:0] burst_offset_reg76;
reg [31:0] burst_remain_reg76;
reg [31:0] burst_size_reg77;
reg [31:0] burst_stride_reg77;
reg [31:0] burst_mask_reg77;
reg [31:0] burst_offset_reg77;
reg [31:0] burst_remain_reg77;
reg [31:0] burst_size_reg78;
reg [31:0] burst_stride_reg78;
reg [31:0] burst_mask_reg78;
reg [31:0] burst_offset_reg78;
reg [31:0] burst_remain_reg78;
reg [31:0] burst_size_reg79;
reg [31:0] burst_stride_reg79;
reg [31:0] burst_mask_reg79;
reg [31:0] burst_offset_reg79;
reg [31:0] burst_remain_reg79;
reg [31:0] burst_size_reg80;
reg [31:0] burst_stride_reg80;
reg [31:0] burst_mask_reg80;
reg [31:0] burst_offset_reg80;
reg [31:0] burst_remain_reg80;
reg [31:0] burst_size_reg81;
reg [31:0] burst_stride_reg81;
reg [31:0] burst_mask_reg81;
reg [31:0] burst_offset_reg81;
reg [31:0] burst_remain_reg81;
reg [31:0] burst_size_reg82;
reg [31:0] burst_stride_reg82;
reg [31:0] burst_mask_reg82;
reg [31:0] burst_offset_reg82;
reg [31:0] burst_remain_reg82;
reg [31:0] burst_size_reg83;
reg [31:0] burst_stride_reg83;
reg [31:0] burst_mask_reg83;
reg [31:0] burst_offset_reg83;
reg [31:0] burst_remain_reg83;
reg [31:0] burst_size_reg84;
reg [31:0] burst_stride_reg84;
reg [31:0] burst_mask_reg84;
reg [31:0] burst_offset_reg84;
reg [31:0] burst_remain_reg84;
reg [31:0] burst_size_reg85;
reg [31:0] burst_stride_reg85;
reg [31:0] burst_mask_reg85;
reg [31:0] burst_offset_reg85;
reg [31:0] burst_remain_reg85;
reg [31:0] burst_size_reg86;
reg [31:0] burst_stride_reg86;
reg [31:0] burst_mask_reg86;
reg [31:0] burst_offset_reg86;
reg [31:0] burst_remain_reg86;
reg [31:0] burst_size_reg87;
reg [31:0] burst_stride_reg87;
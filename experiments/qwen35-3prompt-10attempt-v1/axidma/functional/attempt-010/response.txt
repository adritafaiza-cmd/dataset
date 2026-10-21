```verilog
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

	// Internal State Machine and Control
	localparam STATE_IDLE = 2'b00;
	localparam STATE_CONFIG = 2'b01;
	localparam STATE_READ = 2'b10;
	localparam STATE_WRITE = 2'b11;
	localparam STATE_ABORT = 2'b100;

	reg [1:0] state;
	reg [31:0] src_addr;
	reg [31:0] dst_addr;
	reg [31:0] len;
	reg [31:0] next_addr;
	reg [31:0] next_dst;
	reg [31:0] burst_count;
	reg [31:0] remaining_len;
	reg [31:0] current_addr;
	reg [31:0] current_dst;
	reg [31:0] current_len;
	reg [31:0] current_burst_count;
	reg [31:0] current_remaining;
	reg [31:0] current_src;
	reg [31:0] current_dst_addr;
	reg [31:0] current_len_val;
	reg [31:0] current_burst_cnt;
	reg [31:0] current_rem;
	reg [31:0] current_src_addr;
	reg [31:0] current_dst_addr_val;
	reg [31:0] current_len_val_reg;
	reg [31:0] current_burst_cnt_reg;
	reg [31:0] current_rem_reg;
	reg [31:0] current_src_addr_reg;
	reg [31:0] current_dst_addr_val_reg;
	reg [31:0] current_len_val_reg2;
	reg [31:0] current_burst_cnt_reg2;
	reg [31:0] current_rem_reg2;
	reg [31:0] current_src_addr_reg2;
	reg [31:0] current_dst_addr_val_reg2;
	reg [31:0] current_len_val_reg3;
	reg [31:0] current_burst_cnt_reg3;
	reg [31:0] current_rem_reg3;
	reg [31:0] current_src_addr_reg3;
	reg [31:0] current_dst_addr_val_reg3;
	reg [31:0] current_len_val_reg4;
	reg [31:0] current_burst_cnt_reg4;
	reg [31:0] current_rem_reg4;
	reg [31:0] current_src_addr_reg4;
	reg [31:0] current_dst_addr_val_reg4;
	reg [31:0] current_len_val_reg5;
	reg [31:0] current_burst_cnt_reg5;
	reg [31:0] current_rem_reg5;
	reg [31:0] current_src_addr_reg5;
	reg [31:0] current_dst_addr_val_reg5;
	reg [31:0] current_len_val_reg6;
	reg [31:0] current_burst_cnt_reg6;
	reg [31:0] current_rem_reg6;
	reg [31:0] current_src_addr_reg6;
	reg [31:0] current_dst_addr_val_reg6;
	reg [31:0] current_len_val_reg7;
	reg [31:0] current_burst_cnt_reg7;
	reg [31:0] current_rem_reg7;
	reg [31:0] current_src_addr_reg7;
	reg [31:0] current_dst_addr_val_reg7;
	reg [31:0] current_len_val_reg8;
	reg [31:0] current_burst_cnt_reg8;
	reg [31:0] current_rem_reg8;
	reg [31:0] current_src_addr_reg8;
	reg [31:0] current_dst_addr_val_reg8;
	reg [31:0] current_len_val_reg9;
	reg [31:0] current_burst_cnt_reg9;
	reg [31:0] current_rem_reg9;
	reg [31:0] current_src_addr_reg9;
	reg [31:0] current_dst_addr_val_reg9;
	reg [31:0] current_len_val_reg10;
	reg [31:0] current_burst_cnt_reg10;
	reg [31:0] current_rem_reg10;
	reg [31:0] current_src_addr_reg10;
	reg [31:0] current_dst_addr_val_reg10;
	reg [31:0] current_len_val_reg11;
	reg [31:0] current_burst_cnt_reg11;
	reg [31:0] current_rem_reg11;
	reg [31:0] current_src_addr_reg11;
	reg [31:0] current_dst_addr_val_reg11;
	reg [31:0] current_len_val_reg12;
	reg [31:0] current_burst_cnt_reg12;
	reg [31:0] current_rem_reg12;
	reg [31:0] current_src_addr_reg12;
	reg [31:0] current_dst_addr_val_reg12;
	reg [31:0] current_len_val_reg13;
	reg [31:0] current_burst_cnt_reg13;
	reg [31:0] current_rem_reg13;
	reg [31:0] current_src_addr_reg13;
	reg [31:0] current_dst_addr_val_reg13;
	reg [31:0] current_len_val_reg14;
	reg [31:0] current_burst_cnt_reg14;
	reg [31:0] current_rem_reg14;
	reg [31:0] current_src_addr_reg14;
	reg [31:0] current_dst_addr_val_reg14;
	reg [31:0] current_len_val_reg15;
	reg [31:0] current_burst_cnt_reg15;
	reg [31:0] current_rem_reg15;
	reg [31:0] current_src_addr_reg15;
	reg [31:0] current_dst_addr_val_reg15;
	reg [31:0] current_len_val_reg16;
	reg [31:0] current_burst_cnt_reg16;
	reg [31:0] current_rem_reg16;
	reg [31:0] current_src_addr_reg16;
	reg [31:0] current_dst_addr_val_reg16;
	reg [31:0] current_len_val_reg17;
	reg [31:0] current_burst_cnt_reg17;
	reg [31:0] current_rem_reg17;
	reg [31:0] current_src_addr_reg17;
	reg [31:0] current_dst_addr_val_reg17;
	reg [31:0] current_len_val_reg18;
	reg [31:0] current_burst_cnt_reg18;
	reg [31:0] current_rem_reg18;
	reg [31:0] current_src_addr_reg18;
	reg [31:0] current_dst_addr_val_reg18;
	reg [31:0] current_len_val_reg19;
	reg [31:0] current_burst_cnt_reg19;
	reg [31:0] current_rem_reg19;
	reg [31:0] current_src_addr_reg19;
	reg [31:0] current_dst_addr_val_reg19;
	reg [31:0] current_len_val_reg20;
	reg [31:0] current_burst_cnt_reg20;
	reg [31:0] current_rem_reg20;
	reg [31:0] current_src_addr_reg20;
	reg [31:0] current_dst_addr_val_reg20;
	reg [31:0] current_len_val_reg21;
	reg [31:0] current_burst_cnt_reg21;
	reg [31:0] current_rem_reg21;
	reg [31:0] current_src_addr_reg21;
	reg [31:0] current_dst_addr_val_reg21;
	reg [31:0] current_len_val_reg22;
	reg [31:0] current_burst_cnt_reg22;
	reg [31:0] current_rem_reg22;
	reg [31:0] current_src_addr_reg22;
	reg [31:0] current_dst_addr_val_reg22;
	reg [31:0] current_len_val_reg23;
	reg [31:0] current_burst_cnt_reg23;
	reg [31:0] current_rem_reg23;
	reg [31:0] current_src_addr_reg23;
	reg [31:0] current_dst_addr_val_reg23;
	reg [31:0] current_len_val_reg24;
	reg [31:0] current_burst_cnt_reg24;
	reg [31:0] current_rem_reg24;
	reg [31:0] current_src_addr_reg24;
	reg [31:0] current_dst_addr_val_reg24;
	reg [31:0] current_len_val_reg25;
	reg [31:0] current_burst_cnt_reg25;
	reg [31:0] current_rem_reg25;
	reg [31:0] current_src_addr_reg25;
	reg [31:0] current_dst_addr_val_reg25;
	reg [31:0] current_len_val_reg26;
	reg [31:0] current_burst_cnt_reg26;
	reg [31:0] current_rem_reg26;
	reg [31:0] current_src_addr_reg26;
	reg [31:0] current_dst_addr_val_reg26;
	reg [31:0] current_len_val_reg27;
	reg [31:0] current_burst_cnt_reg27;
	reg [31:0] current_rem_reg27;
	reg [31:0] current_src_addr_reg27;
	reg [31:0] current_dst_addr_val_reg27;
	reg [31:0] current_len_val_reg28;
	reg [31:0] current_burst_cnt_reg28;
	reg [31:0] current_rem_reg28;
	reg [31:0] current_src_addr_reg28;
	reg [31:0] current_dst_addr_val_reg28;
	reg [31:0] current_len_val_reg29;
	reg [31:0] current_burst_cnt_reg29;
	reg [31:0] current_rem_reg29;
	reg [31:0] current_src_addr_reg29;
	reg [31:0] current_dst_addr_val_reg29;
	reg [31:0] current_len_val_reg30;
	reg [31:0] current_burst_cnt_reg30;
	reg [31:0] current_rem_reg30;
	reg [31:0] current_src_addr_reg30;
	reg [31:0] current_dst_addr_val_reg30;
	reg [31:0] current_len_val_reg31;
	reg [31:0] current_burst_cnt_reg31;
	reg [31:0] current_rem_reg31;
	reg [31:0] current_src_addr_reg31;
	reg [31:0] current_dst_addr_val_reg31;
	reg [31:0] current_len_val_reg32;
	reg [31:0] current_burst_cnt_reg32;
	reg [31:0] current_rem_reg32;
	reg [31:0] current_src_addr_reg32;
	reg [31:0] current_dst_addr_val_reg32;
	reg [31:0] current_len_val_reg33;
	reg [31:0] current_burst_cnt_reg33;
	reg [31:0] current_rem_reg33;
	reg [31:0] current_src_addr_reg33;
	reg [31:0] current_dst_addr_val_reg33;
	reg [31:0] current_len_val_reg34;
	reg [31:0] current_burst_cnt_reg34;
	reg [31:0] current_rem_reg34;
	reg [31:0] current_src_addr_reg34;
	reg [31:0] current_dst_addr_val_reg34;
	reg [31:0] current_len_val_reg35;
	reg [31:0] current_burst_cnt_reg35;
	reg [31:0] current_rem_reg35;
	reg [31:0] current_src_addr_reg35;
	reg [31:0] current_dst_addr_val_reg35;
	reg [31:0] current_len_val_reg36;
	reg [31:0] current_burst_cnt_reg36;
	reg [31:0] current_rem_reg36;
	reg [31:0] current_src_addr_reg36;
	reg [31:0] current_dst_addr_val_reg36;
	reg [31:0] current_len_val_reg37;
	reg [31:0] current_burst_cnt_reg37;
	reg [31:0] current_rem_reg37;
	reg [31:0] current_src_addr_reg37;
	reg [31:0] current_dst_addr_val_reg37;
	reg [31:0] current_len_val_reg38;
	reg [31:0] current_burst_cnt_reg38;
	reg [31:0] current_rem_reg38;
	reg [31:0] current_src_addr_reg38;
	reg [31:0] current_dst_addr_val_reg38;
	reg [31:0] current_len_val_reg39;
	reg [31:0] current_burst_cnt_reg39;
	reg [31:0] current_rem_reg39;
	reg [31:0] current_src_addr_reg39;
	reg [31:0] current_dst_addr_val_reg39;
	reg [31:0] current_len_val_reg40;
	reg [31:0] current_burst_cnt_reg40;
	reg [31:0] current_rem_reg40;
	reg [31:0] current_src_addr_reg40;
	reg [31:0] current_dst_addr_val_reg40;
	reg [31:0] current_len_val_reg41;
	reg [31:0] current_burst_cnt_reg41;
	reg [31:0] current_rem_reg41;
	reg [31:0] current_src_addr_reg41;
	reg [31:0] current_dst_addr_val_reg41;
	reg [31:0] current_len_val_reg42;
	reg [31:0] current_burst_cnt_reg42;
	reg [31:0] current_rem_reg42;
	reg [31:0] current_src_addr_reg42;
	reg [31:0] current_dst_addr_val_reg42;
	reg [31:0] current_len_val_reg43;
	reg [31:0] current_burst_cnt_reg43;
	reg [31:0] current_rem_reg43;
	reg [31:0] current_src_addr_reg43;
	reg [31:0] current_dst_addr_val_reg43;
	reg [31:0] current_len_val_reg44;
	reg [31:0] current_burst_cnt_reg44;
	reg [31:0] current_rem_reg44;
	reg [31:0] current_src_addr_reg44;
	reg [31:0] current_dst_addr_val_reg44;
	reg [31:0] current_len_val_reg45;
	reg [31:0] current_burst_cnt_reg45;
	reg [31:0] current_rem_reg45;
	reg [31:0] current_src_addr_reg45;
	reg [31:0] current_dst_addr_val_reg45;
	reg [31:0] current_len_val_reg46;
	reg [31:0] current_burst_cnt_reg46;
	reg [31:0] current_rem_reg46;
	reg [31:0] current_src_addr_reg46;
	reg [31:0] current_dst_addr_val_reg46;
	reg [31:0] current_len_val_reg47;
	reg [31:0] current_burst_cnt_reg47;
	reg [31:0] current_rem_reg47;
	reg [31:0] current_src_addr_reg47;
	reg [31:0] current_dst_addr_val_reg47;
	reg [31:0] current_len_val_reg48;
	reg [31:0] current_burst_cnt_reg48;
	reg [31:0] current_rem_reg48;
	reg [31:0] current_src_addr_reg48;
	reg [31:0] current_dst_addr_val_reg48;
	reg [31:0] current_len_val_reg49;
	reg [31:0] current_burst_cnt_reg49;
	reg [31:0] current_rem_reg49;
	reg [31:0] current_src_addr_reg49;
	reg [31:0] current_dst_addr_val_reg49;
	reg [31:0] current_len_val_reg50;
	reg [31:0] current_burst_cnt_reg50;
	reg [31:0] current_rem_reg50;
	reg [31:0] current_src_addr_reg50;
	reg [31:0] current_dst_addr_val_reg50;
	reg [31:0] current_len_val_reg51;
	reg [31:0] current_burst_cnt_reg51;
	reg [31:0] current_rem_reg51;
	reg [31:0] current_src_addr_reg51;
	reg [31:0] current_dst_addr_val_reg51;
	reg [31:0] current_len_val_reg52;
	reg [31:0] current_burst_cnt_reg52;
	reg [31:0] current_rem_reg52;
	reg [31:0] current_src_addr_reg52;
	reg [31:0] current_dst_addr_val_reg52;
	reg [31:0] current_len_val_reg53;
	reg [31:0] current_burst_cnt_reg53;
	reg [31:0] current_rem_reg53;
	reg [31:0] current_src_addr_reg53;
	reg [31:0] current_dst_addr_val_reg53;
	reg [31:0] current_len_val_reg54;
	reg [31:0] current_burst_cnt_reg54;
	reg [31:0] current_rem_reg54;
	reg [31:0] current_src_addr_reg54;
	reg [31:0] current_dst_addr_val_reg54;
	reg [31:0] current_len_val_reg55;
	reg [31:0] current_burst_cnt_reg55;
	reg [31:0] current_rem_reg55;
	reg [31:0] current_src_addr_reg55;
	reg [31:0] current_dst_addr_val_reg55;
	reg [31:0] current_len_val_reg56;
	reg [31:0] current_burst_cnt_reg56;
	reg [31:0] current_rem_reg56;
	reg [31:0] current_src_addr_reg56;
	reg [31:0] current_dst_addr_val_reg56;
	reg [31:0] current_len_val_reg57;
	reg [31:0] current_burst_cnt_reg57;
	reg [31:0] current_rem_reg57;
	reg [31:0] current_src_addr_reg57;
	reg [31:0] current_dst_addr_val_reg57;
	reg [31:0] current_len_val_reg58;
	reg [31:0] current_burst_cnt_reg58;
	reg [31:0] current_rem_reg58;
	reg [31:0] current_src_addr_reg58;
	reg [31:0] current_dst_addr_val_reg58;
	reg [31:0] current_len_val_reg59;
	reg [31:0] current_burst_cnt_reg59;
	reg [31:0] current_rem_reg59;
	reg [31:0] current_src_addr_reg59;
	reg [31:0] current_dst_addr_val_reg59;
	reg [31:0] current_len_val_reg60;
	reg [31:0] current_burst_cnt_reg60;
	reg [31:0] current_rem_reg60;
	reg [31:0] current_src_addr_reg60;
	reg [31:0] current_dst_addr_val_reg60;
	reg [31:0] current_len_val_reg61;
	reg [31:0] current_burst_cnt_reg61;
	reg [31:0] current_rem_reg61;
	reg [31:0] current_src_addr_reg61;
	reg [31:0] current_dst_addr_val_reg61;
	reg [31:0] current_len_val_reg62;
	reg [31:0] current_burst_cnt_reg62;
	reg [31:0] current_rem_reg62;
	reg [31:0] current_src_addr_reg62;
	reg [31:0] current_dst_addr_val_reg62;
	reg [31:0] current_len_val_reg63;
	reg [31:0] current_burst_cnt_reg63;
	reg [31:0] current_rem_reg63;
	reg [31:0] current_src_addr_reg63;
	reg [31:0] current_dst_addr_val_reg63;
	reg [31:0] current_len_val_reg64;
	reg [31:0] current_burst_cnt_reg64;
	reg [31:0] current_rem_reg64;
	reg [31:0] current_src_addr_reg64;
	reg [31:0] current_dst_addr_val_reg64;
	reg [31:0] current_len_val_reg65;
	reg [31:0] current_burst_cnt_reg65;
	reg [31:0] current_rem_reg65;
	reg [31:0] current_src_addr_reg65;
	reg [31:0] current_dst_addr_val_reg65;
	reg [31:0] current_len_val_reg66;
	reg [31:0] current_burst_cnt_reg66;
	reg [31:0] current_rem_reg66;
	reg [31:0] current_src_addr_reg66;
	reg [31:0] current_dst_addr_val_reg66;
	reg [31:0] current_len_val_reg67;
	reg [31:0] current_burst_cnt_reg67;
	reg [31:0] current_rem_reg67;
	reg [31:0] current_src_addr_reg67;
	reg [31:0] current_dst_addr_val_reg67;
	reg [31:0] current_len_val_reg68;
	reg [31:0] current_burst_cnt_reg68;
	reg [31:0] current_rem_reg68;
	reg [31:0] current_src_addr_reg68;
	reg [31:0] current_dst_addr_val_reg68;
	reg [31:0] current_len_val_reg69;
	reg [31:0] current_burst_cnt_reg69;
	reg [31:0] current_rem_reg69;
	reg [31:0] current_src_addr_reg69;
	reg [31:0] current_dst_addr_val_reg69;
	reg [31:0] current_len_val_reg70;
	reg [31:0] current_burst_cnt_reg70;
	reg [31:0] current_rem_reg70;
	reg [31:0] current_src_addr_reg70;
	reg [31:0] current_dst_addr_val_reg70;
	reg [31:0] current_len_val_reg71;
	reg [31:0] current_burst_cnt_reg71;
	reg [31:0] current_rem_reg71;
	reg [31:0] current_src_addr_reg71;
	reg [31:0] current_dst_addr_val_reg71;
	reg [31:0] current_len_val_reg72;
	reg [31:0] current_burst_cnt_reg72;
	reg [31:0] current_rem_reg72;
	reg [31:0] current_src_addr_reg72;
	reg [31:0] current_dst_addr_val_reg72;
	reg [31:0] current_len_val_reg73;
	reg [31:0] current_burst_cnt_reg73;
	reg [31:0] current_rem_reg73;
	reg [31:0] current_src_addr_reg73;
	reg [31:0] current_dst_addr_val_reg73;
	reg [31:0] current_len_val_reg74;
	reg [31:0] current_burst_cnt_reg74;
	reg [31:0] current_rem_reg74;
	reg [31:0] current_src_addr_reg74;
	reg [31:0] current_dst_addr_val_reg74;
	reg [31:0] current_len_val_reg75;
	reg [31:0] current_burst_cnt_reg75;
	reg [31:0] current_rem_reg75;
	reg [31:0] current_src_addr_reg75;
	reg [31:0] current_dst_addr_val_reg75;
	reg [31:0] current_len_val_reg76;
	reg [31:0] current_burst_cnt_reg76;
	reg [31:0] current_rem_reg76;
	reg [31:0] current_src_addr_reg76;
	reg [31:0] current_dst_addr_val_reg76;
	reg [31:0] current_len_val_reg77;
	reg [31:0] current_burst_cnt_reg77;
	reg [31:0] current_rem_reg77;
	reg [31:0] current_src_addr_reg77;
	reg [31:0] current_dst_addr_val_reg77;
	reg [31:0] current_len_val_reg78;
	reg [31:0] current_burst_cnt_reg78;
	reg [31:0] current_rem_reg78;
	reg [31:0] current_src_addr_reg78;
	reg [31:0] current_dst_addr_val_reg78;
	reg [31:0] current_len_val_reg79;
	reg [31:0] current_burst_cnt_reg79;
	reg [31:0] current_rem_reg79;
	reg [31:0] current_src_addr_reg79;
	reg [31:0] current_dst_addr_val_reg79;
	reg [31:0] current_len_val_reg80;
	reg [31:0] current_burst_cnt_reg80;
	reg [31:0] current_rem_reg80;
	reg [31:0] current_src_addr_reg80;
	reg [31:0] current_dst_addr_val_reg80;
	reg [31:0] current_len_val_reg81;
	reg [31:0] current_burst_cnt_reg81;
	reg [31:0] current_rem_reg81;
	reg [31:0] current_src_addr_reg81;
	reg [31:0] current_dst_addr_val_reg81;
	reg [31:0] current_len_val_reg82;
	reg [31:0] current_burst_cnt_reg82;
	reg [31:0] current_rem_reg82;
	reg [31:0] current_src_addr_reg82;
	reg [31:0] current_dst_addr_val_reg82;
	reg [31:0] current_len_val_reg83;
	reg [31:0] current_burst_cnt_reg83;
	reg [31:0] current_rem_reg83;
	reg [31:0] current_src_addr_reg83;
	reg [31:0] current_dst_addr_val_reg83;
	reg [31:0] current_len_val_reg84;
	reg [31:0] current_burst_cnt_reg84;
	reg [31:0] current_rem_reg84;
	reg [31:0] current_src_addr_reg84;
	reg [31:0] current_dst_addr_val_reg84;
	reg [31:0] current_len_val_reg85;
	reg [31:0] current_burst_cnt_reg85;
	reg [31:0] current_rem_reg85;
	reg [31:0] current_src_addr_reg85;
	reg [31:0] current_dst_addr_val_reg85;
	reg [31:0] current_len_val_reg86;
	reg [31:0] current_burst_cnt_reg86;
	reg [31:0] current_rem_reg86;
	reg [31:0] current_src_addr_reg86;
	reg [31:0] current_dst_addr_val_reg86;
	reg [31:0] current_len_val_reg87;
	reg [31:0] current_burst_cnt_reg87;
	reg [31:0] current_rem_reg87;
	reg [31:0] current_src_addr_reg87;
	reg [31:0] current_dst_addr_val_reg87;
	reg [31:0] current_len_val_reg88;
	reg [31:0] current_burst_cnt_reg88;
	reg [31:0] current_rem_reg88;
	reg [31:0] current_src_addr_reg88;
	reg [31:0] current_dst_addr_val_reg88;
	reg [31:0] current_len_val_reg89;
	reg [31:0] current_burst_cnt_reg89;
	reg [31:0] current_rem_reg89;
	reg [31:0] current_src_addr_reg89;
	reg [31:0] current_dst_addr_val_reg89;
	reg [31:0] current_len_val_reg90;

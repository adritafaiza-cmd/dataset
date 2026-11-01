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

	// Local parameters
	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer AW_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Reset synchronization for M_AXI domain
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	wire m_reset_sync_rise;
	wire m_reset_sync_fall;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign m_reset_sync_rise = (m_reset_sync == 2'b10);
	assign m_reset_sync_fall = (m_reset_sync == 2'b01);
	assign M_AXI_ARESETN = m_reset_sync[1];

	// AW channel: S to M
	reg [AW_FIFO_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync2;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync3;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync4;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync5;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync6;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync7;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync8;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync9;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync10;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync11;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync12;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync13;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync14;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync15;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync16;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync17;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync18;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync19;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync20;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync21;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync22;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync23;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync24;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync25;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync26;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync27;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync28;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync29;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync30;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync31;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync32;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync33;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync34;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync35;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync36;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync37;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync38;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync39;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync40;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync41;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync42;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync43;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync44;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync45;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync46;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync47;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync48;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync49;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync50;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync51;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync52;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync53;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync54;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync55;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync56;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync57;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync58;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync59;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync60;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync61;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync62;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync63;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync64;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync65;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync66;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync67;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync68;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync69;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync70;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync71;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync72;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync73;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync74;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync75;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync76;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync77;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync78;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync79;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync80;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync81;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync82;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync83;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync84;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync85;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync86;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync87;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync88;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync89;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync90;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync91;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync92;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync93;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync94;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync95;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync96;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync97;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync98;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync99;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync100;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync101;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync102;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync103;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync104;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync105;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync106;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync107;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync108;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync109;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync110;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync111;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync112;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync113;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync114;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync115;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync116;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync117;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync118;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync119;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync120;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync121;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync122;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync123;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync124;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync125;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync126;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync127;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync128;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync129;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync130;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync131;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync132;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync133;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync134;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync135;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync136;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync137;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync138;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync139;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync140;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync141;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync142;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync143;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync144;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync145;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync146;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync147;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync148;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync149;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync150;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync151;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync152;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync153;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync154;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync155;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync156;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync157;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync158;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync159;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync160;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync161;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync162;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync163;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync164;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync165;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync166;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync167;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync168;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync169;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync170;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync171;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync172;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync173;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync174;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync175;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync176;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync177;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync178;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync179;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync180;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync181;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync182;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync183;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync184;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync185;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync186;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync187;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync188;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync189;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync190;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync191;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync192;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync193;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync194;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync195;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync196;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync197;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync198;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync199;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync200;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync201;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync202;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync203;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync204;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync205;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync206;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync207;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync208;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync209;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync210;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync211;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync212;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync213;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync214;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync215;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync216;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync217;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync218;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync219;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync220;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync221;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync222;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync223;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync224;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync225;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync226;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync227;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync228;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync229;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync230;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync231;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync232;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync233;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync234;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync235;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync236;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync237;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync238;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync239;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync240;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync241;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync242;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync243;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync244;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync245;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync246;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync247;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync248;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync249;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync250;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync251;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync252;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync253;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync254;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync255;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync256;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync257;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync258;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync259;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync260;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync261;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync262;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync263;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync264;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync265;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync266;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync267;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync268;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync269;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync270;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync271;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync272;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync273;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync274;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync275;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync276;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync277;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync278;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync279;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync280;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync281;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync282;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync283;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync284;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync285;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync286;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync287;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync288;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync289;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync290;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync291;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync292;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync293;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync294;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync295;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync296;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync297;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync298;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync299;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync300;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync301;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync302;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync303;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync304;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync305;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync306;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync307;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync308;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync309;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync310;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync311;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync312;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync313;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync314;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync315;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync316;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync317;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync318;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync319;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync320;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync321;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync322;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync323;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync324;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync325;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync326;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync327;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync328;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync329;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync330;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync331;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync332;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync333;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync334;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m_sync335;
	reg [FIFO
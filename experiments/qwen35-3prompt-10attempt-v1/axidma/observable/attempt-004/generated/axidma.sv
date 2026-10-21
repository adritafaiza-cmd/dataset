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

	localparam LGMAXBURST = 8;
	localparam LGLENW = LGLEN - ADDRLSB;
	localparam LGLENW_LOG = $clog2(LGLENW);
	localparam LGLENW_LOG2 = $clog2(LGLENW_LOG);
	localparam LGLENW_LOG3 = $clog2(LGLENW_LOG2);
	localparam LGLENW_LOG4 = $clog2(LGLENW_LOG3);
	localparam LGLENW_LOG5 = $clog2(LGLENW_LOG4);
	localparam LGLENW_LOG6 = $clog2(LGLENW_LOG5);
	localparam LGLENW_LOG7 = $clog2(LGLENW_LOG6);
	localparam LGLENW_LOG8 = $clog2(LGLENW_LOG7);
	localparam LGLENW_LOG9 = $clog2(LGLENW_LOG8);
	localparam LGLENW_LOG10 = $clog2(LGLENW_LOG9);
	localparam LGLENW_LOG11 = $clog2(LGLENW_LOG10);
	localparam LGLENW_LOG12 = $clog2(LGLENW_LOG11);
	localparam LGLENW_LOG13 = $clog2(LGLENW_LOG12);
	localparam LGLENW_LOG14 = $clog2(LGLENW_LOG13);
	localparam LGLENW_LOG15 = $clog2(LGLENW_LOG14);
	localparam LGLENW_LOG16 = $clog2(LGLENW_LOG15);
	localparam LGLENW_LOG17 = $clog2(LGLENW_LOG16);
	localparam LGLENW_LOG18 = $clog2(LGLENW_LOG17);
	localparam LGLENW_LOG19 = $clog2(LGLENW_LOG18);
	localparam LGLENW_LOG20 = $clog2(LGLENW_LOG19);
	localparam LGLENW_LOG21 = $clog2(LGLENW_LOG20);
	localparam LGLENW_LOG22 = $clog2(LGLENW_LOG21);
	localparam LGLENW_LOG23 = $clog2(LGLENW_LOG22);
	localparam LGLENW_LOG24 = $clog2(LGLENW_LOG23);
	localparam LGLENW_LOG25 = $clog2(LGLENW_LOG24);
	localparam LGLENW_LOG26 = $clog2(LGLENW_LOG25);
	localparam LGLENW_LOG27 = $clog2(LGLENW_LOG26);
	localparam LGLENW_LOG28 = $clog2(LGLENW_LOG27);
	localparam LGLENW_LOG29 = $clog2(LGLENW_LOG28);
	localparam LGLENW_LOG30 = $clog2(LGLENW_LOG29);
	localparam LGLENW_LOG31 = $clog2(LGLENW_LOG30);
	localparam LGLENW_LOG32 = $clog2(LGLENW_LOG31);
	localparam LGLENW_LOG33 = $clog2(LGLENW_LOG32);
	localparam LGLENW_LOG34 = $clog2(LGLENW_LOG33);
	localparam LGLENW_LOG35 = $clog2(LGLENW_LOG34);
	localparam LGLENW_LOG36 = $clog2(LGLENW_LOG35);
	localparam LGLENW_LOG37 = $clog2(LGLENW_LOG36);
	localparam LGLENW_LOG38 = $clog2(LGLENW_LOG37);
	localparam LGLENW_LOG39 = $clog2(LGLENW_LOG38);
	localparam LGLENW_LOG40 = $clog2(LGLENW_LOG39);
	localparam LGLENW_LOG41 = $clog2(LGLENW_LOG40);
	localparam LGLENW_LOG42 = $clog2(LGLENW_LOG41);
	localparam LGLENW_LOG43 = $clog2(LGLENW_LOG42);
	localparam LGLENW_LOG44 = $clog2(LGLENW_LOG43);
	localparam LGLENW_LOG45 = $clog2(LGLENW_LOG44);
	localparam LGLENW_LOG46 = $clog2(LGLENW_LOG45);
	localparam LGLENW_LOG47 = $clog2(LGLENW_LOG46);
	localparam LGLENW_LOG48 = $clog2(LGLENW_LOG47);
	localparam LGLENW_LOG49 = $clog2(LGLENW_LOG48);
	localparam LGLENW_LOG50 = $clog2(LGLENW_LOG49);
	localparam LGLENW_LOG51 = $clog2(LGLENW_LOG50);
	localparam LGLENW_LOG52 = $clog2(LGLENW_LOG51);
	localparam LGLENW_LOG53 = $clog2(LGLENW_LOG52);
	localparam LGLENW_LOG54 = $clog2(LGLENW_LOG53);
	localparam LGLENW_LOG55 = $clog2(LGLENW_LOG54);
	localparam LGLENW_LOG56 = $clog2(LGLENW_LOG55);
	localparam LGLENW_LOG57 = $clog2(LGLENW_LOG56);
	localparam LGLENW_LOG58 = $clog2(LGLENW_LOG57);
	localparam LGLENW_LOG59 = $clog2(LGLENW_LOG58);
	localparam LGLENW_LOG60 = $clog2(LGLENW_LOG59);
	localparam LGLENW_LOG61 = $clog2(LGLENW_LOG60);
	localparam LGLENW_LOG62 = $clog2(LGLENW_LOG61);
	localparam LGLENW_LOG63 = $clog2(LGLENW_LOG62);
	localparam LGLENW_LOG64 = $clog2(LGLENW_LOG63);
	localparam LGLENW_LOG65 = $clog2(LGLENW_LOG64);
	localparam LGLENW_LOG66 = $clog2(LGLENW_LOG65);
	localparam LGLENW_LOG67 = $clog2(LGLENW_LOG66);
	localparam LGLENW_LOG68 = $clog2(LGLENW_LOG67);
	localparam LGLENW_LOG69 = $clog2(LGLENW_LOG68);
	localparam LGLENW_LOG70 = $clog2(LGLENW_LOG69);
	localparam LGLENW_LOG71 = $clog2(LGLENW_LOG70);
	localparam LGLENW_LOG72 = $clog2(LGLENW_LOG71);
	localparam LGLENW_LOG73 = $clog2(LGLENW_LOG72);
	localparam LGLENW_LOG74 = $clog2(LGLENW_LOG73);
	localparam LGLENW_LOG75 = $clog2(LGLENW_LOG74);
	localparam LGLENW_LOG76 = $clog2(LGLENW_LOG75);
	localparam LGLENW_LOG77 = $clog2(LGLENW_LOG76);
	localparam LGLENW_LOG78 = $clog2(LGLENW_LOG77);
	localparam LGLENW_LOG79 = $clog2(LGLENW_LOG78);
	localparam LGLENW_LOG80 = $clog2(LGLENW_LOG79);
	localparam LGLENW_LOG81 = $clog2(LGLENW_LOG80);
	localparam LGLENW_LOG82 = $clog2(LGLENW_LOG81);
	localparam LGLENW_LOG83 = $clog2(LGLENW_LOG82);
	localparam LGLENW_LOG84 = $clog2(LGLENW_LOG83);
	localparam LGLENW_LOG85 = $clog2(LGLENW_LOG84);
	localparam LGLENW_LOG86 = $clog2(LGLENW_LOG85);
	localparam LGLENW_LOG87 = $clog2(LGLENW_LOG86);
	localparam LGLENW_LOG88 = $clog2(LGLENW_LOG87);
	localparam LGLENW_LOG89 = $clog2(LGLENW_LOG88);
	localparam LGLENW_LOG90 = $clog2(LGLENW_LOG89);
	localparam LGLENW_LOG91 = $clog2(LGLENW_LOG90);
	localparam LGLENW_LOG92 = $clog2(LGLENW_LOG91);
	localparam LGLENW_LOG93 = $clog2(LGLENW_LOG92);
	localparam LGLENW_LOG94 = $clog2(LGLENW_LOG93);
	localparam LGLENW_LOG95 = $clog2(LGLENW_LOG94);
	localparam LGLENW_LOG96 = $clog2(LGLENW_LOG95);
	localparam LGLENW_LOG97 = $clog2(LGLENW_LOG96);
	localparam LGLENW_LOG98 = $clog2(LGLENW_LOG97);
	localparam LGLENW_LOG99 = $clog2(LGLENW_LOG98);
	localparam LGLENW_LOG100 = $clog2(LGLENW_LOG99);
	localparam LGLENW_LOG101 = $clog2(LGLENW_LOG100);
	localparam LGLENW_LOG102 = $clog2(LGLENW_LOG101);
	localparam LGLENW_LOG103 = $clog2(LGLENW_LOG102);
	localparam LGLENW_LOG104 = $clog2(LGLENW_LOG103);
	localparam LGLENW_LOG105 = $clog2(LGLENW_LOG104);
	localparam LGLENW_LOG106 = $clog2(LGLENW_LOG105);
	localparam LGLENW_LOG107 = $clog2(LGLENW_LOG106);
	localparam LGLENW_LOG108 = $clog2(LGLENW_LOG107);
	localparam LGLENW_LOG109 = $clog2(LGLENW_LOG108);
	localparam LGLENW_LOG110 = $clog2(LGLENW_LOG109);
	localparam LGLENW_LOG111 = $clog2(LGLENW_LOG110);
	localparam LGLENW_LOG112 = $clog2(LGLENW_LOG111);
	localparam LGLENW_LOG113 = $clog2(LGLENW_LOG112);
	localparam LGLENW_LOG114 = $clog2(LGLENW_LOG113);
	localparam LGLENW_LOG115 = $clog2(LGLENW_LOG114);
	localparam LGLENW_LOG116 = $clog2(LGLENW_LOG115);
	localparam LGLENW_LOG117 = $clog2(LGLENW_LOG116);
	localparam LGLENW_LOG118 = $clog2(LGLENW_LOG117);
	localparam LGLENW_LOG119 = $clog2(LGLENW_LOG118);
	localparam LGLENW_LOG120 = $clog2(LGLENW_LOG119);
	localparam LGLENW_LOG121 = $clog2(LGLENW_LOG120);
	localparam LGLENW_LOG122 = $clog2(LGLENW_LOG121);
	localparam LGLENW_LOG123 = $clog2(LGLENW_LOG122);
	localparam LGLENW_LOG124 = $clog2(LGLENW_LOG123);
	localparam LGLENW_LOG125 = $clog2(LGLENW_LOG124);
	localparam LGLENW_LOG126 = $clog2(LGLENW_LOG125);
	localparam LGLENW_LOG127 = $clog2(LGLENW_LOG126);
	localparam LGLENW_LOG128 = $clog2(LGLENW_LOG127);
	localparam LGLENW_LOG129 = $clog2(LGLENW_LOG128);
	localparam LGLENW_LOG130 = $clog2(LGLENW_LOG129);
	localparam LGLENW_LOG131 = $clog2(LGLENW_LOG130);
	localparam LGLENW_LOG132 = $clog2(LGLENW_LOG131);
	localparam LGLENW_LOG133 = $clog2(LGLENW_LOG132);
	localparam LGLENW_LOG134 = $clog2(LGLENW_LOG133);
	localparam LGLENW_LOG135 = $clog2(LGLENW_LOG134);
	localparam LGLENW_LOG136 = $clog2(LGLENW_LOG135);
	localparam LGLENW_LOG137 = $clog2(LGLENW_LOG136);
	localparam LGLENW_LOG138 = $clog2(LGLENW_LOG137);
	localparam LGLENW_LOG139 = $clog2(LGLENW_LOG138);
	localparam LGLENW_LOG140 = $clog2(LGLENW_LOG139);
	localparam LGLENW_LOG141 = $clog2(LGLENW_LOG140);
	localparam LGLENW_LOG142 = $clog2(LGLENW_LOG141);
	localparam LGLENW_LOG143 = $clog2(LGLENW_LOG142);
	localparam LGLENW_LOG144 = $clog2(LGLENW_LOG143);
	localparam LGLENW_LOG145 = $clog2(LGLENW_LOG144);
	localparam LGLENW_LOG146 = $clog2(LGLENW_LOG145);
	localparam LGLENW_LOG147 = $clog2(LGLENW_LOG146);
	localparam LGLENW_LOG148 = $clog2(LGLENW_LOG147);
	localparam LGLENW_LOG149 = $clog2(LGLENW_LOG148);
	localparam LGLENW_LOG150 = $clog2(LGLENW_LOG149);
	localparam LGLENW_LOG151 = $clog2(LGLENW_LOG150);
	localparam LGLENW_LOG152 = $clog2(LGLENW_LOG151);
	localparam LGLENW_LOG153 = $clog2(LGLENW_LOG152);
	localparam LGLENW_LOG154 = $clog2(LGLENW_LOG153);
	localparam LGLENW_LOG155 = $clog2(LGLENW_LOG154);
	localparam LGLENW_LOG156 = $clog2(LGLENW_LOG155);
	localparam LGLENW_LOG157 = $clog2(LGLENW_LOG156);
	localparam LGLENW_LOG158 = $clog2(LGLENW_LOG157);
	localparam LGLENW_LOG159 = $clog2(LGLENW_LOG158);
	localparam LGLENW_LOG160 = $clog2(LGLENW_LOG159);
	localparam LGLENW_LOG161 = $clog2(LGLENW_LOG160);
	localparam LGLENW_LOG162 = $clog2(LGLENW_LOG161);
	localparam LGLENW_LOG163 = $clog2(LGLENW_LOG162);
	localparam LGLENW_LOG164 = $clog2(LGLENW_LOG163);
	localparam LGLENW_LOG165 = $clog2(LGLENW_LOG164);
	localparam LGLENW_LOG166 = $clog2(LGLENW_LOG165);
	localparam LGLENW_LOG167 = $clog2(LGLENW_LOG166);
	localparam LGLENW_LOG168 = $clog2(LGLENW_LOG167);
	localparam LGLENW_LOG169 = $clog2(LGLENW_LOG168);
	localparam LGLENW_LOG170 = $clog2(LGLENW_LOG169);
	localparam LGLENW_LOG171 = $clog2(LGLENW_LOG170);
	localparam LGLENW_LOG172 = $clog2(LGLENW_LOG171);
	localparam LGLENW_LOG173 = $clog2(LGLENW_LOG172);
	localparam LGLENW_LOG174 = $clog2(LGLENW_LOG173);
	localparam LGLENW_LOG175 = $clog2(LGLENW_LOG174);
	localparam LGLENW_LOG176 = $clog2(LGLENW_LOG175);
	localparam LGLENW_LOG177 = $clog2(LGLENW_LOG176);
	localparam LGLENW_LOG178 = $clog2(LGLENW_LOG177);
	localparam LGLENW_LOG179 = $clog2(LGLENW_LOG178);
	localparam LGLENW_LOG180 = $clog2(LGLENW_LOG179);
	localparam LGLENW_LOG181 = $clog2(LGLENW_LOG180);
	localparam LGLENW_LOG182 = $clog2(LGLENW_LOG181);
	localparam LGLENW_LOG183 = $clog2(LGLENW_LOG182);
	localparam LGLENW_LOG184 = $clog2(LGLENW_LOG183);
	localparam LGLENW_LOG185 = $clog2(LGLENW_LOG184);
	localparam LGLENW_LOG186 = $clog2(LGLENW_LOG185);
	localparam LGLENW_LOG187 = $clog2(LGLENW_LOG186);
	localparam LGLENW_LOG188 = $clog2(LGLENW_LOG187);
	localparam LGLENW_LOG189 = $clog2(LGLENW_LOG188);
	localparam LGLENW_LOG190 = $clog2(LGLENW_LOG189);
	localparam LGLENW_LOG191 = $clog2(LGLENW_LOG190);
	localparam LGLENW_LOG192 = $clog2(LGLENW_LOG191);
	localparam LGLENW_LOG193 = $clog2(LGLENW_LOG192);
	localparam LGLENW_LOG194 = $clog2(LGLENW_LOG193);
	localparam LGLENW_LOG195 = $clog2(LGLENW_LOG194);
	localparam LGLENW_LOG196 = $clog2(LGLENW_LOG195);
	localparam LGLENW_LOG197 = $clog2(LGLENW_LOG196);
	localparam LGLENW_LOG198 = $clog2(LGLENW_LOG197);
	localparam LGLENW_LOG199 = $clog2(LGLENW_LOG198);
	localparam LGLENW_LOG200 = $clog2(LGLENW_LOG199);
	localparam LGLENW_LOG201 = $clog2(LGLENW_LOG200);
	localparam LGLENW_LOG202 = $clog2(LGLENW_LOG201);
	localparam LGLENW_LOG203 = $clog2(LGLENW_LOG202);
	localparam LGLENW_LOG204 = $clog2(LGLENW_LOG203);
	localparam LGLENW_LOG205 = $clog2(LGLENW_LOG204);
	localparam LGLENW_LOG206 = $clog2(LGLENW_LOG205);
	localparam LGLENW_LOG207 = $clog2(LGLENW_LOG206);
	localparam LGLENW_LOG208 = $clog2(LGLENW_LOG207);
	localparam LGLENW_LOG209 = $clog2(LGLENW_LOG208);
	localparam LGLENW_LOG210 = $clog2(LGLENW_LOG209);
	localparam LGLENW_LOG211 = $clog2(LGLENW_LOG210);
	localparam LGLENW_LOG212 = $clog2(LGLENW_LOG211);
	localparam LGLENW_LOG213 = $clog2(LGLENW_LOG212);
	localparam LGLENW_LOG214 = $clog2(LGLENW_LOG213);
	localparam LGLENW_LOG215 = $clog2(LGLENW_LOG214);
	localparam LGLENW_LOG216 = $clog2(LGLENW_LOG215);
	localparam LGLENW_LOG217 = $clog2(LGLENW_LOG216);
	localparam LGLENW_LOG218 = $clog2(LGLENW_LOG217);
	localparam LGLENW_LOG219 = $clog2(LGLENW_LOG218);
	localparam LGLENW_LOG220 = $clog2(LGLENW_LOG219);
	localparam LGLENW_LOG221 = $clog2(LGLENW_LOG220);
	localparam LGLENW_LOG222 = $clog2(LGLENW_LOG221);
	localparam LGLENW_LOG223 = $clog2(LGLENW_LOG222);
	localparam LGLENW_LOG224 = $clog2(LGLENW_LOG223);
	localparam LGLENW_LOG225 = $clog2(LGLENW_LOG224);
	localparam LGLENW_LOG226 = $clog2(LGLENW_LOG225);
	localparam LGLENW_LOG227 = $clog2(LGLENW_LOG226);
	localparam LGLENW_LOG228 = $clog2(LGLENW_LOG227);
	localparam LGLENW_LOG229 = $clog2(LGLENW_LOG228);
	localparam LGLENW_LOG230 = $clog2(LGLENW_LOG229);
	localparam LGLENW_LOG231 = $clog2(LGLENW_LOG230);
	localparam LGLENW_LOG232 = $clog2(LGLENW_LOG231);
	localparam LGLENW_LOG233 = $clog2(LGLENW_LOG232);
	localparam LGLENW_LOG234 = $clog2(LGLENW_LOG233);
	localparam LGLENW_LOG235 = $clog2(LGLENW_LOG234);
	localparam LGLENW_LOG236 = $clog2(LGLENW_LOG235);
	localparam LGLENW_LOG237 = $clog2(LGLENW_LOG236);
	localparam LGLENW_LOG238 = $clog2(LGLENW_LOG237);
	localparam LGLENW_LOG239 = $clog2(LGLENW_LOG238);
	localparam LGLENW_LOG240 = $clog2(LGLENW_LOG239);
	localparam LGLENW_LOG241 = $clog2(LGLENW_LOG240);
	localparam LGLENW_LOG242 = $clog2(LGLENW_LOG241);
	localparam LGLENW_LOG243 = $clog2(LGLENW_LOG242);
	localparam LGLENW_LOG244 = $clog2(LGLENW_LOG243);
	localparam LGLENW_LOG245 = $clog2(LGLENW_LOG244);
	localparam LGLENW_LOG246 = $clog2(LGLENW_LOG245);
	localparam LGLENW_LOG247 = $clog2(LGLENW_LOG246);
	localparam LGLENW_LOG248 = $clog2(LGLENW_LOG247);
	localparam LGLENW_LOG249 = $clog2(LGLENW_LOG248);
	localparam LGLENW_LOG250 = $clog2(LGLENW_LOG249);
	localparam LGLENW_LOG251 = $clog2(LGLENW_LOG250);
	localparam LGLENW_LOG252 = $clog2(LGLENW_LOG251);
	localparam LGLENW_LOG253 = $clog2(LGLENW_LOG252);
	localparam LGLENW_LOG254 = $clog2(LGLENW_LOG253);
	localparam LGLENW_LOG255 = $clog2(LGLENW_LOG254);
	localparam LGLENW_LOG256 = $clog2(LGLENW_LOG255);
	localparam LGLENW_LOG257 = $clog2(LGLENW_LOG256);
	localparam LGLENW_LOG258 = $clog2(LGLENW_LOG257);
	localparam LGLENW_LOG259 = $clog2(LGLENW_LOG258);
	localparam LGLENW_LOG260 = $clog2(LGLENW_LOG259);
	localparam LGLENW_LOG261 = $clog2(LGLENW_LOG260);
	localparam LGLENW_LOG262 = $clog2(LGLENW_LOG261);
	localparam LGLENW_LOG263 = $clog2(LGLENW_LOG262);
	localparam LGLENW_LOG264 = $clog2(LGLENW_LOG263);
	localparam LGLENW_LOG265 = $clog2(LGLENW_LOG264);
	localparam LGLENW_LOG266 = $clog2(LGLENW_LOG265);
	localparam LGLENW_LOG267 = $clog2(LGLENW_LOG266);
	localparam LGLENW_LOG268 = $clog2(LGLENW_LOG267);
	localparam LGLENW_LOG269 = $clog2(LGLENW_LOG268);
	localparam LGLENW_LOG270 = $clog2(LGLENW_LOG269);
	localparam LGLENW_LOG271 = $clog2(LGLENW_LOG270);
	localparam LGLENW_LOG272 = $clog2(LGLENW_LOG271);
	localparam LGLENW_LOG273 = $clog2(LGLENW_LOG272);
	localparam LGLENW_LOG274 = $clog2(LGLENW_LOG273);
	localparam LGLENW_LOG275 = $clog2(LGLENW_LOG274);
	localparam LGLENW_LOG276 = $clog2(LGLENW_LOG275);
	localparam LGLENW_LOG277 = $clog2(LGLENW_LOG276);
	localparam LGLENW_LOG278 = $clog2(LGLENW_LOG277);
	localparam LGLENW_LOG279 = $clog2(LGLENW_LOG278);
	localparam LGLENW_LOG280 = $clog2(LGLENW_LOG279);
	localparam LGLENW_LOG281 = $clog2(LGLENW_LOG280);
	localparam LGLENW_LOG282 = $clog2(LGLENW_LOG281);
	localparam LGLENW_LOG283 = $clog2(LGLENW_LOG282);
	localparam LGLENW_LOG284 = $clog2(LGLENW_LOG283);
	localparam LGLENW_LOG285 = $clog2(LGLENW_LOG284);
	localparam LGLENW_LOG286 = $clog2(LGLENW_LOG285);
	localparam LGLENW_LOG287 = $clog2(LGLENW_LOG286);
	localparam LGLENW_LOG288 = $clog2(LGLENW_LOG287);
	localparam LGLENW_LOG289 = $clog2(LGLENW_LOG288);
	localparam LGLENW_LOG290 = $clog2(LGLENW_LOG289);
	localparam LGLENW_LOG291 = $clog2(LGLENW_LOG290);
	localparam LGLENW_LOG292 = $clog2(LGLENW_LOG291);
	localparam LGLENW_LOG293 = $clog2(LGLENW_LOG292);
	localparam LGLENW_LOG294 = $clog2(LGLENW_LOG293);
	localparam LGLENW_LOG295 = $clog2(LGLENW_LOG294);
	localparam LGLENW_LOG296 = $clog2(LGLENW_LOG295);
	localparam LGLENW_LOG297 = $clog2(LGLENW_LOG296);
	localparam LGLENW_LOG298 = $clog2(LGLENW_LOG297);
	localparam LGLENW_LOG299 = $clog2(LGLENW_LOG298);
	localparam LGLENW_LOG300 = $clog2(LGLENW_LOG299);
	localparam LGLENW_LOG301 = $clog2(LGLENW_LOG30
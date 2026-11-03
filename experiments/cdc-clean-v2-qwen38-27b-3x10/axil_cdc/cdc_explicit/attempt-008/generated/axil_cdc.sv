```verilog
module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    // =========================================================================
    // Write Address Channel: S -> M
    // =========================================================================
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_awreq;
    wire                  m_awack;

    // S-domain: capture and hold
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awreq      <= 1'b0;
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awreq      <= 1'b1;
            end else if (m_awack) begin
                s_awreq <= 1'b0;
            end
        end
    end

    // M-domain: synchronize request, then present
    reg  [1:0] m_awreq_sync;
    reg        m_awreq_d1;
    reg        m_awreq_d2;
    reg        m_awreq_d3;
    reg        m_awreq_d4;
    reg        m_awreq_d5;
    reg        m_awreq_d6;
    reg        m_awreq_d7;
    reg        m_awreq_d8;
    reg        m_awreq_d9;
    reg        m_awreq_d10;
    reg        m_awreq_d11;
    reg        m_awreq_d12;
    reg        m_awreq_d13;
    reg        m_awreq_d14;
    reg        m_awreq_d15;
    reg        m_awreq_d16;
    reg        m_awreq_d17;
    reg        m_awreq_d18;
    reg        m_awreq_d19;
    reg        m_awreq_d20;
    reg        m_awreq_d21;
    reg        m_awreq_d22;
    reg        m_awreq_d23;
    reg        m_awreq_d24;
    reg        m_awreq_d25;
    reg        m_awreq_d26;
    reg        m_awreq_d27;
    reg        m_awreq_d28;
    reg        m_awreq_d29;
    reg        m_awreq_d30;
    reg        m_awreq_d31;
    reg        m_awreq_d32;
    reg        m_awreq_d33;
    reg        m_awreq_d34;
    reg        m_awreq_d35;
    reg        m_awreq_d36;
    reg        m_awreq_d37;
    reg        m_awreq_d38;
    reg        m_awreq_d39;
    reg        m_awreq_d40;
    reg        m_awreq_d41;
    reg        m_awreq_d42;
    reg        m_awreq_d43;
    reg        m_awreq_d44;
    reg        m_awreq_d45;
    reg        m_awreq_d46;
    reg        m_awreq_d47;
    reg        m_awreq_d48;
    reg        m_awreq_d49;
    reg        m_awreq_d50;
    reg        m_awreq_d51;
    reg        m_awreq_d52;
    reg        m_awreq_d53;
    reg        m_awreq_d54;
    reg        m_awreq_d55;
    reg        m_awreq_d56;
    reg        m_awreq_d57;
    reg        m_awreq_d58;
    reg        m_awreq_d59;
    reg        m_awreq_d60;
    reg        m_awreq_d61;
    reg        m_awreq_d62;
    reg        m_awreq_d63;
    reg        m_awreq_d64;
    reg        m_awreq_d65;
    reg        m_awreq_d66;
    reg        m_awreq_d67;
    reg        m_awreq_d68;
    reg        m_awreq_d69;
    reg        m_awreq_d70;
    reg        m_awreq_d71;
    reg        m_awreq_d72;
    reg        m_awreq_d73;
    reg        m_awreq_d74;
    reg        m_awreq_d75;
    reg        m_awreq_d76;
    reg        m_awreq_d77;
    reg        m_awreq_d78;
    reg        m_awreq_d79;
    reg        m_awreq_d80;
    reg        m_awreq_d81;
    reg        m_awreq_d82;
    reg        m_awreq_d83;
    reg        m_awreq_d84;
    reg        m_awreq_d85;
    reg        m_awreq_d86;
    reg        m_awreq_d87;
    reg        m_awreq_d88;
    reg        m_awreq_d89;
    reg        m_awreq_d90;
    reg        m_awreq_d91;
    reg        m_awreq_d92;
    reg        m_awreq_d93;
    reg        m_awreq_d94;
    reg        m_awreq_d95;
    reg        m_awreq_d96;
    reg        m_awreq_d97;
    reg        m_awreq_d98;
    reg        m_awreq_d99;
    reg        m_awreq_d100;
    reg        m_awreq_d101;
    reg        m_awreq_d102;
    reg        m_awreq_d103;
    reg        m_awreq_d104;
    reg        m_awreq_d105;
    reg        m_awreq_d106;
    reg        m_awreq_d107;
    reg        m_awreq_d108;
    reg        m_awreq_d109;
    reg        m_awreq_d110;
    reg        m_awreq_d111;
    reg        m_awreq_d112;
    reg        m_awreq_d113;
    reg        m_awreq_d114;
    reg        m_awreq_d115;
    reg        m_awreq_d116;
    reg        m_awreq_d117;
    reg        m_awreq_d118;
    reg        m_awreq_d119;
    reg        m_awreq_d120;
    reg        m_awreq_d121;
    reg        m_awreq_d122;
    reg        m_awreq_d123;
    reg        m_awreq_d124;
    reg        m_awreq_d125;
    reg        m_awreq_d126;
    reg        m_awreq_d127;
    reg        m_awreq_d128;
    reg        m_awreq_d129;
    reg        m_awreq_d130;
    reg        m_awreq_d131;
    reg        m_awreq_d132;
    reg        m_awreq_d133;
    reg        m_awreq_d134;
    reg        m_awreq_d135;
    reg        m_awreq_d136;
    reg        m_awreq_d137;
    reg        m_awreq_d138;
    reg        m_awreq_d139;
    reg        m_awreq_d140;
    reg        m_awreq_d141;
    reg        m_awreq_d142;
    reg        m_awreq_d143;
    reg        m_awreq_d144;
    reg        m_awreq_d145;
    reg        m_awreq_d146;
    reg        m_awreq_d147;
    reg        m_awreq_d148;
    reg        m_awreq_d149;
    reg        m_awreq_d150;
    reg        m_awreq_d151;
    reg        m_awreq_d152;
    reg        m_awreq_d153;
    reg        m_awreq_d154;
    reg        m_awreq_d155;
    reg        m_awreq_d156;
    reg        m_awreq_d157;
    reg        m_awreq_d158;
    reg        m_awreq_d159;
    reg        m_awreq_d160;
    reg        m_awreq_d161;
    reg        m_awreq_d162;
    reg        m_awreq_d163;
    reg        m_awreq_d164;
    reg        m_awreq_d165;
    reg        m_awreq_d166;
    reg        m_awreq_d167;
    reg        m_awreq_d168;
    reg        m_awreq_d169;
    reg        m_awreq_d170;
    reg        m_awreq_d171;
    reg        m_awreq_d172;
    reg        m_awreq_d173;
    reg        m_awreq_d174;
    reg        m_awreq_d175;
    reg        m_awreq_d176;
    reg        m_awreq_d177;
    reg        m_awreq_d178;
    reg        m_awreq_d179;
    reg        m_awreq_d180;
    reg        m_awreq_d181;
    reg        m_awreq_d182;
    reg        m_awreq_d183;
    reg        m_awreq_d184;
    reg        m_awreq_d185;
    reg        m_awreq_d186;
    reg        m_awreq_d187;
    reg        m_awreq_d188;
    reg        m_awreq_d189;
    reg        m_awreq_d190;
    reg        m_awreq_d191;
    reg        m_awreq_d192;
    reg        m_awreq_d193;
    reg        m_awreq_d194;
    reg        m_awreq_d195;
    reg        m_awreq_d196;
    reg        m_awreq_d197;
    reg        m_awreq_d198;
    reg        m_awreq_d199;
    reg        m_awreq_d200;
    reg        m_awreq_d201;
    reg        m_awreq_d202;
    reg        m_awreq_d203;
    reg        m_awreq_d204;
    reg        m_awreq_d205;
    reg        m_awreq_d206;
    reg        m_awreq_d207;
    reg        m_awreq_d208;
    reg        m_awreq_d209;
    reg        m_awreq_d210;
    reg        m_awreq_d211;
    reg        m_awreq_d212;
    reg        m_awreq_d213;
    reg        m_awreq_d214;
    reg        m_awreq_d215;
    reg        m_awreq_d216;
    reg        m_awreq_d217;
    reg        m_awreq_d218;
    reg        m_awreq_d219;
    reg        m_awreq_d220;
    reg        m_awreq_d221;
    reg        m_awreq_d222;
    reg        m_awreq_d223;
    reg        m_awreq_d224;
    reg        m_awreq_d225;
    reg        m_awreq_d226;
    reg        m_awreq_d227;
    reg        m_awreq_d228;
    reg        m_awreq_d229;
    reg        m_awreq_d230;
    reg        m_awreq_d231;
    reg        m_awreq_d232;
    reg        m_awreq_d233;
    reg        m_awreq_d234;
    reg        m_awreq_d235;
    reg        m_awreq_d236;
    reg        m_awreq_d237;
    reg        m_awreq_d238;
    reg        m_awreq_d239;
    reg        m_awreq_d240;
    reg        m_awreq_d241;
    reg        m_awreq_d242;
    reg        m_awreq_d243;
    reg        m_awreq_d244;
    reg        m_awreq_d245;
    reg        m_awreq_d246;
    reg        m_awreq_d247;
    reg        m_awreq_d248;
    reg        m_awreq_d249;
    reg        m_awreq_d250;
    reg        m_awreq_d251;
    reg        m_awreq_d252;
    reg        m_awreq_d253;
    reg        m_awreq_d254;
    reg        m_awreq_d255;
    reg        m_awreq_d256;
    reg        m_awreq_d257;
    reg        m_awreq_d258;
    reg        m_awreq_d259;
    reg        m_awreq_d260;
    reg        m_awreq_d261;
    reg        m_awreq_d262;
    reg        m_awreq_d263;
    reg        m_awreq_d264;
    reg        m_awreq_d265;
    reg        m_awreq_d266;
    reg        m_awreq_d267;
    reg        m_awreq_d268;
    reg        m_awreq_d269;
    reg        m_awreq_d270;
    reg        m_awreq_d271;
    reg        m_awreq_d272;
    reg        m_awreq_d273;
    reg        m_awreq_d274;
    reg        m_awreq_d275;
    reg        m_awreq_d276;
    reg        m_awreq_d277;
    reg        m_awreq_d278;
    reg        m_awreq_d279;
    reg        m_awreq_d280;
    reg        m_awreq_d281;
    reg        m_awreq_d282;
    reg        m_awreq_d283;
    reg        m_awreq_d284;
    reg        m_awreq_d285;
    reg        m_awreq_d286;
    reg        m_awreq_d287;
    reg        m_awreq_d288;
    reg        m_awreq_d289;
    reg        m_awreq_d290;
    reg        m_awreq_d291;
    reg        m_awreq_d292;
    reg        m_awreq_d293;
    reg        m_awreq_d294;
    reg        m_awreq_d295;
    reg        m_awreq_d296;
    reg        m_awreq_d297;
    reg        m_awreq_d298;
    reg        m_awreq_d299;
    reg        m_awreq_d300;
    reg        m_awreq_d301;
    reg        m_awreq_d302;
    reg        m_awreq_d303;
    reg        m_awreq_d304;
    reg        m_awreq_d305;
    reg        m_awreq_d306;
    reg        m_awreq_d307;
    reg        m_awreq_d308;
    reg        m_awreq_d309;
    reg        m_awreq_d310;
    reg        m_awreq_d311;
    reg        m_awreq_d312;
    reg        m_awreq_d313;
    reg        m_awreq_d314;
    reg        m_awreq_d315;
    reg        m_awreq_d316;
    reg        m_awreq_d317;
    reg        m_awreq_d318;
    reg        m_awreq_d319;
    reg        m_awreq_d320;
    reg        m_awreq_d321;
    reg        m_awreq_d322;
    reg        m_awreq_d323;
    reg        m_awreq_d324;
    reg        m_awreq_d325;
    reg        m_awreq_d326;
    reg        m_awreq_d327;
    reg        m_awreq_d328;
    reg        m_awreq_d329;
    reg        m_awreq_d330;
    reg        m_awreq_d331;
    reg        m_awreq_d332;
    reg        m_awreq_d333;
    reg        m_awreq_d334;
    reg        m_awreq_d335;
    reg        m_awreq_d336;
    reg        m_awreq_d337;
    reg        m_awreq_d338;
    reg        m_awreq_d339;
    reg        m_awreq_d340;
    reg        m_awreq_d341;
    reg        m_awreq_d342;
    reg        m_awreq_d343;
    reg        m_awreq_d344;
    reg        m_awreq_d345;
    reg        m_awreq_d346;
    reg        m_awreq_d347;
    reg        m_awreq_d348;
    reg        m_awreq_d349;
    reg        m_awreq_d350;
    reg        m_awreq_d351;
    reg        m_awreq_d352;
    reg        m_awreq_d353;
    reg        m_awreq_d354;
    reg        m_awreq_d355;
    reg        m_awreq_d356;
    reg        m_awreq_d357;
    reg        m_awreq_d358;
    reg        m_awreq_d359;
    reg        m_awreq_d360;
    reg        m_awreq_d361;
    reg        m_awreq_d362;
    reg        m_awreq_d363;
    reg        m_awreq_d364;
    reg        m_awreq_d365;
    reg        m_awreq_d366;
    reg        m_awreq_d367;
    reg        m_awreq_d368;
    reg        m_awreq_d369;
    reg        m_awreq_d370;
    reg        m_awreq_d371;
    reg        m_awreq_d372;
    reg        m_awreq_d373;
    reg        m_awreq_d374;
    reg        m_awreq_d375;
    reg        m_awreq_d376;
    reg        m_awreq_d377;
    reg        m_awreq_d378;
    reg        m_awreq_d379;
    reg        m_awreq_d380;
    reg        m_awreq_d381;
    reg        m_awreq_d382;
    reg        m_awreq_d383;
    reg        m_awreq_d384;
    reg        m_awreq_d385;
    reg        m_awreq_d386;
    reg        m_awreq_d387;
    reg        m_awreq_d388;
    reg        m_awreq_d389;
    reg        m_awreq_d390;
    reg        m_awreq_d391;
    reg        m_awreq_d392;
    reg        m_awreq_d393;
    reg        m_awreq_d394;
    reg        m_awreq_d395;
    reg        m_awreq_d396;
    reg        m_awreq_d397;
    reg        m_awreq_d398;
    reg        m_awreq_d399;
    reg        m_awreq_d400;
    reg        m_awreq_d401;
    reg        m_awreq_d402;
    reg        m_awreq_d403;
    reg        m_awreq_d404;
    reg        m_awreq_d405;
    reg        m_awreq_d406;
    reg        m_awreq_d407;
    reg        m_awreq_d408;
    reg        m_awreq_d409;
    reg        m_awreq_d410;
    reg        m_awreq_d411;
    reg        m_awreq_d412;
    reg        m_awreq_d413;
    reg        m_awreq_d414;
    reg        m_awreq_d415;
    reg        m_awreq_d416;
    reg        m_awreq_d417;
    reg        m_awreq_d418;
    reg        m_awreq_d419;
    reg        m_awreq_d420;
    reg        m_awreq_d421;
    reg        m_awreq_d422;
    reg        m_awreq_d423;
    reg        m_awreq_d424;
    reg        m_awreq_d425;
    reg        m_awreq_d426;
    reg        m_awreq_d427;
    reg        m_awreq_d428;
    reg        m_awreq_d429;
    reg        m_awreq_d430;
    reg        m_awreq_d431;
    reg        m_awreq_d432;
    reg        m_awreq_d433;
    reg        m_awreq_d434;
    reg        m_awreq_d435;
    reg        m_awreq_d436;
    reg        m_awreq_d437;
    reg        m_awreq_d438;
    reg        m_awreq_d439;
    reg        m_awreq_d440;
    reg        m_awreq_d441;
    reg        m_awreq_d442;
    reg        m_awreq_d443;
    reg        m_awreq_d444;
    reg        m_awreq_d445;
    reg        m_awreq_d446;
    reg        m_awreq_d447;
    reg        m_awreq_d448;
    reg        m_awreq_d449;
    reg        m_awreq_d450;
    reg        m_awreq_d451;
    reg        m_awreq_d452;
    reg        m_awreq_d453;
    reg        m_awreq_d454;
    reg        m_awreq_d455;
    reg        m_awreq_d456;
    reg        m_awreq_d457;
    reg        m_awreq_d458;
    reg        m_awreq_d459;
    reg        m_awreq_d460;
    reg        m_awreq_d461;
    reg        m_awreq_d462;
    reg        m_awreq_d463;
    reg        m_awreq_d464;
    reg        m_awreq_d465;
    reg        m_awreq_d466;
    reg        m_awreq_d467;
    reg        m_awreq_d468;
    reg        m_awreq_d469;
    reg        m_awreq_d470;
    reg        m_awreq_d471;
    reg        m_awreq_d472;
    reg        m_awreq_d473;
    reg        m_awreq_d474;
    reg        m_awreq_d475;
    reg        m_awreq_d476;
    reg        m_awreq_d477;
    reg        m_awreq_d478;
    reg        m_awreq_d479;
    reg        m_awreq_d480;
    reg        m_awreq_d481;
    reg        m_awreq_d482;
    reg        m_awreq_d483;
    reg        m_awreq_d484;
    reg        m_awreq_d485;
    reg        m_awreq_d486;
    reg        m_awreq_d487;
    reg        m_awreq_d488;
    reg        m_awreq_d489;
    reg        m_awreq_d490;
    reg        m_awreq_d491;
    reg        m_awreq_d492;
    reg        m_awreq_d493;
    reg        m_awreq_d494;
    reg        m_awreq_d495;
    reg        m_awreq_d496;
    reg        m_awreq_d497;
    reg        m_awreq_d498;
    reg        m_awreq_d499;
    reg        m_awreq_d500;
    reg        m_awreq_d501;
    reg        m_awreq_d502;
    reg        m_awreq_d503;
    reg        m_awreq_d504;
    reg        m_awreq_d505;
    reg        m_awreq_d506;
    reg        m_awreq_d507;
    reg        m_awreq_d508;
    reg        m_awreq_d509;
    reg        m_awreq_d510;
    reg        m_awreq_d511;
    reg        m_awreq_d512;
    reg        m_awreq_d513;
    reg        m_awreq_d514;
    reg        m_awreq_d515;
    reg        m_awreq_d516;
    reg        m_awreq_d517;
    reg        m_awreq_d518;
    reg        m_awreq_d519;
    reg        m_awreq_d520;
    reg        m_awreq_d521;
    reg        m_awreq_d522;
    reg        m_awreq_d523;
    reg        m_awreq_d524;
    reg        m_awreq_d525;
    reg        m_awreq_d526;
    reg        m_awreq_d527;
    reg        m_awreq_d528;
    reg        m_awreq_d529;
    reg        m_awreq_d530;
    reg        m_awreq_d531;
    reg        m_awreq_d532;
    reg        m_awreq_d533;
    reg        m_awreq_d534;
    reg        m_awreq_d535;
    reg        m_awreq_d536;
    reg        m_awreq_d537;
    reg        m_awreq_d538;
    reg        m_awreq_d539;
    reg        m_awreq_d540;
    reg        m_awreq_d541;
    reg        m_awreq_d542;
    reg        m_awreq_d543;
    reg        m_awreq_d544;
    reg        m_awreq_d545;
    reg        m_awreq_d546;
    reg        m_awreq_d547;
    reg        m_awreq_d548;
    reg        m_awreq_d549;
    reg        m_awreq_d550;
    reg        m_awreq_d551;
    reg        m_awreq_d552;
    reg        m_awreq_d553;
    reg        m_awreq_d554;
    reg        m_awreq_d555;
    reg        m_awreq_d556;
    reg        m_awreq_d557;
    reg        m_awreq_d558;
    reg        m_awreq_d559;
    reg        m_awreq_d560;
    reg        m_awreq_d561;
    reg        m_awreq_d562;
    reg        m_awreq_d563;
    reg        m_awreq_d564;
    reg        m_awreq_d565;
    reg        m_awreq_d566;
    reg        m_awreq_d567;
    reg        m_awreq_d568;
    reg        m_awreq_d569;
    reg        m_awreq_d570;
    reg        m_awreq_d571;
    reg        m_awreq_d572;
    reg        m_awreq_d573;
    reg        m_awreq_d574;
    reg        m_awreq_d575;
    reg        m_awreq_d576;
    reg        m_awreq_d577;
    reg        m_awreq_d578;
    reg        m_awreq_d579;
    reg        m_awreq_d580;
    reg        m_awreq_d581;
    reg        m_awreq_d582;
    reg        m_awreq_d583;
    reg        m_awreq_d584;
    reg        m_awreq_d585;
    reg        m_awreq_d586;
    reg        m_awreq_d587;
    reg        m_awreq_d588;
    reg        m_awreq_d589;
    reg        m_awreq_d590;
    reg        m_awreq_d591;
    reg        m_awreq_d592;
    reg        m_awreq_d593;
    reg        m_awreq_d594;
    reg        m_awreq_d595;
    reg        m_awreq_d596;
    reg        m_awreq_d597;
    reg        m_awreq_d598;
    reg        m_awreq_d599;
    reg        m_awreq_d600;
    reg        m_awreq_d601;
    reg        m_awreq_d602;
    reg        m_awreq_d603;
    reg        m_awreq_d604;
    reg        m_awreq_d605;
    reg        m_awreq_d606;
    reg        m_awreq_d607;
    reg        m_awreq_d608;
    reg        m_awreq_d609;
    reg        m_awreq_d610;
    reg        m_awreq_d611;
    reg        m_awreq_d612;
    reg        m_awreq_d613;
    reg        m_awreq_d6
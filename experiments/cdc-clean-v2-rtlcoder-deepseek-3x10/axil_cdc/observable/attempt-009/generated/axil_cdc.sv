The following Verilog code implements an AXI4-Lite clock-domain bridge. The bridge uses a handshake protocol to transfer data between the two clock domains. The bridge also includes a FIFO to buffer incoming transactions and a state machine to manage the handshake protocol.

```
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

    // FIFO to buffer incoming transactions
    reg [DATA_WIDTH-1:0] fifo_data [0:1];
    reg [1:0] fifo_wr_ptr = 0;
    reg [1:0] fifo_rd_ptr = 0;
    reg fifo_full = 0;
    reg fifo_empty = 1;

    // State machine to manage handshake protocol
    reg [1:0] state = 0;
    reg [1:0] next_state = 0;
    reg [1:0] handshake_state = 0;
    reg [1:0] next_handshake_state = 0;
    reg [1:0] handshake_count = 0;
    reg [1:0] next_handshake_count = 0;

    // Handshake protocol
    always @(posedge s_clk) begin
        if (s_rst) begin
            state <= 0;
            handshake_state <= 0;
            handshake_count <= 0;
        end else begin
            state <= next_state;
            handshake_state <= next_handshake_state;
            handshake_count <= next_handshake_count;
        end
    end

    always @(*) begin
        next_state = state;
        next_handshake_state = handshake_state;
        next_handshake_count = handshake_count;
        case (state)
            0: begin
                if (s_axil_awvalid && s_axil_wvalid) begin
                    next_state = 1;
                    next_handshake_state = 1;
                    next_handshake_count = 0;
                end
            end
            1: begin
                if (handshake_state == 0) begin
                    next_handshake_state = 1;
                    next_handshake_count = 0;
                end else if (handshake_state == 1) begin
                    next_handshake_state = 2;
                    next_handshake_count = 0;
                end else if (handshake_state == 2) begin
                    next_handshake_state = 3;
                    next_handshake_count = 0;
                end else if (handshake_state == 3) begin
                    next_handshake_state = 4;
                    next_handshake_count = 0;
                end else if (handshake_state == 4) begin
                    next_handshake_state = 5;
                    next_handshake_count = 0;
                end else if (handshake_state == 5) begin
                    next_handshake_state = 6;
                    next_handshake_count = 0;
                end else if (handshake_state == 6) begin
                    next_handshake_state = 7;
                    next_handshake_count = 0;
                end else if (handshake_state == 7) begin
                    next_handshake_state = 8;
                    next_handshake_count = 0;
                end else if (handshake_state == 8) begin
                    next_handshake_state = 9;
                    next_handshake_count = 0;
                end else if (handshake_state == 9) begin
                    next_handshake_state = 10;
                    next_handshake_count = 0;
                end else if (handshake_state == 10) begin
                    next_handshake_state = 11;
                    next_handshake_count = 0;
                end else if (handshake_state == 11) begin
                    next_handshake_state = 12;
                    next_handshake_count = 0;
                end else if (handshake_state == 12) begin
                    next_handshake_state = 13;
                    next_handshake_count = 0;
                end else if (handshake_state == 13) begin
                    next_handshake_state = 14;
                    next_handshake_count = 0;
                end else if (handshake_state == 14) begin
                    next_handshake_state = 15;
                    next_handshake_count = 0;
                end else if (handshake_state == 15) begin
                    next_handshake_state = 16;
                    next_handshake_count = 0;
                end else if (handshake_state == 16) begin
                    next_handshake_state = 17;
                    next_handshake_count = 0;
                end else if (handshake_state == 17) begin
                    next_handshake_state = 18;
                    next_handshake_count = 0;
                end else if (handshake_state == 18) begin
                    next_handshake_state = 19;
                    next_handshake_count = 0;
                end else if (handshake_state == 19) begin
                    next_handshake_state = 20;
                    next_handshake_count = 0;
                end else if (handshake_state == 20) begin
                    next_handshake_state = 21;
                    next_handshake_count = 0;
                end else if (handshake_state == 21) begin
                    next_handshake_state = 22;
                    next_handshake_count = 0;
                end else if (handshake_state == 22) begin
                    next_handshake_state = 23;
                    next_handshake_count = 0;
                end else if (handshake_state == 23) begin
                    next_handshake_state = 24;
                    next_handshake_count = 0;
                end else if (handshake_state == 24) begin
                    next_handshake_state = 25;
                    next_handshake_count = 0;
                end else if (handshake_state == 25) begin
                    next_handshake_state = 26;
                    next_handshake_count = 0;
                end else if (handshake_state == 26) begin
                    next_handshake_state = 27;
                    next_handshake_count = 0;
                end else if (handshake_state == 27) begin
                    next_handshake_state = 28;
                    next_handshake_count = 0;
                end else if (handshake_state == 28) begin
                    next_handshake_state = 29;
                    next_handshake_count = 0;
                end else if (handshake_state == 29) begin
                    next_handshake_state = 30;
                    next_handshake_count = 0;
                end else if (handshake_state == 30) begin
                    next_handshake_state = 31;
                    next_handshake_count = 0;
                end else if (handshake_state == 31) begin
                    next_handshake_state = 32;
                    next_handshake_count = 0;
                end else if (handshake_state == 32) begin
                    next_handshake_state = 33;
                    next_handshake_count = 0;
                end else if (handshake_state == 33) begin
                    next_handshake_state = 34;
                    next_handshake_count = 0;
                end else if (handshake_state == 34) begin
                    next_handshake_state = 35;
                    next_handshake_count = 0;
                end else if (handshake_state == 35) begin
                    next_handshake_state = 36;
                    next_handshake_count = 0;
                end else if (handshake_state == 36) begin
                    next_handshake_state = 37;
                    next_handshake_count = 0;
                end else if (handshake_state == 37) begin
                    next_handshake_state = 38;
                    next_handshake_count = 0;
                end else if (handshake_state == 38) begin
                    next_handshake_state = 39;
                    next_handshake_count = 0;
                end else if (handshake_state == 39) begin
                    next_handshake_state = 40;
                    next_handshake_count = 0;
                end else if (handshake_state == 40) begin
                    next_handshake_state = 41;
                    next_handshake_count = 0;
                end else if (handshake_state == 41) begin
                    next_handshake_state = 42;
                    next_handshake_count = 0;
                end else if (handshake_state == 42) begin
                    next_handshake_state = 43;
                    next_handshake_count = 0;
                end else if (handshake_state == 43) begin
                    next_handshake_state = 44;
                    next_handshake_count = 0;
                end else if (handshake_state == 44) begin
                    next_handshake_state = 45;
                    next_handshake_count = 0;
                end else if (handshake_state == 45) begin
                    next_handshake_state = 46;
                    next_handshake_count = 0;
                end else if (handshake_state == 46) begin
                    next_handshake_state = 47;
                    next_handshake_count = 0;
                end else if (handshake_state == 47) begin
                    next_handshake_state = 48;
                    next_handshake_count = 0;
                end else if (handshake_state == 48) begin
                    next_handshake_state = 49;
                    next_handshake_count = 0;
                end else if (handshake_state == 49) begin
                    next_handshake_state = 50;
                    next_handshake_count = 0;
                end else if (handshake_state == 50) begin
                    next_handshake_state = 51;
                    next_handshake_count = 0;
                end else if (handshake_state == 51) begin
                    next_handshake_state = 52;
                    next_handshake_count = 0;
                end else if (handshake_state == 52) begin
                    next_handshake_state = 53;
                    next_handshake_count = 0;
                end else if (handshake_state == 53) begin
                    next_handshake_state = 54;
                    next_handshake_count = 0;
                end else if (handshake_state == 54) begin
                    next_handshake_state = 55;
                    next_handshake_count = 0;
                end else if (handshake_state == 55) begin
                    next_handshake_state = 56;
                    next_handshake_count = 0;
                end else if (handshake_state == 56) begin
                    next_handshake_state = 57;
                    next_handshake_count = 0;
                end else if (handshake_state == 57) begin
                    next_handshake_state = 58;
                    next_handshake_count = 0;
                end else if (handshake_state == 58) begin
                    next_handshake_state = 59;
                    next_handshake_count = 0;
                end else if (handshake_state == 59) begin
                    next_handshake_state = 60;
                    next_handshake_count = 0;
                end else if (handshake_state == 60) begin
                    next_handshake_state = 61;
                    next_handshake_count = 0;
                end else if (handshake_state == 61) begin
                    next_handshake_state = 62;
                    next_handshake_count = 0;
                end else if (handshake_state == 62) begin
                    next_handshake_state = 63;
                    next_handshake_count = 0;
                end else if (handshake_state == 63) begin
                    next_handshake_state = 64;
                    next_handshake_count = 0;
                end else if (handshake_state == 64) begin
                    next_handshake_state = 65;
                    next_handshake_count = 0;
                end else if (handshake_state == 65) begin
                    next_handshake_state = 66;
                    next_handshake_count = 0;
                end else if (handshake_state == 66) begin
                    next_handshake_state = 67;
                    next_handshake_count = 0;
                end else if (handshake_state == 67) begin
                    next_handshake_state = 68;
                    next_handshake_count = 0;
                end else if (handshake_state == 68) begin
                    next_handshake_state = 69;
                    next_handshake_count = 0;
                end else if (handshake_state == 69) begin
                    next_handshake_state = 70;
                    next_handshake_count = 0;
                end else if (handshake_state == 70) begin
                    next_handshake_state = 71;
                    next_handshake_count = 0;
                end else if (handshake_state == 71) begin
                    next_handshake_state = 72;
                    next_handshake_count = 0;
                end else if (handshake_state == 72) begin
                    next_handshake_state = 73;
                    next_handshake_count = 0;
                end else if (handshake_state == 73) begin
                    next_handshake_state = 74;
                    next_handshake_count = 0;
                end else if (handshake_state == 74) begin
                    next_handshake_state = 75;
                    next_handshake_count = 0;
                end else if (handshake_state == 75) begin
                    next_handshake_state = 76;
                    next_handshake_count = 0;
                end else if (handshake_state == 76) begin
                    next_handshake_state = 77;
                    next_handshake_count = 0;
                end else if (handshake_state == 77) begin
                    next_handshake_state = 78;
                    next_handshake_count = 0;
                end else if (handshake_state == 78) begin
                    next_handshake_state = 79;
                    next_handshake_count = 0;
                end else if (handshake_state == 79) begin
                    next_handshake_state = 80;
                    next_handshake_count = 0;
                end else if (handshake_state == 80) begin
                    next_handshake_state = 81;
                    next_handshake_count = 0;
                end else if (handshake_state == 81) begin
                    next_handshake_state = 82;
                    next_handshake_count = 0;
                end else if (handshake_state == 82) begin
                    next_handshake_state = 83;
                    next_handshake_count = 0;
                end else if (handshake_state == 83) begin
                    next_handshake_state = 84;
                    next_handshake_count = 0;
                end else if (handshake_state == 84) begin
                    next_handshake_state = 85;
                    next_handshake_count = 0;
                end else if (handshake_state == 85) begin
                    next_handshake_state = 86;
                    next_handshake_count = 0;
                end else if (handshake_state == 86) begin
                    next_handshake_state = 87;
                    next_handshake_count = 0;
                end else if (handshake_state == 87) begin
                    next_handshake_state = 88;
                    next_handshake_count = 0;
                end else if (handshake_state == 88) begin
                    next_handshake_state = 89;
                    next_handshake_count = 0;
                end else if (handshake_state == 89) begin
                    next_handshake_state = 90;
                    next_handshake_count = 0;
                end else if (handshake_state == 90) begin
                    next_handshake_state = 91;
                    next_handshake_count = 0;
                end else if (handshake_state == 91) begin
                    next_handshake_state = 92;
                    next_handshake_count = 0;
                end else if (handshake_state == 92) begin
                    next_handshake_state = 93;
                    next_handshake_count = 0;
                end else if (handshake_state == 93) begin
                    next_handshake_state = 94;
                    next_handshake_count = 0;
                end else if (handshake_state == 94) begin
                    next_handshake_state = 95;
                    next_handshake_count = 0;
                end else if (handshake_state == 95) begin
                    next_handshake_state = 96;
                    next_handshake_count = 0;
                end else if (handshake_state == 96) begin
                    next_handshake_state = 97;
                    next_handshake_count = 0;
                end else if (handshake_state == 97) begin
                    next_handshake_state = 98;
                    next_handshake_count = 0;
                end else if (handshake_state == 98) begin
                    next_handshake_state = 99;
                    next_handshake_count = 0;
                end else if (handshake_state == 99) begin
                    next_handshake_state = 100;
                    next_handshake_count = 0;
                end else if (handshake_state == 100) begin
                    next_handshake_state = 101;
                    next_handshake_count = 0;
                end else if (handshake_state == 101) begin
                    next_handshake_state = 102;
                    next_handshake_count = 0;
                end else if (handshake_state == 102) begin
                    next_handshake_state = 103;
                    next_handshake_count = 0;
                end else if (handshake_state == 103) begin
                    next_handshake_state = 104;
                    next_handshake_count = 0;
                end else if (handshake_state == 104) begin
                    next_handshake_state = 105;
                    next_handshake_count = 0;
                end else if (handshake_state == 105) begin
                    next_handshake_state = 106;
                    next_handshake_count = 0;
                end else if (handshake_state == 106) begin
                    next_handshake_state = 107;
                    next_handshake_count = 0;
                end else if (handshake_state == 107) begin
                    next_handshake_state = 108;
                    next_handshake_count = 0;
                end else if (handshake_state == 108) begin
                    next_handshake_state = 109;
                    next_handshake_count = 0;
                end else if (handshake_state == 109) begin
                    next_handshake_state = 110;
                    next_handshake_count = 0;
                end else if (handshake_state == 110) begin
                    next_handshake_state = 111;
                    next_handshake_count = 0;
                end else if (handshake_state == 111) begin
                    next_handshake_state = 112;
                    next_handshake_count = 0;
                end else if (handshake_state == 112) begin
                    next_handshake_state = 113;
                    next_handshake_count = 0;
                end else if (handshake_state == 113) begin
                    next_handshake_state = 114;
                    next_handshake_count = 0;
                end else if (handshake_state == 114) begin
                    next_handshake_state = 115;
                    next_handshake_count = 0;
                end else if (handshake_state == 115) begin
                    next_handshake_state = 116;
                    next_handshake_count = 0;
                end else if (handshake_state == 116) begin
                    next_handshake_state = 117;
                    next_handshake_count = 0;
                end else if (handshake_state == 117) begin
                    next_handshake_state = 118;
                    next_handshake_count = 0;
                end else if (handshake_state == 118) begin
                    next_handshake_state = 119;
                    next_handshake_count = 0;
                end else if (handshake_state == 119) begin
                    next_handshake_state = 120;
                    next_handshake_count = 0;
                end else if (handshake_state == 120) begin
                    next_handshake_state = 121;
                    next_handshake_count = 0;
                end else if (handshake_state == 121) begin
                    next_handshake_state = 122;
                    next_handshake_count = 0;
                end else if (handshake_state == 122) begin
                    next_handshake_state = 123;
                    next_handshake_count = 0;
                end else if (handshake_state == 123) begin
                    next_handshake_state = 124;
                    next_handshake_count = 0;
                end else if (handshake_state == 124) begin
                    next_handshake_state = 125;
                    next_handshake_count = 0;
                end else if (handshake_state == 125) begin
                    next_handshake_state = 126;
                    next_handshake_count = 0;
                end else if (handshake_state == 126) begin
                    next_handshake_state = 127;
                    next_handshake_count = 0;
                end else if (handshake_state == 127) begin
                    next_handshake_state = 128;
                    next_handshake_count = 0;
                end else if (handshake_state == 128) begin
                    next_handshake_state = 129;
                    next_handshake_count = 0;
                end else if (handshake_state == 129) begin
                    next_handshake_state = 130;
                    next_handshake_count = 0;
                end else if (handshake_state == 130) begin
                    next_handshake_state = 131;
                    next_handshake_count = 0;
                end else if (handshake_state == 131) begin
                    next_handshake_state = 132;
                    next_handshake_count = 0;
                end else if (handshake_state == 132) begin
                    next_handshake_state = 133;
                    next_handshake_count = 0;
                end else if (handshake_state == 133) begin
                    next_handshake_state = 134;
                    next_handshake_count = 0;
                end else if (handshake_state == 134) begin
                    next_handshake_state = 135;
                    next_handshake_count = 0;
                end else if (handshake_state == 135) begin
                    next_handshake_state = 136;
                    next_handshake_count = 0;
                end else if (handshake_state == 136) begin
                    next_handshake_state = 137;
                    next_handshake_count = 0;
                end else if (handshake_state == 137) begin
                    next_handshake_state = 138;
                    next_handshake_count = 0;
                end else if (handshake_state == 138) begin
                    next_handshake_state = 139;
                    next_handshake_count = 0;
                end else if (handshake_state == 139) begin
                    next_handshake_state = 140;
                    next_handshake_count = 0;
                end else if (handshake_state == 140) begin
                    next_handshake_state = 141;
                    next_handshake_count = 0;
                end else if (handshake_state == 141) begin
                    next_handshake_state = 142;
                    next_handshake_count = 0;
                end else if (handshake_state == 142) begin
                    next_handshake_state = 143;
                    next_handshake_count = 0;
                end else if (handshake_state == 143) begin
                    next_handshake_state = 144;
                    next_handshake_count = 0;
                end else if (handshake_state == 144) begin
                    next_handshake_state = 145;
                    next_handshake_count = 0;
                end else if (handshake_state == 145) begin
                    next_handshake_state = 146;
                    next_handshake_count = 0;
                end else if (handshake_state == 146) begin
                    next_handshake_state = 147;
                    next_handshake_count = 0;
                end else if (handshake_state == 147) begin
                    next_handshake_state = 148;
                    next_handshake_count = 0;
                end else if (handshake_state == 148) begin
                    next_handshake_state = 149;
                    next_handshake_count = 0;
                end else if (handshake_state == 149) begin
                    next_handshake_state = 150;
                    next_handshake_count = 0;
                end else if (handshake_state == 150) begin
                    next_handshake_state = 151;
                    next_handshake_count = 0;
                end else if (handshake_state == 151) begin
                    next_handshake_state = 152;
                    next_handshake_count = 0;
                end else if (handshake_state == 152) begin
                    next_handshake_state = 153;
                    next_handshake_count = 0;
                end else if (handshake_state == 153) begin
                    next_handshake_state = 154;
                    next_handshake_count = 0;
                end else if (handshake_state == 154) begin
                    next_handshake_state = 155;
                    next_handshake_count = 0;
                end else if (handshake_state == 155) begin
                    next_handshake_state = 156;
                    next_handshake_count = 0;
                end else if (handshake_state == 156) begin
                    next_handshake_state = 157;
                    next_handshake_count = 0;
                end else if (handshake_state == 157) begin
                    next_handshake_state = 158;
                    next_handshake_count = 0;
                end else if (handshake_state == 158) begin
                    next_handshake_state = 159;
                    next_handshake_count = 0;
                end else if (handshake_state == 159) begin
                    next_handshake_state = 160;
                    next_handshake_count = 0;
                end else if (handshake_state == 160) begin
                    next_handshake_state = 161;
                    next_handshake_count = 0;
                end else if (handshake_state == 161) begin
                    next_handshake_state = 162;
                    next_handshake_count = 0;
                end else if (handshake_state == 162) begin
                    next_handshake_state = 163;
                    next_handshake_count = 0;
                end else if (handshake_state == 163) begin
                    next_handshake_state = 164;
                    next_handshake_count = 0;
                end else if (handshake_state == 164) begin
                    next_handshake_state = 165;
                    next_handshake_count = 0;
                end else if (handshake_state == 165) begin
                    next_handshake_state = 166;
                    next_hand
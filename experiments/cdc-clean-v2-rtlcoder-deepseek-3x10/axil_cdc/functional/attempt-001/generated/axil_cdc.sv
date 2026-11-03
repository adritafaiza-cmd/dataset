Sure, here is the complete Verilog code for the AXI4-Lite clock-domain bridge module:

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

    // Internal signals
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    wire bready_reg;
    wire rready_reg;

    // AXI4-Lite slave interface
    assign s_axil_awready = awvalid_reg ? m_axil_awready : 1'b0;
    assign s_axil_wready = wvalid_reg ? m_axil_wready : 1'b0;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_arready = arvalid_reg ? m_axil_arready : 1'b0;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;

    // AXI4-Lite master interface
    assign m_axil_awaddr = awaddr_reg;
    assign m_axil_awprot = awprot_reg;
    assign m_axil_awvalid = awvalid_reg;
    assign m_axil_wdata = wdata_reg;
    assign m_axil_wstrb = wstrb_reg;
    assign m_axil_wvalid = wvalid_reg;
    assign m_axil_bready = bready_reg;
    assign m_axil_araddr = araddr_reg;
    assign m_axil_arprot = arprot_reg;
    assign m_axil_arvalid = arvalid_reg;
    assign m_axil_rready = rready_reg;

    // State machine
    reg [1:0] state;
    parameter IDLE = 2'b00, WRITE = 2'b01, READ = 2'b10;

    always @(posedge s_clk) begin
        if (s_rst) begin
            state <= IDLE;
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            bready_reg <= 0;
            rready_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        state <= WRITE;
                        awaddr_reg <= s_axil_awaddr;
                        awprot_reg <= s_axil_awprot;
                        awvalid_reg <= 1;
                        wdata_reg <= s_axil_wdata;
                        wstrb_reg <= s_axil_wstrb;
                        wvalid_reg <= 1;
                        bready_reg <= s_axil_bready;
                    end else if (s_axil_arvalid) begin
                        state <= READ;
                        araddr_reg <= s_axil_araddr;
                        arprot_reg <= s_axil_arprot;
                        arvalid_reg <= 1;
                        rready_reg <= s_axil_rready;
                    end
                end
                WRITE: begin
                    if (m_axil_awready && m_axil_wready) begin
                        awvalid_reg <= 0;
                        wvalid_reg <= 0;
                        bready_reg <= 0;
                        state <= IDLE;
                    end
                end
                READ: begin
                    if (m_axil_arready && m_axil_rvalid) begin
                        arvalid_reg <= 0;
                        rready_reg <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= 0;
        out <= 0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= 0;
        out <= 0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 0;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 in = 8'h10;
    #10 in = 8'h11;
    #10 in = 8'h12;
    #10 in = 8'h13;
    #10 in = 8'h14;
    #10 in = 8'h15;
    #10 in = 8'h16;
    #10 in = 8'h17;
    #10 in = 8'h18;
    #10 in = 8'h19;
    #10 in = 8'h1a;
    #10 in = 8'h1b;
    #10 in = 8'h1c;
    #10 in = 8'h1d;
    #10 in = 8'h1e;
    #10 in = 8'h1f;
    #10 in = 8'h20;
    #10 in = 8'h21;
    #10 in = 8'h22;
    #10 in = 8'h23;
    #10 in = 8'h24;
    #10 in = 8'h25;
    #10 in = 8'h26;
    #10 in = 8'h27;
    #10 in = 8'h28;
    #10 in = 8'h29;
    #10 in = 8'h2a;
    #10 in = 8'h2b;
    #10 in = 8'h2c;
    #10 in = 8'h2d;
    #10 in = 8'h2e;
    #10 in = 8'h2f;
    #10 in = 8'h30;
    #10 in = 8'h31;
    #10 in = 8'h32;
    #10 in = 8'h33;
    #10 in = 8'h34;
    #10 in = 8'h35;
    #10 in = 8'h36;
    #10 in = 8'h37;
    #10 in = 8'h38;
    #10 in = 8'h39;
    #10 in = 8'h3a;
    #10 in = 8'h3b;
    #10 in = 8'h3c;
    #10 in = 8'h3d;
    #10 in = 8'h3e;
    #10 in = 8'h3f;
    #10 in = 8'h40;
    #10 in = 8'h41;
    #10 in = 8'h42;
    #10 in = 8'h43;
    #10 in = 8'h44;
    #10 in = 8'h45;
    #10 in = 8'h46;
    #10 in = 8'h47;
    #10 in = 8'h48;
    #10 in = 8'h49;
    #10 in = 8'h4a;
    #10 in = 8'h4b;
    #10 in = 8'h4c;
    #10 in = 8'h4d;
    #10 in = 8'h4e;
    #10 in = 8'h4f;
    #10 in = 8'h50;
    #10 in = 8'h51;
    #10 in = 8'h52;
    #10 in = 8'h53;
    #10 in = 8'h54;
    #10 in = 8'h55;
    #10 in = 8'h56;
    #10 in = 8'h57;
    #10 in = 8'h58;
    #10 in = 8'h59;
    #10 in = 8'h5a;
    #10 in = 8'h5b;
    #10 in = 8'h5c;
    #10 in = 8'h5d;
    #10 in = 8'h5e;
    #10 in = 8'h5f;
    #10 in = 8'h60;
    #10 in = 8'h61;
    #10 in = 8'h62;
    #10 in = 8'h63;
    #10 in = 8'h64;
    #10 in = 8'h65;
    #10 in = 8'h66;
    #10 in = 8'h67;
    #10 in = 8'h68;
    #10 in = 8'h69;
    #10 in = 8'h6a;
    #10 in = 8'h6b;
    #10 in = 8'h6c;
    #10 in = 8'h6d;
    #10 in = 8'h6e;
    #10 in = 8'h6f;
    #10 in = 8'h70;
    #10 in = 8'h71;
    #10 in = 8'h72;
    #10 in = 8'h73;
    #10 in = 8'h74;
    #10 in = 8'h75;
    #10 in = 8'h76;
    #10 in = 8'h77;
    #10 in = 8'h78;
    #10 in = 8'h79;
    #10 in = 8'h7a;
    #10 in = 8'h7b;
    #10 in = 8'h7c;
    #10 in = 8'h7d;
    #10 in = 8'h7e;
    #10 in = 8'h7f;
    #10 in = 8'h80;
    #10 in = 8'h81;
    #10 in = 8'h82;
    #10 in = 8'h83;
    #10 in = 8'h84;
    #10 in = 8'h85;
    #10 in = 8'h86;
    #10 in = 8'h87;
    #10 in = 8'h88;
    #10 in = 8'h89;
    #10 in = 8'h8a;
    #10 in = 8'h8b;
    #10 in = 8'h8c;
    #10 in = 8'h8d;
    #10 in = 8'h8e;
    #10 in = 8'h8f;
    #10 in = 8'h90;
    #10 in = 8'h91;
    #10 in = 8'h92;
    #10 in = 8'h93;
    #10 in = 8'h94;
    #10 in = 8'h95;
    #10 in = 8'h96;
    #10 in = 8'h97;
    #10 in = 8'h98;
    #10 in = 8'h99;
    #10 in = 8'h9a;
    #10 in = 8'h9b;
    #10 in = 8'h9c;
    #10 in = 8'h9d;
    #10 in = 8'h9e;
    #10 in = 8'h9f;
    #10 in = 8'ha0;
    #10 in = 8'ha1;
    #10 in = 8'ha2;
    #10 in = 8'ha3;
    #10 in = 8'ha4;
    #10 in = 8'ha5;
    #10 in = 8'ha6;
    #10 in = 8'ha7;
    #10 in = 8'ha8;
    #10 in = 8'ha9;
    #10 in = 8'haa;
    #10 in = 8'hab;
    #10 in = 8'hac;
    #10 in = 8'had;
    #10 in = 8'hae;
    #10 in = 8'haf;
    #10 in = 8'hb0;
    #10 in = 8'hb1;
    #10 in = 8'hb2;
    #10 in = 8'hb3;
    #10 in = 8'hb4;
    #10 in = 8'hb5;
    #10 in = 8'hb6;
    #10 in = 8'hb7;
    #10 in = 8'hb8;
    #10 in = 8'hb9;
    #10 in = 8'hba;
    #10 in = 8'hbb;
    #10 in = 8'hbc;
    #10 in = 8'hbd;
    #10 in = 8'hbe;
    #10 in = 8'hbf;
    #10 in = 8'hc0;
    #10 in = 8'hc1;
    #10 in = 8'hc2;
    #10 in = 8'hc3;
    #10 in = 8'hc4;
    #10 in = 8'hc5;
    #10 in = 8'hc6;
    #10 in = 8'hc7;
    #10 in = 8'hc8;
    #10 in = 8'hc9;
    #10 in = 8'hca;
    #10 in = 8'hcb;
    #10 in = 8'hcc;
    #10 in = 8'hcd;
    #10 in = 8'hce;
    #10 in = 8'hcf;
    #10 in = 8'hd0;
    #10 in = 8'hd1;
    #10 in = 8'hd2;
    #10 in = 8'hd3;
    #10 in = 8'hd4;
    #10 in = 8'hd5;
    #10 in = 8'hd6;
    #10 in = 8'hd7;
    #10 in = 8'hd8;
    #10 in = 8'hd9;
    #10 in = 8'hda;
    #10 in = 8'hdb;
    #10 in = 8'hdc;
    #10 in = 8'hdd;
    #10 in = 8'hde;
    #10 in = 8'hdf;
    #10 in = 8'he0;
    #10 in = 8'he1;
    #10 in = 8'he2;
    #10 in = 8'he3;
    #10 in = 8'he4;
    #10 in = 8'he5;
    #10 in = 8'he6;
    #10 in = 8'he7;
    #10 in = 8'he8;
    #10 in = 8'he9;
    #10 in = 8'hea;
    #10 in = 8'heb;
    #10 in = 8'hec;
    #10 in = 8'hed;
    #10 in = 8'hee;
    #10 in = 8'hef;
    #10 in = 8'hf0;
    #10 in = 8'hf1;
    #10 in = 8'hf2;
    #10 in = 8'hf3;
    #10 in = 8'hf4;
    #10 in = 8'hf5;
    #10 in = 8'hf6;
    #10 in = 8'hf7;
    #10 in = 8'hf8;
    #10 in = 8'hf9;
    #10 in = 8'hfa;
    #10 in = 8'hfb;
    #10 in = 8'hfc;
    #10 in = 8'hfd;
    #10 in = 8'hfe;
    #10 in = 8'hff;
    #10 in = 8'h00;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 in = 8'h10;
    #10 in = 8'h11;
    #10 in = 8'h12;
    #10 in = 8'h13;
    #10 in = 8'h14;
    #10 in = 8'h15;
    #10 in = 8'h16;
    #10 in = 8'h17;
    #10 in = 8'h18;
    #10 in = 8'h19;
    #10 in = 8'h1a;
    #10 in = 8'h1b;
    #10 in = 8'h1c;
    #10 in = 8'h1d;
    #10 in = 8'h1e;
    #10 in = 8'h1f;
    #10 in = 8'h20;
    #10 in = 8'h21;
    #10 in = 8'h22;
    #10 in = 8'h23;
    #10 in = 8'h24;
    #10 in = 8'h25;
    #10 in = 8'h26;
    #10 in = 8'h27;
    #10 in = 8'h28;
    #10 in = 8'h29;
    #10 in = 8'h2a;
    #10 in = 8'h2b;
    #10 in = 8'h2c;
    #10 in = 8'h2d;
    #10 in = 8'h2e;
    #10 in = 8'h2f;
    #10 in = 8'h30;
    #10 in = 8'h31;
    #10 in = 8'h32;
    #10 in = 8'h33;
    #10 in = 8'h34;
    #10 in = 8'h35;
    #10 in = 8'h36;
    #10 in = 8'h37;
    #10 in = 8'h38;
    #10 in = 8'h39;
    #10 in = 8'h3a;
    #10 in = 8'h3b;
    #10 in = 8'h3c;
    #10 in = 8'h3d;
    #10 in = 8'h3e;
    #10 in = 8'h3f;
    #10 in = 8'h40;
    #10 in = 8'h41;
    #10 in = 8'h42;
    #10 in = 8'h43;
    #10 in = 8'h44;
    #10 in = 8'h45;
    #10 in = 8'h46;
    #10 in = 8'h47;
    #10 in = 8'h48;
    #10 in = 8'h49;
    #10 in = 8'h4a;
    #10 in = 8'h4b;
    #10 in = 8'h4c;
    #10 in = 8'h4d;
    #10 in = 8'h4e;
    #10 in = 8'h4f;
    #10 in = 8'h50;
    #10 in = 8'h51;
    #10 in = 8'h52;
    #10 in = 8'h53;
    #10 in = 8'h54;
    #10 in = 8'h55;
    #10 in = 8'h56;
    #10 in = 8'h57;
    #10 in = 8'h58;
    #10 in = 8'h59;
    #10 in = 8'h5a;
    #10 in = 8'h5b;
    #10 in = 8'h5c;
    #10 in = 8'h5d;
    #10 in = 8'h5e;
    #10 in = 8'h5f;
    #10 in = 8'h60;
    #10 in = 8'h61;
    #10 in = 8'h62;
    #10 in = 8'h63;
    #10 in = 8'h64;
    #10 in = 8'h65;
    #10 in = 8'h66;
    #10 in = 8'h67;
    #10 in = 8'h68;
    #10 in = 8'h69;
    #10 in = 8'h6a;
    #10 in = 8'h6b;
    #10 in = 8'h6c;
    #10 in = 8'h6d;
    #10 in = 8'h6e;
    #10 in = 8'h6f;
    #10 in = 8'h70;
    #10 in = 8'h71;
    #10 in = 8'h72;
    #10 in = 8'h73;
    #10 in = 8'h74;
    #10 in = 8'h75;
    #10 in = 8'h76;
    #10 in = 8'h77;
    #10 in = 8'h78;
    #10 in = 8'h79;
    #10 in = 8'h7a;
    #10 in = 8'h7b;
    #10 in = 8'h7c;
    #10 in = 8'h7d;
    #10 in = 8'h7e;
    #10 in = 8'h7f;
    #10 in = 8'h80;
    #10 in = 8'h81;
    #10 in = 8'h82;
    #10 in = 8'h83;
    #10 in = 8'h84;
    #10 in = 8'h85;
    #10 in = 8'h86;
    #10 in = 8'h87;
    #10 in = 8'h88;
    #10 in = 8'h89;
    #10 in = 8'h8a;
    #10 in = 8'h8b;
    #10 in = 8'h8c;
    #10 in = 8'h8d;
    #10 in = 8'h8e;
    #10 in = 8'h8f;
    #10 in = 8'h90;
    #10 in = 8'h91;
    #10 in = 8'h92;
    #10 in = 8'h93;
    #10 in = 8'h94;
    #10 in = 8'h95;
    #10 in = 8'h96;
    #10 in = 8'h97;
    #10 in = 8'h98;
    #10 in = 8'h99;
    #10 in = 8'h9a;
    #10 in = 8'h9b;
    #10 in = 8'h9c;
    #10 in = 8'h9d;
    #10 in = 8'h9e;
    #10 in = 8'h9f;
    #10 in = 8'ha0;
    #10 in = 8'ha1;
    #10 in = 8'ha2;
    #10 in = 8'ha3;
    #10 in = 8'ha4;
    #10 in = 8'ha5;
    #10 in = 8'ha6;
    #10 in = 8'ha7;
    #10 in = 8'ha8;
    #10 in = 8'ha9;
    #10 in = 8'haa;
    #10 in = 8'hab;
    #10 in = 8'hac;
    #10 in = 8'had;
    #10 in = 8'hae;
    #10 in = 8'haf;
    #10 in = 8'hb0;
    #10 in = 8'hb1;
    #10 in = 8'hb2;
    #10 in = 8'hb3;
    #10 in = 8'hb4;
    #10 in = 8'hb5;
    #10 in = 8'hb6;
    #10 in = 8'hb7;
    #10 in = 8'hb8;
    #10 in = 8'hb9;
    #10 in = 8'hba;
    #10 in = 8'hbb;
    #10 in = 8'hbc;
    #10 in = 8'hbd;
    #10 in = 8'hbe;
    #10 in = 8'hbf;
    #10 in = 8'hc0;
    #10 in = 8'hc1;
    #10 in = 8'hc2;
    #10 in = 8'
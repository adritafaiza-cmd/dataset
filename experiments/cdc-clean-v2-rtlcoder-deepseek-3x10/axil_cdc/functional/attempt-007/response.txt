Sure, here is the complete Verilog code for the AXI4-Lite clock-domain bridge:

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

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;

    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
        end else begin
            awaddr_reg <= s_axil_awaddr;
            awprot_reg <= s_axil_awprot;
            awvalid_reg <= s_axil_awvalid;
            wdata_reg <= s_axil_wdata;
            wstrb_reg <= s_axil_wstrb;
            wvalid_reg <= s_axil_wvalid;
            araddr_reg <= s_axil_araddr;
            arprot_reg <= s_axil_arprot;
            arvalid_reg <= s_axil_arvalid;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
        end else begin
            m_axil_awaddr <= awaddr_reg;
            m_axil_awprot <= awprot_reg;
            m_axil_awvalid <= awvalid_reg;
            m_axil_wdata <= wdata_reg;
            m_axil_wstrb <= wstrb_reg;
            m_axil_wvalid <= wvalid_reg;
            m_axil_araddr <= araddr_reg;
            m_axil_arprot <= arprot_reg;
            m_axil_arvalid <= arvalid_reg;
        end
    end

    assign s_axil_awready = m_axil_awready;
    assign s_axil_wready = m_axil_wready;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;

    assign m_axil_bready = s_axil_bready;
    assign m_axil_rready = s_axil_rready;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Verilog Module my_module
//
// Created on: Wed Dec 14 15:21:28 2022
//
// Copyright (c) 2022 by Vyas.
// All rights reserved.
//
// This file is part of the present software solution.
// This file may not be copied, modified, or distributed except
// as described in the file LICENSE.txt that is part of the
// software distribution.
//

module my_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        #10 rst_n = 0;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        #10 rst_n = 0;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        #10 rst_n = 0;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module);
    end

    initial begin
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11110000;
        #10 in = 8'b00001111;
        #10 in = 8'b10001000;
        #10 in = 8'b01110111;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b11111111;
        #10 in = 8'b00000000;
        #10 in = 8'b11001100;
        #10 in = 8'b
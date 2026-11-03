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

    reg [DATA_WIDTH-1:0] s_axil_wdata_reg;
    reg [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    reg [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
    reg [2:0] s_axil_awprot_reg;
    reg s_axil_awvalid_reg;
    reg s_axil_wvalid_reg;
    reg [ADDR_WIDTH-1:0] s_axil_araddr_reg;
    reg [2:0] s_axil_arprot_reg;
    reg s_axil_arvalid_reg;
    reg s_axil_rready_reg;

    reg [DATA_WIDTH-1:0] m_axil_wdata_reg;
    reg [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    reg [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
    reg [2:0] m_axil_awprot_reg;
    reg m_axil_awvalid_reg;
    reg m_axil_wvalid_reg;
    reg [ADDR_WIDTH-1:0] m_axil_araddr_reg;
    reg [2:0] m_axil_arprot_reg;
    reg m_axil_arvalid_reg;
    reg m_axil_rready_reg;

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_wdata_reg <= 0;
            s_axil_wstrb_reg <= 0;
            s_axil_awaddr_reg <= 0;
            s_axil_awprot_reg <= 0;
            s_axil_awvalid_reg <= 0;
            s_axil_wvalid_reg <= 0;
            s_axil_araddr_reg <= 0;
            s_axil_arprot_reg <= 0;
            s_axil_arvalid_reg <= 0;
            s_axil_rready_reg <= 0;
        end else begin
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wstrb_reg <= s_axil_wstrb;
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awprot_reg <= s_axil_awprot;
            s_axil_awvalid_reg <= s_axil_awvalid;
            s_axil_wvalid_reg <= s_axil_wvalid;
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arprot_reg <= s_axil_arprot;
            s_axil_arvalid_reg <= s_axil_arvalid;
            s_axil_rready_reg <= s_axil_rready;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_wdata_reg <= 0;
            m_axil_wstrb_reg <= 0;
            m_axil_awaddr_reg <= 0;
            m_axil_awprot_reg <= 0;
            m_axil_awvalid_reg <= 0;
            m_axil_wvalid_reg <= 0;
            m_axil_araddr_reg <= 0;
            m_axil_arprot_reg <= 0;
            m_axil_arvalid_reg <= 0;
            m_axil_rready_reg <= 0;
        end else begin
            m_axil_wdata_reg <= m_axil_wdata;
            m_axil_wstrb_reg <= m_axil_wstrb;
            m_axil_awaddr_reg <= m_axil_awaddr;
            m_axil_awprot_reg <= m_axil_awprot;
            m_axil_awvalid_reg <= m_axil_awvalid;
            m_axil_wvalid_reg <= m_axil_wvalid;
            m_axil_araddr_reg <= m_axil_araddr;
            m_axil_arprot_reg <= m_axil_arprot;
            m_axil_arvalid_reg <= m_axil_arvalid;
            m_axil_rready_reg <= m_axil_rready;
        end
    end

    assign s_axil_awready = m_axil_awready;
    assign s_axil_wready = m_axil_wready;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_arready = m_axil_arready;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;

    assign m_axil_awaddr = s_axil_awaddr_reg;
    assign m_axil_awprot = s_axil_awprot_reg;
    assign m_axil_awvalid = s_axil_awvalid_reg;
    assign m_axil_wdata = s_axil_wdata_reg;
    assign m_axil_wstrb = s_axil_wstrb_reg;
    assign m_axil_wvalid = s_axil_wvalid_reg;
    assign m_axil_bready = s_axil_bready;
    assign m_axil_araddr = s_axil_araddr_reg;
    assign m_axil_arprot = s_axil_arprot_reg;
    assign m_axil_arvalid = s_axil_arvalid_reg;
    assign m_axil_rready = s_axil_rready_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

`include "defines.sv"

module testbench();
    reg clk;
    reg reset;
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] write_data;
    wire [4:0] write_reg;
    wire write_enable;
    wire [31:0] read_data1_port_b;
    wire [31:0] read_data2_port_b;
    wire [31:0] write_data_port_b;
    wire [4:0] write_reg_port_b;
    wire write_enable_port_b;
    wire [31:0] read_data1_port_c;
    wire [31:0] read_data2_port_c;
    wire [31:0] write_data_port_c;
    wire [4:0] write_reg_port_c;
    wire write_enable_port_c;
    wire [31:0] read_data1_port_d;
    wire [31:0] read_data2_port_d;
    wire [31:0] write_data_port_d;
    wire [4:0] write_reg_port_d;
    wire write_enable_port_d;
    wire [31:0] read_data1_port_e;
    wire [31:0] read_data2_port_e;
    wire [31:0] write_data_port_e;
    wire [4:0] write_reg_port_e;
    wire write_enable_port_e;
    wire [31:0] read_data1_port_f;
    wire [31:0] read_data2_port_f;
    wire [31:0] write_data_port_f;
    wire [4:0] write_reg_port_f;
    wire write_enable_port_f;
    wire [31:0] read_data1_port_g;
    wire [31:0] read_data2_port_g;
    wire [31:0] write_data_port_g;
    wire [4:0] write_reg_port_g;
    wire write_enable_port_g;
    wire [31:0] read_data1_port_h;
    wire [31:0] read_data2_port_h;
    wire [31:0] write_data_port_h;
    wire [4:0] write_reg_port_h;
    wire write_enable_port_h;
    wire [31:0] read_data1_port_i;
    wire [31:0] read_data2_port_i;
    wire [31:0] write_data_port_i;
    wire [4:0] write_reg_port_i;
    wire write_enable_port_i;
    wire [31:0] read_data1_port_j;
    wire [31:0] read_data2_port_j;
    wire [31:0] write_data_port_j;
    wire [4:0] write_reg_port_j;
    wire write_enable_port_j;
    wire [31:0] read_data1_port_k;
    wire [31:0] read_data2_port_k;
    wire [31:0] write_data_port_k;
    wire [4:0] write_reg_port_k;
    wire write_enable_port_k;
    wire [31:0] read_data1_port_l;
    wire [31:0] read_data2_port_l;
    wire [31:0] write_data_port_l;
    wire [4:0] write_reg_port_l;
    wire write_enable_port_l;
    wire [31:0] read_data1_port_m;
    wire [31:0] read_data2_port_m;
    wire [31:0] write_data_port_m;
    wire [4:0] write_reg_port_m;
    wire write_enable_port_m;
    wire [31:0] read_data1_port_n;
    wire [31:0] read_data2_port_n;
    wire [31:0] write_data_port_n;
    wire [4:0] write_reg_port_n;
    wire write_enable_port_n;
    wire [31:0] read_data1_port_o;
    wire [31:0] read_data2_port_o;
    wire [31:0] write_data_port_o;
    wire [4:0] write_reg_port_o;
    wire write_enable_port_o;
    wire [31:0] read_data1_port_p;
    wire [31:0] read_data2_port_p;
    wire [31:0] write_data_port_p;
    wire [4:0] write_reg_port_p;
    wire write_enable_port_p;
    wire [31:0] read_data1_port_q;
    wire [31:0] read_data2_port_q;
    wire [31:0] write_data_port_q;
    wire [4:0] write_reg_port_q;
    wire write_enable_port_q;
    wire [31:0] read_data1_port_r;
    wire [31:0] read_data2_port_r;
    wire [31:0] write_data_port_r;
    wire [4:0] write_reg_port_r;
    wire write_enable_port_r;
    wire [31:0] read_data1_port_s;
    wire [31:0] read_data2_port_s;
    wire [31:0] write_data_port_s;
    wire [4:0] write_reg_port_s;
    wire write_enable_port_s;
    wire [31:0] read_data1_port_t;
    wire [31:0] read_data2_port_t;
    wire [31:0] write_data_port_t;
    wire [4:0] write_reg_port_t;
    wire write_enable_port_t;
    wire [31:0] read_data1_port_u;
    wire [31:0] read_data2_port_u;
    wire [31:0] write_data_port_u;
    wire [4:0] write_reg_port_u;
    wire write_enable_port_u;
    wire [31:0] read_data1_port_v;
    wire [31:0] read_data2_port_v;
    wire [31:0] write_data_port_v;
    wire [4:0] write_reg_port_v;
    wire write_enable_port_v;
    wire [31:0] read_data1_port_w;
    wire [31:0] read_data2_port_w;
    wire [31:0] write_data_port_w;
    wire [4:0] write_reg_port_w;
    wire write_enable_port_w;
    wire [31:0] read_data1_port_x;
    wire [31:0] read_data2_port_x;
    wire [31:0] write_data_port_x;
    wire [4:0] write_reg_port_x;
    wire write_enable_port_x;
    wire [31:0] read_data1_port_y;
    wire [31:0] read_data2_port_y;
    wire [31:0] write_data_port_y;
    wire [4:0] write_reg_port_y;
    wire write_enable_port_y;
    wire [31:0] read_data1_port_z;
    wire [31:0] read_data2_port_z;
    wire [31:0] write_data_port_z;
    wire [4:0] write_reg_port_z;
    wire write_enable_port_z;
    wire [31:0] read_data1_port_aa;
    wire [31:0] read_data2_port_aa;
    wire [31:0] write_data_port_aa;
    wire [4:0] write_reg_port_aa;
    wire write_enable_port_aa;
    wire [31:0] read_data1_port_bb;
    wire [31:0] read_data2_port_bb;
    wire [31:0] write_data_port_bb;
    wire [4:0] write_reg_port_bb;
    wire write_enable_port_bb;
    wire [31:0] read_data1_port_cc;
    wire [31:0] read_data2_port_cc;
    wire [31:0] write_data_port_cc;
    wire [4:0] write_reg_port_cc;
    wire write_enable_port_cc;
    wire [31:0] read_data1_port_dd;
    wire [31:0] read_data2_port_dd;
    wire [31:0] write_data_port_dd;
    wire [4:0] write_reg_port_dd;
    wire write_enable_port_dd;
    wire [31:0] read_data1_port_ee;
    wire [31:0] read_data2_port_ee;
    wire [31:0] write_data_port_ee;
    wire [4:0] write_reg_port_ee;
    wire write_enable_port_ee;
    wire [31:0] read_data1_port_ff;
    wire [31:0] read_data2_port_ff;
    wire [31:0] write_data_port_ff;
    wire [4:0] write_reg_port_ff;
    wire write_enable_port_ff;
    wire [31:0] read_data1_port_10;
    wire [31:0] read_data2_port_10;
    wire [31:0] write_data_port_10;
    wire [4:0] write_reg_port_10;
    wire write_enable_port_10;
    wire [31:0] read_data1_port_11;
    wire [31:0] read_data2_port_11;
    wire [31:0] write_data_port_11;
    wire [4:0] write_reg_port_11;
    wire write_enable_port_11;
    wire [31:0] read_data1_port_12;
    wire [31:0] read_data2_port_12;
    wire [31:0] write_data_port_12;
    wire [4:0] write_reg_port_12;
    wire write_enable_port_12;
    wire [31:0] read_data1_port_13;
    wire [31:0] read_data2_port_13;
    wire [31:0] write_data_port_13;
    wire [4:0] write_reg_port_13;
    wire write_enable_port_13;
    wire [31:0] read_data1_port_14;
    wire [31:0] read_data2_port_14;
    wire [31:0] write_data_port_14;
    wire [4:0] write_reg_port_14;
    wire write_enable_port_14;
    wire [31:0] read_data1_port_15;
    wire [31:0] read_data2_port_15;
    wire [31:0] write_data_port_15;
    wire [4:0] write_reg_port_15;
    wire write_enable_port_15;
    wire [31:0] read_data1_port_16;
    wire [31:0] read_data2_port_16;
    wire [31:0] write_data_port_16;
    wire [4:0] write_reg_port_16;
    wire write_enable_port_16;
    wire [31:0] read_data1_port_17;
    wire [31:0] read_data2_port_17;
    wire [31:0] write_data_port_17;
    wire [4:0] write_reg_port_17;
    wire write_enable_port_17;
    wire [31:0] read_data1_port_18;
    wire [31:0] read_data2_port_18;
    wire [31:0] write_data_port_18;
    wire [4:0] write_reg_port_18;
    wire write_enable_port_18;
    wire [31:0] read_data1_port_19;
    wire [31:0] read_data2_port_19;
    wire [31:0] write_data_port_19;
    wire [4:0] write_reg_port_19;
    wire write_enable_port_19;
    wire [31:0] read_data1_port_1a;
    wire [31:0] read_data2_port_1a;
    wire [31:0] write_data_port_1a;
    wire [4:0] write_reg_port_1a;
    wire write_enable_port_1a;
    wire [31:0] read_data1_port_1b;
    wire [31:0] read_data2_port_1b;
    wire [31:0] write_data_port_1b;
    wire [4:0] write_reg_port_1b;
    wire write_enable_port_1b;
    wire [31:0] read_data1_port_1c;
    wire [31:0] read_data2_port_1c;
    wire [31:0] write_data_port_1c;
    wire [4:0] write_reg_port_1c;
    wire write_enable_port_1c;
    wire [31:0] read_data1_port_1d;
    wire [31:0] read_data2_port_1d;
    wire [31:0] write_data_port_1d;
    wire [4:0] write_reg_port_1d;
    wire write_enable_port_1d;
    wire [31:0] read_data1_port_1e;
    wire [31:0] read_data2_port_1e;
    wire [31:0] write_data_port_1e;
    wire [4:0] write_reg_port_1e;
    wire write_enable_port_1e;
    wire [31:0] read_data1_port_1f;
    wire [31:0] read_data2_port_1f;
    wire [31:0] write_data_port_1f;
    wire [4:0] write_reg_port_1f;
    wire write_enable_port_1f;
    wire [31:0] read_data1_port_20;
    wire [31:0] read_data2_port_20;
    wire [31:0] write_data_port_20;
    wire [4:0] write_reg_port_20;
    wire write_enable_port_20;
    wire [31:0] read_data1_port_21;
    wire [31:0] read_data2_port_21;
    wire [31:0] write_data_port_21;
    wire [4:0] write_reg_port_21;
    wire write_enable_port_21;
    wire [31:0] read_data1_port_22;
    wire [31:0] read_data2_port_22;
    wire [31:0] write_data_port_22;
    wire [4:0] write_reg_port_22;
    wire write_enable_port_22;
    wire [31:0] read_data1_port_23;
    wire [31:0] read_data2_port_23;
    wire [31:0] write_data_port_23;
    wire [4:0] write_reg_port_23;
    wire write_enable_port_23;
    wire [31:0] read_data1_port_24;
    wire [31:0] read_data2_port_24;
    wire [31:0] write_data_port_24;
    wire [4:0] write_reg_port_24;
    wire write_enable_port_24;
    wire [31:0] read_data1_port_25;
    wire [31:0] read_data2_port_25;
    wire [31:0] write_data_port_25;
    wire [4:0] write_reg_port_25;
    wire write_enable_port_25;
    wire [31:0] read_data1_port_26;
    wire [31:0] read_data2_port_26;
    wire [31:0] write_data_port_26;
    wire [4:0] write_reg_port_26;
    wire write_enable_port_26;
    wire [31:0] read_data1_port_27;
    wire [31:0] read_data2_port_27;
    wire [31:0] write_data_port_27;
    wire [4:0] write_reg_port_27;
    wire write_enable_port_27;
    wire [31:0] read_data1_port_28;
    wire [31:0] read_data2_port_28;
    wire [31:0] write_data_port_28;
    wire [4:0] write_reg_port_28;
    wire write_enable_port_28;
    wire [31:0] read_data1_port_29;
    wire [31:0] read_data2_port_29;
    wire [31:0] write_data_port_29;
    wire [4:0] write_reg_port_29;
    wire write_enable_port_29;
    wire [31:0] read_data1_port_2a;
    wire [31:0] read_data2_port_2a;
    wire [31:0] write_data_port_2a;
    wire [4:0] write_reg_port_2a;
    wire write_enable_port_2a;
    wire [31:0] read_data1_port_2b;
    wire [31:0] read_data2_port_2b;
    wire [31:0] write_data_port_2b;
    wire [4:0] write_reg_port_2b;
    wire write_enable_port_2b;
    wire [31:0] read_data1_port_2c;
    wire [31:0] read_data2_port_2c;
    wire [31:0] write_data_port_2c;
    wire [4:0] write_reg_port_2c;
    wire write_enable_port_2c;
    wire [31:0] read_data1_port_2d;
    wire [31:0] read_data2_port_2d;
    wire [31:0] write_data_port_2d;
    wire [4:0] write_reg_port_2d;
    wire write_enable_port_2d;
    wire [31:0] read_data1_port_2e;
    wire [31:0] read_data2_port_2e;
    wire [31:0] write_data_port_2e;
    wire [4:0] write_reg_port_2e;
    wire write_enable_port_2e;
    wire [31:0] read_data1_port_2f;
    wire [31:0] read_data2_port_2f;
    wire [31:0] write_data_port_2f;
    wire [4:0] write_reg_port_2f;
    wire write_enable_port_2f;
    wire [31:0] read_data1_port_30;
    wire [31:0] read_data2_port_30;
    wire [31:0] write_data_port_30;
    wire [4:0] write_reg_port_30;
    wire write_enable_port_30;
    wire [31:0] read_data1_port_31;
    wire [31:0] read_data2_port_31;
    wire [31:0] write_data_port_31;
    wire [4:0] write_reg_port_31;
    wire write_enable_port_31;
    wire [31:0] read_data1_port_32;
    wire [31:0] read_data2_port_32;
    wire [31:0] write_data_port_32;
    wire [4:0] write_reg_port_32;
    wire write_enable_port_32;
    wire [31:0] read_data1_port_33;
    wire [31:0] read_data2_port_33;
    wire [31:0] write_data_port_33;
    wire [4:0] write_reg_port_33;
    wire write_enable_port_33;
    wire [31:0] read_data1_port_34;
    wire [31:0] read_data2_port_34;
    wire [31:
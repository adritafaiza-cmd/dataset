The AXI4-Lite clock-domain bridge can be implemented using a simple FIFO-based bridge. The bridge has two FIFOs, one for write requests and one for read requests. The write request FIFO is connected to the slave clock domain, while the read request FIFO is connected to the master clock domain. The write response FIFO is connected to the master clock domain, while the read response FIFO is connected to the slave clock domain.

The Verilog code for the AXI4-Lite clock-domain bridge is as follows:

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

// Write request FIFO
reg [ADDR_WIDTH-1:0] awaddr_fifo [0:1];
reg [2:0] awprot_fifo [0:1];
reg awvalid_fifo [0:1];
wire awready_fifo [0:1];

// Write response FIFO
reg [1:0] bresp_fifo [0:1];
reg bvalid_fifo [0:1];
wire bready_fifo [0:1];

// Read request FIFO
reg [ADDR_WIDTH-1:0] araddr_fifo [0:1];
reg [2:0] arprot_fifo [0:1];
reg arvalid_fifo [0:1];
wire arready_fifo [0:1];

// Read response FIFO
reg [DATA_WIDTH-1:0] rdata_fifo [0:1];
reg [1:0] rresp_fifo [0:1];
reg rvalid_fifo [0:1];
wire rready_fifo [0:1];

// Write request FIFO
always @(posedge s_clk) begin
    if (s_rst) begin
        awaddr_fifo[0] <= 0;
        awprot_fifo[0] <= 0;
        awvalid_fifo[0] <= 0;
    end else begin
        awaddr_fifo[0] <= s_axil_awaddr;
        awprot_fifo[0] <= s_axil_awprot;
        awvalid_fifo[0] <= s_axil_awvalid;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        awaddr_fifo[1] <= 0;
        awprot_fifo[1] <= 0;
        awvalid_fifo[1] <= 0;
    end else begin
        awaddr_fifo[1] <= awaddr_fifo[0];
        awprot_fifo[1] <= awprot_fifo[0];
        awvalid_fifo[1] <= awvalid_fifo[0];
    end
end

assign s_axil_awready = awready_fifo[0];
assign m_axil_awaddr = awaddr_fifo[1];
assign m_axil_awprot = awprot_fifo[1];
assign m_axil_awvalid = awvalid_fifo[1];
assign awready_fifo[0] = m_axil_awready;

// Write response FIFO
always @(posedge m_clk) begin
    if (m_rst) begin
        bresp_fifo[0] <= 0;
        bvalid_fifo[0] <= 0;
    end else begin
        bresp_fifo[0] <= m_axil_bresp;
        bvalid_fifo[0] <= m_axil_bvalid;
    end
end

always @(posedge s_clk) begin
    if (s_rst) begin
        bresp_fifo[1] <= 0;
        bvalid_fifo[1] <= 0;
    end else begin
        bresp_fifo[1] <= bresp_fifo[0];
        bvalid_fifo[1] <= bvalid_fifo[0];
    end
end

assign m_axil_bresp = bresp_fifo[0];
assign m_axil_bvalid = bvalid_fifo[0];
assign bready_fifo[0] = s_axil_bready;
assign s_axil_bresp = bresp_fifo[1];
assign s_axil_bvalid = bvalid_fifo[1];
assign bready_fifo[1] = m_axil_bready;

// Read request FIFO
always @(posedge s_clk) begin
    if (s_rst) begin
        araddr_fifo[0] <= 0;
        arprot_fifo[0] <= 0;
        arvalid_fifo[0] <= 0;
    end else begin
        araddr_fifo[0] <= s_axil_araddr;
        arprot_fifo[0] <= s_axil_arprot;
        arvalid_fifo[0] <= s_axil_arvalid;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        araddr_fifo[1] <= 0;
        arprot_fifo[1] <= 0;
        arvalid_fifo[1] <= 0;
    end else begin
        araddr_fifo[1] <= araddr_fifo[0];
        arprot_fifo[1] <= arprot_fifo[0];
        arvalid_fifo[1] <= arvalid_fifo[0];
    end
end

assign s_axil_arready = arready_fifo[0];
assign m_axil_araddr = araddr_fifo[1];
assign m_axil_arprot = arprot_fifo[1];
assign m_axil_arvalid = arvalid_fifo[1];
assign arready_fifo[0] = m_axil_arready;

// Read response FIFO
always @(posedge m_clk) begin
    if (m_rst) begin
        rdata_fifo[0] <= 0;
        rresp_fifo[0] <= 0;
        rvalid_fifo[0] <= 0;
    end else begin
        rdata_fifo[0] <= m_axil_rdata;
        rresp_fifo[0] <= m_axil_rresp;
        rvalid_fifo[0] <= m_axil_rvalid;
    end
end

always @(posedge s_clk) begin
    if (s_rst) begin
        rdata_fifo[1] <= 0;
        rresp_fifo[1] <= 0;
        rvalid_fifo[1] <= 0;
    end else begin
        rdata_fifo[1] <= rdata_fifo[0];
        rresp_fifo[1] <= rresp_fifo[0];
        rvalid_fifo[1] <= rvalid_fifo[0];
    end
end

assign m_axil_rdata = rdata_fifo[0];
assign m_axil_rresp = rresp_fifo[0];
assign m_axil_rvalid = rvalid_fifo[0];
assign rready_fifo[0] = s_axil_rready;
assign s_axil_rdata = rdata_fifo[1];
assign s_axil_rresp = rresp_fifo[1];
assign s_axil_rvalid = rvalid_fifo[1];
assign rready_fifo[1] = m_axil_rready;

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
        out <= 0;
        for (int i = 0; i < 8; i = i + 1) begin
            shift_reg[i] <= 0;
        end
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[7];
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
        out <= 0;
        for (int i = 0; i < 8; i = i + 1) begin
            shift_reg[i] <= 0;
        end
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[7];
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
    #10 $finish;
end

always #5 clk = ~clk;

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
        out <= 0;
        for (int i = 0; i < 8; i = i + 1) begin
            shift_reg[i] <= 0;
        end
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[7];
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
    #10 $finish;
end

always #5 clk = ~clk;

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
        out <= 0;
        for (int i = 0; i < 8; i = i + 1) begin
            shift_reg[i] <= 0;
        end
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[7];
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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 $finish;
end

always #5 clk = ~clk;

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
    reset = 
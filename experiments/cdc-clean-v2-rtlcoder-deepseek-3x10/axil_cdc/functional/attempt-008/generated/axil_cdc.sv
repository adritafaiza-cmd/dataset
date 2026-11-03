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

    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg bready_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;
    reg rready_reg;

    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            bready_reg <= 0;
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
            bready_reg <= s_axil_bready;
            araddr_reg <= s_axil_araddr;
            arprot_reg <= s_axil_arprot;
            arvalid_reg <= s_axil_arvalid;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            rdata_reg <= 0;
            rresp_reg <= 0;
            rvalid_reg <= 0;
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m_axil_bready <= 0;
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
            m_axil_bresp <= 0;
            m_axil_bvalid <= 0;
            m_axil_rdata <= 0;
            m_axil_rresp <= 0;
            m_axil_rvalid <= 0;
            m_axil_rready <= 0;
        end else begin
            rdata_reg <= m_axil_rdata;
            rresp_reg <= m_axil_rresp;
            rvalid_reg <= m_axil_rvalid;
            m_axil_awaddr <= awaddr_reg;
            m_axil_awprot <= awprot_reg;
            m_axil_awvalid <= awvalid_reg;
            m_axil_wdata <= wdata_reg;
            m_axil_wstrb <= wstrb_reg;
            m_axil_wvalid <= wvalid_reg;
            m_axil_bready <= bready_reg;
            m_axil_araddr <= araddr_reg;
            m_axil_arprot <= arprot_reg;
            m_axil_arvalid <= arvalid_reg;
            m_axil_bresp <= bresp_reg;
            m_axil_bvalid <= bvalid_reg;
            m_axil_rdata <= rdata_reg;
            m_axil_rresp <= rresp_reg;
            m_axil_rvalid <= rvalid_reg;
            m_axil_rready <= rready_reg;
        end
    end

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_bresp <= 0;
            s_axil_bvalid <= 0;
            s_axil_arready <= 0;
            s_axil_rdata <= 0;
            s_axil_rresp <= 0;
            s_axil_rvalid <= 0;
        end else begin
            s_axil_awready <= m_axil_awready;
            s_axil_wready <= m_axil_wready;
            s_axil_bresp <= m_axil_bresp;
            s_axil_bvalid <= m_axil_bvalid;
            s_axil_arready <= m_axil_arready;
            s_axil_rdata <= m_axil_rdata;
            s_axil_rresp <= m_axil_rresp;
            s_axil_rvalid <= m_axil_rvalid;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            rready_reg <= 0;
        end else begin
            rready_reg <= s_axil_rready;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            bresp_reg <= 0;
            bvalid_reg <= 0;
        end else begin
            if (m_axil_awready && m_axil_awvalid) begin
                bresp_reg <= 0;
                bvalid_reg <= 0;
            end else if (m_axil_wready && m_axil_wvalid) begin
                bresp_reg <= 0;
                bvalid_reg <= 0;
            end else if (m_axil_rready && m_axil_rvalid) begin
                bresp_reg <= 0;
                bvalid_reg <= 0;
            end else if (m_axil_bready && m_axil_bvalid) begin
                bresp_reg <= 0;
                bvalid_reg <= 0;
            end else if (m_axil_bresp != 0) begin
                bresp_reg <= m_axil_bresp;
                bvalid_reg <= 1;
            end
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
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
    in = 8'b0;
    #10 reset = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end
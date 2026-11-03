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

    // Internal signals
    reg [ADDR_WIDTH-1:0]  awaddr_reg;
    reg [2:0]             awprot_reg;
    reg                   awvalid_reg;
    reg [DATA_WIDTH-1:0]  wdata_reg;
    reg [STRB_WIDTH-1:0]  wstrb_reg;
    reg                   wvalid_reg;
    reg [ADDR_WIDTH-1:0]  araddr_reg;
    reg [2:0]             arprot_reg;
    reg                   arvalid_reg;
    wire                  awready_int;
    wire                  wready_int;
    wire [1:0]            bresp_int;
    wire                  bvalid_int;
    wire                  arready_int;
    wire [DATA_WIDTH-1:0] rdata_int;
    wire [1:0]            rresp_int;
    wire                  rvalid_int;

    // AXI4-Lite slave interface
    assign s_axil_awready = awready_int;
    assign s_axil_wready = wready_int;
    assign s_axil_bresp = bresp_int;
    assign s_axil_bvalid = bvalid_int;
    assign s_axil_arready = arready_int;
    assign s_axil_rdata = rdata_int;
    assign s_axil_rresp = rresp_int;
    assign s_axil_rvalid = rvalid_int;

    // AXI4-Lite master interface
    assign m_axil_awaddr = awaddr_reg;
    assign m_axil_awprot = awprot_reg;
    assign m_axil_awvalid = awvalid_reg;
    assign m_axil_wdata = wdata_reg;
    assign m_axil_wstrb = wstrb_reg;
    assign m_axil_wvalid = wvalid_reg;
    assign m_axil_bready = 1'b1;
    assign m_axil_araddr = araddr_reg;
    assign m_axil_arprot = arprot_reg;
    assign m_axil_arvalid = arvalid_reg;
    assign m_axil_rready = 1'b1;

    // Write channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
        end else begin
            if (s_axil_awvalid && awready_int) begin
                awaddr_reg <= s_axil_awaddr;
                awprot_reg <= s_axil_awprot;
                awvalid_reg <= 1;
            end else if (s_axil_wvalid && wready_int) begin
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                wvalid_reg <= 1;
            end else begin
                awvalid_reg <= 0;
                wvalid_reg <= 0;
            end
        end
    end

    // Read channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
        end else begin
            if (s_axil_arvalid && arready_int) begin
                araddr_reg <= s_axil_araddr;
                arprot_reg <= s_axil_arprot;
                arvalid_reg <= 1;
            end else begin
                arvalid_reg <= 0;
            end
        end
    end

    // Response channel
    always @(posedge m_clk) begin
        if (m_rst) begin
            bresp_int <= 0;
            bvalid_int <= 0;
            rdata_int <= 0;
            rresp_int <= 0;
            rvalid_int <= 0;
        end else begin
            if (m_axil_awready) begin
                bresp_int <= 0;
                bvalid_int <= 0;
            end else if (m_axil_wready) begin
                bresp_int <= 0;
                bvalid_int <= 0;
            end else if (m_axil_arready) begin
                rdata_int <= m_axil_rdata;
                rresp_int <= m_axil_rresp;
                rvalid_int <= m_axil_rvalid;
            end
        end
    end

    // AXI4-Lite slave interface
    assign awready_int = m_axil_awready;
    assign wready_int = m_axil_wready;
    assign bresp_int = m_axil_bresp;
    assign bvalid_int = m_axil_bvalid;
    assign arready_int = m_axil_arready;
    assign rdata_int = m_axil_rdata;
    assign rresp_int = m_axil_rresp;
    assign rvalid_int = m_axil_rvalid;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b010
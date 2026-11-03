The following Verilog code implements an AXI4-Lite clock-domain bridge using a handshake-based approach. The code uses two FIFOs to store the incoming transactions and two handshake signals to synchronize the transactions between the two clock domains.

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

    // FIFO for write transactions
    reg [ADDR_WIDTH-1:0] awaddr_fifo [0:1];
    reg [2:0] awprot_fifo [0:1];
    reg awvalid_fifo [0:1];
    reg awready_fifo [0:1];
    reg [DATA_WIDTH-1:0] wdata_fifo [0:1];
    reg [STRB_WIDTH-1:0] wstrb_fifo [0:1];
    reg wvalid_fifo [0:1];
    reg wready_fifo [0:1];
    reg [1:0] bresp_fifo [0:1];
    reg bvalid_fifo [0:1];
    reg bready_fifo [0:1];

    // FIFO for read transactions
    reg [ADDR_WIDTH-1:0] araddr_fifo [0:1];
    reg [2:0] arprot_fifo [0:1];
    reg arvalid_fifo [0:1];
    reg arready_fifo [0:1];
    reg [DATA_WIDTH-1:0] rdata_fifo [0:1];
    reg [1:0] rresp_fifo [0:1];
    reg rvalid_fifo [0:1];
    reg rready_fifo [0:1];

    // Handshake signals
    reg aw_handshake_s;
    reg w_handshake_s;
    reg b_handshake_s;
    reg ar_handshake_s;
    reg r_handshake_s;

    // Write transaction
    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_fifo[0] <= 0;
            awprot_fifo[0] <= 0;
            awvalid_fifo[0] <= 0;
            awready_fifo[0] <= 0;
            wdata_fifo[0] <= 0;
            wstrb_fifo[0] <= 0;
            wvalid_fifo[0] <= 0;
            wready_fifo[0] <= 0;
            bresp_fifo[0] <= 0;
            bvalid_fifo[0] <= 0;
            bready_fifo[0] <= 0;
        end else begin
            awaddr_fifo[0] <= s_axil_awaddr;
            awprot_fifo[0] <= s_axil_awprot;
            awvalid_fifo[0] <= s_axil_awvalid;
            awready_fifo[0] <= aw_handshake_s;
            wdata_fifo[0] <= s_axil_wdata;
            wstrb_fifo[0] <= s_axil_wstrb;
            wvalid_fifo[0] <= s_axil_wvalid;
            wready_fifo[0] <= w_handshake_s;
            bresp_fifo[0] <= s_axil_bresp;
            bvalid_fifo[0] <= s_axil_bvalid;
            bready_fifo[0] <= s_axil_bready;
        end
    end

    // Read transaction
    always @(posedge s_clk) begin
        if (s_rst) begin
            araddr_fifo[0] <= 0;
            arprot_fifo[0] <= 0;
            arvalid_fifo[0] <= 0;
            arready_fifo[0] <= 0;
            rdata_fifo[0] <= 0;
            rresp_fifo[0] <= 0;
            rvalid_fifo[0] <= 0;
            rready_fifo[0] <= 0;
        end else begin
            araddr_fifo[0] <= s_axil_araddr;
            arprot_fifo[0] <= s_axil_arprot;
            arvalid_fifo[0] <= s_axil_arvalid;
            arready_fifo[0] <= ar_handshake_s;
            rdata_fifo[0] <= s_axil_rdata;
            rresp_fifo[0] <= s_axil_rresp;
            rvalid_fifo[0] <= s_axil_rvalid;
            rready_fifo[0] <= r_handshake_s;
        end
    end

    // Write handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            aw_handshake_s <= 0;
            w_handshake_s <= 0;
            b_handshake_s <= 0;
        end else begin
            if (awvalid_fifo[0] && awready_fifo[1]) begin
                aw_handshake_s <= 1;
            end else if (wvalid_fifo[0] && wready_fifo[1]) begin
                w_handshake_s <= 1;
            end else if (bvalid_fifo[1] && bready_fifo[0]) begin
                b_handshake_s <= 1;
            end else begin
                aw_handshake_s <= 0;
                w_handshake_s <= 0;
                b_handshake_s <= 0;
            end
        end
    end

    // Read handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            ar_handshake_s <= 0;
            r_handshake_s <= 0;
        end else begin
            if (arvalid_fifo[0] && arready_fifo[1]) begin
                ar_handshake_s <= 1;
            end else if (rvalid_fifo[1] && rready_fifo[0]) begin
                r_handshake_s <= 1;
            end else begin
                ar_handshake_s <= 0;
                r_handshake_s <= 0;
            end
        end
    end

    // Output signals
    assign s_axil_awready = awready_fifo[1];
    assign s_axil_wready = wready_fifo[1];
    assign s_axil_bresp = bresp_fifo[1];
    assign s_axil_bvalid = bvalid_fifo[1];
    assign s_axil_arready = arready_fifo[1];
    assign s_axil_rdata = rdata_fifo[1];
    assign s_axil_rresp = rresp_fifo[1];
    assign s_axil_rvalid = rvalid_fifo[1];

    // Master signals
    assign m_axil_awaddr = awaddr_fifo[1];
    assign m_axil_awprot = awprot_fifo[1];
    assign m_axil_awvalid = awvalid_fifo[1];
    assign awready_fifo[1] = m_axil_awready;
    assign m_axil_wdata = wdata_fifo[1];
    assign m_axil_wstrb = wstrb_fifo[1];
    assign m_axil_wvalid = wvalid_fifo[1];
    assign wready_fifo[1] = m_axil_wready;
    assign m_axil_bresp = bresp_fifo[1];
    assign m_axil_bvalid = bvalid_fifo[1];
    assign bready_fifo[1] = m_axil_bready;
    assign m_axil_araddr = araddr_fifo[1];
    assign m_axil_arprot = arprot_fifo[1];
    assign m_axil_arvalid = arvalid_fifo[1];
    assign arready_fifo[1] = m_axil_arready;
    assign m_axil_rdata = rdata_fifo[1];
    assign m_axil_rresp = rresp_fifo[1];
    assign m_axil_rvalid = rvalid_fifo[1];
    assign rready_fifo[1] = m_axil_rready;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #
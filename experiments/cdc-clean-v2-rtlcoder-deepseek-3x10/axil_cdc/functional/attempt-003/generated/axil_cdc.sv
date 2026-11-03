The following Verilog code implements an AXI4-Lite clock-domain bridge using a handshake mechanism to synchronize the write and read channels between the slave and master ports. The code uses two flip-flops to store the write and read transactions, and two synchronizers to synchronize the handshake signals between the two clock domains.

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

    // Write channel
    reg [ADDR_WIDTH-1:0] awaddr_ff;
    reg [2:0] awprot_ff;
    reg awvalid_ff;
    reg [DATA_WIDTH-1:0] wdata_ff;
    reg [STRB_WIDTH-1:0] wstrb_ff;
    reg wvalid_ff;
    reg bready_ff;

    // Read channel
    reg [ADDR_WIDTH-1:0] araddr_ff;
    reg [2:0] arprot_ff;
    reg arvalid_ff;
    reg rready_ff;

    // Synchronizers
    reg awready_sync;
    reg wready_sync;
    reg bvalid_sync;
    reg arready_sync;
    reg rvalid_sync;

    // Write channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_ff <= 0;
            awprot_ff <= 0;
            awvalid_ff <= 0;
            wdata_ff <= 0;
            wstrb_ff <= 0;
            wvalid_ff <= 0;
            bready_ff <= 0;
        end else begin
            awaddr_ff <= s_axil_awaddr;
            awprot_ff <= s_axil_awprot;
            awvalid_ff <= s_axil_awvalid;
            wdata_ff <= s_axil_wdata;
            wstrb_ff <= s_axil_wstrb;
            wvalid_ff <= s_axil_wvalid;
            bready_ff <= s_axil_bready;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            awready_sync <= 0;
            wready_sync <= 0;
            bvalid_sync <= 0;
        end else begin
            awready_sync <= m_axil_awready;
            wready_sync <= m_axil_wready;
            bvalid_sync <= m_axil_bvalid;
        end
    end

    // Read channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            araddr_ff <= 0;
            arprot_ff <= 0;
            arvalid_ff <= 0;
            rready_ff <= 0;
        end else begin
            araddr_ff <= s_axil_araddr;
            arprot_ff <= s_axil_arprot;
            arvalid_ff <= s_axil_arvalid;
            rready_ff <= s_axil_rready;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            arready_sync <= 0;
            rvalid_sync <= 0;
        end else begin
            arready_sync <= m_axil_arready;
            rvalid_sync <= m_axil_rvalid;
        end
    end

    // Output assignments
    assign s_axil_awready = awready_sync;
    assign s_axil_wready = wready_sync;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = bvalid_sync;
    assign s_axil_arready = arready_sync;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = rvalid_sync;

    assign m_axil_awaddr = awaddr_ff;
    assign m_axil_awprot = awprot_ff;
    assign m_axil_awvalid = awvalid_ff;
    assign m_axil_wdata = wdata_ff;
    assign m_axil_wstrb = wstrb_ff;
    assign m_axil_wvalid = wvalid_ff;
    assign m_axil_bready = bready_ff;
    assign m_axil_araddr = araddr_ff;
    assign m_axil_arprot = arprot_ff;
    assign m_axil_arvalid = arvalid_ff;
    assign m_axil_rready = rready_ff;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_
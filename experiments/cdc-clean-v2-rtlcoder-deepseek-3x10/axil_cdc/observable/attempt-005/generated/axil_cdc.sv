The following Verilog code implements an AXI4-Lite clock-domain bridge using a handshake mechanism between the two clock domains. The code is written in Verilog-2001 and uses a handshake mechanism to synchronize the AXI4-Lite signals between the two clock domains.

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

reg [DATA_WIDTH-1:0] s_axil_rdata_reg;
reg [1:0] s_axil_rresp_reg;
reg s_axil_rvalid_reg;

reg [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
reg [2:0] m_axil_awprot_reg;
reg m_axil_awvalid_reg;

reg [DATA_WIDTH-1:0] m_axil_wdata_reg;
reg [STRB_WIDTH-1:0] m_axil_wstrb_reg;
reg m_axil_wvalid_reg;

reg [1:0] m_axil_bresp_reg;
reg m_axil_bvalid_reg;

reg [ADDR_WIDTH-1:0] m_axil_araddr_reg;
reg [2:0] m_axil_arprot_reg;
reg m_axil_arvalid_reg;

reg [DATA_WIDTH-1:0] m_axil_rdata_reg;
reg [1:0] m_axil_rresp_reg;
reg m_axil_rvalid_reg;

reg [DATA_WIDTH-1:0] s_axil_wdata_reg;
reg [STRB_WIDTH-1:0] s_axil_wstrb_reg;
reg s_axil_wvalid_reg;

reg [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
reg [2:0] s_axil_awprot_reg;
reg s_axil_awvalid_reg;

reg [ADDR_WIDTH-1:0] s_axil_araddr_reg;
reg [2:0] s_axil_arprot_reg;
reg s_axil_arvalid_reg;

reg [1:0] s_axil_bresp_reg;
reg s_axil_bvalid_reg;

reg [DATA_WIDTH-1:0] s_axil_rdata_reg;
reg [1:0] s_axil_rresp_reg;
reg s_axil_rvalid_reg;

always @(posedge s_clk) begin
    if (s_rst) begin
        s_axil_rdata_reg <= 0;
        s_axil_rresp_reg <= 0;
        s_axil_rvalid_reg <= 0;
    end else begin
        s_axil_rdata_reg <= m_axil_rdata_reg;
        s_axil_rresp_reg <= m_axil_rresp_reg;
        s_axil_rvalid_reg <= m_axil_rvalid_reg;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_axil_awaddr_reg <= 0;
        m_axil_awprot_reg <= 0;
        m_axil_awvalid_reg <= 0;
        m_axil_wdata_reg <= 0;
        m_axil_wstrb_reg <= 0;
        m_axil_wvalid_reg <= 0;
        m_axil_bresp_reg <= 0;
        m_axil_bvalid_reg <= 0;
        m_axil_araddr_reg <= 0;
        m_axil_arprot_reg <= 0;
        m_axil_arvalid_reg <= 0;
        m_axil_rdata_reg <= 0;
        m_axil_rresp_reg <= 0;
        m_axil_rvalid_reg <= 0;
    end else begin
        m_axil_awaddr_reg <= s_axil_awaddr_reg;
        m_axil_awprot_reg <= s_axil_awprot_reg;
        m_axil_awvalid_reg <= s_axil_awvalid_reg;
        m_axil_wdata_reg <= s_axil_wdata_reg;
        m_axil_wstrb_reg <= s_axil_wstrb_reg;
        m_axil_wvalid_reg <= s_axil_wvalid_reg;
        m_axil_bresp_reg <= s_axil_bresp_reg;
        m_axil_bvalid_reg <= s_axil_bvalid_reg;
        m_axil_araddr_reg <= s_axil_araddr_reg;
        m_axil_arprot_reg <= s_axil_arprot_reg;
        m_axil_arvalid_reg <= s_axil_arvalid_reg;
        m_axil_rdata_reg <= s_axil_rdata_reg;
        m_axil_rresp_reg <= s_axil_rresp_reg;
        m_axil_rvalid_reg <= s_axil_rvalid_reg;
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
        s_axil_awready <= m_axil_awready_reg;
        s_axil_wready <= m_axil_wready_reg;
        s_axil_bresp <= m_axil_bresp_reg;
        s_axil_bvalid <= m_axil_bvalid_reg;
        s_axil_arready <= m_axil_arready_reg;
        s_axil_rdata <= m_axil_rdata_reg;
        s_axil_rresp <= m_axil_rresp_reg;
        s_axil_rvalid <= m_axil_rvalid_reg;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_axil_awready_reg <= 0;
        m_axil_wready_reg <= 0;
        m_axil_bresp_reg <= 0;
        m_axil_bvalid_reg <= 0;
        m_axil_arready_reg <= 0;
        m_axil_rdata_reg <= 0;
        m_axil_rresp_reg <= 0;
        m_axil_rvalid_reg <= 0;
    end else begin
        m_axil_awready_reg <= s_axil_awready;
        m_axil_wready_reg <= s_axil_wready;
        m_axil_bresp_reg <= s_axil_bresp;
        m_axil_bvalid_reg <= s_axil_bvalid;
        m_axil_arready_reg <= s_axil_arready;
        m_axil_rdata_reg <= s_axil_rdata;
        m_axil_rresp_reg <= s_axil_rresp;
        m_axil_rvalid_reg <= s_axil_rvalid;
    end
end

always @(posedge s_clk) begin
    if (s_rst) begin
        s_axil_awaddr_reg <= 0;
        s_axil_awprot_reg <= 0;
        s_axil_awvalid_reg <= 0;
        s_axil_wdata_reg <= 0;
        s_axil_wstrb_reg <= 0;
        s_axil_wvalid_reg <= 0;
        s_axil_bresp_reg <= 0;
        s_axil_bvalid_reg <= 0;
        s_axil_araddr_reg <= 0;
        s_axil_arprot_reg <= 0;
        s_axil_arvalid_reg <= 0;
        s_axil_rdata_reg <= 0;
        s_axil_rresp_reg <= 0;
        s_axil_rvalid_reg <= 0;
    end else begin
        s_axil_awaddr_reg <= m_axil_awaddr_reg;
        s_axil_awprot_reg <= m_axil_awprot_reg;
        s_axil_awvalid_reg <= m_axil_awvalid_reg;
        s_axil_wdata_reg <= m_axil_wdata_reg;
        s_axil_wstrb_reg <= m_axil_wstrb_reg;
        s_axil_wvalid_reg <= m_axil_wvalid_reg;
        s_axil_bresp_reg <= m_axil_bresp_reg;
        s_axil_bvalid_reg <= m_axil_bvalid_reg;
        s_axil_araddr_reg <= m_axil_araddr_reg;
        s_axil_arprot_reg <= m_axil_arprot_reg;
        s_axil_arvalid_reg <= m_axil_arvalid_reg;
        s_axil_rdata_reg <= m_axil_rdata_reg;
        s_axil_rresp_reg <= m_axil_rresp_reg;
        s_axil_rvalid_reg <= m_axil_rvalid_reg;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_axil_awaddr_reg <= 0;
        m_axil_awprot_reg <= 0;
        m_axil_awvalid_reg <= 0;
        m_axil_wdata_reg <= 0;
        m_axil_wstrb_reg <= 0;
        m_axil_wvalid_reg <= 0;
        m_axil_bresp_reg <= 0;
        m_axil_bvalid_reg <= 0;
        m_axil_araddr_reg <= 0;
        m_axil_arprot_reg <= 0;
        m_axil_arvalid_reg <= 0;
        m_axil_rdata_reg <= 0;
        m_axil_rresp_reg <= 0;
        m_axil_rvalid_reg <= 0;
    end else begin
        m_axil_awaddr_reg <= s_axil_awaddr_reg;
        m_axil_awprot_reg <= s_axil_awprot_reg;
        m_axil_awvalid_reg <= s_axil_awvalid_reg;
        m_axil_wdata_reg <= s_axil_wdata_reg;
        m_axil_wstrb_reg <= s_axil_wstrb_reg;
        m_axil_wvalid_reg <= s_axil_wvalid_reg;
        m_axil_bresp_reg <= s_axil_bresp_reg;
        m_axil_bvalid_reg <= s_axil_bvalid_reg;
        m_axil_araddr_reg <= s_axil_araddr_reg;
        m_axil_arprot_reg <= s_axil_arprot_reg;
        m_axil_arvalid_reg <= s_axil_arvalid_reg;
        m_axil_rdata_reg <= s_axil_rdata_reg;
        m_axil_rresp_reg <= s_axil_rresp_reg;
        m_axil_rvalid_reg <= s_axil_rvalid_reg;
    end
end

assign m_axil_awaddr = m_axil_awaddr_reg;
assign m_axil_awprot = m_axil_awprot_reg;
assign m_axil_awvalid = m_axil_awvalid_reg;
assign m_axil_wdata = m_axil_wdata_reg;
assign m_axil_wstrb = m_axil_wstrb_reg;
assign m_axil_wvalid = m_axil_wvalid_reg;
assign m_axil_bresp = m_axil_bresp_reg;
assign m_axil_bvalid = m_axil_bvalid_reg;
assign m_axil_araddr = m_axil_araddr_reg;
assign m_axil_arprot = m_axil_arprot_reg;
assign m_axil_arvalid = m_axil_arvalid_reg;
assign m_axil_rdata = m_axil_rdata_reg;
assign m_axil_rresp = m_axil_rresp_reg;
assign m_axil_rvalid = m_axil_rvalid_reg;

assign s_axil_awaddr = s_axil_awaddr_reg;
assign s_axil_awprot = s_axil_awprot_reg;
assign s_axil_awvalid = s_axil_awvalid_reg;
assign s_axil_wdata = s_axil_wdata_reg;
assign s_axil_wstrb = s_axil_wstrb_reg;
assign s_axil_wvalid = s_axil_wvalid_reg;
assign s_axil_bresp = s_axil_bresp_reg;
assign s_axil_bvalid = s_axil_bvalid_reg;
assign s_axil_araddr = s_axil_araddr_reg;
assign s_axil_arprot = s_axil_arprot_reg;
assign s_axil_arvalid = s_axil_arvalid_reg;
assign s_axil_rdata = s_axil_rdata_reg;
assign s_axil_rresp = s_axil_rresp_reg;
assign s_axil_rvalid = s_axil_rvalid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
        end else begin
            data_out <= data_in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

    // Data output verification
    always @(posedge clk) begin
        if (reset) begin
            assert(data_out == 8'h00) else $error("Reset failed");
        end else begin
            assert(data_out == data_in) else $error("Data mismatch");
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], data_in};
            data_out <= shift_reg[7];
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

    // Data output verification
    always @(posedge clk) begin
        if (reset) begin
            assert(data_out == 8'h00) else $error("Reset failed");
        end else begin
            assert(data_out == data_in) else $error("Data mismatch");
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], data_in};
            data_out <= shift_reg[7];
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

    // Data output verification
    always @(posedge clk) begin
        if (reset) begin
            assert(data_out == 8'h00) else $error("Reset failed");
        end else begin
            assert(data_out == data_in) else $error("Data mismatch");
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], data_in};
            data_out <= shift_reg[7];
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

    // Data output verification
    always @(posedge clk) begin
        if (reset) begin
            assert(data_out == 8'h00) else $error("Reset failed");
        end else begin
            assert(data_out == data_in) else $error("Data mismatch");
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

    // Data output verification
    always @(posedge clk) begin
        if (reset) begin
            assert(data_out == 8'h00) else $error("Reset failed");
        end else begin
            assert(data_out == data_in) else $error("Data mismatch");
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], data_in};
            data_out <= shift_reg[7];
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 
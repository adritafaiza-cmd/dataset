Here is the complete Verilog code for the AXI4-Lite clock-domain bridge module:

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
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;

    // State machine signals
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter WRITE = 2'b01;
    parameter READ = 2'b10;

    // Reset logic
    always @(posedge s_clk) begin
        if (s_rst) begin
            state <= IDLE;
            awvalid_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bvalid_reg <= 1'b0;
            arvalid_reg <= 1'b0;
            rvalid_reg <= 1'b0;
        end
    end

    // Write address channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
            awprot_reg <= {3{1'b0}};
        end else if (s_axil_awvalid && s_axil_awready) begin
            awaddr_reg <= s_axil_awaddr;
            awprot_reg <= s_axil_awprot;
            awvalid_reg <= 1'b1;
        end else if (m_axil_awready) begin
            awvalid_reg <= 1'b0;
        end
    end

    // Write data channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            wdata_reg <= {DATA_WIDTH{1'b0}};
            wstrb_reg <= {STRB_WIDTH{1'b0}};
        end else if (s_axil_wvalid && s_axil_wready) begin
            wdata_reg <= s_axil_wdata;
            wstrb_reg <= s_axil_wstrb;
            wvalid_reg <= 1'b1;
        end else if (m_axil_wready) begin
            wvalid_reg <= 1'b0;
        end
    end

    // Write response channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            bresp_reg <= {2{1'b0}};
        end else if (m_axil_bvalid && m_axil_bready) begin
            bresp_reg <= m_axil_bresp;
            bvalid_reg <= 1'b1;
        end else if (s_axil_bready) begin
            bvalid_reg <= 1'b0;
        end
    end

    // Read address channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            araddr_reg <= {ADDR_WIDTH{1'b0}};
            arprot_reg <= {3{1'b0}};
        end else if (s_axil_arvalid && s_axil_arready) begin
            araddr_reg <= s_axil_araddr;
            arprot_reg <= s_axil_arprot;
            arvalid_reg <= 1'b1;
        end else if (m_axil_arready) begin
            arvalid_reg <= 1'b0;
        end
    end

    // Read response channel
    always @(posedge s_clk) begin
        if (s_rst) begin
            rresp_reg <= {2{1'b0}};
        end else if (m_axil_rvalid && m_axil_rready) begin
            rresp_reg <= m_axil_rresp;
            rdata_reg <= m_axil_rdata;
            rvalid_reg <= 1'b1;
        end else if (s_axil_rready) begin
            rvalid_reg <= 1'b0;
        end
    end

    // State machine
    always @(posedge s_clk) begin
        if (s_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        state <= WRITE;
                    end else if (s_axil_arvalid && s_axil_arready) begin
                        state <= READ;
                    end
                end
                WRITE: begin
                    if (m_axil_awready && m_axil_wready && m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                    end
                end
                READ: begin
                    if (m_axil_arready && m_axil_rvalid && m_axil_rready) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign s_axil_awready = (state == IDLE);
    assign s_axil_wready = (state == WRITE);
    assign s_axil_bresp = bresp_reg;
    assign s_axil_bvalid = bvalid_reg;
    assign s_axil_arready = (state == IDLE);
    assign s_axil_rdata = rdata_reg;
    assign s_axil_rresp = rresp_reg;
    assign s_axil_rvalid = rvalid_reg;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_2();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_2();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_3();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_4();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_5();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_6();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_7();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_8();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_9();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_10();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_11();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_12();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_13();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_14();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_15();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_16();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_17();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_18();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_19();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_20();

    reg clk;
    reg rst;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst = 1;
        in = 8'b0;
        #10 rst = 0;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb_21();


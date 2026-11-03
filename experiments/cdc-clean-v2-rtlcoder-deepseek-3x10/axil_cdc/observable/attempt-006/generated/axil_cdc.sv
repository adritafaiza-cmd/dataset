The following Verilog code implements an AXI4-Lite clock-domain bridge using a handshake mechanism between the two clock domains. The code uses a FIFO to store the transactions and a handshake mechanism to ensure that the transactions are processed in the correct order.

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

    // FIFO to store transactions
    reg [DATA_WIDTH+ADDR_WIDTH+3:0] fifo_data [0:1];
    reg [1:0] fifo_wr_ptr;
    reg [1:0] fifo_rd_ptr;
    reg [1:0] fifo_count;

    // Handshake signals
    reg s_aw_handshake;
    reg s_w_handshake;
    reg s_b_handshake;
    reg s_ar_handshake;
    reg s_r_handshake;
    reg m_aw_handshake;
    reg m_w_handshake;
    reg m_b_handshake;
    reg m_ar_handshake;
    reg m_r_handshake;

    // Write data and strobe
    reg [DATA_WIDTH-1:0] write_data;
    reg [STRB_WIDTH-1:0] write_strobe;

    // Read data and response
    reg [DATA_WIDTH-1:0] read_data;
    reg [1:0] read_resp;

    // Write address and control signals
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [2:0] write_prot;
    reg write_valid;
    reg write_ready;

    // Read address and control signals
    reg [ADDR_WIDTH-1:0] read_addr;
    reg [2:0] read_prot;
    reg read_valid;
    reg read_ready;

    // Write handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_aw_handshake <= 1'b0;
            s_w_handshake <= 1'b0;
            s_b_handshake <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_axil_awready && !s_aw_handshake) begin
                s_aw_handshake <= 1'b1;
            end else if (s_axil_wvalid && s_axil_wready && !s_w_handshake) begin
                s_w_handshake <= 1'b1;
            end else if (s_axil_bvalid && s_axil_bready && !s_b_handshake) begin
                s_b_handshake <= 1'b1;
            end else begin
                s_aw_handshake <= 1'b0;
                s_w_handshake <= 1'b0;
                s_b_handshake <= 1'b0;
            end
        end
    end

    // Read handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_ar_handshake <= 1'b0;
            s_r_handshake <= 1'b0;
        end else begin
            if (s_axil_arvalid && s_axil_arready && !s_ar_handshake) begin
                s_ar_handshake <= 1'b1;
            end else if (s_axil_rvalid && s_axil_rready && !s_r_handshake) begin
                s_r_handshake <= 1'b1;
            end else begin
                s_ar_handshake <= 1'b0;
                s_r_handshake <= 1'b0;
            end
        end
    end

    // Write FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_wr_ptr <= 2'b00;
            fifo_count <= 2'b00;
        end else begin
            if (s_aw_handshake && s_w_handshake && !s_b_handshake) begin
                fifo_data[fifo_wr_ptr] <= {s_axil_awaddr, s_axil_awprot, s_axil_wdata, s_axil_wstrb};
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count + 1;
            end else if (s_b_handshake) begin
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count - 1;
            end
        end
    end

    // Read FIFO
    always @(posedge m_clk) begin
        if (m_rst) begin
            fifo_rd_ptr <= 2'b00;
        end else begin
            if (m_r_handshake) begin
                read_data <= fifo_data[fifo_rd_ptr][DATA_WIDTH+ADDR_WIDTH-1:ADDR_WIDTH];
                read_resp <= fifo_data[fifo_rd_ptr][ADDR_WIDTH-1:ADDR_WIDTH-2];
                fifo_rd_ptr <= fifo_rd_ptr + 1;
            end
        end
    end

    // Write address and control signals
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_addr <= 0;
            write_prot <= 0;
            write_valid <= 0;
            write_ready <= 0;
        end else begin
            if (s_aw_handshake && s_w_handshake && !s_b_handshake) begin
                write_addr <= s_axil_awaddr;
                write_prot <= s_axil_awprot;
                write_valid <= 1;
                write_ready <= m_axil_awready;
            end else if (m_axil_awready) begin
                write_valid <= 0;
                write_ready <= 0;
            end
        end
    end

    // Read address and control signals
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_addr <= 0;
            read_prot <= 0;
            read_valid <= 0;
            read_ready <= 0;
        end else begin
            if (s_ar_handshake && !s_r_handshake) begin
                read_addr <= s_axil_araddr;
                read_prot <= s_axil_arprot;
                read_valid <= 1;
                read_ready <= m_axil_arready;
            end else if (m_axil_arready) begin
                read_valid <= 0;
                read_ready <= 0;
            end
        end
    end

    // Write data and strobe
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_data <= 0;
            write_strobe <= 0;
        end else begin
            if (s_aw_handshake && s_w_handshake && !s_b_handshake) begin
                write_data <= s_axil_wdata;
                write_strobe <= s_axil_wstrb;
            end
        end
    end

    // Write response
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_bresp <= 0;
            m_axil_bvalid <= 0;
            m_b_handshake <= 0;
        end else begin
            if (m_axil_awready && write_valid && write_ready) begin
                m_axil_bresp <= 0;
                m_axil_bvalid <= 1;
                m_b_handshake <= 1;
            end else if (m_axil_bvalid && m_axil_bready) begin
                m_axil_bresp <= 0;
                m_axil_bvalid <= 0;
                m_b_handshake <= 0;
            end
        end
    end

    // Read data and response
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_rdata <= 0;
            m_axil_rresp <= 0;
            m_axil_rvalid <= 0;
            m_r_handshake <= 0;
        end else begin
            if (m_axil_arready && read_valid && read_ready) begin
                m_axil_rdata <= read_data;
                m_axil_rresp <= read_resp;
                m_axil_rvalid <= 1;
                m_r_handshake <= 1;
            end else if (m_axil_rvalid && m_axil_rready) begin
                m_axil_rdata <= 0;
                m_axil_rresp <= 0;
                m_axil_rvalid <= 0;
                m_r_handshake <= 0;
            end
        end
    end

    // Write address and control signals
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_aw_handshake <= 0;
        end else begin
            if (m_axil_awready && write_valid && write_ready) begin
                m_axil_awaddr <= write_addr;
                m_axil_awprot <= write_prot;
                m_axil_awvalid <= 1;
                m_aw_handshake <= 1;
            end else if (m_axil_awvalid && m_axil_awready) begin
                m_axil_awaddr <= 0;
                m_axil_awprot <= 0;
                m_axil_awvalid <= 0;
                m_aw_handshake <= 0;
            end
        end
    end

    // Write data and strobe
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m_w_handshake <= 0;
        end else begin
            if (m_axil_awready && write_valid && write_ready) begin
                m_axil_wdata <= write_data;
                m_axil_wstrb <= write_strobe;
                m_axil_wvalid <= 1;
                m_w_handshake <= 1;
            end else if (m_axil_wvalid && m_axil_wready) begin
                m_axil_wdata <= 0;
                m_axil_wstrb <= 0;
                m_axil_wvalid <= 0;
                m_w_handshake <= 0;
            end
        end
    end

    // Read address and control signals
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
            m_ar_handshake <= 0;
        end else begin
            if (m_axil_arready && read_valid && read_ready) begin
                m_axil_araddr <= read_addr;
                m_axil_arprot <= read_prot;
                m_axil_arvalid <= 1;
                m_ar_handshake <= 1;
            end else if (m_axil_arvalid && m_axil_arready) begin
                m_axil_araddr <= 0;
                m_axil_arprot <= 0;
                m_axil_arvalid <= 0;
                m_ar_handshake <= 0;
            end
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_
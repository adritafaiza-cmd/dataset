The APB clock-domain bridge can be implemented using a simple FIFO to store the APB transaction data. The FIFO can be implemented using a shift register with a write pointer and a read pointer. The write pointer increments on each clock cycle when a new transaction is accepted, and the read pointer increments on each clock cycle when a transaction is completed. The FIFO is empty when the write pointer equals the read pointer, and is full when the write pointer wraps around to the read pointer.

The following Verilog code implements the APB clock-domain bridge:

```
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // FIFO parameters
    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH_FIFO = ADDR_WIDTH + LOG_DEPTH;
    localparam DATA_WIDTH_FIFO = DATA_WIDTH + 1; // 1 bit for valid signal

    // FIFO signals
    reg [ADDR_WIDTH_FIFO-1:0] fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH_FIFO-1:0] fifo_data [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] fifo_write_ptr;
    reg [LOG_DEPTH-1:0] fifo_read_ptr;
    wire fifo_empty = (fifo_write_ptr == fifo_read_ptr);
    wire fifo_full = (fifo_write_ptr == (fifo_read_ptr ^ {LOG_DEPTH{1'b1}}));

    // APB signals
    reg [ADDR_WIDTH-1:0] apb_addr;
    reg [DATA_WIDTH-1:0] apb_wdata;
    reg [DATA_WIDTH/8-1:0] apb_wstrb;
    reg apb_write;
    reg apb_sel;
    reg apb_enable;
    reg [DATA_WIDTH-1:0] apb_rdata;
    reg apb_err;

    // APB source interface
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            apb_addr <= 0;
            apb_wdata <= 0;
            apb_wstrb <= 0;
            apb_write <= 0;
            apb_sel <= 0;
            apb_enable <= 0;
            apb_rdata <= 0;
            apb_err <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                if (apb_sel) begin
                    if (apb_write) begin
                        apb_wdata <= src_pwdata_i;
                        apb_wstrb <= src_pstrb_i;
                    end else begin
                        apb_rdata <= dst_prdata_i;
                        apb_err <= dst_pslverr_i;
                    end
                end else begin
                    apb_addr <= src_paddr_i;
                    apb_write <= src_pwrite_i;
                    apb_sel <= 1;
                    apb_enable <= 1;
                end
            end else begin
                apb_sel <= 0;
                apb_enable <= 0;
            end
        end
    end

    // APB destination interface
    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 1'b0) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else begin
            if (apb_sel && !apb_enable) begin
                dst_psel_o <= apb_sel;
                dst_penable_o <= apb_enable;
                dst_pwrite_o <= apb_write;
                dst_paddr_o <= apb_addr;
                dst_pwdata_o <= apb_wdata;
                dst_pstrb_o <= apb_wstrb;
                dst_pprot_o <= src_pprot_i;
            end else begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_pwrite_o <= 0;
                dst_paddr_o <= 0;
                dst_pwdata_o <= 0;
                dst_pstrb_o <= 0;
                dst_pprot_o <= 0;
            end
        end
    end

    // FIFO write
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            fifo_write_ptr <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !fifo_full) begin
                fifo_addr[fifo_write_ptr] <= {src_paddr_i, fifo_write_ptr};
                fifo_data[fifo_write_ptr] <= {src_pwdata_i, src_pstrb_i, 1'b1};
                fifo_write_ptr <= fifo_write_ptr + 1;
            end
        end
    end

    // FIFO read
    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 1'b0) begin
            fifo_read_ptr <= 0;
        end else begin
            if (dst_pready_i && !fifo_empty) begin
                apb_addr <= fifo_addr[fifo_read_ptr][ADDR_WIDTH-1:0];
                apb_wdata <= fifo_data[fifo_read_ptr][DATA_WIDTH-1:0];
                apb_wstrb <= fifo_data[fifo_read_ptr][DATA_WIDTH+:DATA_WIDTH/8];
                apb_write <= fifo_data[fifo_read_ptr][DATA_WIDTH+DATA_WIDTH/8];
                apb_sel <= 1;
                apb_enable <= 1;
                fifo_read_ptr <= fifo_read_ptr + 1;
            end
        end
    end

    // Output signals
    assign src_pready_o = dst_pready_i;
    assign src_prdata_o = apb_rdata;
    assign src_pslverr_o = apb_err;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            out <= shift_reg[0];
        end
    end
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            out <= shift_reg[0];
        end
    end
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 $finish;
end

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
    in = 8'h0
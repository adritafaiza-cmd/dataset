The complete Verilog code for the AXI-Stream asynchronous FIFO is as follows:

```
module axis_async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

// Internal wires and registers
wire [DATA_WIDTH-1:0] axis_tdata_int;
wire [KEEP_WIDTH-1:0] axis_tkeep_int;
wire axis_tvalid_int;
wire axis_tready_int;
wire axis_tlast_int;
wire [ID_WIDTH-1:0] axis_tid_int;
wire [DEST_WIDTH-1:0] axis_tdest_int;
wire [USER_WIDTH-1:0] axis_tuser_int;
wire s_pause_req_int;
wire m_pause_req_int;
wire [$clog2(DEPTH):0] s_status_depth_int;
wire [$clog2(DEPTH):0] s_status_depth_commit_int;
wire s_status_overflow_int;
wire s_status_bad_frame_int;
wire s_status_good_frame_int;
wire [$clog2(DEPTH):0] m_status_depth_int;
wire [$clog2(DEPTH):0] m_status_depth_commit_int;
wire m_status_overflow_int;
wire m_status_bad_frame_int;
wire m_status_good_frame_int;

// Instantiate the AXI-Stream FIFO
axis_async_fifo_v1_0_0 axis_async_fifo_inst (
    .s_clk(s_clk),
    .s_rst(s_rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_clk(m_clk),
    .m_rst(m_rst),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser),
    .s_pause_req(s_pause_req),
    .s_pause_ack(s_pause_ack),
    .m_pause_req(m_pause_req),
    .m_pause_ack(m_pause_ack),
    .s_status_depth(s_status_depth),
    .s_status_depth_commit(s_status_depth_commit),
    .s_status_overflow(s_status_overflow),
    .s_status_bad_frame(s_status_bad_frame),
    .s_status_good_frame(s_status_good_frame),
    .m_status_depth(m_status_depth),
    .m_status_depth_commit(m_status_depth_commit),
    .m_status_overflow(m_status_overflow),
    .m_status_bad_frame(m_status_bad_frame),
    .m_status_good_frame(m_status_good_frame),
    .axis_tdata_int(axis_tdata_int),
    .axis_tkeep_int(axis_tkeep_int),
    .axis_tvalid_int(axis_tvalid_int),
    .axis_tready_int(axis_tready_int),
    .axis_tlast_int(axis_tlast_int),
    .axis_tid_int(axis_tid_int),
    .axis_tdest_int(axis_tdest_int),
    .axis_tuser_int(axis_tuser_int),
    .s_pause_req_int(s_pause_req_int),
    .m_pause_req_int(m_pause_req_int),
    .s_status_depth_int(s_status_depth_int),
    .s_status_depth_commit_int(s_status_depth_commit_int),
    .s_status_overflow_int(s_status_overflow_int),
    .s_status_bad_frame_int(s_status_bad_frame_int),
    .s_status_good_frame_int(s_status_good_frame_int),
    .m_status_depth_int(m_status_depth_int),
    .m_status_depth_commit_int(m_status_depth_commit_int),
    .m_status_overflow_int(m_status_overflow_int),
    .m_status_bad_frame_int(m_status_bad_frame_int),
    .m_status_good_frame_int(m_status_good_frame_int)
);

// Assign the internal wires to the output ports
assign m_axis_tdata = axis_tdata_int;
assign m_axis_tkeep = axis_tkeep_int;
assign m_axis_tvalid = axis_tvalid_int;
assign m_axis_tlast = axis_tlast_int;
assign m_axis_tid = axis_tid_int;
assign m_axis_tdest = axis_tdest_int;
assign m_axis_tuser = axis_tuser_int;
assign s_pause_req_int = s_pause_req;
assign m_pause_req_int = m_pause_req;
assign s_status_depth = s_status_depth_int;
assign s_status_depth_commit = s_status_depth_commit_int;
assign s_status_overflow = s_status_overflow_int;
assign s_status_bad_frame = s_status_bad_frame_int;
assign s_status_good_frame = s_status_good_frame_int;
assign m_status_depth = m_status_depth_int;
assign m_status_depth_commit = m_status_depth_commit_int;
assign m_status_overflow = m_status_overflow_int;
assign m_status_bad_frame = m_status_bad_frame_int;
assign m_status_good_frame = m_status_good_frame_int;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end

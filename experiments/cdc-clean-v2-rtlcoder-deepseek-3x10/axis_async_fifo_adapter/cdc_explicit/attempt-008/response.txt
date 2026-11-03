The complete Verilog code for the asynchronous AXI-Stream FIFO with a width adapter is as follows:

```
module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    // Width adapter
    wire [M_DATA_WIDTH-1:0] m_axis_tdata_adapter;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_adapter;
    wire m_axis_tvalid_adapter;
    wire m_axis_tlast_adapter;
    wire [ID_WIDTH-1:0] m_axis_tid_adapter;
    wire [DEST_WIDTH-1:0] m_axis_tdest_adapter;
    wire [USER_WIDTH-1:0] m_axis_tuser_adapter;

    axis_data_fifo_v2_0 #(
        .C_AXIS_TDATA_WIDTH(M_DATA_WIDTH),
        .C_AXIS_TKEEP_WIDTH(M_KEEP_WIDTH),
        .C_AXIS_TID_WIDTH(ID_WIDTH),
        .C_AXIS_TDST_WIDTH(DEST_WIDTH),
        .C_AXIS_TUSER_WIDTH(USER_WIDTH),
        .C_RAM_PIPELINE(RAM_PIPELINE),
        .C_OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .C_FRAME_FIFO(FRAME_FIFO),
        .C_USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .C_USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .C_DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .C_DROP_BAD_FRAME(DROP_BAD_FRAME),
        .C_DROP_WHEN_FULL(DROP_WHEN_FULL),
        .C_MARK_WHEN_FULL(MARK_WHEN_FULL),
        .C_PAUSE_ENABLE(PAUSE_ENABLE),
        .C_FRAME_PAUSE(FRAME_PAUSE)
    )
    axis_data_fifo_v2_0_inst (
        .s_axis_aclk(s_clk),
        .s_axis_aresetn(~s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_aclk(m_clk),
        .m_axis_aresetn(~m_rst),
        .m_axis_tdata(m_axis_tdata_adapter),
        .m_axis_tkeep(m_axis_tkeep_adapter),
        .m_axis_tvalid(m_axis_tvalid_adapter),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast_adapter),
        .m_axis_tid(m_axis_tid_adapter),
        .m_axis_tdest(m_axis_tdest_adapter),
        .m_axis_tuser(m_axis_tuser_adapter),
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
        .m_status_good_frame(m_status_good_frame)
    );

    // Width converter
    axis_width_converter_v2_0 #(
        .C_S_AXIS_TDATA_WIDTH(M_DATA_WIDTH),
        .C_S_AXIS_TKEEP_WIDTH(M_KEEP_WIDTH),
        .C_S_AXIS_TID_WIDTH(ID_WIDTH),
        .C_S_AXIS_TDST_WIDTH(DEST_WIDTH),
        .C_S_AXIS_TUSER_WIDTH(USER_WIDTH),
        .C_M_AXIS_TDATA_WIDTH(S_DATA_WIDTH),
        .C_M_AXIS_TKEEP_WIDTH(S_KEEP_WIDTH),
        .C_M_AXIS_TID_WIDTH(ID_WIDTH),
        .C_M_AXIS_TDST_WIDTH(DEST_WIDTH),
        .C_M_AXIS_TUSER_WIDTH(USER_WIDTH)
    )
    axis_width_converter_v2_0_inst (
        .s_axis_aclk(m_clk),
        .s_axis_aresetn(~m_rst),
        .s_axis_tdata(m_axis_tdata_adapter),
        .s_axis_tkeep(m_axis_tkeep_adapter),
        .s_axis_tvalid(m_axis_tvalid_adapter),
        .s_axis_tready(),
        .s_axis_tlast(m_axis_tlast_adapter),
        .s_axis_tid(m_axis_tid_adapter),
        .s_axis_tdest(m_axis_tdest_adapter),
        .s_axis_tuser(m_axis_tuser_adapter),
        .m_axis_aclk(s_clk),
        .m_axis_aresetn(~s_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>// SPDX-License-Identifier: MIT
//
// Copyright (c) 2021 Antonio Niño Díaz

module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        data_in = 8'b0;
        #10 rst = 0;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;

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

    // CDC FIFO instantiation for s_clk to m_clk
    cdc_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) s2m_fifo (
        .clk_in(s_clk),
        .rst_in(s_rst),
        .data_in(s_axis_tdata),
        .keep_in(s_axis_tkeep),
        .valid_in(s_axis_tvalid),
        .ready_out(s_axis_tready),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .clk_out(m_clk),
        .rst_out(m_rst),
        .data_out(m_axis_tdata),
        .keep_out(m_axis_tkeep),
        .valid_out(m_axis_tvalid),
        .ready_in(m_axis_tready),
        .last_out(m_axis_tlast),
        .id_out(m_axis_tid),
        .dest_out(m_axis_tdest),
        .user_out(m_axis_tuser),
        .pause_req(s_pause_req),
        .pause_ack(s_pause_ack)
    );

    // CDC FIFO instantiation for m_clk to s_clk
    cdc_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(1), // Simplified for pause signal
        .KEEP_WIDTH(1),
        .LAST_ENABLE(0),
        .ID_ENABLE(0),
        .ID_WIDTH(1),
        .DEST_ENABLE(0),
        .DEST_WIDTH(1),
        .USER_ENABLE(0),
        .USER_WIDTH(1),
        .RAM_PIPELINE(0),
        .OUTPUT_FIFO_ENABLE(0),
        .FRAME_FIFO(0),
        .USER_BAD_FRAME_VALUE(1'b0),
        .USER_BAD_FRAME_MASK(1'b0),
        .DROP_OVERSIZE_FRAME(0),
        .DROP_BAD_FRAME(0),
        .DROP_WHEN_FULL(0),
        .MARK_WHEN_FULL(0),
        .PAUSE_ENABLE(0),
        .FRAME_PAUSE(0)
    ) m2s_fifo (
        .clk_in(m_clk),
        .rst_in(m_rst),
        .data_in({m_pause_req}),
        .keep_in(1'b1),
        .valid_in(1'b1),
        .ready_out(),
        .last_in(1'b0),
        .id_in(1'b0),
        .dest_in(1'b0),
        .user_in(1'b0),
        .clk_out(s_clk),
        .rst_out(s_rst),
        .data_out({m_pause_ack}),
        .keep_out(),
        .valid_out(),
        .ready_in(),
        .last_out(),
        .id_out(),
        .dest_out(),
        .user_out(),
        .pause_req(1'b0),
        .pause_ack()
    );

    // Status signals are not implemented in this simplified example
    // They would require additional logic to count and report FIFO status
    assign s_status_depth = 0;
    assign s_status_depth_commit = 0;
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_depth = 0;
    assign m_status_depth_commit = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

endmodule

module cdc_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
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
    input  wire                   clk_in,
    input  wire                   rst_in,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [KEEP_WIDTH-1:0]  keep_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    input  wire                   last_in,
    input  wire [ID_WIDTH-1:0]    id_in,
    input  wire [DEST_WIDTH-1:0]  dest_in,
    input  wire [USER_WIDTH-1:0]  user_in,
    input  wire                   clk_out,
    input  wire                   rst_out,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire [KEEP_WIDTH-1:0]  keep_out,
    output wire                   valid_out,
    input  wire                   ready_in,
    output wire                   last_out,
    output wire [ID_WIDTH-1:0]    id_out,
    output wire [DEST_WIDTH-1:0]  dest_out,
    output wire [USER_WIDTH-1:0]  user_out,
    input  wire                   pause_req,
    output wire                   pause_ack
);

    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];

    // Gray code conversion
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray code to binary conversion
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = 1; i <= $clog2(DEPTH); i = i * 2) begin
            bin = bin ^ (bin >> i);
        end
        gray2bin = bin;
    endfunction

    // Write pointer logic
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (valid_in && ready_out) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin2gray(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_out or posedge rst_out) begin
        if (rst_out) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (valid_out && ready_in) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin2gray(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_out or posedge rst_out) begin
        if (rst_out) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // FIFO write
    always @(posedge clk_in) begin
        if (valid_in && ready_out) begin
            mem[wr_ptr] <= data_in;
            keep_mem[wr_ptr] <= keep_in;
            user_mem[wr_ptr] <= user_in;
            id_mem[wr_ptr] <= id_in;
            dest_mem[wr_ptr] <= dest_in;
            last_mem[wr_ptr] <= last_in;
        end
    end

    // FIFO read
    always @(posedge clk_out) begin
        if (valid_out && ready_in) begin
            data_out <= mem[rd_ptr];
            keep_out <= keep_mem[rd_ptr];
            user_out <= user_mem[rd_ptr];
            id_out <= id_mem[rd_ptr];
            dest_out <= dest_mem[rd_ptr];
            last_out <= last_mem[rd_ptr];
        end
    end

    // FIFO full/empty flags
    reg fifo_full, fifo_empty;
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            fifo_full <= (wr_ptr_gray == {~rd_ptr_gray_sync[$clog2(DEPTH):1], rd_ptr_gray_sync[0]});
            fifo_empty <= (wr_ptr_gray == rd_ptr_gray_sync);
        end
    end

    // Ready out signal
    assign ready_out = ~fifo_full;

    // Valid out signal
    assign valid_out = ~fifo_empty;

    // Pause acknowledge
    assign pause_ack = pause_req;

endmodule

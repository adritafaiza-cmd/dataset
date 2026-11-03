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

    // Instantiate the async_fifo module
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
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
    ) async_fifo_inst (
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
        .m_status_good_frame(m_status_good_frame)
    );

endmodule

module async_fifo #
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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wptr, rptr, wptr_gray, rptr_gray, wptr_gray_sync, rptr_gray_sync;
    reg [ADDR_WIDTH:0] wptr_gray_next, rptr_gray_next;
    reg [ADDR_WIDTH:0] depth, depth_commit;
    reg [ADDR_WIDTH:0] depth_sync;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];
    reg tid_mem [0:DEPTH-1];
    reg tdest_mem [0:DEPTH-1];

    reg [ADDR_WIDTH:0] wptr_gray_gray;
    reg [ADDR_WIDTH:0] rptr_gray_gray;

    reg s_pause_ack_reg, m_pause_ack_reg;
    reg s_status_overflow_reg, s_status_bad_frame_reg, s_status_good_frame_reg;
    reg m_status_overflow_reg, m_status_bad_frame_reg, m_status_good_frame_reg;

    // Binary to gray conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = 1; i <= ADDR_WIDTH; i = i + 1) begin
            bin = bin ^ (bin >> i);
        end
        gray_to_bin = bin;
    endfunction

    // Write pointer logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_gray_next <= 0;
        end else begin
            wptr_gray_next = bin_to_gray(wptr + 1);
            if (s_axis_tvalid && s_axis_tready) begin
                wptr <= wptr + 1;
                wptr_gray <= wptr_gray_next;
            end
        end
    end

    // Read pointer logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_next <= 0;
        end else begin
            rptr_gray_next = bin_to_gray(rptr + 1);
            if (m_axis_tvalid && m_axis_tready) begin
                rptr <= rptr + 1;
                rptr_gray <= rptr_gray_next;
            end
        end
    end

    // Gray code synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    // Depth calculation
    assign depth = gray_to_bin(wptr_gray_sync) - gray_to_bin(rptr_gray_sync);

    // Depth synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            depth_sync <= 0;
        end else begin
            depth_sync <= depth;
        end
    end

    // Status outputs
    assign s_status_depth = depth_sync;
    assign m_status_depth = depth;

    assign s_status_depth_commit = depth_commit;
    assign m_status_depth_commit = depth_commit;

    assign s_status_overflow = s_status_overflow_reg;
    assign m_status_overflow = m_status_overflow_reg;

    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;

    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Handshake logic
    assign s_axis_tready = (depth < DEPTH) && !s_pause_req;
    assign m_axis_tvalid = (depth != 0) && !m_pause_req;

    // Write memory
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem[wptr] <= s_axis_tdata;
            if (KEEP_ENABLE) keep_mem[wptr] <= s_axis_tkeep;
            if (LAST_ENABLE) last_mem[wptr] <= s_axis_tlast;
            if (ID_ENABLE) tid_mem[wptr] <= s_axis_tid;
            if (DEST_ENABLE) tdest_mem[wptr] <= s_axis_tdest;
            if (USER_ENABLE) user_mem[wptr] <= s_axis_tuser;
        end
    end

    // Read memory
    always @(posedge m_clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tdata <= mem[rptr];
            if (KEEP_ENABLE) m_axis_tkeep <= keep_mem[rptr];
            if (LAST_ENABLE) m_axis_tlast <= last_mem[rptr];
            if (ID_ENABLE) m_axis_tid <= tid_mem[rptr];
            if (DEST_ENABLE) m_axis_tdest <= tdest_mem[rptr];
            if (USER_ENABLE) m_axis_tuser <= user_mem[rptr];
        end
    end

    // Frame tracking and pause
    reg frame_in_progress;
    reg frame_in_progress_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            frame_in_progress <= 0;
            frame_in_progress_sync <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    frame_in_progress <= 0;
                end else begin
                    frame_in_progress <= 1;
                end
            end
            frame_in_progress_sync <= frame_in_progress;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            frame_in_progress_sync <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tlast) begin
                    frame_in_progress_sync <= 0;
                end else begin
                    frame_in_progress_sync <= 1;
                end
            end
        end
    end

    assign s_pause_ack = s_pause_req && frame_in_progress_sync;
    assign m_pause_ack = m_pause_req && frame_in_progress_sync;

    // Status flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            if (depth == DEPTH && s_axis_tvalid && s_axis_tready) begin
                s_status_overflow_reg <= 1;
            end else begin
                s_status_overflow_reg <= 0;
            end

            if (USER_ENABLE && (user_mem[wptr] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                s_status_bad_frame_reg <= 1;
            end else begin
                s_status_bad_frame_reg <= 0;
            end

            if (USER_ENABLE && (user_mem[wptr] & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) begin
                s_status_good_frame_reg <= 1;
            end else begin
                s_status_good_frame_reg <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            if (depth == DEPTH && m_axis_tvalid && m_axis_tready) begin
                m_status_overflow_reg <= 1;
            end else begin
                m_status_overflow_reg <= 0;
            end

            if (USER_ENABLE && (user_mem[rptr] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                m_status_bad_frame_reg <= 1;
            end else begin
                m_status_bad_frame_reg <= 0;
            end

            if (USER_ENABLE && (user_mem[rptr] & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) begin
                m_status_good_frame_reg <= 1;
            end else begin
                m_status_good_frame_reg <= 0;
            end
        end
    end

endmodule

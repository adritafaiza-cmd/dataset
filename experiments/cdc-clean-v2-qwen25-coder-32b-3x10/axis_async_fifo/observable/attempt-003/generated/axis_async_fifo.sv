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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wptr_s, wptr_m;
    reg [ADDR_WIDTH:0] rptr_s, rptr_m;
    reg [ADDR_WIDTH:0] wptr_gray_s, wptr_gray_m;
    reg [ADDR_WIDTH:0] rptr_gray_s, rptr_gray_m;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [LAST_ENABLE:0]  mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

    reg [ADDR_WIDTH:0] depth_s, depth_m;
    reg [ADDR_WIDTH:0] depth_commit_s, depth_commit_m;
    reg overflow_s, overflow_m;
    reg bad_frame_s, bad_frame_m;
    reg good_frame_s, good_frame_m;

    reg s_pause_ack_reg, m_pause_ack_reg;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i] ^ bin[i+1];
        end
        gray2bin = bin;
    endfunction

    // Write side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr_s <= 0;
            wptr_gray_s <= 0;
            depth_s <= 0;
            depth_commit_s <= 0;
            overflow_s <= 0;
            bad_frame_s <= 0;
            good_frame_s <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_wptr_s;
            reg [ADDR_WIDTH:0] next_depth_s;
            reg [ADDR_WIDTH:0] next_depth_commit_s;
            reg next_overflow_s;
            reg next_bad_frame_s;
            reg next_good_frame_s;

            next_wptr_s = wptr_s;
            next_depth_s = depth_s;
            next_depth_commit_s = depth_commit_s;
            next_overflow_s = overflow_s;
            next_bad_frame_s = bad_frame_s;
            next_good_frame_s = good_frame_s;

            if (s_axis_tvalid && s_axis_tready) begin
                mem_data[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) mem_keep[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE) mem_last[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE) mem_id[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) mem_dest[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) mem_user[wptr_s[ADDR_WIDTH-1:0]] <= s_axis_tuser;

                next_wptr_s = wptr_s + 1;
                next_depth_s = depth_s + 1;

                if (depth_s >= DEPTH) begin
                    next_overflow_s = 1;
                    if (DROP_WHEN_FULL) begin
                        next_depth_s = depth_s;
                    end else if (MARK_WHEN_FULL) begin
                        mem_user[wptr_s[ADDR_WIDTH-1:0]] <= mem_user[wptr_s[ADDR_WIDTH-1:0]] | USER_BAD_FRAME_MASK;
                    end
                end else begin
                    next_overflow_s = 0;
                end

                if (s_axis_tlast) begin
                    if (bad_frame_s) begin
                        if (DROP_BAD_FRAME) begin
                            next_depth_commit_s = depth_commit_s;
                        end else begin
                            next_depth_commit_s = depth_commit_s + depth_s;
                        end
                    end else begin
                        next_depth_commit_s = depth_commit_s + depth_s;
                        next_good_frame_s = 1;
                    end
                    next_bad_frame_s = 0;
                end else if (depth_s >= DEPTH && DROP_OVERSIZE_FRAME) begin
                    next_bad_frame_s = 1;
                end
            end

            if (s_axis_tlast && !bad_frame_s) begin
                next_good_frame_s = 1;
            end

            wptr_s <= next_wptr_s;
            wptr_gray_s <= bin2gray(next_wptr_s);
            depth_s <= next_depth_s;
            depth_commit_s <= next_depth_commit_s;
            overflow_s <= next_overflow_s;
            bad_frame_s <= next_bad_frame_s;
            good_frame_s <= next_good_frame_s;
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr_m <= 0;
            rptr_gray_m <= 0;
            depth_m <= 0;
            depth_commit_m <= 0;
            overflow_m <= 0;
            bad_frame_m <= 0;
            good_frame_m <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_rptr_m;
            reg [ADDR_WIDTH:0] next_depth_m;
            reg [ADDR_WIDTH:0] next_depth_commit_m;
            reg next_overflow_m;
            reg next_bad_frame_m;
            reg next_good_frame_m;

            next_rptr_m = rptr_m;
            next_depth_m = depth_m;
            next_depth_commit_m = depth_commit_m;
            next_overflow_m = overflow_m;
            next_bad_frame_m = bad_frame_m;
            next_good_frame_m = good_frame_m;

            if (m_axis_tvalid && m_axis_tready) begin
                next_rptr_m = rptr_m + 1;
                next_depth_m = depth_m - 1;

                if (mem_last[rptr_m[ADDR_WIDTH-1:0]] && (mem_user[rptr_m[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK)) begin
                    next_bad_frame_m = 1;
                end else if (mem_last[rptr_m[ADDR_WIDTH-1:0]]) begin
                    next_good_frame_m = 1;
                end
            end

            if (mem_last[rptr_m[ADDR_WIDTH-1:0]]) begin
                next_depth_commit_m = depth_commit_m - depth_m;
                next_bad_frame_m = 0;
                next_good_frame_m = 0;
            end

            rptr_m <= next_rptr_m;
            rptr_gray_m <= bin2gray(next_rptr_m);
            depth_m <= next_depth_m;
            depth_commit_m <= next_depth_commit_m;
            overflow_m <= next_overflow_m;
            bad_frame_m <= next_bad_frame_m;
            good_frame_m <= next_good_frame_m;
        end
    end

    // Cross-domain logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr_s <= 0;
            rptr_gray_s <= 0;
        end else begin
            rptr_gray_s <= wptr_gray_s;
            rptr_s <= gray2bin(rptr_gray_s);
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr_m <= 0;
            wptr_gray_m <= 0;
        end else begin
            wptr_gray_m <= rptr_gray_m;
            wptr_m <= gray2bin(wptr_gray_m);
        end
    end

    // Ready signals
    assign s_axis_tready = (depth_s < DEPTH) && !s_pause_req;
    assign m_axis_tvalid = (depth_m > 0) && !m_pause_req;

    // Pause signals
    assign s_pause_ack = s_pause_req && (depth_s >= DEPTH);
    assign m_pause_ack = m_pause_req && (depth_m == 0);

    // Status signals
    assign s_status_depth = depth_s;
    assign s_status_depth_commit = depth_commit_s;
    assign s_status_overflow = overflow_s;
    assign s_status_bad_frame = bad_frame_s;
    assign s_status_good_frame = good_frame_s;

    assign m_status_depth = depth_m;
    assign m_status_depth_commit = depth_commit_m;
    assign m_status_overflow = overflow_m;
    assign m_status_bad_frame = bad_frame_m;
    assign m_status_good_frame = good_frame_m;

    // Output signals
    assign m_axis_tdata = mem_data[rptr_m[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? mem_keep[rptr_m[ADDR_WIDTH-1:0]] : {KEEP_WIDTH{1'b1}};
    assign m_axis_tlast = LAST_ENABLE ? mem_last[rptr_m[ADDR_WIDTH-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? mem_id[rptr_m[ADDR_WIDTH-1:0]] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? mem_dest[rptr_m[ADDR_WIDTH-1:0]] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? mem_user[rptr_m[ADDR_WIDTH-1:0]] : {USER_WIDTH{1'b0}};

endmodule

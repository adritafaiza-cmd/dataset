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

    // FIFO Memory
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];
    reg mem_last [DEPTH-1:0];

    // Write and Read Pointers
    reg [ADDR_WIDTH:0] wr_ptr_s, wr_ptr_m;
    reg [ADDR_WIDTH:0] rd_ptr_s, rd_ptr_m;

    // Flags
    reg s_full, s_empty, m_full, m_empty;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    // Status Counters
    reg [$clog2(DEPTH):0] s_depth, s_depth_commit;
    reg [$clog2(DEPTH):0] m_depth, m_depth_commit;

    // Pause Control
    reg s_pause, m_pause;

    // CDC Synchronization
    reg [1:0] s_rst_sync, m_rst_sync;
    reg [1:0] s_pause_sync, m_pause_sync;

    // CDC Synchronization for Reset
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_sync <= 2'b11;
        else
            s_rst_sync <= {s_rst_sync[0], s_rst};
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_sync <= 2'b11;
        else
            m_rst_sync <= {m_rst_sync[0], m_rst};
    end

    // CDC Synchronization for Pause
    always @(posedge s_clk) begin
        s_pause_sync <= {s_pause_sync[0], s_pause_req};
    end

    always @(posedge m_clk) begin
        m_pause_sync <= {m_pause_sync[0], m_pause_req};
    end

    // Write Side Logic
    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1]) begin
            wr_ptr_s <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_full) begin
                mem[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE)
                    mem_keep[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE)
                    mem_last[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE)
                    mem_id[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE)
                    mem_dest[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE)
                    mem_user[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tuser;

                wr_ptr_s <= wr_ptr_s + 1;
                s_empty <= 0;
                s_depth <= s_depth + 1;
                if (s_axis_tlast) begin
                    s_depth_commit <= s_depth + 1;
                    s_good_frame <= 1;
                end
            end

            if (wr_ptr_s[ADDR_WIDTH:0] == {~rd_ptr_s[ADDR_WIDTH:0] & {ADDR_WIDTH+1{1'b1}}})
                s_full <= 1;
            else
                s_full <= 0;

            if (s_depth_commit == DEPTH)
                s_overflow <= 1;
            else
                s_overflow <= 0;

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                s_bad_frame <= 1;
            else
                s_bad_frame <= 0;

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE)
                s_good_frame <= 1;
            else
                s_good_frame <= 0;
        end
    end

    // Read Side Logic
    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1]) begin
            rd_ptr_m <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready && !m_empty) begin
                rd_ptr_m <= rd_ptr_m + 1;
                m_full <= 0;
                m_depth <= m_depth - 1;
                if (mem_last[rd_ptr_m[ADDR_WIDTH-1:0]])
                    m_depth_commit <= m_depth - 1;
            end

            if (rd_ptr_m[ADDR_WIDTH:0] == {~wr_ptr_m[ADDR_WIDTH:0] & {ADDR_WIDTH+1{1'b1}}})
                m_empty <= 1;
            else
                m_empty <= 0;

            if (m_depth_commit == DEPTH)
                m_overflow <= 1;
            else
                m_overflow <= 0;

            if (mem_last[rd_ptr_m[ADDR_WIDTH-1:0]] && (mem_user[rd_ptr_m[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                m_bad_frame <= 1;
            else
                m_bad_frame <= 0;

            if (mem_last[rd_ptr_m[ADDR_WIDTH-1:0]] && (mem_user[rd_ptr_m[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE)
                m_good_frame <= 1;
            else
                m_good_frame <= 0;
        end
    end

    // Cross-domain synchronization of pointers
    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1])
            rd_ptr_s <= 0;
        else
            rd_ptr_s <= rd_ptr_m;
    end

    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1])
            wr_ptr_m <= 0;
        else
            wr_ptr_m <= wr_ptr_s;
    end

    // Output Assignment
    assign s_axis_tready = !s_full && !s_pause_sync[1];
    assign m_axis_tdata = mem[rd_ptr_m[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? mem_keep[rd_ptr_m[ADDR_WIDTH-1:0]] : {KEEP_WIDTH{1'b1}};
    assign m_axis_tvalid = !m_empty && !m_pause_sync[1];
    assign m_axis_tlast = LAST_ENABLE ? mem_last[rd_ptr_m[ADDR_WIDTH-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? mem_id[rd_ptr_m[ADDR_WIDTH-1:0]] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? mem_dest[rd_ptr_m[ADDR_WIDTH-1:0]] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? mem_user[rd_ptr_m[ADDR_WIDTH-1:0]] : {USER_WIDTH{1'b0}};

    // Pause Acknowledgment
    assign s_pause_ack = s_pause_sync[1];
    assign m_pause_ack = m_pause_sync[1];

    // Status Outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule

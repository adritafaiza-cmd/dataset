```verilog
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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam S_KEEP_WIDTH_LOG = $clog2(S_KEEP_WIDTH);
    localparam M_KEEP_WIDTH_LOG = $clog2(M_KEEP_WIDTH);

    // Internal signals
    reg [LOG2_DEPTH:0] s_ptr, m_ptr;
    reg [LOG2_DEPTH:0] s_ptr_commit, m_ptr_commit;
    reg [LOG2_DEPTH:0] s_depth, m_depth;
    reg s_full, s_empty;
    reg m_full, m_empty;
    reg s_pause, m_pause;
    reg s_pause_ack_int, m_pause_ack_int;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;
    reg s_overflow, m_overflow;

    // FIFO Memory
    reg [S_DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep_commit [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user_commit [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [M_DATA_WIDTH-1:0] mem_data_m [0:DEPTH-1];
    reg [M_KEEP_WIDTH-1:0] mem_keep_m [0:DEPTH-1];
    reg [M_KEEP_WIDTH-1:0] mem_keep_m_commit [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user_m [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user_m_commit [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id_m [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest_m [0:DEPTH-1];
    reg [M_DATA_WIDTH-1:0] mem_data_m_commit [0:DEPTH-1];
    reg [M_KEEP_WIDTH-1:0] mem_keep_m_commit [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user_m_commit [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id_m_commit [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest_m_commit [0:DEPTH-1];
    reg [M_DATA_WIDTH-1:0] mem_data_m_commit [0:DEPTH-1];
    reg [M_KEEP_WIDTH-1:0] mem_keep_m_commit [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user_m_commit [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id_m_commit [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest_m_commit [0:DEPTH-1];

    // Pipeline registers for async FIFO
    reg [LOG2_DEPTH:0] s_ptr_pipe, m_ptr_pipe;
    reg [LOG2_DEPTH:0] s_depth_pipe, m_depth_pipe;
    reg s_full_pipe, s_empty_pipe;
    reg m_full_pipe, m_empty_pipe;
    reg s_pause_pipe, m_pause_pipe;
    reg s_pause_ack_pipe, m_pause_ack_pipe;
    reg s_bad_frame_pipe, m_bad_frame_pipe;
    reg s_good_frame_pipe, m_good_frame_pipe;
    reg s_overflow_pipe, m_overflow_pipe;

    // Width conversion logic
    wire [M_DATA_WIDTH-1:0] s_data_packed;
    wire [M_KEEP_WIDTH-1:0] s_keep_packed;
    wire [M_DATA_WIDTH-1:0] m_data_unpacked;
    wire [M_KEEP_WIDTH-1:0] m_keep_unpacked;

    // Generate packed/unpacked data
    genvar i;
    generate
        for (i = 0; i < M_KEEP_WIDTH; i = i + 1) begin : gen_keep
            assign s_keep_packed[i] = s_axis_tkeep[i];
            assign m_keep_unpacked[i] = m_axis_tkeep[i];
        end
    endgenerate

    // Packed data logic
    assign s_data_packed = s_axis_tdata;
    assign m_data_unpacked = m_axis_tdata;

    // Status outputs
    assign s_status_depth = s_depth_pipe;
    assign s_status_depth_commit = s_depth_pipe; // Simplified for this implementation
    assign s_status_overflow = s_overflow_pipe;
    assign s_status_bad_frame = s_bad_frame_pipe;
    assign s_status_good_frame = s_good_frame_pipe;

    assign m_status_depth = m_depth_pipe;
    assign m_status_depth_commit = m_depth_pipe; // Simplified for this implementation
    assign m_status_overflow = m_overflow_pipe;
    assign m_status_bad_frame = m_bad_frame_pipe;
    assign m_status_good_frame = m_good_frame_pipe;

    // Pause logic
    assign s_pause_ack = s_pause_ack_pipe;
    assign m_pause_ack = m_pause_ack_pipe;

    // Main process
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ptr <= 0;
            s_ptr_commit <= 0;
            s_depth <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_pause <= 0;
            s_pause_ack_int <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
            s_overflow <= 0;
        end else begin
            s_ptr <= s_ptr_pipe;
            s_ptr_commit <= s_ptr_pipe;
            s_depth <= s_depth_pipe;
            s_full <= s_full_pipe;
            s_empty <= s_empty_pipe;
            s_pause <= s_pause_pipe;
            s_pause_ack_int <= s_pause_ack_pipe;
            s_bad_frame <= s_bad_frame_pipe;
            s_good_frame <= s_good_frame_pipe;
            s_overflow <= s_overflow_pipe;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ptr <= 0;
            m_ptr_commit <= 0;
            m_depth <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_pause <= 0;
            m_pause_ack_int <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_overflow <= 0;
        end else begin
            m_ptr <= m_ptr_pipe;
            m_ptr_commit <= m_ptr_pipe;
            m_depth <= m_depth_pipe;
            m_full <= m_full_pipe;
            m_empty <= m_empty_pipe;
            m_pause <= m_pause_pipe;
            m_pause_ack_int <= m_pause_ack_pipe;
            m_bad_frame <= m_bad_frame_pipe;
            m_good_frame <= m_good_frame_pipe;
            m_overflow <= m_overflow_pipe;
        end
    end

    // Synchronous logic for S side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ptr_pipe <= 0;
            s_ptr_commit_pipe <= 0;
            s_depth_pipe <= 0;
            s_full_pipe <= 0;
            s_empty_pipe <= 1;
            s_pause_pipe <= 0;
            s_pause_ack_pipe <= 0;
            s_bad_frame_pipe <= 0;
            s_good_frame_pipe <= 0;
            s_overflow_pipe <= 0;
        end else begin
            s_ptr_pipe <= s_ptr;
            s_ptr_commit_pipe <= s_ptr_commit;
            s_depth_pipe <= s_depth;
            s_full_pipe <= s_full;
            s_empty_pipe <= s_empty;
            s_pause_pipe <= s_pause;
            s_pause_ack_pipe <= s_pause_ack_int;
            s_bad_frame_pipe <= s_bad_frame;
            s_good_frame_pipe <= s_good_frame;
            s_overflow_pipe <= s_overflow;
        end
    end

    // Synchronous logic for M side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ptr_pipe <= 0;
            m_ptr_commit_pipe <= 0;
            m_depth_pipe <= 0;
            m_full_pipe <= 0;
            m_empty_pipe <= 1;
            m_pause_pipe <= 0;
            m_pause_ack_pipe <= 0;
            m_bad_frame_pipe <= 0;
            m_good_frame_pipe <= 0;
            m_overflow_pipe <= 0;
        end else begin
            m_ptr_pipe <= m_ptr;
            m_ptr_commit_pipe <= m_ptr_commit;
            m_depth_pipe <= m_depth;
            m_full_pipe <= m_full;
            m_empty_pipe <= m_empty;
            m_pause_pipe <= m_pause;
            m_pause_ack_pipe <= m_pause_ack_int;
            m_bad_frame_pipe <= m_bad_frame;
            m_good_frame_pipe <= m_good_frame;
            m_overflow_pipe <= m_overflow;
        end
    end

    // S side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 0;
            s_pause_ack_int <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
            s_overflow <= 0;
        end else begin
            // Check pause request
            if (s_pause_req) begin
                s_pause <= 1;
                s_pause_ack_int <= 1;
            end else if (s_pause_ack_int) begin
                s_pause <= 0;
                s_pause_ack_int <= 0;
            end

            // Check bad frame
            if (s_axis_tvalid && s_axis_tuser == USER_BAD_FRAME_VALUE && s_axis_tuser == USER_BAD_FRAME_MASK) begin
                s_bad_frame <= 1;
                s_good_frame <= 0;
            end else if (s_axis_tvalid) begin
                s_bad_frame <= 0;
                s_good_frame <= 1;
            end else begin
                s_bad_frame <= 0;
                s_good_frame <= 0;
            end

            // Check overflow
            if (s_axis_tvalid && s_full) begin
                s_overflow <= 1;
                if (DROP_WHEN_FULL) begin
                    s_axis_tready <= 0;
                end else if (MARK_WHEN_FULL) begin
                    s_axis_tready <= 1;
                end else begin
                    s_axis_tready <= 0;
                end
            end else if (s_axis_tvalid && !s_full) begin
                s_overflow <= 0;
                s_axis_tready <= 1;
            end else begin
                s_overflow <= 0;
                s_axis_tready <= 0;
            end
        end
    end

    // M side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid <= 0;
            m_pause_ack_int <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_overflow <= 0;
        end else begin
            // Check pause request
            if (m_pause_req) begin
                m_pause <= 1;
                m_pause_ack_int <= 1;
            end else if (m_pause_ack_int) begin
                m_pause <= 0;
                m_pause_ack_int <= 0;
            end

            // Check bad frame
            if (m_axis_tvalid && m_axis_tuser == USER_BAD_FRAME_VALUE && m_axis_tuser == USER_BAD_FRAME_MASK) begin
                m_bad_frame <= 1;
                m_good_frame <= 0;
            end else if (m_axis_tvalid) begin
                m_bad_frame <= 0;
                m_good_frame <= 1;
            end else begin
                m_bad_frame <= 0;
                m_good_frame <= 0;
            end

            // Check overflow
            if (m_axis_tvalid && m_full) begin
                m_overflow <= 1;
                if (DROP_WHEN_FULL) begin
                    m_axis_tvalid <= 0;
                end else if (MARK_WHEN_FULL) begin
                    m_axis_tvalid <= 1;
                end else begin
                    m_axis_tvalid <= 0;
                end
            end else if (m_axis_tvalid && !m_full) begin
                m_overflow <= 0;
                m_axis_tvalid <= 1;
            end else begin
                m_overflow <= 0;
                m_axis_tvalid <= 0;
            end
        end
    end

    // FIFO write logic (S side)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            mem_data[s_ptr] <= 0;
            mem_keep[s_ptr] <= 0;
            mem_keep_commit[s_ptr] <= 0;
            mem_user[s_ptr] <= 0;
            mem_user_commit[s_ptr] <= 0;
            mem_id[s_ptr] <= 0;
            mem_dest[s_ptr] <= 0;
            mem_data_m[s_ptr] <= 0;
            mem_keep_m[s_ptr] <= 0;
            mem_keep_m_commit[s_ptr] <= 0;
            mem_user_m[s_ptr] <= 0;
            mem_user_m_commit[s_ptr] <= 0;
            mem_id_m[s_ptr] <= 0;
            mem_dest_m[s_ptr] <= 0;
            mem_data_m_commit[s_ptr] <= 0;
            mem_keep_m_commit[s_ptr] <= 0;
            mem_user_m_commit[s_ptr] <= 0;
            mem_id_m_commit[s_ptr] <= 0;
            mem_dest_m_commit[s_ptr] <= 0;
            mem_data_m_commit[s_ptr] <= 0;
            mem_keep_m_commit[s_ptr] <= 0;
            mem_user_m_commit[s_ptr] <= 0;
            mem_id_m_commit[s_ptr] <= 0;
            mem_dest_m_commit[s_ptr] <= 0;
            mem_data_m_commit[s_ptr] <= 0;
            mem_keep_m_commit[s_ptr] <= 0;
            mem_user_m_commit[s_ptr] <= 0;
            mem_id_m_commit[s_ptr] <= 0;
            mem_dest_m_commit[s_ptr] <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_full) begin
                mem_data[s_ptr] <= s_data_packed;
                mem_keep[s_ptr] <= s_keep_packed;
                mem_keep_commit[s_ptr] <= s_keep_packed;
                mem_user[s_ptr] <= s_axis_tuser;
                mem_user_commit[s_ptr] <= s_axis_tuser;
                mem_id[s_ptr] <= s_axis_tid;
                mem_dest[s_ptr] <= s_axis_tdest;
                mem_data_m[s_ptr] <= m_data_unpacked;
                mem_keep_m[s_ptr] <= m_keep_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m[s_ptr] <= s_axis_tuser;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m[s_ptr] <= s_axis_tid;
                mem_dest_m[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
                mem_data_m_commit[s_ptr] <= m_data_unpacked;
                mem_keep_m_commit[s_ptr] <= m_keep_unpacked;
                mem_user_m_commit[s_ptr] <= s_axis_tuser;
                mem_id_m_commit[s_ptr] <= s_axis_tid;
                mem_dest_m_commit[s_ptr] <= s_axis_tdest;
               
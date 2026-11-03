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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    // Internal signals
    reg [DEPTH-1:0] read_ptr;
    reg [DEPTH-1:0] write_ptr;
    reg [DEPTH-1:0] count;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [LAST_ENABLE?0:1] mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg [USER_WIDTH-1:0] status_depth;
    reg [USER_WIDTH-1:0] status_depth_commit;
    reg status_overflow;
    reg status_bad_frame;
    reg status_good_frame;
    reg [USER_WIDTH-1:0] m_status_depth;
    reg [USER_WIDTH-1:0] m_status_depth_commit;
    reg m_status_overflow;
    reg m_status_bad_frame;
    reg m_status_good_frame;

    // Write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            write_ptr <= 0;
            count <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[write_ptr] <= s_axis_tdata;
            mem_keep[write_ptr] <= s_axis_tkeep;
            mem_last[write_ptr] <= s_axis_tlast;
            mem_id[write_ptr] <= s_axis_tid;
            mem_dest[write_ptr] <= s_axis_tdest;
            mem_user[write_ptr] <= s_axis_tuser;
            write_ptr <= (write_ptr + 1) % DEPTH;
            count <= count + 1;
        end
    end

    // Read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            read_ptr <= 0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            read_ptr <= (read_ptr + 1) % DEPTH;
        end
    end

    // Status logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            status_depth <= 0;
            status_depth_commit <= 0;
            status_overflow <= 0;
            status_bad_frame <= 0;
            status_good_frame <= 0;
        end else begin
            status_depth <= count;
            status_depth_commit <= count;
            status_overflow <= (count == DEPTH);
            status_bad_frame <= (count == DEPTH);
            status_good_frame <= (count == DEPTH);
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_depth <= 0;
            m_status_depth_commit <= 0;
            m_status_overflow <= 0;
            m_status_bad_frame <= 0;
            m_status_good_frame <= 0;
        end else begin
            m_status_depth <= count;
            m_status_depth_commit <= count;
            m_status_overflow <= (count == DEPTH);
            m_status_bad_frame <= (count == DEPTH);
            m_status_good_frame <= (count == DEPTH);
        end
    end

    // Handshake logic
    assign s_axis_tready = (count < DEPTH);
    assign m_axis_tvalid = (count > 0);
    assign m_axis_tdata = mem[read_ptr];
    assign m_axis_tkeep = mem_keep[read_ptr];
    assign m_axis_tlast = mem_last[read_ptr];
    assign m_axis_tid = mem_id[read_ptr];
    assign m_axis_tdest = mem_dest[read_ptr];
    assign m_axis_tuser = mem_user[read_ptr];

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk) begin
        s_pause_ack_reg <= s_pause_req;
    end

    always @(posedge m_clk) begin
        m_pause_ack_reg <= m_pause_req;
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule

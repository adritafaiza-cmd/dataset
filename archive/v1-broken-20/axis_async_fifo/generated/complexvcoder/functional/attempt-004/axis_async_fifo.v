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
    reg [DATA_WIDTH-1:0] s_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] s_fifo_keep [0:DEPTH-1];
    reg [LAST_ENABLE:0]  s_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   s_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] s_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] s_fifo_user [0:DEPTH-1];
    reg [31:0]           s_fifo_write_ptr;
    reg [31:0]           s_fifo_read_ptr;
    reg [31:0]           s_fifo_count;
    reg                  s_fifo_full;
    reg                  s_fifo_empty;

    reg [DATA_WIDTH-1:0] m_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] m_fifo_keep [0:DEPTH-1];
    reg [LAST_ENABLE:0]  m_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   m_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] m_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] m_fifo_user [0:DEPTH-1];
    reg [31:0]           m_fifo_write_ptr;
    reg [31:0]           m_fifo_read_ptr;
    reg [31:0]           m_fifo_count;
    reg                  m_fifo_full;
    reg                  m_fifo_empty;

    // AXI interface handling
    reg                  s_axis_tready_reg;
    reg                  m_axis_tvalid_reg;

    // Pause handling
    reg                  s_pause_ack_reg;
    reg                  m_pause_ack_reg;

    // Status signals
    assign s_status_depth = s_fifo_count;
    assign s_status_depth_commit = s_fifo_count;
    assign s_status_overflow = s_fifo_full;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;

    assign m_status_depth = m_fifo_count;
    assign m_status_depth_commit = m_fifo_count;
    assign m_status_overflow = m_fifo_full;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

    // FIFO operations
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_write_ptr <= 0;
            s_fifo_read_ptr <= 0;
            s_fifo_count <= 0;
            s_fifo_full <= 0;
            s_fifo_empty <= 1;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_fifo_full) begin
                s_fifo_data[s_fifo_write_ptr] <= s_axis_tdata;
                s_fifo_keep[s_fifo_write_ptr] <= s_axis_tkeep;
                s_fifo_last[s_fifo_write_ptr] <= s_axis_tlast;
                s_fifo_id[s_fifo_write_ptr] <= s_axis_tid;
                s_fifo_dest[s_fifo_write_ptr] <= s_axis_tdest;
                s_fifo_user[s_fifo_write_ptr] <= s_axis_tuser;
                s_fifo_write_ptr <= s_fifo_write_ptr + 1;
                if (s_fifo_count < DEPTH) begin
                    s_fifo_count <= s_fifo_count + 1;
                    s_fifo_empty <= 0;
                end
                if (s_fifo_count == DEPTH - 1) begin
                    s_fifo_full <= 1;
                end
            end
            if (m_axis_tready && !m_fifo_empty) begin
                m_fifo_read_ptr <= m_fifo_read_ptr + 1;
                if (m_fifo_count > 0) begin
                    m_fifo_count <= m_fifo_count - 1;
                end
                if (m_fifo_count == 1) begin
                    m_fifo_empty <= 1;
                end
            end
        end
    end

    // AXI interface logic
    always @(posedge s_clk) begin
        s_axis_tready_reg <= s_axis_tready;
    end

    always @(posedge m_clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid;
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    // Pause logic
    always @(posedge s_clk) begin
        if (s_pause_req && !s_pause_ack_reg) begin
            s_pause_ack_reg <= 1;
        end else begin
            s_pause_ack_reg <= 0;
        end
    end

    always @(posedge m_clk) begin
        if (m_pause_req && !m_pause_ack_reg) begin
            m_pause_ack_reg <= 1;
        end else begin
            m_pause_ack_reg <= 0;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule

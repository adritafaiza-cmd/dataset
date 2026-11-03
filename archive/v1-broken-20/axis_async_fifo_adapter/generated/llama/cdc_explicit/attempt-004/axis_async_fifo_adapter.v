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

reg [S_DATA_WIDTH-1:0] fifo_data [DEPTH-1:0];
reg [S_KEEP_WIDTH-1:0] fifo_keep [DEPTH-1:0];
reg [ID_WIDTH-1:0] fifo_id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] fifo_dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] fifo_user [DEPTH-1:0];
reg [DEPTH-1:0] fifo_valid;
reg [DEPTH-1:0] fifo_last;
reg [$clog2(DEPTH):0] fifo_depth;
reg [$clog2(DEPTH):0] fifo_depth_commit;
reg s_pause_ack_reg;
reg m_pause_ack_reg;
reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
reg s_axis_tvalid_reg;
reg s_axis_tlast_reg;
reg [ID_WIDTH-1:0] s_axis_tid_reg;
reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
reg [USER_WIDTH-1:0] s_axis_tuser_reg;
reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg m_axis_tvalid_reg;
reg m_axis_tlast_reg;
reg [ID_WIDTH-1:0] m_axis_tid_reg;
reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
reg [USER_WIDTH-1:0] m_axis_tuser_reg;

integer i;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axis_tready <= 1'b0;
        s_pause_ack_reg <= 1'b0;
        s_axis_tdata_reg <= {S_DATA_WIDTH{1'b0}};
        s_axis_tkeep_reg <= {S_KEEP_WIDTH{1'b0}};
        s_axis_tvalid_reg <= 1'b0;
        s_axis_tlast_reg <= 1'b0;
        s_axis_tid_reg <= {ID_WIDTH{1'b0}};
        s_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
        s_axis_tuser_reg <= {USER_WIDTH{1'b0}};
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end
        if (s_pause_req) begin
            s_pause_ack_reg <= 1'b1;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
        if (fifo_depth < DEPTH) begin
            s_axis_tready <= 1'b1;
        end else begin
            s_axis_tready <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axis_tdata_reg <= {M_DATA_WIDTH{1'b0}};
        m_axis_tkeep_reg <= {M_KEEP_WIDTH{1'b0}};
        m_axis_tvalid_reg <= 1'b0;
        m_axis_tlast_reg <= 1'b0;
        m_axis_tid_reg <= {ID_WIDTH{1'b0}};
        m_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
        m_axis_tuser_reg <= {USER_WIDTH{1'b0}};
        m_pause_ack_reg <= 1'b0;
    end else begin
        if (m_axis_tready && m_axis_tvalid_reg) begin
            m_axis_tdata_reg <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
            m_axis_tid_reg <= {ID_WIDTH{1'b0}};
            m_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            m_axis_tuser_reg <= {USER_WIDTH{1'b0}};
        end
        if (m_pause_req) begin
            m_pause_ack_reg <= 1'b1;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end
end

always @(posedge s_clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
        fifo_data[fifo_depth] <= s_axis_tdata_reg;
        fifo_keep[fifo_depth] <= s_axis_tkeep_reg;
        fifo_id[fifo_depth] <= s_axis_tid_reg;
        fifo_dest[fifo_depth] <= s_axis_tdest_reg;
        fifo_user[fifo_depth] <= s_axis_tuser_reg;
        fifo_valid[fifo_depth] <= 1'b1;
        fifo_last[fifo_depth] <= s_axis_tlast_reg;
        if (fifo_depth < DEPTH-1) begin
            fifo_depth <= fifo_depth + 1;
        end
    end
end

always @(posedge m_clk) begin
    if (m_axis_tready && m_axis_tvalid_reg) begin
        m_axis_tdata_reg <= fifo_data[0];
        m_axis_tkeep_reg <= fifo_keep[0];
        m_axis_tvalid_reg <= fifo_valid[0];
        m_axis_tlast_reg <= fifo_last[0];
        m_axis_tid_reg <= fifo_id[0];
        m_axis_tdest_reg <= fifo_dest[0];
        m_axis_tuser_reg <= fifo_user[0];
        if (fifo_depth > 1) begin
            for (i = 0; i < DEPTH-1; i = i + 1) begin
                fifo_data[i] <= fifo_data[i+1];
                fifo_keep[i] <= fifo_keep[i+1];
                fifo_id[i] <= fifo_id[i+1];
                fifo_dest[i] <= fifo_dest[i+1];
                fifo_user[i] <= fifo_user[i+1];
                fifo_valid[i] <= fifo_valid[i+1];
                fifo_last[i] <= fifo_last[i+1];
            end
            fifo_depth <= fifo_depth - 1;
        end else begin
            fifo_depth <= 0;
        end
    end
end

assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tid = m_axis_tid_reg;
assign m_axis_tdest = m_axis_tdest_reg;
assign m_axis_tuser = m_axis_tuser_reg;
assign s_status_depth = fifo_depth;
assign s_status_depth_commit = fifo_depth;
assign s_status_overflow = (fifo_depth == DEPTH) ? 1'b1 : 1'b0;
assign s_status_bad_frame = 1'b0;
assign s_status_good_frame = 1'b0;
assign m_status_depth = fifo_depth;
assign m_status_depth_commit = fifo_depth;
assign m_status_overflow = (fifo_depth == DEPTH) ? 1'b1 : 1'b0;
assign m_status_bad_frame = 1'b0;
assign m_status_good_frame = 1'b0;

endmodule

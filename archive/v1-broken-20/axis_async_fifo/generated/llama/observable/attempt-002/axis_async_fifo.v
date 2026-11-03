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

// Internal signals
reg [DATA_WIDTH-1:0] data_reg;
reg [KEEP_WIDTH-1:0] keep_reg;
reg last_reg;
reg [ID_WIDTH-1:0] id_reg;
reg [DEST_WIDTH-1:0] dest_reg;
reg [USER_WIDTH-1:0] user_reg;
reg [DATA_WIDTH-1:0] data_pipe [RAM_PIPELINE-1:0];
reg [KEEP_WIDTH-1:0] keep_pipe [RAM_PIPELINE-1:0];
reg last_pipe [RAM_PIPELINE-1:0];
reg [ID_WIDTH-1:0] id_pipe [RAM_PIPELINE-1:0];
reg [DEST_WIDTH-1:0] dest_pipe [RAM_PIPELINE-1:0];
reg [USER_WIDTH-1:0] user_pipe [RAM_PIPELINE-1:0];
reg [DEPTH-1:0] wr_ptr;
reg [DEPTH-1:0] rd_ptr;
reg [DEPTH-1:0] wr_ptr_gray;
reg [DEPTH-1:0] rd_ptr_gray;
reg [DEPTH-1:0] wr_ptr_bin;
reg [DEPTH-1:0] rd_ptr_bin;
reg full;
reg empty;
reg [DEPTH-1:0] depth;
reg [DEPTH-1:0] depth_commit;
reg overflow;
reg bad_frame;
reg good_frame;
reg s_pause;
reg m_pause;

// Clock domain crossing
reg [DEPTH-1:0] wr_ptr_gray_sync;
reg [DEPTH-1:0] rd_ptr_gray_sync;
reg [DEPTH-1:0] wr_ptr_bin_sync;
reg [DEPTH-1:0] rd_ptr_bin_sync;

// FIFO logic
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        wr_ptr <= 0;
        data_reg <= 0;
        keep_reg <= 0;
        last_reg <= 0;
        id_reg <= 0;
        dest_reg <= 0;
        user_reg <= 0;
        full <= 0;
        empty <= 1;
        depth <= 0;
        depth_commit <= 0;
        overflow <= 0;
        bad_frame <= 0;
        good_frame <= 0;
        s_pause <= 0;
    end else begin
        if (s_axis_tvalid &&!full) begin
            data_reg <= s_axis_tdata;
            keep_reg <= s_axis_tkeep;
            last_reg <= s_axis_tlast;
            id_reg <= s_axis_tid;
            dest_reg <= s_axis_tdest;
            user_reg <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH - 1) begin
                full <= 1;
            end
            if (s_axis_tlast) begin
                good_frame <= 1;
            end
        end
        if (s_pause_req) begin
            s_pause <= 1;
        end
        if (s_axis_tvalid && full) begin
            overflow <= 1;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        rd_ptr <= 0;
        m_axis_tdata <= 0;
        m_axis_tkeep <= 0;
        m_axis_tvalid <= 0;
        m_axis_tlast <= 0;
        m_axis_tid <= 0;
        m_axis_tdest <= 0;
        m_axis_tuser <= 0;
        empty <= 1;
        depth <= 0;
        depth_commit <= 0;
        bad_frame <= 0;
        good_frame <= 0;
        m_pause <= 0;
    end else begin
        if (m_axis_tready &&!empty) begin
            m_axis_tdata <= data_pipe[RAM_PIPELINE-1];
            m_axis_tkeep <= keep_pipe[RAM_PIPELINE-1];
            m_axis_tvalid <= 1;
            m_axis_tlast <= last_pipe[RAM_PIPELINE-1];
            m_axis_tid <= id_pipe[RAM_PIPELINE-1];
            m_axis_tdest <= dest_pipe[RAM_PIPELINE-1];
            m_axis_tuser <= user_pipe[RAM_PIPELINE-1];
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH - 1) begin
                empty <= 1;
            end
        end
        if (m_pause_req) begin
            m_pause <= 1;
        end
    end
end

// Pipeline logic
always @(posedge s_clk) begin
    data_pipe[0] <= data_reg;
    keep_pipe[0] <= keep_reg;
    last_pipe[0] <= last_reg;
    id_pipe[0] <= id_reg;
    dest_pipe[0] <= dest_reg;
    user_pipe[0] <= user_reg;
    for (int i = 1; i < RAM_PIPELINE; i++) begin
        data_pipe[i] <= data_pipe[i-1];
        keep_pipe[i] <= keep_pipe[i-1];
        last_pipe[i] <= last_pipe[i-1];
        id_pipe[i] <= id_pipe[i-1];
        dest_pipe[i] <= dest_pipe[i-1];
        user_pipe[i] <= user_pipe[i-1];
    end
end

// Gray code conversion
always @(posedge s_clk) begin
    wr_ptr_gray <= {wr_ptr[DEPTH-1], wr_ptr[DEPTH-2:0]};
end

always @(posedge m_clk) begin
    rd_ptr_gray <= {rd_ptr[DEPTH-1], rd_ptr[DEPTH-2:0]};
end

// Binary code conversion
always @(posedge s_clk) begin
    wr_ptr_bin <= wr_ptr_gray;
end

always @(posedge m_clk) begin
    rd_ptr_bin <= rd_ptr_gray;
end

// Clock domain crossing
always @(posedge m_clk) begin
    wr_ptr_gray_sync <= wr_ptr_gray;
    wr_ptr_bin_sync <= wr_ptr_bin;
end

always @(posedge s_clk) begin
    rd_ptr_gray_sync <= rd_ptr_gray;
    rd_ptr_bin_sync <= rd_ptr_bin;
end

// Status logic
always @(posedge s_clk) begin
    s_status_depth <= depth;
    s_status_depth_commit <= depth_commit;
    s_status_overflow <= overflow;
    s_status_bad_frame <= bad_frame;
    s_status_good_frame <= good_frame;
end

always @(posedge m_clk) begin
    m_status_depth <= depth;
    m_status_depth_commit <= depth_commit;
    m_status_overflow <= overflow;
    m_status_bad_frame <= bad_frame;
    m_status_good_frame <= good_frame;
end

// Pause logic
always @(posedge s_clk) begin
    s_pause_ack <= s_pause;
end

always @(posedge m_clk) begin
    m_pause_ack <= m_pause;
end

// Ready logic
always @(posedge s_clk) begin
    s_axis_tready <=!full;
end

assign s_axis_tready =!full;

endmodule

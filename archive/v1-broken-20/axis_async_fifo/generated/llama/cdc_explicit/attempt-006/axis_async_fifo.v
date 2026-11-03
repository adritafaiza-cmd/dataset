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

reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] keep_mem [DEPTH-1:0];
reg [ID_WIDTH-1:0] id_mem [DEPTH-1:0];
reg [DEST_WIDTH-1:0] dest_mem [DEPTH-1:0];
reg [USER_WIDTH-1:0] user_mem [DEPTH-1:0];
reg [DEPTH-1:0] wr_ptr;
reg [DEPTH-1:0] rd_ptr;
reg [DEPTH-1:0] wr_ptr_gray;
reg [DEPTH-1:0] rd_ptr_gray;
reg [DEPTH-1:0] wr_ptr_sync;
reg [DEPTH-1:0] rd_ptr_sync;
reg [DEPTH-1:0] wr_ptr_sync2;
reg [DEPTH-1:0] rd_ptr_sync2;
reg [DATA_WIDTH-1:0] data_out;
reg [KEEP_WIDTH-1:0] keep_out;
reg [ID_WIDTH-1:0] id_out;
reg [DEST_WIDTH-1:0] dest_out;
reg [USER_WIDTH-1:0] user_out;
reg full;
reg empty;
reg overflow;
reg underflow;
reg [DEPTH-1:0] count;
reg [DEPTH-1:0] count_sync;
reg [DEPTH-1:0] count_sync2;
reg s_axis_tready_reg;
reg m_axis_tvalid_reg;
reg s_pause_ack_reg;
reg m_pause_ack_reg;
reg s_status_overflow_reg;
reg m_status_overflow_reg;
reg s_status_bad_frame_reg;
reg m_status_bad_frame_reg;
reg s_status_good_frame_reg;
reg m_status_good_frame_reg;

// Gray encoding
always @(posedge s_clk)
begin
    wr_ptr_gray <= {wr_ptr[DEPTH-2:0], 1'b0} ^ wr_ptr;
end

// Synchronization
always @(posedge m_clk)
begin
    wr_ptr_sync <= wr_ptr_gray;
    wr_ptr_sync2 <= wr_ptr_sync;
end

// Gray decoding
always @(posedge m_clk)
begin
    wr_ptr_sync2 <= wr_ptr_sync;
    if (wr_ptr_sync[DEPTH-1] == wr_ptr_sync2[DEPTH-1])
        count_sync <= wr_ptr_sync;
    else
        count_sync <= {wr_ptr_sync[DEPTH-2:0], 1'b0};
end

// Count calculation
always @(posedge m_clk)
begin
    if (m_rst)
        count_sync2 <= 0;
    else
        count_sync2 <= count_sync;
end

// Empty and full flags
always @(posedge m_clk)
begin
    if (m_rst)
    begin
        empty <= 1'b1;
        full <= 1'b0;
    end
    else
    begin
        if (count_sync2 == 0)
            empty <= 1'b1;
        else
            empty <= 1'b0;
        if (count_sync2 == DEPTH-1)
            full <= 1'b1;
        else
            full <= 1'b0;
    end
end

// Write logic
always @(posedge s_clk)
begin
    if (s_rst)
    begin
        wr_ptr <= 0;
        s_axis_tready_reg <= 1'b1;
    end
    else
    begin
        if (s_axis_tvalid && s_axis_tready_reg)
        begin
            mem[wr_ptr] <= s_axis_tdata;
            keep_mem[wr_ptr] <= s_axis_tkeep;
            id_mem[wr_ptr] <= s_axis_tid;
            dest_mem[wr_ptr] <= s_axis_tdest;
            user_mem[wr_ptr] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end
        if (full)
            s_axis_tready_reg <= 1'b0;
        else
            s_axis_tready_reg <= 1'b1;
    end
end

// Read logic
always @(posedge m_clk)
begin
    if (m_rst)
    begin
        rd_ptr <= 0;
        m_axis_tvalid_reg <= 1'b0;
    end
    else
    begin
        if (m_axis_tready && m_axis_tvalid_reg)
        begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
        end
        if (empty)
            m_axis_tvalid_reg <= 1'b0;
        else
            m_axis_tvalid_reg <= 1'b1;
    end
end

// Output logic
always @(posedge m_clk)
begin
    if (m_rst)
    begin
        data_out <= 0;
        keep_out <= 0;
        id_out <= 0;
        dest_out <= 0;
        user_out <= 0;
    end
    else
    begin
        data_out <= mem[rd_ptr];
        keep_out <= keep_mem[rd_ptr];
        id_out <= id_mem[rd_ptr];
        dest_out <= dest_mem[rd_ptr];
        user_out <= user_mem[rd_ptr];
    end
end

// Status logic
always @(posedge s_clk)
begin
    if (s_rst)
    begin
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
    end
    else
    begin
        if (s_axis_tvalid && s_axis_tready_reg)
        begin
            if (s_axis_tlast)
            begin
                if (s_axis_tuser == USER_BAD_FRAME_VALUE)
                    s_status_bad_frame_reg <= 1'b1;
                else
                    s_status_good_frame_reg <= 1'b1;
            end
        end
        if (full)
            s_status_overflow_reg <= 1'b1;
        else
            s_status_overflow_reg <= 1'b0;
    end
end

always @(posedge m_clk)
begin
    if (m_rst)
    begin
        m_status_overflow_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
    end
    else
    begin
        if (m_axis_tready && m_axis_tvalid_reg)
        begin
            if (m_axis_tlast)
            begin
                if (m_axis_tuser == USER_BAD_FRAME_VALUE)
                    m_status_bad_frame_reg <= 1'b1;
                else
                    m_status_good_frame_reg <= 1'b1;
            end
        end
        if (empty)
            m_status_overflow_reg <= 1'b0;
        else
            m_status_overflow_reg <= 1'b1;
    end
end

// Pause logic
always @(posedge s_clk)
begin
    if (s_rst)
        s_pause_ack_reg <= 1'b0;
    else
    begin
        if (s_pause_req)
            s_pause_ack_reg <= 1'b1;
        else
            s_pause_ack_reg <= 1'b0;
    end
end

always @(posedge m_clk)
begin
    if (m_rst)
        m_pause_ack_reg <= 1'b0;
    else
    begin
        if (m_pause_req)
            m_pause_ack_reg <= 1'b1;
        else
            m_pause_ack_reg <= 1'b0;
    end
end

assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tdata = data_out;
assign m_axis_tkeep = keep_out;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast = (rd_ptr == DEPTH-2) ? 1'b1 : 1'b0;
assign m_axis_tid = id_out;
assign m_axis_tdest = dest_out;
assign m_axis_tuser = user_out;
assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
assign s_status_depth = count_sync2;
assign s_status_depth_commit = count_sync2;
assign s_status_overflow = s_status_overflow_reg;
assign s_status_bad_frame = s_status_bad_frame_reg;
assign s_status_good_frame = s_status_good_frame_reg;
assign m_status_depth = count_sync2;
assign m_status_depth_commit = count_sync2;
assign m_status_overflow = m_status_overflow_reg;
assign m_status_bad_frame = m_status_bad_frame_reg;
assign m_status_good_frame = m_status_good_frame_reg;

endmodule

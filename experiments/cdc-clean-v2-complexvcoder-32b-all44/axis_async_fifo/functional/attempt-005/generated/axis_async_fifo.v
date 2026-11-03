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

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [1:0] mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

    reg [ADDR_WIDTH:0] s_depth, s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth, m_depth_commit;

    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    reg s_pause_ack_reg, m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_rd_ptr <= 0;
            s_rd_ptr_gray <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_wr_ptr, next_rd_ptr;
            reg [ADDR_WIDTH:0] next_depth;

            next_wr_ptr = s_wr_ptr;
            next_rd_ptr = s_rd_ptr;
            next_depth = s_depth;

            if (s_axis_tvalid && s_axis_tready) begin
                mem_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tlast, s_axis_tlast};
                if (ID_ENABLE)
                    mem_id[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE)
                    mem_dest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE)
                    mem_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;

                next_wr_ptr = s_wr_ptr + 1;
                next_depth = s_depth + 1;
            end

            if (m_axis_tvalid && m_axis_tready) begin
                next_rd_ptr = s_rd_ptr + 1;
                next_depth = s_depth - 1;
            end

            s_wr_ptr <= next_wr_ptr;
            s_wr_ptr_gray <= (next_wr_ptr >> 1) ^ next_wr_ptr;
            s_rd_ptr <= next_rd_ptr;
            s_rd_ptr_gray <= (next_rd_ptr >> 1) ^ next_rd_ptr;
            s_depth <= next_depth;
            s_depth_commit <= next_depth;

            s_overflow <= (next_depth == DEPTH);
            s_pause_ack_reg <= s_pause_req;

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                if (USER_ENABLE && (mem_user[s_wr_ptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    s_bad_frame <= 1;
                else
                    s_good_frame <= 1;
            end else if (s_axis_tready) begin
                s_bad_frame <= 0;
                s_good_frame <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 0;
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_wr_ptr, next_rd_ptr;
            reg [ADDR_WIDTH:0] next_depth;

            next_wr_ptr = m_wr_ptr;
            next_rd_ptr = m_rd_ptr;
            next_depth = m_depth;

            if (m_axis_tvalid && m_axis_tready) begin
                next_rd_ptr = m_rd_ptr + 1;
                next_depth = m_depth - 1;
            end

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) begin
                next_wr_ptr = m_wr_ptr + 1;
                next_depth = m_depth + 1;
            end

            m_wr_ptr <= next_wr_ptr;
            m_wr_ptr_gray <= (next_wr_ptr >> 1) ^ next_wr_ptr;
            m_rd_ptr <= next_rd_ptr;
            m_rd_ptr_gray <= (next_rd_ptr >> 1) ^ next_rd_ptr;
            m_depth <= next_depth;
            m_depth_commit <= next_depth;

            m_overflow <= (next_depth == DEPTH);
            m_pause_ack_reg <= m_pause_req;

            if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                if (USER_ENABLE && (mem_user[m_rd_ptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    m_bad_frame <= 1;
                else
                    m_good_frame <= 1;
            end else if (m_axis_tready) begin
                m_bad_frame <= 0;
                m_good_frame <= 0;
            end
        end
    end

    reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg [1:0] s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tlast_reg <= {s_axis_tlast, s_axis_tlast};
            if (ID_ENABLE)
                s_axis_tid_reg <= s_axis_tid;
            if (DEST_ENABLE)
                s_axis_tdest_reg <= s_axis_tdest;
            if (USER_ENABLE)
                s_axis_tuser_reg <= s_axis_tuser;
        end
    end

    assign s_axis_tready = (s_depth < DEPTH);

    assign m_axis_tdata = mem_data[m_rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = mem_keep[m_rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tvalid = (m_depth > 0);
    assign m_axis_tlast = mem_last[m_rd_ptr[ADDR_WIDTH-1:0]][0];
    assign m_axis_tid = ID_ENABLE ? mem_id[m_rd_ptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tdest = DEST_ENABLE ? mem_dest[m_rd_ptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tuser = USER_ENABLE ? mem_user[m_rd_ptr[ADDR_WIDTH-1:0]] : 0;

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

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

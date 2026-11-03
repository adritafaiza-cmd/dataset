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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH-1:0] wr_cnt;
    reg [ADDR_WIDTH-1:0] rd_cnt;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [LAST_ENABLE?0:1] last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg [ADDR_WIDTH-1:0] wr_ptr_reg;
    reg [ADDR_WIDTH-1:0] rd_ptr_reg;
    reg [ADDR_WIDTH-1:0] wr_cnt_reg;
    reg [ADDR_WIDTH-1:0] rd_cnt_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_cnt <= 0;
            rd_cnt <= 0;
            s_axis_tready_reg <= 1;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            s_axis_tready_reg <= 1;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;

            if (s_axis_tvalid && s_axis_tready_reg && !s_pause_req) begin
                mem[wr_ptr] <= s_axis_tdata;
                if (KEEP_ENABLE) begin
                    keep_mem[wr_ptr] <= s_axis_tkeep;
                end
                if (LAST_ENABLE) begin
                    last_mem[wr_ptr] <= s_axis_tlast;
                end
                if (ID_ENABLE) begin
                    id_mem[wr_ptr] <= s_axis_tid;
                end
                if (DEST_ENABLE) begin
                    dest_mem[wr_ptr] <= s_axis_tdest;
                end
                if (USER_ENABLE) begin
                    user_mem[wr_ptr] <= s_axis_tuser;
                end
                wr_ptr <= wr_ptr + 1;
                wr_cnt <= wr_cnt + 1;
            end

            if (m_axis_tready && m_axis_tvalid_reg) begin
                rd_ptr <= rd_ptr + 1;
                rd_cnt <= rd_cnt - 1;
            end

            if (rd_cnt > 0) begin
                m_axis_tdata <= mem[rd_ptr];
                if (KEEP_ENABLE) begin
                    m_axis_tkeep <= keep_mem[rd_ptr];
                end
                if (LAST_ENABLE) begin
                    m_axis_tlast <= last_mem[rd_ptr];
                end
                if (ID_ENABLE) begin
                    m_axis_tid <= id_mem[rd_ptr];
                end
                if (DEST_ENABLE) begin
                    m_axis_tdest <= dest_mem[rd_ptr];
                end
                if (USER_ENABLE) begin
                    m_axis_tuser <= user_mem[rd_ptr];
                end
                m_axis_tvalid_reg <= 1;
                if (m_axis_tlast) begin
                    m_axis_tlast_reg <= 1;
                end
            end

            if (wr_cnt > rd_cnt) begin
                s_axis_tready_reg <= 0;
            end

            if (wr_cnt == DEPTH) begin
                s_status_overflow <= 1;
            end else begin
                s_status_overflow <= 0;
            end

            s_status_depth <= wr_cnt;
            s_status_depth_commit <= wr_cnt;
            s_status_bad_frame <= 0;
            s_status_good_frame <= 1;

            m_status_depth <= wr_cnt;
            m_status_depth_commit <= wr_cnt;
            m_status_overflow <= 0;
            m_status_bad_frame <= 0;
            m_status_good_frame <= 1;
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

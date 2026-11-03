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
    reg [ADDR_WIDTH-1:0] cnt;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            s_axis_tready_reg <= 1;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem[wr_ptr] <= s_axis_tdata;
                keep_mem[wr_ptr] <= s_axis_tkeep;
                user_mem[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                if (s_axis_tlast) begin
                    cnt <= cnt + 1;
                end
            end

            if (m_axis_tready && m_axis_tvalid) begin
                rd_ptr <= rd_ptr + 1;
                if (m_axis_tlast) begin
                    cnt <= cnt - 1;
                end
            end

            s_axis_tready_reg <= (cnt < DEPTH);
            m_axis_tvalid_reg <= (rd_ptr != wr_ptr);
            m_axis_tlast_reg <= (rd_ptr == (wr_ptr - 1));
            m_axis_tdata_reg <= mem[rd_ptr];
            m_axis_tkeep_reg <= keep_mem[rd_ptr];
            m_axis_tuser_reg <= user_mem[rd_ptr];
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    assign s_status_depth = cnt;
    assign s_status_depth_commit = cnt;
    assign s_status_overflow = (cnt == DEPTH);
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;

    assign m_status_depth = cnt;
    assign m_status_depth_commit = cnt;
    assign m_status_overflow = (cnt == DEPTH);
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;
endmodule

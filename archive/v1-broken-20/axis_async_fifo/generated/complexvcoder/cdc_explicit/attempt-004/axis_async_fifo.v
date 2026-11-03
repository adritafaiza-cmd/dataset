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
    logic [DATA_WIDTH-1:0] s_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    logic s_axis_tvalid_reg;
    logic s_axis_tlast_reg;
    logic [ID_WIDTH-1:0] s_axis_tid_reg;
    logic [DEST_WIDTH-1:0] s_axis_tdest_reg;
    logic [USER_WIDTH-1:0] s_axis_tuser_reg;
    logic s_axis_tready_reg;

    logic [DATA_WIDTH-1:0] m_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    logic m_axis_tvalid_reg;
    logic m_axis_tlast_reg;
    logic [ID_WIDTH-1:0] m_axis_tid_reg;
    logic [DEST_WIDTH-1:0] m_axis_tdest_reg;
    logic [USER_WIDTH-1:0] m_axis_tuser_reg;
    logic m_axis_tready_reg;

    logic [DEPTH-1:0] wr_ptr;
    logic [DEPTH-1:0] rd_ptr;
    logic full;
    logic empty;
    logic [DEPTH-1:0] count;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Synchronous FIFO logic
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (!full && s_axis_tvalid && s_axis_tready) begin
                mem[wr_ptr] <= s_axis_tdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH - 1) begin
                    wr_ptr <= 0;
                end
                if (empty) begin
                    empty <= 0;
                end
                if (full) begin
                    full <= 1;
                end else begin
                    full <= 0;
                end
            end
            if (!empty && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH - 1) begin
                    rd_ptr <= 0;
                end
                if (empty) begin
                    empty <= 1;
                end
                if (full) begin
                    full <= 0;
                end else begin
                    full <= 0;
                end
            end
        end
    end

    assign s_axis_tready = !full || (DROP_WHEN_FULL && m_axis_tready);

    assign m_axis_tdata = mem[rd_ptr];
    assign m_axis_tkeep = mem[rd_ptr + 1][KEEP_WIDTH-1:0];
    assign m_axis_tvalid = !empty;
    assign m_axis_tlast = (rd_ptr == wr_ptr - 1);
    assign m_axis_tid = mem[rd_ptr + 2][ID_WIDTH-1:0];
    assign m_axis_tdest = mem[rd_ptr + 3][DEST_WIDTH-1:0];
    assign m_axis_tuser = mem[rd_ptr + 4][USER_WIDTH-1:0];

    assign s_status_depth = count;
    assign s_status_depth_commit = count;
    assign s_status_overflow = full;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = !full;

    assign m_status_depth = count;
    assign m_status_depth_commit = count;
    assign m_status_overflow = full;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = !full;

    // Pause logic
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            s_pause_ack <= s_pause_req;
        end
    end

    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            m_pause_ack <= m_pause_req;
        end
    end

endmodule

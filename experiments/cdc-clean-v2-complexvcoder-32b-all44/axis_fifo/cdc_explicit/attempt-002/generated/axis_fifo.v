module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
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
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

localparam ADDR_WIDTH = $clog2(DEPTH);

reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
reg                  mem_last [DEPTH-1:0];
reg [ID_WIDTH-1:0]   mem_id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

reg [ADDR_WIDTH:0] wr_ptr;
reg [ADDR_WIDTH:0] rd_ptr;
reg [ADDR_WIDTH:0] depth;

reg s_axis_tready_reg;
reg m_axis_tvalid_reg;
reg m_axis_tlast_reg;
reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg [ID_WIDTH-1:0] m_axis_tid_reg;
reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
reg [USER_WIDTH-1:0] m_axis_tuser_reg;

reg status_overflow_reg;
reg status_bad_frame_reg;
reg status_good_frame_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        depth <= 0;
        s_axis_tready_reg <= 0;
        m_axis_tvalid_reg <= 0;
        status_overflow_reg <= 0;
        status_bad_frame_reg <= 0;
        status_good_frame_reg <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            mem_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            mem_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            mem_id[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            mem_dest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            mem_user[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
            depth <= depth + 1;
        end
        if (m_axis_tvalid_reg && m_axis_tready) begin
            rd_ptr <= rd_ptr + 1;
            depth <= depth - 1;
            if (m_axis_tlast_reg) begin
                status_good_frame_reg <= 1;
            end
        end else begin
            status_good_frame_reg <= 0;
        end

        if (s_axis_tvalid && s_axis_tready_reg && depth == DEPTH) begin
            status_overflow_reg <= 1;
        end else begin
            status_overflow_reg <= 0;
        end

        if (s_axis_tvalid && s_axis_tready_reg && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
            status_bad_frame_reg <= 1;
        end else begin
            status_bad_frame_reg <= 0;
        end
    end
end

assign s_axis_tready = (depth < DEPTH) && !DROP_WHEN_FULL;
assign m_axis_tdata = mem_data[rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tkeep = mem_keep[rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tid = mem_id[rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tdest = mem_dest[rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tuser = mem_user[rd_ptr[ADDR_WIDTH-1:0]];
assign pause_ack = 0; // No pause functionality implemented
assign status_depth = depth;
assign status_depth_commit = depth;
assign status_overflow = status_overflow_reg;
assign status_bad_frame = status_bad_frame_reg;
assign status_good_frame = status_good_frame_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        m_axis_tvalid_reg <= 0;
        m_axis_tlast_reg <= 0;
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tid_reg <= 0;
        m_axis_tdest_reg <= 0;
        m_axis_tuser_reg <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            m_axis_tvalid_reg <= 1;
            m_axis_tlast_reg <= s_axis_tlast;
            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tkeep_reg <= s_axis_tkeep;
            m_axis_tid_reg <= s_axis_tid;
            m_axis_tdest_reg <= s_axis_tdest;
            m_axis_tuser_reg <= s_axis_tuser;
        end else if (m_axis_tvalid_reg && m_axis_tready) begin
            m_axis_tvalid_reg <= 0;
        end
    end
end

endmodule

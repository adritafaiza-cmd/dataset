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

reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] keep_mem [DEPTH-1:0];
reg [ID_WIDTH-1:0] id_mem [DEPTH-1:0];
reg [DEST_WIDTH-1:0] dest_mem [DEPTH-1:0];
reg [USER_WIDTH-1:0] user_mem [DEPTH-1:0];
reg [DEPTH-1:0] last_mem;

reg [$clog2(DEPTH)-1:0] wr_ptr;
reg [$clog2(DEPTH)-1:0] rd_ptr;
reg [$clog2(DEPTH)-1:0] commit_ptr;

reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg [ID_WIDTH-1:0] m_axis_tid_reg;
reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
reg [USER_WIDTH-1:0] m_axis_tuser_reg;
reg m_axis_tlast_reg;

reg [DATA_WIDTH-1:0] output_fifo [OUTPUT_FIFO_ENABLE ? 2 : 1];
reg [KEEP_WIDTH-1:0] output_fifo_keep [OUTPUT_FIFO_ENABLE ? 2 : 1];
reg [ID_WIDTH-1:0] output_fifo_id [OUTPUT_FIFO_ENABLE ? 2 : 1];
reg [DEST_WIDTH-1:0] output_fifo_dest [OUTPUT_FIFO_ENABLE ? 2 : 1];
reg [USER_WIDTH-1:0] output_fifo_user [OUTPUT_FIFO_ENABLE ? 2 : 1];
reg [OUTPUT_FIFO_ENABLE ? 2 : 1] output_fifo_last;

reg pause_ack_reg;
reg status_overflow_reg;
reg status_bad_frame_reg;
reg status_good_frame_reg;

integer i;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        commit_ptr <= 0;
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tid_reg <= 0;
        m_axis_tdest_reg <= 0;
        m_axis_tuser_reg <= 0;
        m_axis_tlast_reg <= 0;
        pause_ack_reg <= 0;
        status_overflow_reg <= 0;
        status_bad_frame_reg <= 0;
        status_good_frame_reg <= 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] <= 0;
            keep_mem[i] <= 0;
            id_mem[i] <= 0;
            dest_mem[i] <= 0;
            user_mem[i] <= 0;
            last_mem[i] <= 0;
        end
        for (i = 0; i < OUTPUT_FIFO_ENABLE ? 2 : 1; i = i + 1) begin
            output_fifo[i] <= 0;
            output_fifo_keep[i] <= 0;
            output_fifo_id[i] <= 0;
            output_fifo_dest[i] <= 0;
            output_fifo_user[i] <= 0;
            output_fifo_last[i] <= 0;
        end
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_ptr] <= s_axis_tdata;
            keep_mem[wr_ptr] <= s_axis_tkeep;
            id_mem[wr_ptr] <= s_axis_tid;
            dest_mem[wr_ptr] <= s_axis_tdest;
            user_mem[wr_ptr] <= s_axis_tuser;
            last_mem[wr_ptr] <= s_axis_tlast;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH - 1) begin
                wr_ptr <= 0;
            end
        end
        if (m_axis_tready && m_axis_tvalid) begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH - 1) begin
                rd_ptr <= 0;
            end
        end
        if (pause_req) begin
            pause_ack_reg <= 1;
        end else begin
            pause_ack_reg <= 0;
        end
        if (wr_ptr == rd_ptr && last_mem[rd_ptr]) begin
            status_good_frame_reg <= 1;
        end else begin
            status_good_frame_reg <= 0;
        end
        if (wr_ptr == rd_ptr && !last_mem[rd_ptr]) begin
            status_bad_frame_reg <= 1;
        end else begin
            status_bad_frame_reg <= 0;
        end
        if (wr_ptr == DEPTH - 1 && s_axis_tvalid && s_axis_tready) begin
            status_overflow_reg <= 1;
        end else begin
            status_overflow_reg <= 0;
        end
        if (OUTPUT_FIFO_ENABLE) begin
            if (m_axis_tready && m_axis_tvalid) begin
                output_fifo[1] <= output_fifo[0];
                output_fifo_keep[1] <= output_fifo_keep[0];
                output_fifo_id[1] <= output_fifo_id[0];
                output_fifo_dest[1] <= output_fifo_dest[0];
                output_fifo_user[1] <= output_fifo_user[0];
                output_fifo_last[1] <= output_fifo_last[0];
                output_fifo[0] <= mem[rd_ptr];
                output_fifo_keep[0] <= keep_mem[rd_ptr];
                output_fifo_id[0] <= id_mem[rd_ptr];
                output_fifo_dest[0] <= dest_mem[rd_ptr];
                output_fifo_user[0] <= user_mem[rd_ptr];
                output_fifo_last[0] <= last_mem[rd_ptr];
            end
        end
    end
end

assign s_axis_tready = (wr_ptr != rd_ptr) || (OUTPUT_FIFO_ENABLE && output_fifo_last[0]);
assign m_axis_tdata = OUTPUT_FIFO_ENABLE ? output_fifo[1] : mem[rd_ptr];
assign m_axis_tkeep = OUTPUT_FIFO_ENABLE ? output_fifo_keep[1] : keep_mem[rd_ptr];
assign m_axis_tvalid = OUTPUT_FIFO_ENABLE ? output_fifo_last[1] : last_mem[rd_ptr];
assign m_axis_tlast = OUTPUT_FIFO_ENABLE ? output_fifo_last[1] : last_mem[rd_ptr];
assign m_axis_tid = OUTPUT_FIFO_ENABLE ? output_fifo_id[1] : id_mem[rd_ptr];
assign m_axis_tdest = OUTPUT_FIFO_ENABLE ? output_fifo_dest[1] : dest_mem[rd_ptr];
assign m_axis_tuser = OUTPUT_FIFO_ENABLE ? output_fifo_user[1] : user_mem[rd_ptr];
assign pause_ack = pause_ack_reg;
assign status_depth = wr_ptr;
assign status_depth_commit = commit_ptr;
assign status_overflow = status_overflow_reg;
assign status_bad_frame = status_bad_frame_reg;
assign status_good_frame = status_good_frame_reg;

endmodule

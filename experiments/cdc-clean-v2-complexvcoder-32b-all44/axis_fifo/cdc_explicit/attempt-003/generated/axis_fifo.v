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

reg [DATA_WIDTH-1:0]  mem_tdata [0:DEPTH-1];
reg [KEEP_WIDTH-1:0]  mem_tkeep [0:DEPTH-1];
reg                   mem_tlast [0:DEPTH-1];
reg [ID_WIDTH-1:0]    mem_tid [0:DEPTH-1];
reg [DEST_WIDTH-1:0]  mem_tdest [0:DEPTH-1];
reg [USER_WIDTH-1:0]  mem_tuser [0:DEPTH-1];

reg [ADDR_WIDTH-1:0]  wr_ptr;
reg [ADDR_WIDTH-1:0]  rd_ptr;
reg [ADDR_WIDTH-1:0]  wr_ptr_gray;
reg [ADDR_WIDTH-1:0]  rd_ptr_gray;
reg [ADDR_WIDTH:0]    fifo_count;

reg                   fifo_full;
reg                   fifo_empty;
reg                   fifo_wr_en;
reg                   fifo_rd_en;

reg                   frame_bad;
reg                   frame_good;
reg [ADDR_WIDTH:0]    frame_count;

reg                   pause_state;

wire [DATA_WIDTH-1:0] dout_tdata;
wire [KEEP_WIDTH-1:0] dout_tkeep;
wire                  dout_tlast;
wire [ID_WIDTH-1:0]   dout_tid;
wire [DEST_WIDTH-1:0] dout_tdest;
wire [USER_WIDTH-1:0] dout_tuser;

assign s_axis_tready = ~fifo_full & ~pause_state;
assign pause_ack     = pause_state;

assign dout_tdata = mem_tdata[rd_ptr];
assign dout_tkeep = mem_tkeep[rd_ptr];
assign dout_tlast = mem_tlast[rd_ptr];
assign dout_tid   = mem_tid[rd_ptr];
assign dout_tdest = mem_tdest[rd_ptr];
assign dout_tuser = mem_tuser[rd_ptr];

assign m_axis_tdata  = dout_tdata;
assign m_axis_tkeep  = dout_tkeep;
assign m_axis_tvalid = ~fifo_empty & m_axis_tready;
assign m_axis_tlast  = dout_tlast;
assign m_axis_tid    = dout_tid;
assign m_axis_tdest  = dout_tdest;
assign m_axis_tuser  = dout_tuser;

assign status_depth       = fifo_count;
assign status_depth_commit= fifo_count;
assign status_overflow    = fifo_full;
assign status_bad_frame   = frame_bad;
assign status_good_frame  = frame_good;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr        <= 0;
        rd_ptr        <= 0;
        wr_ptr_gray   <= 0;
        rd_ptr_gray   <= 0;
        fifo_count    <= 0;
        fifo_full     <= 0;
        fifo_empty    <= 1;
        fifo_wr_en    <= 0;
        fifo_rd_en    <= 0;
        frame_bad     <= 0;
        frame_good    <= 0;
        frame_count   <= 0;
        pause_state   <= 0;
    end else begin
        fifo_wr_en <= s_axis_tvalid & s_axis_tready;
        fifo_rd_en <= m_axis_tvalid & m_axis_tready;

        if (fifo_wr_en) begin
            mem_tdata[wr_ptr] <= s_axis_tdata;
            mem_tkeep[wr_ptr] <= s_axis_tkeep;
            mem_tlast[wr_ptr] <= s_axis_tlast;
            mem_tid[wr_ptr]   <= s_axis_tid;
            mem_tdest[wr_ptr] <= s_axis_tdest;
            mem_tuser[wr_ptr] <= s_axis_tuser;
        end

        if (fifo_wr_en & ~fifo_full) begin
            wr_ptr <= wr_ptr + 1;
        end

        if (fifo_rd_en & ~fifo_empty) begin
            rd_ptr <= rd_ptr + 1;
        end

        wr_ptr_gray <= (wr_ptr >> 1) ^ wr_ptr;
        rd_ptr_gray <= (rd_ptr >> 1) ^ rd_ptr;

        fifo_full  <= (wr_ptr_gray == {~rd_ptr_gray[ADDR_WIDTH-1], rd_ptr_gray[ADDR_WIDTH-2:0]});
        fifo_empty <= (wr_ptr_gray == rd_ptr_gray);

        if (fifo_wr_en & ~fifo_full)
            fifo_count <= fifo_count + 1;
        else if (fifo_rd_en & ~fifo_empty)
            fifo_count <= fifo_count - 1;

        if (s_axis_tvalid & s_axis_tready) begin
            if (s_axis_tlast) begin
                if (frame_count > DEPTH) begin
                    frame_bad <= DROP_OVERSIZE_FRAME;
                end else begin
                    frame_good <= 1;
                end
                frame_count <= 0;
            end else begin
                frame_count <= frame_count + 1;
            end
        end

        if (m_axis_tvalid & m_axis_tready & dout_tlast) begin
            frame_bad  <= 0;
            frame_good <= 0;
        end

        if (PAUSE_ENABLE) begin
            if (pause_req & ~pause_state) begin
                pause_state <= 1;
            end else if (m_axis_tready & ~pause_req & pause_state) begin
                pause_state <= 0;
            end
        end
    end
end

endmodule

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

    // Internal signals for FIFO
    wire [S_DATA_WIDTH-1:0]  s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep_reg;
    wire                     s_axis_tvalid_reg;
    wire                     s_axis_tlast_reg;
    wire [ID_WIDTH-1:0]      s_axis_tid_reg;
    wire [DEST_WIDTH-1:0]    s_axis_tdest_reg;
    wire [USER_WIDTH-1:0]    s_axis_tuser_reg;
    wire                     s_axis_tready_reg;
    wire                     s_axis_tready_reg_q;
    wire [M_DATA_WIDTH-1:0]  m_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep_reg;
    wire                     m_axis_tvalid_reg;
    wire                     m_axis_tlast_reg;
    wire [ID_WIDTH-1:0]      m_axis_tid_reg;
    wire [DEST_WIDTH-1:0]    m_axis_tdest_reg;
    wire [USER_WIDTH-1:0]    m_axis_tuser_reg;
    wire                     m_axis_tready_reg;
    wire                     m_axis_tready_reg_q;

    // FIFOs for data, keep, valid, last, id, dest, and user
    axis_async_fifo #(
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .DEPTH(DEPTH)
    ) s_axis_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_tdata),
        .tkeep(s_axis_tkeep),
        .tvalid(s_axis_tvalid),
        .tready(s_axis_tready_reg),
        .tlast(s_axis_tlast),
        .tid(s_axis_tid),
        .tdest(s_axis_tdest),
        .tuser(s_axis_tuser),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_overflow(s_status_overflow),
        .status_bad_frame(s_status_bad_frame),
        .status_good_frame(s_status_good_frame)
    );

    axis_async_fifo #(
        .DATA_WIDTH(M_DATA_WIDTH),
        .KEEP_WIDTH(M_KEEP_WIDTH),
        .DEPTH(DEPTH)
    ) m_axis_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(m_axis_tdata),
        .tkeep(m_axis_tkeep),
        .tvalid(m_axis_tvalid),
        .tready(m_axis_tready_reg),
        .tlast(m_axis_tlast),
        .tid(m_axis_tid),
        .tdest(m_axis_tdest),
        .tuser(m_axis_tuser),
        .status_depth(m_status_depth),
        .status_depth_commit(m_status_depth_commit),
        .status_overflow(m_status_overflow),
        .status_bad_frame(m_status_bad_frame),
        .status_good_frame(m_status_good_frame)
    );

    // Width adapter for data, keep, valid, last, id, dest, and user
    axis_width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) width_adapter (
        .clk(s_clk),
        .rst(s_rst),
        .s_axis_tdata(s_axis_tdata_reg),
        .s_axis_tkeep(s_axis_tkeep_reg),
        .s_axis_tvalid(s_axis_tvalid_reg),
        .s_axis_tlast(s_axis_tlast_reg),
        .s_axis_tid(s_axis_tid_reg),
        .s_axis_tdest(s_axis_tdest_reg),
        .s_axis_tuser(s_axis_tuser_reg),
        .m_axis_tdata(m_axis_tdata_reg),
        .m_axis_tkeep(m_axis_tkeep_reg),
        .m_axis_tvalid(m_axis_tvalid_reg),
        .m_axis_tlast(m_axis_tlast_reg),
        .m_axis_tid(m_axis_tid_reg),
        .m_axis_tdest(m_axis_tdest_reg),
        .m_axis_tuser(m_axis_tuser_reg)
    );

    // Pause logic for input and output
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Register outputs for synchronous interfaces
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 1'b0;
        end else begin
            s_axis_tready_reg <= s_axis_tready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tready_reg <= 1'b0;
        end else begin
            m_axis_tready_reg <= m_axis_tready;
        end
    end

endmodule

module axis_async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter DEPTH = 4096
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [DATA_WIDTH-1:0]  tdata,
    input  wire [KEEP_WIDTH-1:0]  tkeep,
    input  wire                     tvalid,
    output wire                     tready,
    input  wire                     tlast,
    input  wire [7:0]               tid,
    input  wire [7:0]               tdest,
    input  wire [7:0]               tuser,
    output wire [$clog2(DEPTH):0]   status_depth,
    output wire [$clog2(DEPTH):0]   status_depth_commit,
    output wire                     status_overflow,
    output wire                     status_bad_frame,
    output wire                     status_good_frame
);

    // Internal signals
    reg [DATA_WIDTH-1:0]  mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  keep_mem [0:DEPTH-1];
    reg                     valid_mem [0:DEPTH-1];
    reg                     last_mem [0:DEPTH-1];
    reg [7:0]               tid_mem [0:DEPTH-1];
    reg [7:0]               tdest_mem [0:DEPTH-1];
    reg [7:0]               tuser_mem [0:DEPTH-1];
    reg [31:0]              wr_ptr;
    reg [31:0]              rd_ptr;
    reg                     wr_en;
    reg                     rd_en;
    reg                     full;
    reg                     empty;

    // Write process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_en <= 0;
        end else begin
            if (tvalid && tready) begin
                mem[wr_ptr] <= tdata;
                keep_mem[wr_ptr] <= tkeep;
                valid_mem[wr_ptr] <= tvalid;
                last_mem[wr_ptr] <= tlast;
                tid_mem[wr_ptr] <= tid;
                tdest_mem[wr_ptr] <= tdest;
                tuser_mem[wr_ptr] <= tuser;
                wr_ptr <= wr_ptr + 1;
                wr_en <= 1;
            end else begin
                wr_en <= 0;
            end
        end
    end

    // Read process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_en <= 0;
        end else begin
            if (m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
                rd_en <= 1;
            end else begin
                rd_en <= 0;
            end
        end
    end

    // Output logic
    assign tdata = mem[rd_ptr];
    assign tkeep = keep_mem[rd_ptr];
    assign tvalid = valid_mem[rd_ptr];
    assign tlast = last_mem[rd_ptr];
    assign tid = tid_mem[rd_ptr];
    assign tdest = tdest_mem[rd_ptr];
    assign tuser = tuser_mem[rd_ptr];

    // Full and empty flags
    assign full = (wr_ptr == rd_ptr) && wr_en;
    assign empty = (wr_ptr == rd_ptr) && !wr_en;

    // Status outputs
    assign status_depth = wr_ptr - rd_ptr;
    assign status_depth_commit = wr_ptr - rd_ptr;
    assign status_overflow = full;
    assign status_bad_frame = 1'b0;
    assign status_good_frame = 1'b1;

endmodule

module axis_width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = 1,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = 1,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 1,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 1,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal signals
    wire [S_DATA_WIDTH-1:0]  s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep_reg;
    wire                     s_axis_tvalid_reg;
    wire                     s_axis_tlast_reg;
    wire [ID_WIDTH-1:0]      s_axis_tid_reg;
    wire [DEST_WIDTH-1:0]    s_axis_tdest_reg;
    wire [USER_WIDTH-1:0]    s_axis_tuser_reg;
    wire                     s_axis_tready_reg;

    // Register inputs for synchronous interfaces
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end
    end

    // Output logic
    assign m_axis_tdata = s_axis_tdata_reg;
    assign m_axis_tkeep = s_axis_tkeep_reg;
    assign m_axis_tvalid = s_axis_tvalid_reg;
    assign m_axis_tlast = s_axis_tlast_reg;
    assign m_axis_tid = s_axis_tid_reg;
    assign m_axis_tdest = s_axis_tdest_reg;
    assign m_axis_tuser = s_axis_tuser_reg;

    // Ready logic
    assign s_axis_tready = m_axis_tready;

endmodule

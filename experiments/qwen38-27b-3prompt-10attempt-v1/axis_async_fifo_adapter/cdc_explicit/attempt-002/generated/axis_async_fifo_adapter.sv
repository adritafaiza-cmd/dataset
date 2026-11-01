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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signal declarations
    wire [S_DATA_WIDTH-1:0] s_axis_tdata_int;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_int;
    wire s_axis_tvalid_int;
    wire s_axis_tready_int;
    wire s_axis_tlast_int;
    wire [ID_WIDTH-1:0] s_axis_tid_int;
    wire [DEST_WIDTH-1:0] s_axis_tdest_int;
    wire [USER_WIDTH-1:0] s_axis_tuser_int;

    wire [M_DATA_WIDTH-1:0] m_axis_tdata_int;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_int;
    wire m_axis_tvalid_int;
    wire m_axis_tready_int;
    wire m_axis_tlast_int;
    wire [ID_WIDTH-1:0] m_axis_tid_int;
    wire [DEST_WIDTH-1:0] m_axis_tdest_int;
    wire [USER_WIDTH-1:0] m_axis_tuser_int;

    wire s_pause_req_int;
    wire s_pause_ack_int;
    wire m_pause_req_int;
    wire m_pause_ack_int;

    wire [$clog2(DEPTH):0] s_status_depth_int;
    wire [$clog2(DEPTH):0] s_status_depth_commit_int;
    wire s_status_overflow_int;
    wire s_status_bad_frame_int;
    wire s_status_good_frame_int;

    wire [$clog2(DEPTH):0] m_status_depth_int;
    wire [$clog2(DEPTH):0] m_status_depth_commit_int;
    wire m_status_overflow_int;
    wire m_status_bad_frame_int;
    wire m_status_good_frame_int;

    // Assign outputs
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;
    assign s_pause_ack = s_pause_ack_int;
    assign m_pause_ack = m_pause_ack_int;
    assign s_status_depth = s_status_depth_int;
    assign s_status_depth_commit = s_status_depth_commit_int;
    assign s_status_overflow = s_status_overflow_int;
    assign s_status_bad_frame = s_status_bad_frame_int;
    assign s_status_good_frame = s_status_good_frame_int;
    assign m_status_depth = m_status_depth_int;
    assign m_status_depth_commit = m_status_depth_commit_int;
    assign m_status_overflow = m_status_overflow_int;
    assign m_status_bad_frame = m_status_bad_frame_int;
    assign m_status_good_frame = m_status_good_frame_int;

    // Assign inputs to internal signals
    assign s_axis_tdata_int = s_axis_tdata;
    assign s_axis_tkeep_int = s_axis_tkeep;
    assign s_axis_tvalid_int = s_axis_tvalid;
    assign s_axis_tlast_int = s_axis_tlast;
    assign s_axis_tid_int = s_axis_tid;
    assign s_axis_tdest_int = s_axis_tdest;
    assign s_axis_tuser_int = s_axis_tuser;
    assign m_axis_tready_int = m_axis_tready;
    assign s_pause_req_int = s_pause_req;
    assign m_pause_req_int = m_pause_req;

    // FIFO implementation
    wire [S_DATA_WIDTH-1:0] fifo_din_data;
    wire [S_KEEP_WIDTH-1:0] fifo_din_keep;
    wire fifo_din_last;
    wire [ID_WIDTH-1:0] fifo_din_tid;
    wire [DEST_WIDTH-1:0] fifo_din_tdest;
    wire [USER_WIDTH-1:0] fifo_din_tuser;
    wire fifo_din_valid;
    wire fifo_din_ready;

    wire [M_DATA_WIDTH-1:0] fifo_dout_data;
    wire [M_KEEP_WIDTH-1:0] fifo_dout_keep;
    wire fifo_dout_last;
    wire [ID_WIDTH-1:0] fifo_dout_tid;
    wire [DEST_WIDTH-1:0] fifo_dout_tdest;
    wire [USER_WIDTH-1:0] fifo_dout_tuser;
    wire fifo_dout_valid;
    wire fifo_dout_ready;

    wire fifo_full;
    wire fifo_empty;
    wire [$clog2(DEPTH):0] fifo_depth;
    wire [$clog2(DEPTH):0] fifo_depth_commit;

    // Connect FIFO inputs
    assign fifo_din_data = s_axis_tdata_int;
    assign fifo_din_keep = s_axis_tkeep_int;
    assign fifo_din_last = s_axis_tlast_int;
    assign fifo_din_tid = s_axis_tid_int;
    assign fifo_din_tdest = s_axis_tdest_int;
    assign fifo_din_tuser = s_axis_tuser_int;
    assign fifo_din_valid = s_axis_tvalid_int;
    assign s_axis_tready_int = fifo_din_ready;

    // Connect FIFO outputs
    assign m_axis_tdata_int = fifo_dout_data;
    assign m_axis_tkeep_int = fifo_dout_keep;
    assign m_axis_tlast_int = fifo_dout_last;
    assign m_axis_tid_int = fifo_dout_tid;
    assign m_axis_tdest_int = fifo_dout_tdest;
    assign m_axis_tuser_int = fifo_dout_tuser;
    assign m_axis_tvalid_int = fifo_dout_valid;
    assign fifo_dout_ready = m_axis_tready_int;

    // Connect status
    assign s_status_depth_int = fifo_depth;
    assign s_status_depth_commit_int = fifo_depth_commit;
    assign m_status_depth_int = fifo_depth;
    assign m_status_depth_commit_int = fifo_depth_commit;

    // Status signals
    assign s_status_overflow_int = 1'b0;
    assign s_status_bad_frame_int = 1'b0;
    assign s_status_good_frame_int = 1'b0;
    assign m_status_overflow_int = 1'b0;
    assign m_status_bad_frame_int = 1'b0;
    assign m_status_good_frame_int = 1'b0;

    // Pause signals
    assign s_pause_ack_int = 1'b0;
    assign m_pause_ack_int = 1'b0;

    // Instantiate the async FIFO
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) u_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(fifo_din_data),
        .s_axis_tkeep(fifo_din_keep),
        .s_axis_tvalid(fifo_din_valid),
        .s_axis_tready(fifo_din_ready),
        .s_axis_tlast(fifo_din_last),
        .s_axis_tid(fifo_din_tid),
        .s_axis_tdest(fifo_din_tdest),
        .s_axis_tuser(fifo_din_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(fifo_dout_data),
        .m_axis_tkeep(fifo_dout_keep),
        .m_axis_tvalid(fifo_dout_valid),
        .m_axis_tready(fifo_dout_ready),
        .m_axis_tlast(fifo_dout_last),
        .m_axis_tid(fifo_dout_tid),
        .m_axis_tdest(fifo_dout_tdest),
        .m_axis_tuser(fifo_dout_tuser),
        .s_status_depth(fifo_depth),
        .s_status_depth_commit(fifo_depth_commit),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );

endmodule

module axis_async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg w_en;
    reg [DATA_WIDTH-1:0] w_data;
    reg [KEEP_WIDTH-1:0] w_keep;
    reg w_last;
    reg [ID_WIDTH-1:0] w_tid;
    reg [DEST_WIDTH-1:0] w_tdest;
    reg [USER_WIDTH-1:0] w_tuser;

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg r_en;
    reg [DATA_WIDTH-1:0] r_data;
    reg [KEEP_WIDTH-1:0] r_keep;
    reg r_last;
    reg [ID_WIDTH-1:0] r_tid;
    reg [DEST_WIDTH-1:0] r_tdest;
    reg [USER_WIDTH-1:0] r_tuser;

    // CDC synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_m1, w_ptr_m2, w_ptr_m3;
    reg [PTR_WIDTH-1:0] r_ptr_s1, r_ptr_s2, r_ptr_s3;

    // RAM
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser [0:DEPTH-1];

    // Pipeline registers for RAM read
    reg [DATA_WIDTH-1:0] pipe_data;
    reg [KEEP_WIDTH-1:0] pipe_keep;
    reg pipe_last;
    reg [ID_WIDTH-1:0] pipe_tid;
    reg [DEST_WIDTH-1:0] pipe_tdest;
    reg [USER_WIDTH-1:0] pipe_tuser;
    reg pipe_valid;

    // Write logic (s_clk domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_en <= 1'b0;
            w_data <= {DATA_WIDTH{1'b0}};
            w_keep <= {KEEP_WIDTH{1'b0}};
            w_last <= 1'b0;
            w_tid <= {ID_WIDTH{1'b0}};
            w_tdest <= {DEST_WIDTH{1'b0}};
            w_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            w_en <= s_axis_tvalid && s_axis_tready;
            w_data <= s_axis_tdata;
            w_keep <= s_axis_tkeep;
            w_last <= s_axis_tlast;
            w_tid <= s_axis_tid;
            w_tdest <= s_axis_tdest;
            w_tuser <= s_axis_tuser;
            if (w_en) begin
                w_addr <= w_addr + 1'b1;
                w_ptr <= w_ptr + 1'b1;
            end
        end
    end

    // RAM write
    always @(posedge s_clk) begin
        if (w_en) begin
            ram_data[w_addr] <= w_data;
            ram_keep[w_addr] <= w_keep;
            ram_last[w_addr] <= w_last;
            ram_tid[w_addr] <= w_tid;
            ram_tdest[w_addr] <= w_tdest;
            ram_tuser[w_addr] <= w_tuser;
        end
    end

    // Read logic (m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            r_en <= 1'b0;
            r_data <= {DATA_WIDTH{1'b0}};
            r_keep <= {KEEP_WIDTH{1'b0}};
            r_last <= 1'b0;
            r_tid <= {ID_WIDTH{1'b0}};
            r_tdest <= {DEST_WIDTH{1'b0}};
            r_tuser <= {USER_WIDTH{1'b0}};
            pipe_data <= {DATA_WIDTH{1'b0}};
            pipe_keep <= {KEEP_WIDTH{1'b0}};
            pipe_last <= 1'b0;
            pipe_tid <= {ID_WIDTH{1'b0}};
            pipe_tdest <= {DEST_WIDTH{1'b0}};
            pipe_tuser <= {USER_WIDTH{1'b0}};
            pipe_valid <= 1'b0;
        end else begin
            r_en <= m_axis_tready && m_axis_tvalid;
            if (r_en) begin
                r_addr <= r_addr + 1'b1;
                r_ptr <= r_ptr + 1'b1;
            end
            if (r_en) begin
                pipe_data <= ram_data[r_addr];
                pipe_keep <= ram_keep[r_addr];
                pipe_last <= ram_last[r_addr];
                pipe_tid <= ram_tid[r_addr];
                pipe_tdest <= ram_tdest[r_addr];
                pipe_tuser <= ram_tuser[r_addr];
                pipe_valid <= 1'b1;
            end else begin
                pipe_valid <= 1'b0;
            end
        end
    end

    // CDC synchronizers
    always @(posedge m_clk) begin
        w_ptr_m1 <= w_ptr;
        w_ptr_m2 <= w_ptr_m1;
        w_ptr_m3 <= w_ptr_m2;
    end

    always @(posedge s_clk) begin
        r_ptr_s1 <= r_ptr;
        r_ptr_s2 <= r_ptr_s1;
        r_ptr_s3 <= r_ptr_s2;
    end

    // Full/Empty logic
    wire full;
    wire empty;
    wire [$clog2(DEPTH):0] depth;
    wire [$clog2(DEPTH):0] depth_commit;

    assign full = (w_ptr[ADDR_WIDTH] != r_ptr_s3[ADDR_WIDTH]) && 
                  (w_ptr[ADDR_WIDTH-1:0] == r_ptr_s3[ADDR_WIDTH-1:0]);
    assign empty = (w_ptr_m3 == r_ptr);
    assign depth = w_ptr_m3 - r_ptr;
    assign depth_commit = w_ptr - r_ptr_s3;

    // Ready/Valid logic
    assign s_axis_tready = !full;
    assign m_axis_tvalid = !empty;

    // Output data
    assign m_axis_tdata = pipe_data;
    assign m_axis_tkeep = pipe_keep;
    assign m_axis_tlast = pipe_last;
    assign m_axis_tid = pipe_tid;
    assign m_axis_tdest = pipe_tdest;
    assign m_axis_tuser = pipe_tuser;

    // Status
    assign s_status_depth = depth_commit;
    assign s_status_depth_commit = depth_commit;
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;
    assign m_status_depth = depth;
    assign m_status_depth_commit = depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule

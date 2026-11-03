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

    // Internal signals
    wire fifo_wen;
    wire fifo_ren;
    wire [$clog2(DEPTH):0] fifo_depth;
    wire [$clog2(DEPTH):0] fifo_depth_commit;
    wire fifo_full;
    wire fifo_empty;
    wire [DATA_WIDTH-1:0] fifo_rdata;
    wire [KEEP_WIDTH-1:0] fifo_rkeep;
    wire fifo_rlast;
    wire [ID_WIDTH-1:0] fifo_rtid;
    wire [DEST_WIDTH-1:0] fifo_rdest;
    wire [USER_WIDTH-1:0] fifo_ruser;

    // FIFO memory
    fifo_memory #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) fifo_mem_inst (
        .clk(clk),
        .rst(rst),
        .wen(fifo_wen),
        .ren(fifo_ren),
        .wdata(s_axis_tdata),
        .wkeep(s_axis_tkeep),
        .wlast(s_axis_tlast),
        .wtid(s_axis_tid),
        .wdest(s_axis_tdest),
        .wuser(s_axis_tuser),
        .rdata(fifo_rdata),
        .rkeep(fifo_rkeep),
        .rlast(fifo_rlast),
        .rtid(fifo_rtid),
        .rdest(fifo_rdest),
        .ruser(fifo_ruser)
    );

    // FIFO control
    fifo_control #(
        .DEPTH(DEPTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) fifo_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(fifo_rdata),
        .m_axis_tkeep(fifo_rkeep),
        .m_axis_tlast(fifo_rlast),
        .m_axis_tid(fifo_rtid),
        .m_axis_tdest(fifo_rdest),
        .m_axis_tuser(fifo_ruser),
        .pause_req(pause_req),
        .pause_ack(pause_ack),
        .status_depth(fifo_depth),
        .status_depth_commit(fifo_depth_commit),
        .status_overflow(fifo_full),
        .status_bad_frame(status_bad_frame),
        .status_good_frame(status_good_frame),
        .fifo_wen(fifo_wen),
        .fifo_ren(fifo_ren)
    );

    // Assign outputs
    assign m_axis_tdata = fifo_rdata;
    assign m_axis_tkeep = fifo_rkeep;
    assign m_axis_tlast = fifo_rlast;
    assign m_axis_tid = fifo_rtid;
    assign m_axis_tdest = fifo_rdest;
    assign m_axis_tuser = fifo_ruser;

    // Status outputs
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = fifo_full;

endmodule

module fifo_memory #
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
    parameter USER_WIDTH = 1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wen,
    input  wire                   ren,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [KEEP_WIDTH-1:0]  wkeep,
    input  wire                   wlast,
    input  wire [ID_WIDTH-1:0]    wtid,
    input  wire [DEST_WIDTH-1:0]  wdest,
    input  wire [USER_WIDTH-1:0]  wuser,
    output wire [DATA_WIDTH-1:0]  rdata,
    output wire [KEEP_WIDTH-1:0]  rkeep,
    output wire                   rlast,
    output wire [ID_WIDTH-1:0]    rtid,
    output wire [DEST_WIDTH-1:0]  rdest,
    output wire [USER_WIDTH-1:0]  ruser
);

    // Internal signals
    wire [$clog2(DEPTH):0] wr_ptr;
    wire [$clog2(DEPTH):0] rd_ptr;
    wire [$clog2(DEPTH):0] wr_ptr_gray;
    wire [$clog2(DEPTH):0] rd_ptr_gray;
    wire [$clog2(DEPTH):0] wr_ptr_gray_sync;
    wire [$clog2(DEPTH):0] rd_ptr_gray_sync;

    // Memory arrays
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    // Write pointers and synchronization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wen) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (ren) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    // Synchronize write pointer to read domain
    sync_gray #(.WIDTH($clog2(DEPTH)+1)) sync_wr_ptr (
        .clk(clk),
        .rst(rst),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_sync)
    );

    // Synchronize read pointer to write domain
    sync_gray #(.WIDTH($clog2(DEPTH)+1)) sync_rd_ptr (
        .clk(clk),
        .rst(rst),
        .din(rd_ptr_gray),
        .dout(rd_ptr_gray_sync)
    );

    // Write data to memory
    always @(posedge clk) begin
        if (wen) begin
            mem_data[wr_ptr] <= wdata;
            if (KEEP_ENABLE) mem_keep[wr_ptr] <= wkeep;
            if (LAST_ENABLE) mem_last[wr_ptr] <= wlast;
            if (ID_ENABLE) mem_id[wr_ptr] <= wtid;
            if (DEST_ENABLE) mem_dest[wr_ptr] <= wdest;
            if (USER_ENABLE) mem_user[wr_ptr] <= wuser;
        end
    end

    // Read data from memory
    assign rdata = mem_data[rd_ptr];
    assign rkeep = KEEP_ENABLE ? mem_keep[rd_ptr] : {KEEP_WIDTH{1'b1}};
    assign rlast = LAST_ENABLE ? mem_last[rd_ptr] : 1'b0;
    assign rtid = ID_ENABLE ? mem_id[rd_ptr] : {ID_WIDTH{1'b0}};
    assign rdest = DEST_ENABLE ? mem_dest[rd_ptr] : {DEST_WIDTH{1'b0}};
    assign ruser = USER_ENABLE ? mem_user[rd_ptr] : {USER_WIDTH{1'b0}};

endmodule

module fifo_control #
(
    parameter DEPTH = 4096,
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
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tvalid,
    input  wire [DATA_WIDTH-1:0]  m_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    input  wire                   m_axis_tlast,
    input  wire [ID_WIDTH-1:0]    m_axis_tid,
    input  wire [DEST_WIDTH-1:0]  m_axis_tdest,
    input  wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   pause_req,
    output wire                   pause_ack,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame,
    output wire                   fifo_wen,
    output wire                   fifo_ren
);

    // Internal signals
    wire [$clog2(DEPTH):0] wr_ptr;
    wire [$clog2(DEPTH):0] rd_ptr;
    wire [$clog2(DEPTH):0] wr_ptr_gray;
    wire [$clog2(DEPTH):0] rd_ptr_gray;
    wire [$clog2(DEPTH):0] wr_ptr_gray_sync;
    wire [$clog2(DEPTH):0] rd_ptr_gray_sync;
    wire [$clog2(DEPTH):0] depth;
    reg frame_start;
    reg frame_bad;
    reg frame_good;

    // Write pointers and synchronization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (fifo_wen) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (fifo_ren) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    // Synchronize write pointer to read domain
    sync_gray #(.WIDTH($clog2(DEPTH)+1)) sync_wr_ptr (
        .clk(clk),
        .rst(rst),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_sync)
    );

    // Synchronize read pointer to write domain
    sync_gray #(.WIDTH($clog2(DEPTH)+1)) sync_rd_ptr (
        .clk(clk),
        .rst(rst),
        .din(rd_ptr_gray),
        .dout(rd_ptr_gray_sync)
    );

    // Calculate FIFO depth
    assign depth = wr_ptr_gray_sync - rd_ptr_gray_sync;
    assign status_depth = depth;

    // FIFO write enable
    assign fifo_wen = s_axis_tvalid & s_axis_tready;

    // FIFO read enable
    assign fifo_ren = m_axis_tready & m_axis_tvalid;

    // Status outputs
    assign status_depth_commit = depth;
    assign status_overflow = (depth == DEPTH);

    // Frame handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_start <= 0;
            frame_bad <= 0;
            frame_good <= 0;
        end else begin
            if (s_axis_tvalid & s_axis_tready) begin
                if (s_axis_tlast) begin
                    frame_good <= ~frame_bad;
                    frame_bad <= 0;
                end else if (s_axis_tuser & USER_BAD_FRAME_MASK) begin
                    frame_bad <= 1;
                end
            end
            if (m_axis_tvalid & m_axis_tready & m_axis_tlast) begin
                frame_start <= 0;
            end else if (m_axis_tvalid & m_axis_tready & ~frame_start) begin
                frame_start <= 1;
            end
        end
    end

    // Status flags
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_good;

    // Handshake signals
    assign s_axis_tready = ~status_overflow & ~pause_req;
    assign m_axis_tvalid = ~fifo_empty;

    // Pause handling
    assign pause_ack = pause_req & s_axis_tvalid;

endmodule

module sync_gray #
(
    parameter WIDTH = 4
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [WIDTH-1:0]       din,
    output reg [WIDTH-1:0]        dout
);

    reg [WIDTH-1:0] sync_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_stage1 <= 0;
            dout <= 0;
        end else begin
            sync_stage1 <= din;
            dout <= sync_stage1;
        end
    end

endmodule

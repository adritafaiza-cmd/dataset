```verilog
`timescale 1ns/1ps

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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam S_KEEP_WIDTH_LOG = S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_WIDTH;

    // Internal signals
    wire s_rst_n = ~s_rst;
    wire m_rst_n = ~m_rst;

    // Cross-clock domain synchronization
    // S to M domain
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_pause_ack_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;

    // M to S domain
    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_pause_ack_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;

    // FIFO Depth Signals
    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;

    // Generate FIFO instances
    // Source Side FIFO (S to M)
    genvar i;
    generate
        if (RAM_PIPELINE)
            for (i = 0; i < 2; i = i + 1) begin : gen_pipeline
                axis_async_fifo #(
                    .DEPTH(DEPTH),
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
                    .USER_WIDTH(USER_WIDTH),
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
                ) u_fifo_inst (
                    .s_clk(s_clk),
                    .s_rst(s_rst),
                    .s_axis_tdata(s_axis_tdata),
                    .s_axis_tkeep(s_axis_tkeep),
                    .s_axis_tvalid(s_axis_tvalid),
                    .s_axis_tready(u_fifo_inst.s_axis_tready),
                    .s_axis_tlast(s_axis_tlast),
                    .s_axis_tid(s_axis_tid),
                    .s_axis_tdest(s_axis_tdest),
                    .s_axis_tuser(s_axis_tuser),
                    .m_clk(m_clk),
                    .m_rst(m_rst),
                    .m_axis_tdata(u_fifo_inst.m_axis_tdata),
                    .m_axis_tkeep(u_fifo_inst.m_axis_tkeep),
                    .m_axis_tvalid(u_fifo_inst.m_axis_tvalid),
                    .m_axis_tready(m_axis_tready),
                    .m_axis_tlast(u_fifo_inst.m_axis_tlast),
                    .m_axis_tid(u_fifo_inst.m_axis_tid),
                    .m_axis_tdest(u_fifo_inst.m_axis_tdest),
                    .m_axis_tuser(u_fifo_inst.m_axis_tuser),
                    .s_pause_req(s_pause_req),
                    .s_pause_ack(u_fifo_inst.s_pause_ack),
                    .m_pause_req(m_pause_req),
                    .m_pause_ack(u_fifo_inst.m_pause_ack),
                    .s_status_depth(s_depth),
                    .s_status_depth_commit(u_fifo_inst.s_status_depth_commit),
                    .s_status_overflow(u_fifo_inst.s_status_overflow),
                    .s_status_bad_frame(u_fifo_inst.s_status_bad_frame),
                    .s_status_good_frame(u_fifo_inst.s_status_good_frame),
                    .m_status_depth(m_depth),
                    .m_status_depth_commit(u_fifo_inst.m_status_depth_commit),
                    .m_status_overflow(u_fifo_inst.m_status_overflow),
                    .m_status_bad_frame(u_fifo_inst.m_status_bad_frame),
                    .m_status_good_frame(u_fifo_inst.m_status_good_frame)
                );
            end
        else
            axis_async_fifo #(
                .DEPTH(DEPTH),
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
                .USER_WIDTH(USER_WIDTH),
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
            ) u_fifo_inst (
                .s_clk(s_clk),
                .s_rst(s_rst),
                .s_axis_tdata(s_axis_tdata),
                .s_axis_tkeep(s_axis_tkeep),
                .s_axis_tvalid(s_axis_tvalid),
                .s_axis_tready(u_fifo_inst.s_axis_tready),
                .s_axis_tlast(s_axis_tlast),
                .s_axis_tid(s_axis_tid),
                .s_axis_tdest(s_axis_tdest),
                .s_axis_tuser(s_axis_tuser),
                .m_clk(m_clk),
                .m_rst(m_rst),
                .m_axis_tdata(u_fifo_inst.m_axis_tdata),
                .m_axis_tkeep(u_fifo_inst.m_axis_tkeep),
                .m_axis_tvalid(u_fifo_inst.m_axis_tvalid),
                .m_axis_tready(m_axis_tready),
                .m_axis_tlast(u_fifo_inst.m_axis_tlast),
                .m_axis_tid(u_fifo_inst.m_axis_tid),
                .m_axis_tdest(u_fifo_inst.m_axis_tdest),
                .m_axis_tuser(u_fifo_inst.m_axis_tuser),
                .s_pause_req(s_pause_req),
                .s_pause_ack(u_fifo_inst.s_pause_ack),
                .m_pause_req(m_pause_req),
                .m_pause_ack(u_fifo_inst.m_pause_ack),
                .s_status_depth(s_depth),
                .s_status_depth_commit(u_fifo_inst.s_status_depth_commit),
                .s_status_overflow(u_fifo_inst.s_status_overflow),
                .s_status_bad_frame(u_fifo_inst.s_status_bad_frame),
                .s_status_good_frame(u_fifo_inst.s_status_good_frame),
                .m_status_depth(m_depth),
                .m_status_depth_commit(u_fifo_inst.m_status_depth_commit),
                .m_status_overflow(u_fifo_inst.m_status_overflow),
                .m_status_bad_frame(u_fifo_inst.m_status_bad_frame),
                .m_status_good_frame(u_fifo_inst.m_status_good_frame)
            );
    endgenerate

    // Synchronous logic for S side outputs
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_synced <= 1'b0;
            s_last_synced <= 1'b0;
            s_tid_synced <= {ID_WIDTH{1'b0}};
            s_tdest_synced <= {DEST_WIDTH{1'b0}};
            s_tuser_synced <= {USER_WIDTH{1'b0}};
            s_keep_synced <= {S_KEEP_WIDTH{1'b0}};
            s_pause_ack <= 1'b0;
            s_status_depth_commit <= 0;
            s_status_overflow <= 1'b0;
            s_status_bad_frame <= 1'b0;
            s_status_good_frame <= 1'b0;
        end else begin
            s_valid_synced <= s_axis_tvalid;
            s_last_synced <= s_axis_tlast;
            s_tid_synced <= s_axis_tid;
            s_tdest_synced <= s_axis_tdest;
            s_tuser_synced <= s_axis_tuser;
            s_keep_synced <= s_axis_tkeep;
            s_pause_ack <= s_pause_req;
            s_status_depth_commit <= s_depth;
            s_status_overflow <= s_status_overflow;
            s_status_bad_frame <= s_status_bad_frame;
            s_status_good_frame <= s_status_good_frame;
        end
    end

    // Synchronous logic for M side outputs
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_valid_synced <= 1'b0;
            m_last_synced <= 1'b0;
            m_tid_synced <= {ID_WIDTH{1'b0}};
            m_tdest_synced <= {DEST_WIDTH{1'b0}};
            m_tuser_synced <= {USER_WIDTH{1'b0}};
            m_keep_synced <= {M_KEEP_WIDTH{1'b0}};
            m_pause_ack <= 1'b0;
            m_status_depth_commit <= 0;
            m_status_overflow <= 1'b0;
            m_status_bad_frame <= 1'b0;
            m_status_good_frame <= 1'b0;
        end else begin
            m_valid_synced <= m_axis_tvalid;
            m_last_synced <= m_axis_tlast;
            m_tid_synced <= m_axis_tid;
            m_tdest_synced <= m_axis_tdest;
            m_tuser_synced <= m_axis_tuser;
            m_keep_synced <= m_axis_tkeep;
            m_pause_ack <= m_pause_req;
            m_status_depth_commit <= m_depth;
            m_status_overflow <= m_status_overflow;
            m_status_bad_frame <= m_status_bad_frame;
            m_status_good_frame <= m_status_good_frame;
        end
    end

    // Cross-clock domain synchronization using 2-stage FIFOs
    // S to M domain
    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(S_DATA_WIDTH)
    ) u_sync_valid (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tvalid),
        .dout(s_valid_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_last (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tlast),
        .dout(s_last_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(ID_WIDTH)
    ) u_sync_tid (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tid),
        .dout(s_tid_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(DEST_WIDTH)
    ) u_sync_tdest (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tdest),
        .dout(s_tdest_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(USER_WIDTH)
    ) u_sync_tuser (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tuser),
        .dout(s_tuser_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(S_KEEP_WIDTH)
    ) u_sync_keep (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_axis_tkeep),
        .dout(s_keep_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_pause_req (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_pause_req),
        .dout(s_pause_req_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_pause_ack (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_pause_ack),
        .dout(s_pause_ack_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_overflow (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_status_overflow),
        .dout(s_overflow_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_bad_frame (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_status_bad_frame),
        .dout(s_bad_frame_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_good_frame (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_status_good_frame),
        .dout(s_good_frame_synced)
    );

    // M to S domain
    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(M_DATA_WIDTH)
    ) u_sync_m_valid (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tvalid),
        .dout(m_valid_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_last (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tlast),
        .dout(m_last_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(ID_WIDTH)
    ) u_sync_m_tid (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tid),
        .dout(m_tid_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(DEST_WIDTH)
    ) u_sync_m_tdest (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tdest),
        .dout(m_tdest_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(USER_WIDTH)
    ) u_sync_m_tuser (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tuser),
        .dout(m_tuser_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(M_KEEP_WIDTH)
    ) u_sync_m_keep (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axis_tkeep),
        .dout(m_keep_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_pause_req (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_pause_req),
        .dout(m_pause_req_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_pause_ack (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_pause_ack),
        .dout(m_pause_ack_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_overflow (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_status_overflow),
        .dout(m_overflow_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_bad_frame (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_status_bad_frame),
        .dout(m_bad_frame_synced)
    );

    fifo_sync #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_good_frame (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_status_good_frame),
        .dout(m_good_frame_synced)
    );

    // Status outputs
    assign s_status_depth = s_depth;
    assign m_status_depth = m_depth;
    assign s_status_depth_commit = s_status_depth_commit;
    assign m_status_depth_commit = m_status_depth_commit;
    assign s_status_overflow = s_overflow_synced;
    assign m_status_overflow = m_overflow_synced;
    assign s_status_bad_frame = s_bad_frame_synced;
    assign m_status_bad_frame = m_bad_frame_synced;
    assign s_status_good_frame = s_good_frame_synced;
    assign m_status_good_frame = m_good_frame_synced;

    // Width adaptation logic
    // This logic runs in the M clock domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tid <= {ID_WIDTH{1'b0}};
            m_axis_tdest <= {DEST_WIDTH{1'b0}};
            m_axis_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            if (m_valid_synced && m_axis_tready && !m_pause_req_synced) begin
                // Calculate keep mask
                wire [S_KEEP_WIDTH-1:0] src_keep = s_keep_synced;
                wire [M_KEEP_WIDTH-1:0] dst_keep = {M_KEEP_WIDTH{1'b0}};
                
                if (S_KEEP_ENABLE && M_KEEP_ENABLE) begin
                    for (integer j = 0; j < M_KEEP_WIDTH; j = j + 1) begin
                        if (src_keep[j]) begin
                            dst_keep[j] = 1'b1;
                        end else begin
                            dst_keep[j] = 1'b0;
                        end
                    end
                end else if (S_KEEP_ENABLE && !M_KEEP_ENABLE) begin
                    dst_keep = {M_KEEP_WIDTH{1'b1}};
                end else if (!S_KEEP_ENABLE && M_KEEP_ENABLE) begin
                    dst_keep = {M_KEEP_WIDTH{1'b0}};
                end else begin
                    dst_keep = {M_KEEP_WIDTH{1'b1}};
                end

                // Calculate data
                wire [S_DATA_WIDTH-1:0] src_data = s_axis_tdata; // Use original data from FIFO
                wire [M_DATA_WIDTH-1:0] dst_data = {M_DATA_WIDTH{1'b0}};
                
                if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                    dst_data = src_data;
                end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                    // Truncate
                    dst_data = src_data[(S_DATA_WIDTH - M_DATA_WIDTH):S_DATA_WIDTH-1];
                end else begin
                    // Extend
                    dst_data = {M_DATA_WIDTH - S_DATA_WIDTH, src_data};
                end

                // Calculate last
                wire src_last = s_last_synced;
                wire dst_last = src_last;

                // Calculate other fields
                wire [ID_WIDTH-1:0] dst_tid = s_tid_synced;
                wire [DEST_WIDTH-1:0] dst_tdest = s_tdest_synced;
                wire [USER_WIDTH-1:0] dst_tuser = s_tuser_synced;

                // Update outputs
                m_axis_tdata <= dst_data;
                m_axis_tkeep <= dst_keep;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= dst_last;
                m_axis_tid <= dst_tid;
                m_axis_tdest <= dst_tdest;
                m_axis_tuser <= dst_tuser;
            end else begin
                m_axis_tvalid <= 1'b0;
                // Hold other values when not valid
                // m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser
            end
        end
    end

    // Source side ready logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 1'b0;
        end else begin
            if (m_valid_synced && !m_pause_req_synced) begin
                s_axis_tready <= 1'b1;
            end else begin
                s_axis_tready <= 1'b0;
            end
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 1'b0;
        end else begin
            if (s_pause_req && !m_pause_req_synced) begin
                s_pause_ack <= 1'b1;
            end else begin
                s_pause_ack <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 1'b0;
        end else begin
            if (m_pause_req && !s_pause_req_synced) begin
                m_pause_ack <= 1'b1;
            end else begin
                m_pause_ack <= 1'b0;
            end
        end
    end

    // FIFO Sync Module
    // Simple 2-stage synchronizer for single bit or small data
    // For larger data, we use a small FIFO
    module fifo_sync #(
        parameter DEPTH = 16,
        parameter DATA_WIDTH = 8
    ) (
        input  wire                     clk,
        input  wire                     rst,
        input  wire [DATA_WIDTH-1:0]    din,
        output wire [DATA_WIDTH-1:0]    dout
    );
        reg [DATA_WIDTH-1:0] q;
        reg [DATA_WIDTH-1:0] d;
        reg [LOG2_DEPTH:0] wr_ptr;
        reg [LOG2_DEPTH:0] rd_ptr;
        reg full;
        reg empty;

        assign dout = q;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                q <= {DATA_WIDTH{1'b0}};
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else begin
                full <= (wr_ptr == rd_ptr) ? 0 : 1;
                empty <= (wr_ptr == rd_ptr) ? 1 : 0;
                
                if (din) begin
                    q <= din;
                    wr_ptr <= wr_ptr + 1;
                end
            end
        end
    endmodule

    // Note: The above fifo_sync module is a simplified version.
    // In a real implementation, we would use a proper FIFO with write enable.
    // Since the requirement is for a complete Verilog-2001 code without testbenches,
    // we will use a simple 2-stage synchronizer for single-bit signals and a small FIFO for multi-bit signals.
    
    // Re-implementing fifo_sync with proper write enable
    module fifo_sync_proper #(
        parameter DEPTH = 16,
        parameter DATA_WIDTH = 8
    ) (
        input  wire                     clk,
        input  wire                     rst,
        input  wire                     din_valid,
        input  wire [DATA_WIDTH-1:0]    din,
        output wire [DATA_WIDTH-1:0]    dout
    );
        reg [DATA_WIDTH-1:0] q;
        reg [DATA_WIDTH-1:0] d;
        reg [LOG2_DEPTH:0] wr_ptr;
        reg [LOG2_DEPTH:0] rd_ptr;
        reg full;
        reg empty;
        reg write_enable;

        assign dout = q;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                q <= {DATA_WIDTH{1'b0}};
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
                write_enable <= 0;
            end else begin
                full <= (wr_ptr == rd_ptr) ? 0 : 1;
                empty <= (wr_ptr == rd_ptr) ? 1 : 0;
                
                if (din_valid && !full) begin
                    q <= din;
                    wr_ptr <= wr_ptr + 1;
                    write_enable <= 1;
                end else begin
                    write_enable <= 0;
                end
            end
        end
    endmodule

    // Replacing the previous fifo_sync with fifo_sync_proper
    // S to M domain
    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(S_DATA_WIDTH)
    ) u_sync_valid (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tdata),
        .dout(s_valid_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_last (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tlast),
        .dout(s_last_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(ID_WIDTH)
    ) u_sync_tid (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tid),
        .dout(s_tid_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(DEST_WIDTH)
    ) u_sync_tdest (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tdest),
        .dout(s_tdest_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(USER_WIDTH)
    ) u_sync_tuser (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tuser),
        .dout(s_tuser_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(S_KEEP_WIDTH)
    ) u_sync_keep (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_axis_tkeep),
        .dout(s_keep_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_pause_req (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_pause_req),
        .dout(s_pause_req_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_pause_ack (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_pause_ack),
        .dout(s_pause_ack_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_overflow (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_status_overflow),
        .dout(s_overflow_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_bad_frame (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_status_bad_frame),
        .dout(s_bad_frame_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_good_frame (
        .clk(m_clk),
        .rst(m_rst),
        .din_valid(s_axis_tvalid),
        .din(s_status_good_frame),
        .dout(s_good_frame_synced)
    );

    // M to S domain
    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(M_DATA_WIDTH)
    ) u_sync_m_valid (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tdata),
        .dout(m_valid_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_last (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tlast),
        .dout(m_last_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(ID_WIDTH)
    ) u_sync_m_tid (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tid),
        .dout(m_tid_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(DEST_WIDTH)
    ) u_sync_m_tdest (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tdest),
        .dout(m_tdest_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(USER_WIDTH)
    ) u_sync_m_tuser (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tuser),
        .dout(m_tuser_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(M_KEEP_WIDTH)
    ) u_sync_m_keep (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_axis_tkeep),
        .dout(m_keep_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_pause_req (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_pause_req),
        .dout(m_pause_req_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_pause_ack (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_pause_ack),
        .dout(m_pause_ack_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u_sync_m_overflow (
        .clk(s_clk),
        .rst(s_rst),
        .din_valid(m_axis_tvalid),
        .din(m_status_overflow),
        .dout(m_overflow_synced)
    );

    fifo_sync_proper #(
        .DEPTH(16),
        .DATA_WIDTH(1)
    ) u
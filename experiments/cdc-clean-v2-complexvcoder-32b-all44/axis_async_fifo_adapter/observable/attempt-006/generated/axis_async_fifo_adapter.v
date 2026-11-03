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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
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

    /*
     * Internal signals for width adaptation
     */
    wire [M_DATA_WIDTH-1:0]         width_adapter_m_axis_tdata;
    wire [M_KEEP_WIDTH-1:0]         width_adapter_m_axis_tkeep;
    wire                            width_adapter_m_axis_tvalid;
    wire                            width_adapter_m_axis_tready;
    wire                            width_adapter_m_axis_tlast;
    wire [ID_WIDTH-1:0]             width_adapter_m_axis_tid;
    wire [DEST_WIDTH-1:0]           width_adapter_m_axis_tdest;
    wire [USER_WIDTH-1:0]           width_adapter_m_axis_tuser;

    /*
     * FIFO instance
     */
    fifo_async #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH),
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
    ) fifo_async_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(width_adapter_m_axis_tdata),
        .s_axis_tkeep(width_adapter_m_axis_tkeep),
        .s_axis_tvalid(width_adapter_m_axis_tvalid),
        .s_axis_tready(width_adapter_m_axis_tready),
        .s_axis_tlast(width_adapter_m_axis_tlast),
        .s_axis_tid(width_adapter_m_axis_tid),
        .s_axis_tdest(width_adapter_m_axis_tdest),
        .s_axis_tuser(width_adapter_m_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .s_status_depth(s_status_depth),
        .s_status_depth_commit(s_status_depth_commit),
        .s_status_overflow(s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_status_depth(m_status_depth),
        .m_status_depth_commit(m_status_depth_commit),
        .m_status_overflow(m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

    /*
     * Width adapter instance
     */
    width_adapter #(
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
    ) width_adapter_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tdata(width_adapter_m_axis_tdata),
        .m_axis_tkeep(width_adapter_m_axis_tkeep),
        .m_axis_tvalid(width_adapter_m_axis_tvalid),
        .m_axis_tready(width_adapter_m_axis_tready),
        .m_axis_tlast(width_adapter_m_axis_tlast),
        .m_axis_tid(width_adapter_m_axis_tid),
        .m_axis_tdest(width_adapter_m_axis_tdest),
        .m_axis_tuser(width_adapter_m_axis_tuser)
    );

endmodule

module fifo_async #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
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

    /*
     * FIFO registers and pointers
     */
    reg [DATA_WIDTH-1:0]            mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]            mem_keep [0:DEPTH-1];
    reg                             mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]              mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]            mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]            mem_user [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0]         wr_ptr;
    reg [$clog2(DEPTH)-1:0]         rd_ptr;
    reg [$clog2(DEPTH):0]           depth;
    reg [$clog2(DEPTH):0]           depth_commit;
    reg                             overflow;
    reg                             bad_frame;
    reg                             good_frame;

    /*
     * Cross-domain FIFO pointers
     */
    reg [$clog2(DEPTH)-1:0]         wr_ptr_gray;
    reg [$clog2(DEPTH)-1:0]         rd_ptr_gray;
    reg [$clog2(DEPTH)-1:0]         rd_ptr_gray_sync;
    reg [$clog2(DEPTH)-1:0]         wr_ptr_gray_sync;

    /*
     * Write side logic
     */
    wire                            wr_en;
    wire                            wr_ack;
    wire                            wr_full;

    assign wr_en = s_axis_tvalid & s_axis_tready;
    assign wr_full = (depth_commit == DEPTH);
    assign s_axis_tready = ~wr_full & ~s_pause_req;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            if (wr_en) begin
                mem[wr_ptr] <= s_axis_tdata;
                mem_keep[wr_ptr] <= s_axis_tkeep;
                mem_last[wr_ptr] <= s_axis_tlast;
                mem_id[wr_ptr] <= s_axis_tid;
                mem_dest[wr_ptr] <= s_axis_tdest;
                mem_user[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                if (s_axis_tlast) begin
                    depth_commit <= depth_commit + 1;
                    good_frame <= 1;
                end else begin
                    good_frame <= 0;
                end
                if (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    bad_frame <= 1;
                end
                if (depth_commit == DEPTH) begin
                    overflow <= 1;
                end
            end
            if (depth_commit > 0 && rd_ptr_gray_sync != wr_ptr_gray) begin
                depth_commit <= depth_commit - 1;
            end
        end
    end

    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    /*
     * Read side logic
     */
    wire                            rd_en;
    wire                            rd_ack;
    wire                            rd_empty;

    assign rd_en = m_axis_tready & m_axis_tvalid;
    assign rd_empty = (depth_commit == 0);
    assign m_axis_tvalid = ~rd_empty & ~m_pause_req;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
        end else begin
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
                if (mem_last[rd_ptr]) begin
                    depth_commit <= depth_commit - 1;
                end
            end
            if (wr_en && rd_ptr_gray_sync != wr_ptr_gray) begin
                depth_commit <= depth_commit + 1;
            end
        end
    end

    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    /*
     * Output data
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
            m_axis_tlast <= 0;
            m_axis_tid <= 0;
            m_axis_tdest <= 0;
            m_axis_tuser <= 0;
        end else begin
            if (rd_en) begin
                m_axis_tdata <= mem[rd_ptr];
                m_axis_tkeep <= mem_keep[rd_ptr];
                m_axis_tlast <= mem_last[rd_ptr];
                m_axis_tid <= mem_id[rd_ptr];
                m_axis_tdest <= mem_dest[rd_ptr];
                m_axis_tuser <= mem_user[rd_ptr];
            end
        end
    end

    /*
     * Pause signals
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            if (s_pause_req) begin
                s_pause_ack <= 1;
            end else if (wr_full) begin
                s_pause_ack <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            if (m_pause_req) begin
                m_pause_ack <= 1;
            end else if (rd_empty) begin
                m_pause_ack <= 0;
            end
        end
    end

    /*
     * Status signals
     */
    assign s_status_depth = depth;
    assign s_status_depth_commit = depth_commit;
    assign s_status_overflow = overflow;
    assign s_status_bad_frame = bad_frame;
    assign s_status_good_frame = good_frame;

    assign m_status_depth = depth;
    assign m_status_depth_commit = depth_commit;
    assign m_status_overflow = overflow;
    assign m_status_bad_frame = bad_frame;
    assign m_status_good_frame = good_frame;

endmodule

module width_adapter #(
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
    parameter USER_WIDTH = 1
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    /*
     * Internal signals
     */
    reg [S_DATA_WIDTH-1:0]          data_reg;
    reg [S_KEEP_WIDTH-1:0]          keep_reg;
    reg                             valid_reg;
    reg                             last_reg;
    reg [ID_WIDTH-1:0]              id_reg;
    reg [DEST_WIDTH-1:0]            dest_reg;
    reg [USER_WIDTH-1:0]            user_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;

    /*
     * Write side logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            data_reg <= 0;
            keep_reg <= 0;
            valid_reg <= 0;
            last_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                data_reg <= s_axis_tdata;
                keep_reg <= s_axis_tkeep;
                valid_reg <= s_axis_tvalid;
                last_reg <= s_axis_tlast;
                id_reg <= s_axis_tid;
                dest_reg <= s_axis_tdest;
                user_reg <= s_axis_tuser;
            end
        end
    end

    /*
     * Read side logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
        end else begin
            if (m_axis_tready && m_axis_tvalid_reg) begin
                m_axis_tvalid_reg <= 0;
            end else if (valid_reg) begin
                m_axis_tdata_reg <= data_reg;
                m_axis_tkeep_reg <= keep_reg;
                m_axis_tvalid_reg <= valid_reg;
                m_axis_tlast_reg <= last_reg;
            end
        end
    end

    /*
     * Output data
     */
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = id_reg;
    assign m_axis_tdest = dest_reg;
    assign m_axis_tuser = user_reg;

    /*
     * Ready signal
     */
    assign s_axis_tready = ~m_axis_tvalid_reg || m_axis_tready;

endmodule

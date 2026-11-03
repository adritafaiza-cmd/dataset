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
     * Internal signals
     */
    wire                            fifo_s_ready;
    wire                            fifo_m_valid;
    wire [S_DATA_WIDTH-1:0]         fifo_m_data;
    wire                            fifo_m_ready;
    wire [$clog2(DEPTH):0]          fifo_s_status_depth;
    wire [$clog2(DEPTH):0]          fifo_s_status_depth_commit;
    wire                            fifo_s_status_overflow;
    wire [$clog2(DEPTH):0]          fifo_m_status_depth;
    wire [$clog2(DEPTH):0]          fifo_m_status_depth_commit;
    wire                            fifo_m_status_overflow;
    wire                            adapter_s_valid;
    wire [S_DATA_WIDTH-1:0]         adapter_s_data;
    wire                            adapter_m_valid;
    wire [M_DATA_WIDTH-1:0]         adapter_m_data;
    wire [M_KEEP_WIDTH-1:0]         adapter_m_tkeep;
    wire                            adapter_m_tlast;
    wire [ID_WIDTH-1:0]             adapter_m_tid;
    wire [DEST_WIDTH-1:0]           adapter_m_tdest;
    wire [USER_WIDTH-1:0]           adapter_m_tuser;

    /*
     * Async FIFO
     */
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH)
    ) fifo_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data(s_axis_tdata),
        .s_valid(s_axis_tvalid),
        .s_ready(fifo_s_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(fifo_m_data),
        .m_valid(fifo_m_valid),
        .m_ready(fifo_m_ready),
        .s_status_depth(fifo_s_status_depth),
        .s_status_depth_commit(fifo_s_status_depth_commit),
        .s_status_overflow(fifo_s_status_overflow),
        .m_status_depth(fifo_m_status_depth),
        .m_status_depth_commit(fifo_m_status_depth_commit),
        .m_status_overflow(fifo_m_status_overflow)
    );

    /*
     * Width Adapter
     */
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) adapter_inst (
        .clk(m_clk),
        .rst(m_rst),
        .s_data(fifo_m_data),
        .s_valid(fifo_m_valid),
        .s_ready(adapter_s_ready),
        .m_data(adapter_m_data),
        .m_valid(adapter_m_valid),
        .m_ready(m_axis_tready),
        .m_tkeep(adapter_m_tkeep),
        .m_tlast(adapter_m_tlast),
        .m_tid(adapter_m_tid),
        .m_tdest(adapter_m_tdest),
        .m_tuser(adapter_m_tuser)
    );

    /*
     * Handshake Logic
     */
    handshake_logic handshake_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_tvalid(s_axis_tvalid),
        .s_tready(s_axis_tready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_tready(m_axis_tready),
        .m_tvalid(m_axis_tvalid)
    );

    /*
     * Pause Logic
     */
    pause_logic pause_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack)
    );

    /*
     * Status Logic
     */
    status_logic status_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_status_depth(fifo_s_status_depth),
        .s_status_depth_commit(fifo_s_status_depth_commit),
        .s_status_overflow(fifo_s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_status_depth(fifo_m_status_depth),
        .m_status_depth_commit(fifo_m_status_depth_commit),
        .m_status_overflow(fifo_m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

    /*
     * Connections
     */
    assign fifo_m_ready = adapter_s_ready;
    assign adapter_s_valid = fifo_m_valid;
    assign adapter_s_data = fifo_m_data;
    assign m_axis_tdata = adapter_m_data;
    assign m_axis_tkeep = adapter_m_tkeep;
    assign m_axis_tvalid = adapter_m_valid;
    assign m_axis_tlast = adapter_m_tlast;
    assign m_axis_tid = adapter_m_tid;
    assign m_axis_tdest = adapter_m_tdest;
    assign m_axis_tuser = adapter_m_tuser;

    /*
     * Status outputs
     */
    assign s_status_depth = fifo_s_status_depth;
    assign s_status_depth_commit = fifo_s_status_depth_commit;
    assign s_status_overflow = fifo_s_status_overflow;
    assign m_status_depth = fifo_m_status_depth;
    assign m_status_depth_commit = fifo_m_status_depth_commit;
    assign m_status_overflow = fifo_m_status_overflow;

endmodule

module async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [DATA_WIDTH-1:0]    s_data,
    input  wire                     s_valid,
    output wire                     s_ready,
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [DATA_WIDTH-1:0]    m_data,
    output wire                     m_valid,
    input  wire                     m_ready,
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wptr, rptr, wptr_gray, rptr_gray, wptr_gray_sync, rptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Write side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr <= 0;
        end else if (s_valid && s_ready) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= s_data;
            wptr <= wptr + 1;
        end
    end

    // Read side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr <= 0;
        end else if (m_valid && m_ready) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversion
    always @(*) begin
        wptr_gray = wptr ^ (wptr >> 1);
        rptr_gray = rptr ^ (rptr >> 1);
    end

    // Cross-domain synchronization
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    // Read pointer binary conversion
    reg [ADDR_WIDTH:0] rptr_bin;
    always @(*) begin
        rptr_bin[ADDR_WIDTH] = rptr_gray_sync[ADDR_WIDTH];
        for (integer i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            rptr_bin[i] = rptr_gray_sync[i] ^ rptr_bin[i+1];
        end
    end

    // Write pointer binary conversion
    reg [ADDR_WIDTH:0] wptr_bin;
    always @(*) begin
        wptr_bin[ADDR_WIDTH] = wptr_gray_sync[ADDR_WIDTH];
        for (integer i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            wptr_bin[i] = wptr_gray_sync[i] ^ wptr_bin[i+1];
        end
    end

    // FIFO status
    wire [ADDR_WIDTH:0] depth;
    assign depth = wptr_bin - rptr_bin;

    assign s_status_depth = depth;
    assign s_status_depth_commit = depth;
    assign s_status_overflow = (depth >= DEPTH);

    assign m_status_depth = depth;
    assign m_status_depth_commit = depth;
    assign m_status_overflow = (depth >= DEPTH);

    // FIFO signals
    assign m_data = mem[rptr[ADDR_WIDTH-1:0]];
    assign m_valid = (depth > 0);
    assign s_ready = (depth < DEPTH);

endmodule

module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter M_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = 1,
    parameter S_KEEP_WIDTH = 1,
    parameter M_KEEP_ENABLE = 1,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [S_DATA_WIDTH-1:0]  s_data,
    input  wire                     s_valid,
    output wire                     s_ready,
    output wire [M_DATA_WIDTH-1:0]  m_data,
    output wire                     m_valid,
    input  wire                     m_ready,
    output wire [M_KEEP_WIDTH-1:0]  m_tkeep,
    output wire                     m_tlast,
    output wire [ID_WIDTH-1:0]      m_tid,
    output wire [DEST_WIDTH-1:0]    m_tdest,
    output wire [USER_WIDTH-1:0]    m_tuser
);

    reg [S_DATA_WIDTH-1:0] s_data_reg;
    reg [S_KEEP_WIDTH-1:0] s_keep_reg;
    reg                    s_last_reg;
    reg [ID_WIDTH-1:0]     s_tid_reg;
    reg [DEST_WIDTH-1:0]   s_dest_reg;
    reg [USER_WIDTH-1:0]   s_user_reg;
    reg                    valid_reg;
    reg                    ready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_reg <= 0;
            s_keep_reg <= 0;
            s_last_reg <= 0;
            s_tid_reg <= 0;
            s_dest_reg <= 0;
            s_user_reg <= 0;
            valid_reg <= 0;
            ready_reg <= 0;
        end else begin
            if (s_valid && ready_reg) begin
                s_data_reg <= s_data;
                s_keep_reg <= s_keep;
                s_last_reg <= s_last;
                s_tid_reg <= s_tid;
                s_dest_reg <= s_dest;
                s_user_reg <= s_user;
                valid_reg <= 1;
            end else if (m_valid && m_ready) begin
                valid_reg <= 0;
            end

            if (valid_reg && m_ready) begin
                ready_reg <= 0;
            end else if (!valid_reg && s_valid) begin
                ready_reg <= 1;
            end
        end
    end

    assign s_ready = ready_reg;

    // Width conversion logic
    assign m_data = s_data_reg;
    assign m_valid = valid_reg;

    // Keep signal conversion
    generate
        if (S_KEEP_ENABLE && M_KEEP_ENABLE) begin
            assign m_tkeep = s_keep_reg;
        end else if (S_KEEP_ENABLE && !M_KEEP_ENABLE) begin
            assign m_tkeep = {M_KEEP_WIDTH{1'b1}};
        end else if (!S_KEEP_ENABLE && M_KEEP_ENABLE) begin
            assign m_tkeep = {M_KEEP_WIDTH{1'b1}};
        end else begin
            assign m_tkeep = 1'b1;
        end
    endgenerate

    // Last signal conversion
    assign m_tlast = s_last_reg;

    // TID signal conversion
    generate
        if (ID_ENABLE) begin
            assign m_tid = s_tid_reg;
        end else begin
            assign m_tid = 0;
        end
    endgenerate

    // TDEST signal conversion
    generate
        if (DEST_ENABLE) begin
            assign m_tdest = s_dest_reg;
        end else begin
            assign m_tdest = 0;
        end
    endgenerate

    // TUSER signal conversion
    generate
        if (USER_ENABLE) begin
            assign m_tuser = s_user_reg;
        end else begin
            assign m_tuser = 0;
        end
    endgenerate

endmodule

module handshake_logic (
    input  wire s_clk,
    input  wire s_rst,
    input  wire s_tvalid,
    output wire s_tready,
    input  wire m_clk,
    input  wire m_rst,
    input  wire m_tready,
    output wire m_tvalid
);

    reg s_tready_reg;
    reg m_tvalid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_tready_reg <= 0;
        end else begin
            s_tready_reg <= m_tready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_tvalid_reg <= 0;
        end else begin
            m_tvalid_reg <= s_tvalid;
        end
    end

    assign s_tready = s_tready_reg;
    assign m_tvalid = m_tvalid_reg;

endmodule

module pause_logic (
    input  wire s_clk,
    input  wire s_rst,
    input  wire s_pause_req,
    output wire s_pause_ack,
    input  wire m_clk,
    input  wire m_rst,
    input  wire m_pause_req,
    output wire m_pause_ack
);

    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
        end else begin
            s_pause_ack_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule

module status_logic (
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [$clog2(DEPTH):0]   s_status_depth,
    input  wire [$clog2(DEPTH):0]   s_status_depth_commit,
    input  wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    input  wire                     m_clk,
    input  wire                     m_rst,
    input  wire [$clog2(DEPTH):0]   m_status_depth,
    input  wire [$clog2(DEPTH):0]   m_status_depth_commit,
    input  wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    assign s_status_bad_frame = 1'b0; // Placeholder for actual implementation
    assign s_status_good_frame = 1'b0; // Placeholder for actual implementation
    assign m_status_bad_frame = 1'b0; // Placeholder for actual implementation
    assign m_status_good_frame = 1'b0; // Placeholder for actual implementation

endmodule

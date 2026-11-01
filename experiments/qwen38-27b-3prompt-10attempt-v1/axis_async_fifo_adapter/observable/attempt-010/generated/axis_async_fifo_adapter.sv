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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam S_BYTES = S_DATA_WIDTH / 8;
    localparam M_BYTES = M_DATA_WIDTH / 8;
    localparam S_KEEP_W = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;
    localparam M_KEEP_W = M_KEEP_ENABLE ? M_KEEP_WIDTH : 1;
    localparam ID_W = ID_ENABLE ? ID_WIDTH : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_tdata;
    wire [S_KEEP_W-1:0] s_tkeep;
    wire s_tvalid;
    wire s_tready;
    wire s_tlast;
    wire [ID_W-1:0] s_tid;
    wire [DEST_W-1:0] s_tdest;
    wire [USER_W-1:0] s_tuser;

    wire [M_DATA_WIDTH-1:0] m_tdata;
    wire [M_KEEP_W-1:0] m_tkeep;
    wire m_tvalid;
    wire m_tready;
    wire m_tlast;
    wire [ID_W-1:0] m_tid;
    wire [DEST_W-1:0] m_tdest;
    wire [USER_W-1:0] m_tuser;

    // Assign inputs to internal signals
    assign s_tdata = s_axis_tdata;
    assign s_tkeep = S_KEEP_ENABLE ? s_axis_tkeep : {S_KEEP_W{1'b1}};
    assign s_tvalid = s_axis_tvalid;
    assign s_tlast = s_axis_tlast;
    assign s_tid = ID_ENABLE ? s_axis_tid : {ID_W{1'b0}};
    assign s_tdest = DEST_ENABLE ? s_axis_tdest : {DEST_W{1'b0}};
    assign s_tuser = USER_ENABLE ? s_axis_tuser : {USER_W{1'b0}};

    assign m_tdata = m_axis_tdata;
    assign m_tkeep = M_KEEP_ENABLE ? m_axis_tkeep : {M_KEEP_W{1'b1}};
    assign m_tready = m_axis_tready;
    assign m_tlast = m_axis_tlast;
    assign m_tid = m_axis_tid;
    assign m_tdest = m_axis_tdest;
    assign m_tuser = m_axis_tuser;

    // FIFO control signals
    wire s_wr_en;
    wire m_rd_en;
    wire s_full;
    wire m_empty;
    wire [ADDR_WIDTH-1:0] s_wr_addr;
    wire [ADDR_WIDTH-1:0] m_rd_addr;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [S_DATA_WIDTH-1:0] s_frame_data;
    reg [S_KEEP_W-1:0] s_frame_keep;
    reg [ID_W-1:0] s_frame_tid;
    reg [DEST_W-1:0] s_frame_tdest;
    reg [USER_W-1:0] s_frame_tuser;
    reg s_frame_valid;
    reg s_frame_last;

    reg [M_DATA_WIDTH-1:0] m_frame_data;
    reg [M_KEEP_W-1:0] m_frame_keep;
    reg [ID_W-1:0] m_frame_tid;
    reg [DEST_W-1:0] m_frame_tdest;
    reg [USER_W-1:0] m_frame_tuser;
    reg m_frame_valid;
    reg m_frame_last;

    // Status registers
    reg s_overflow;
    reg s_bad_frame;
    reg s_good_frame;
    reg m_overflow;
    reg m_bad_frame;
    reg m_good_frame;

    // Pause logic
    reg s_paused;
    reg m_paused;

    // Width conversion buffer
    reg [S_DATA_WIDTH-1:0] conv_buf;
    reg [S_KEEP_W-1:0] conv_keep;
    reg [ID_W-1:0] conv_tid;
    reg [DEST_W-1:0] conv_tdest;
    reg [USER_W-1:0] conv_tuser;
    reg conv_valid;
    reg conv_last;
    reg [S_DATA_WIDTH-1:0] m_conv_buf;
    reg [M_KEEP_W-1:0] m_conv_keep;
    reg [ID_W-1:0] m_conv_tid;
    reg [DEST_W-1:0] m_conv_tdest;
    reg [USER_W-1:0] m_conv_tuser;
    reg m_conv_valid;
    reg m_conv_last;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [S_KEEP_W-1:0] mem_keep [0:DEPTH-1];
    reg [ID_W-1:0] mem_tid [0:DEPTH-1];
    reg [DEST_W-1:0] mem_tdest [0:DEPTH-1];
    reg [USER_W-1:0] mem_tuser [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];

    // Read data
    wire [S_DATA_WIDTH-1:0] rd_data;
    wire [S_KEEP_W-1:0] rd_keep;
    wire [ID_W-1:0] rd_tid;
    wire [DEST_W-1:0] rd_tdest;
    wire [USER_W-1:0] rd_tuser;
    wire rd_last;

    assign rd_data = mem[m_rd_addr];
    assign rd_keep = mem_keep[m_rd_addr];
    assign rd_tid = mem_tid[m_rd_addr];
    assign rd_tdest = mem_tdest[m_rd_addr];
    assign rd_tuser = mem_tuser[m_rd_addr];
    assign rd_last = mem_last[m_rd_addr];

    // Clock domain crossing for write pointer
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync_r1, s_wr_ptr_sync_r2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync_r1 <= s_wr_ptr;
            s_wr_ptr_sync_r2 <= s_wr_ptr_sync_r1;
        end
    end
    assign s_wr_ptr_sync = s_wr_ptr_sync_r2;

    // Clock domain crossing for read pointer
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync_r1, m_rd_ptr_sync_r2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync_r1 <= m_rd_ptr;
            m_rd_ptr_sync_r2 <= m_rd_ptr_sync_r1;
        end
    end
    assign m_rd_ptr_sync = m_rd_ptr_sync_r2;

    // Full and empty detection
    wire s_full_internal = (s_wr_ptr[PTR_WIDTH-1] != m_rd_ptr_sync[PTR_WIDTH-1]) && 
                           (s_wr_ptr[ADDR_WIDTH-1:0] == m_rd_ptr_sync[ADDR_WIDTH-1:0]);
    wire m_empty_internal = (m_rd_ptr == s_wr_ptr_sync);

    assign s_full = s_full_internal;
    assign m_empty = m_empty_internal;

    // Write enable
    assign s_wr_en = s_tvalid && s_tready && !s_full;

    // Read enable
    assign m_rd_en = m_tvalid && m_tready && !m_empty;

    // Write address
    assign s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    assign m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_wr_en) begin
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Memory write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            mem[s_wr_addr] <= s_tdata;
            mem_keep[s_wr_addr] <= s_tkeep;
            mem_tid[s_wr_addr] <= s_tid;
            mem_tdest[s_wr_addr] <= s_tdest;
            mem_tuser[s_wr_addr] <= s_tuser;
            mem_last[s_wr_addr] <= s_tlast;
        end
    end

    // Frame tracking on source side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_data <= {S_DATA_WIDTH{1'b0}};
            s_frame_keep <= {S_KEEP_W{1'b0}};
            s_frame_tid <= {ID_W{1'b0}};
            s_frame_tdest <= {DEST_W{1'b0}};
            s_frame_tuser <= {USER_W{1'b0}};
            s_frame_valid <= 1'b0;
            s_frame_last <= 1'b0;
        end else begin
            if (s_tvalid && s_tready) begin
                if (!s_in_frame) begin
                    s_in_frame <= 1'b1;
                    s_frame_data <= s_tdata;
                    s_frame_keep <= s_tkeep;
                    s_frame_tid <= s_tid;
                    s_frame_tdest <= s_tdest;
                    s_frame_tuser <= s_tuser;
                    s_frame_valid <= 1'b1;
                    s_frame_last <= s_tlast;
                end else begin
                    s_frame_data <= s_tdata;
                    s_frame_keep <= s_tkeep;
                    s_frame_tid <= s_tid;
                    s_frame_tdest <= s_tdest;
                    s_frame_tuser <= s_tuser;
                    s_frame_last <= s_tlast;
                    if (s_tlast) begin
                        s_in_frame <= 1'b0;
                        s_frame_valid <= 1'b0;
                    end
                end
            end
        end
    end

    // Frame tracking on master side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_data <= {M_DATA_WIDTH{1'b0}};
            m_frame_keep <= {M_KEEP_W{1'b0}};
            m_frame_tid <= {ID_W{1'b0}};
            m_frame_tdest <= {DEST_W{1'b0}};
            m_frame_tuser <= {USER_W{1'b0}};
            m_frame_valid <= 1'b0;
            m_frame_last <= 1'b0;
        end else begin
            if (m_tvalid && m_tready) begin
                if (!m_in_frame) begin
                    m_in_frame <= 1'b1;
                    m_frame_data <= m_tdata;
                    m_frame_keep <= m_tkeep;
                    m_frame_tid <= m_tid;
                    m_frame_tdest <= m_tdest;
                    m_frame_tuser <= m_tuser;
                    m_frame_valid <= 1'b1;
                    m_frame_last <= m_tlast;
                end else begin
                    m_frame_data <= m_tdata;
                    m_frame_keep <= m_tkeep;
                    m_frame_tid <= m_tid;
                    m_frame_tdest <= m_tdest;
                    m_frame_tuser <= m_tuser;
                    m_frame_last <= m_tlast;
                    if (m_tlast) begin
                        m_in_frame <= 1'b0;
                        m_frame_valid <= 1'b0;
                    end
                end
            end
        end
    end

    // Status registers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_tvalid && s_tready && s_full) begin
                s_overflow <= 1'b1;
            end
            if (s_tvalid && s_tready && s_tlast) begin
                s_good_frame <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_tvalid && m_tready && m_empty) begin
                m_overflow <= 1'b0;
            end
            if (m_tvalid && m_tready && m_tlast) begin
                m_good_frame <= 1'b1;
            end
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (s_pause_req) begin
                s_paused <= 1'b1;
            end else if (s_pause_ack) begin
                s_paused <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (m_pause_req) begin
                m_paused <= 1'b1;
            end else if (m_pause_ack) begin
                m_paused <= 1'b0;
            end
        end
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Ready signals
    assign s_axis_tready = s_tready;
    assign m_axis_tvalid = m_tvalid;
    assign m_axis_tdata = m_tdata;
    assign m_axis_tkeep = m_tkeep;
    assign m_axis_tlast = m_tlast;
    assign m_axis_tid = m_tid;
    assign m_axis_tdest = m_tdest;
    assign m_axis_tuser = m_tuser;

    // Source ready logic
    wire s_ready_internal = !s_full && !s_paused;
    assign s_tready = s_ready_internal;

    // Master valid logic
    wire m_valid_internal = !m_empty && !m_paused;
    assign m_tvalid = m_valid_internal;

    // Width conversion
    // For simplicity, assume S_DATA_WIDTH == M_DATA_WIDTH or handle byte-wise
    // If widths differ, we need to accumulate bytes
    wire [S_DATA_WIDTH-1:0] conv_data;
    wire [S_KEEP_W-1:0] conv_keep_sig;
    wire conv_last_sig;
    wire [ID_W-1:0] conv_tid_sig;
    wire [DEST_W-1:0] conv_tdest_sig;
    wire [USER_W-1:0] conv_tuser_sig;

    // If same width, direct pass
    generate
        if (S_DATA_WIDTH == M_DATA_WIDTH) begin
            assign conv_data = rd_data;
            assign conv_keep_sig = rd_keep;
            assign conv_last_sig = rd_last;
            assign conv_tid_sig = rd_tid;
            assign conv_tdest_sig = rd_tdest;
            assign conv_tuser_sig = rd_tuser;
        end else begin
            // Width conversion logic
            // Accumulate bytes from source to match master width
            reg [S_DATA_WIDTH-1:0] acc_data;
            reg [S_KEEP_W-1:0] acc_keep;
            reg [ID_W-1:0] acc_tid;
            reg [DEST_W-1:0] acc_tdest;
            reg [USER_W-1:0] acc_tuser;
            reg acc_last;
            reg acc_valid;
            reg [3:0] byte_count;

            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    acc_data <= {S_DATA_WIDTH{1'b0}};
                    acc_keep <= {S_KEEP_W{1'b0}};
                    acc_tid <= {ID_W{1'b0}};
                    acc_tdest <= {DEST_W{1'b0}};
                    acc_tuser <= {USER_W{1'b0}};
                    acc_last <= 1'b0;
                    acc_valid <= 1'b0;
                    byte_count <= 4'd0;
                end else begin
                    if (m_rd_en) begin
                        // Shift in new data
                        if (byte_count < M_BYTES) begin
                            // Add bytes from rd_data
                            for (integer i = 0; i < S_BYTES; i = i + 1) begin
                                if (byte_count + i < M_BYTES) begin
                                    acc_data[(byte_count + i)*8 +: 8] <= rd_data[i*8 +: 8];
                                    if (S_KEEP_ENABLE) begin
                                        acc_keep[byte_count + i] <= rd_keep[i];
                                    end
                                end
                            end
                            byte_count <= byte_count + S_BYTES;
                            acc_tid <= rd_tid;
                            acc_tdest <= rd_tdest;
                            acc_tuser <= rd_tuser;
                            acc_last <= rd_last;
                            acc_valid <= 1'b1;
                        end
                    end
                    if (m_tvalid && m_tready) begin
                        acc_valid <= 1'b0;
                        byte_count <= 4'd0;
                    end
                end
            end

            assign conv_data = acc_data;
            assign conv_keep_sig = acc_keep;
            assign conv_last_sig = acc_last;
            assign conv_tid_sig = acc_tid;
            assign conv_tdest_sig = acc_tdest;
            assign conv_tuser_sig = acc_tuser;
        end
    endgenerate

    // Output assignment
    assign m_tdata = conv_data;
    assign m_tkeep = conv_keep_sig;
    assign m_tlast = conv_last_sig;
    assign m_tid = conv_tid_sig;
    assign m_tdest = conv_tdest_sig;
    assign m_tuser = conv_tuser_sig;

    // Status depth
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - m_rd_ptr_sync;
    wire [PTR_WIDTH-1:0] m_depth = s_wr_ptr_sync - m_rd_ptr;

    assign s_status_depth = s_depth[PTR_WIDTH-1:0];
    assign s_status_depth_commit = s_depth[PTR_WIDTH-1:0];
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth[PTR_WIDTH-1:0];
    assign m_status_depth_commit = m_depth[PTR_WIDTH-1:0];
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule

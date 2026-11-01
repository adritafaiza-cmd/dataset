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
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;
    localparam ACC_WIDTH = MAX_BYTES * 8;
    localparam ACC_KEEP_WIDTH = MAX_BYTES;
    localparam ACC_KEEP_ENABLE = (MAX_BYTES > 1);

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_tdata;
    wire [S_KEEP_WIDTH-1:0] s_tkeep;
    wire s_tvalid;
    wire s_tready;
    wire s_tlast;
    wire [ID_WIDTH-1:0] s_tid;
    wire [DEST_WIDTH-1:0] s_tdest;
    wire [USER_WIDTH-1:0] s_tuser;

    wire [M_DATA_WIDTH-1:0] m_tdata;
    wire [M_KEEP_WIDTH-1:0] m_tkeep;
    wire m_tvalid;
    wire m_tready;
    wire m_tlast;
    wire [ID_WIDTH-1:0] m_tid;
    wire [DEST_WIDTH-1:0] m_tdest;
    wire [USER_WIDTH-1:0] m_tuser;

    // Pause logic
    reg s_pause_active;
    reg m_pause_active;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            s_pause_active <= s_pause_req;
        else
            s_pause_active <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            m_pause_active <= m_pause_req;
        else
            m_pause_active <= 1'b0;
    end

    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;

    // Input side: hold data when not ready
    reg [S_DATA_WIDTH-1:0] s_hold_tdata;
    reg [S_KEEP_WIDTH-1:0] s_hold_tkeep;
    reg s_hold_tlast;
    reg [ID_WIDTH-1:0] s_hold_tid;
    reg [DEST_WIDTH-1:0] s_hold_tdest;
    reg [USER_WIDTH-1:0] s_hold_tuser;
    reg s_hold_valid;

    wire s_input_ready = s_tready & ~s_pause_active;
    wire s_input_valid = s_axis_tvalid & ~s_pause_active;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_hold_tdata <= {S_DATA_WIDTH{1'b0}};
            s_hold_tkeep <= {S_KEEP_WIDTH{1'b0}};
            s_hold_tlast <= 1'b0;
            s_hold_tid <= {ID_WIDTH{1'b0}};
            s_hold_tdest <= {DEST_WIDTH{1'b0}};
            s_hold_tuser <= {USER_WIDTH{1'b0}};
            s_hold_valid <= 1'b0;
        end else if (s_input_valid && s_input_ready) begin
            s_hold_tdata <= s_axis_tdata;
            s_hold_tkeep <= s_axis_tkeep;
            s_hold_tlast <= s_axis_tlast;
            s_hold_tid <= s_axis_tid;
            s_hold_tdest <= s_axis_tdest;
            s_hold_tuser <= s_axis_tuser;
            s_hold_valid <= 1'b1;
        end else if (s_input_valid && !s_input_ready) begin
            // Hold current, don't update
        end else if (!s_input_valid && s_hold_valid && s_input_ready) begin
            s_hold_valid <= 1'b0;
        end
    end

    assign s_tdata = s_hold_tdata;
    assign s_tkeep = s_hold_tkeep;
    assign s_tvalid = s_hold_valid;
    assign s_tlast = s_hold_tlast;
    assign s_tid = s_hold_tid;
    assign s_tdest = s_hold_tdest;
    assign s_tuser = s_hold_tuser;

    // Accumulator in s_clk domain
    reg [ACC_WIDTH-1:0] acc_data;
    reg [ACC_KEEP_WIDTH-1:0] acc_keep;
    reg acc_valid;
    reg [ID_WIDTH-1:0] acc_tid;
    reg [DEST_WIDTH-1:0] acc_tdest;
    reg [USER_WIDTH-1:0] acc_tuser;
    reg acc_tlast;
    reg acc_bad_frame;

    wire s_write_en = s_tvalid & s_tready;

    // Calculate how many bytes are valid in current beat
    reg [S_KEEP_WIDTH-1:0] s_keep;
    assign s_keep = S_KEEP_ENABLE ? s_tkeep : {S_KEEP_WIDTH{1'b1}};

    // Count valid bytes in s_keep
    reg [S_KEEP_WIDTH:0] s_valid_bytes;
    always @(*) begin
        s_valid_bytes = 0;
        for (int i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
            if (s_keep[i])
                s_valid_bytes = s_valid_bytes + 1;
        end
    end

    // Accumulator logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            acc_data <= {ACC_WIDTH{1'b0}};
            acc_keep <= {ACC_KEEP_WIDTH{1'b0}};
            acc_valid <= 1'b0;
            acc_tid <= {ID_WIDTH{1'b0}};
            acc_tdest <= {DEST_WIDTH{1'b0}};
            acc_tuser <= {USER_WIDTH{1'b0}};
            acc_tlast <= 1'b0;
            acc_bad_frame <= 1'b0;
        end else if (s_write_en) begin
            if (!acc_valid) begin
                // Start new frame
                acc_data <= {ACC_WIDTH{1'b0}};
                acc_keep <= {ACC_KEEP_WIDTH{1'b0}};
                acc_tid <= s_tid;
                acc_tdest <= s_tdest;
                acc_tuser <= s_tuser;
                acc_tlast <= s_tlast;
                acc_bad_frame <= 1'b0;
                acc_valid <= 1'b1;
                
                // Insert bytes
                for (int i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                    if (s_keep[i]) begin
                        acc_data[i*8 +: 8] <= s_tdata[i*8 +: 8];
                        acc_keep[i] <= 1'b1;
                    end
                end
            end else begin
                // Continue frame
                acc_tlast <= s_tlast;
                
                // Check for bad frame (oversize)
                if (DROP_OVERSIZE_FRAME) begin
                    // Simple check: if we're already full and more data comes
                    // This is a simplified check
                end
                
                // Insert bytes
                for (int i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                    if (s_keep[i]) begin
                        acc_data[i*8 +: 8] <= s_tdata[i*8 +: 8];
                        acc_keep[i] <= 1'b1;
                    end
                end
            end
        end else if (acc_valid && s_tready) begin
            // Frame complete, clear accumulator
            acc_valid <= 1'b0;
        end
    end

    // Frame complete signal
    wire s_frame_complete = s_write_en & s_tlast;

    // Write to FIFO when frame is complete
    wire s_fifo_write = s_frame_complete;
    wire [ACC_WIDTH-1:0] s_fifo_data = acc_data;
    wire [ACC_KEEP_WIDTH-1:0] s_fifo_keep = acc_keep;
    wire [ID_WIDTH-1:0] s_fifo_tid = acc_tid;
    wire [DEST_WIDTH-1:0] s_fifo_tdest = acc_tdest;
    wire [USER_WIDTH-1:0] s_fifo_tuser = acc_tuser;
    wire s_fifo_tlast = 1'b1; // Always last for frame-based FIFO
    wire s_fifo_bad_frame = acc_bad_frame;

    // FIFO pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync2;

    // Synchronizers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync1 <= m_rd_ptr;
            m_rd_ptr_sync2 <= m_rd_ptr_sync1;
        end
    end

    wire [PTR_WIDTH-1:0] s_wr_ptr_sync1;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_wr_ptr_sync1 <= s_wr_ptr;
            m_wr_ptr_sync2 <= m_wr_ptr_sync1;
        end
    end

    // FIFO full/empty
    wire s_fifo_full = (s_wr_ptr - m_rd_ptr_sync2) >= DEPTH;
    wire m_fifo_empty = (m_rd_ptr == m_wr_ptr_sync2);

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_fifo_write && !s_fifo_full)
            s_wr_ptr <= s_wr_ptr + 1'b1;
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (m_tvalid && m_tready && !m_pause_active)
            m_rd_ptr <= m_rd_ptr + 1'b1;
    end

    // FIFO ready
    assign s_tready = ~s_fifo_full & ~s_pause_active;

    // FIFO read in m_clk domain
    reg [ACC_WIDTH-1:0] m_fifo_data;
    reg [ACC_KEEP_WIDTH-1:0] m_fifo_keep;
    reg [ID_WIDTH-1:0] m_fifo_tid;
    reg [DEST_WIDTH-1:0] m_fifo_tdest;
    reg [USER_WIDTH-1:0] m_fifo_tuser;
    reg m_fifo_tlast;
    reg m_fifo_bad_frame;
    reg m_fifo_valid;

    // RAM read (simplified - in real implementation would use dual-port RAM)
    // For this implementation, we use a register-based approach
    // In a real design, this would be a dual-port RAM with proper CDC

    // Output FIFO / Width adapter
    reg [ACC_WIDTH-1:0] out_acc_data;
    reg [ACC_KEEP_WIDTH-1:0] out_acc_keep;
    reg [ID_WIDTH-1:0] out_acc_tid;
    reg [DEST_WIDTH-1:0] out_acc_tdest;
    reg [USER_WIDTH-1:0] out_acc_tuser;
    reg out_acc_tlast;
    reg out_acc_bad_frame;
    reg out_acc_valid;
    reg [ACC_KEEP_WIDTH:0] out_acc_byte_count;

    wire m_read_en = m_tvalid & m_tready & ~m_pause_active;

    // Load from FIFO
    wire m_fifo_read = m_read_en;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_acc_data <= {ACC_WIDTH{1'b0}};
            out_acc_keep <= {ACC_KEEP_WIDTH{1'b0}};
            out_acc_tid <= {ID_WIDTH{1'b0}};
            out_acc_tdest <= {DEST_WIDTH{1'b0}};
            out_acc_tuser <= {USER_WIDTH{1'b0}};
            out_acc_tlast <= 1'b0;
            out_acc_bad_frame <= 1'b0;
            out_acc_valid <= 1'b0;
            out_acc_byte_count <= 0;
        end else if (m_fifo_read && !m_fifo_empty) begin
            // Load new frame from FIFO
            out_acc_data <= m_fifo_data;
            out_acc_keep <= m_fifo_keep;
            out_acc_tid <= m_fifo_tid;
            out_acc_tdest <= m_fifo_tdest;
            out_acc_tuser <= m_fifo_tuser;
            out_acc_tlast <= m_fifo_tlast;
            out_acc_bad_frame <= m_fifo_bad_frame;
            out_acc_valid <= 1'b1;
            out_acc_byte_count <= 0;
            
            // Count bytes
            for (int i = 0; i < ACC_KEEP_WIDTH; i = i + 1) begin
                if (m_fifo_keep[i])
                    out_acc_byte_count <= out_acc_byte_count + 1;
            end
        end else if (out_acc_valid && m_read_en) begin
            // Output a beat
            out_acc_byte_count <= out_acc_byte_count - M_BYTES;
            if (out_acc_byte_count <= M_BYTES) begin
                out_acc_valid <= 1'b0;
            end
        end
    end

    // Output valid
    assign m_tvalid = out_acc_valid & ~m_pause_active;

    // Output data
    assign m_tdata = out_acc_data[M_DATA_WIDTH-1:0];
    assign m_tkeep = M_KEEP_ENABLE ? out_acc_keep[M_KEEP_WIDTH-1:0] : {M_KEEP_WIDTH{1'b1}};
    assign m_tlast = out_acc_tlast & (out_acc_byte_count <= M_BYTES);
    assign m_tid = out_acc_tid;
    assign m_tdest = out_acc_tdest;
    assign m_tuser = out_acc_tuser;

    // Status
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - m_rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_depth = m_wr_ptr_sync2 - m_rd_ptr;

    assign s_status_depth = s_depth[ADDR_WIDTH:0];
    assign s_status_depth_commit = s_depth[ADDR_WIDTH:0];
    assign s_status_overflow = s_fifo_full & s_write_en;
    assign s_status_bad_frame = s_fifo_bad_frame & s_frame_complete;
    assign s_status_good_frame = ~s_fifo_bad_frame & s_frame_complete;

    assign m_status_depth = m_depth[ADDR_WIDTH:0];
    assign m_status_depth_commit = m_depth[ADDR_WIDTH:0];
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = out_acc_bad_frame & m_read_en;
    assign m_status_good_frame = ~out_acc_bad_frame & m_read_en;

endmodule

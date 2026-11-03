module axis_async_fifo #
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
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
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
    input  wire                   m_clk,
    input  wire                   m_rst,
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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Total width of the data word stored in RAM
    localparam TOTAL_WIDTH = DATA_WIDTH + 
                             (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                             (LAST_ENABLE ? 1 : 0) + 
                             (ID_ENABLE ? ID_WIDTH : 0) + 
                             (DEST_ENABLE ? DEST_WIDTH : 0) + 
                             (USER_ENABLE ? USER_WIDTH : 0);

    // Pack input data into a single word
    wire [TOTAL_WIDTH-1:0] s_packed_data;
    assign s_packed_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Unpack output data
    wire [TOTAL_WIDTH-1:0] m_packed_data;
    assign m_axis_tdata = m_packed_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? m_packed_data[DATA_WIDTH +: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? m_packed_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? m_packed_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) +: ID_WIDTH] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? m_packed_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) +: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? m_packed_data[TOTAL_WIDTH-USER_WIDTH-1:0] : {USER_WIDTH{1'b0}};

    // Source domain signals
    reg [ADDR_WIDTH-1:0] s_wr_addr;
    reg [ADDR_WIDTH-1:0] s_rd_addr_sync;
    reg [ADDR_WIDTH-1:0] s_rd_addr_sync1;
    reg [ADDR_WIDTH-1:0] s_rd_addr_sync2;
    reg [ADDR_WIDTH-1:0] s_rd_addr_sync3;
    
    // Destination domain signals
    reg [ADDR_WIDTH-1:0] m_rd_addr;
    reg [ADDR_WIDTH-1:0] m_wr_addr_sync;
    reg [ADDR_WIDTH-1:0] m_wr_addr_sync1;
    reg [ADDR_WIDTH-1:0] m_wr_addr_sync2;
    reg [ADDR_WIDTH-1:0] m_wr_addr_sync3;

    // RAM
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];

    // Source domain: write pointer
    reg [ADDR_WIDTH-1:0] s_wr_ptr;
    reg s_wr_ptr_carry;
    
    // Destination domain: read pointer
    reg [ADDR_WIDTH-1:0] m_rd_ptr;
    reg m_rd_ptr_carry;

    // Source domain: synchronized read pointer (from dest)
    reg [ADDR_WIDTH-1:0] s_m_rd_ptr_sync;
    reg [ADDR_WIDTH-1:0] s_m_rd_ptr_sync1;
    reg [ADDR_WIDTH-1:0] s_m_rd_ptr_sync2;
    reg [ADDR_WIDTH-1:0] s_m_rd_ptr_sync3;

    // Destination domain: synchronized write pointer (from source)
    reg [ADDR_WIDTH-1:0] m_s_wr_ptr_sync;
    reg [ADDR_WIDTH-1:0] m_s_wr_ptr_sync1;
    reg [ADDR_WIDTH-1:0] m_s_wr_ptr_sync2;
    reg [ADDR_WIDTH-1:0] m_s_wr_ptr_sync3;

    // Full/Empty detection
    wire s_full;
    wire m_empty;
    wire s_not_full;
    wire m_not_empty;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_wr_ptr_full;
    wire [PTR_WIDTH-1:0] s_m_rd_ptr_full;
    wire [PTR_WIDTH-1:0] m_rd_ptr_full;
    wire [PTR_WIDTH-1:0] m_s_wr_ptr_full;

    assign s_wr_ptr_full = {s_wr_ptr_carry, s_wr_ptr};
    assign s_m_rd_ptr_full = {s_m_rd_ptr_sync3[ADDR_WIDTH-1], s_m_rd_ptr_sync3};
    assign m_rd_ptr_full = {m_rd_ptr_carry, m_rd_ptr};
    assign m_s_wr_ptr_full = {m_s_wr_ptr_sync3[ADDR_WIDTH-1], m_s_wr_ptr_sync3};

    // Full: write pointer has lapped read pointer by DEPTH
    assign s_full = (s_wr_ptr == s_m_rd_ptr_sync3) && (s_wr_ptr_carry != s_m_rd_ptr_sync3[ADDR_WIDTH-1]);
    // Empty: read pointer equals write pointer
    assign m_empty = (m_rd_ptr == m_s_wr_ptr_sync3) && (m_rd_ptr_carry == m_s_wr_ptr_sync3[ADDR_WIDTH-1]);

    assign s_not_full = !s_full;
    assign m_not_empty = !m_empty;

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

    assign s_pause_ack = PAUSE_ENABLE ? s_pause_active : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_active : 1'b0;

    // Source domain: write enable
    wire s_wr_en;
    assign s_wr_en = s_axis_tvalid && s_axis_tready && !s_pause_active;

    // Source domain: tready
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : (s_not_full && !s_pause_active);

    // Destination domain: read enable
    wire m_rd_en;
    assign m_rd_en = m_axis_tvalid && m_axis_tready && !m_pause_active;

    // Destination domain: tvalid
    assign m_axis_tvalid = m_not_empty && !m_pause_active;

    // Source domain: write to RAM
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram[s_wr_ptr] <= s_packed_data;
            s_wr_ptr <= s_wr_ptr + 1'b1;
            s_wr_ptr_carry <= s_wr_ptr_carry ^ (s_wr_ptr == DEPTH_MASK);
        end
    end

    // Destination domain: read from RAM
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
            m_rd_ptr_carry <= m_rd_ptr_carry ^ (m_rd_ptr == DEPTH_MASK);
        end
    end

    // Destination domain: output data
    reg [TOTAL_WIDTH-1:0] m_out_data;
    always @(posedge m_clk) begin
        m_out_data <= ram[m_rd_ptr];
    end
    assign m_packed_data = m_out_data;

    // Synchronize write pointer to destination domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_s_wr_ptr_sync <= {ADDR_WIDTH{1'b0}};
            m_s_wr_ptr_sync1 <= {ADDR_WIDTH{1'b0}};
            m_s_wr_ptr_sync2 <= {ADDR_WIDTH{1'b0}};
            m_s_wr_ptr_sync3 <= {ADDR_WIDTH{1'b0}};
        end else begin
            m_s_wr_ptr_sync <= s_wr_ptr;
            m_s_wr_ptr_sync1 <= m_s_wr_ptr_sync;
            m_s_wr_ptr_sync2 <= m_s_wr_ptr_sync1;
            m_s_wr_ptr_sync3 <= m_s_wr_ptr_sync2;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_m_rd_ptr_sync <= {ADDR_WIDTH{1'b0}};
            s_m_rd_ptr_sync1 <= {ADDR_WIDTH{1'b0}};
            s_m_rd_ptr_sync2 <= {ADDR_WIDTH{1'b0}};
            s_m_rd_ptr_sync3 <= {ADDR_WIDTH{1'b0}};
        end else begin
            s_m_rd_ptr_sync <= m_rd_ptr;
            s_m_rd_ptr_sync1 <= s_m_rd_ptr_sync;
            s_m_rd_ptr_sync2 <= s_m_rd_ptr_sync1;
            s_m_rd_ptr_sync3 <= s_m_rd_ptr_sync2;
        end
    end

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_raw;
    wire [PTR_WIDTH-1:0] m_depth_raw;
    
    assign s_depth_raw = s_wr_ptr_full - s_m_rd_ptr_full;
    assign m_depth_raw = m_s_wr_ptr_full - m_rd_ptr_full;

    // Clamp depth to DEPTH
    wire [PTR_WIDTH-1:0] s_depth_clamped;
    wire [PTR_WIDTH-1:0] m_depth_clamped;
    
    assign s_depth_clamped = (s_depth_raw > DEPTH) ? DEPTH : s_depth_raw;
    assign m_depth_clamped = (m_depth_raw > DEPTH) ? DEPTH : m_depth_raw;

    assign s_status_depth = s_depth_clamped;
    assign m_status_depth = m_depth_clamped;

    // Commit depth (same as depth for this implementation)
    assign s_status_depth_commit = s_depth_clamped;
    assign m_status_depth_commit = m_depth_clamped;

    // Overflow detection
    reg s_overflow_flag;
    reg m_overflow_flag;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_flag <= 1'b0;
        else if (s_wr_en && s_full)
            s_overflow_flag <= 1'b1;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_flag <= 1'b0;
        else if (m_rd_en && m_empty)
            m_overflow_flag <= 1'b1;
    end

    assign s_status_overflow = s_overflow_flag;
    assign m_status_overflow = m_overflow_flag;

    // Frame status (simplified: good frame when tlast is seen)
    reg s_good_frame_flag;
    reg s_bad_frame_flag;
    reg m_good_frame_flag;
    reg m_bad_frame_flag;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_good_frame_flag <= 1'b0;
            s_bad_frame_flag <= 1'b0;
        end else begin
            if (s_wr_en && LAST_ENABLE && s_axis_tlast) begin
                s_good_frame_flag <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_good_frame_flag <= 1'b0;
            m_bad_frame_flag <= 1'b0;
        end else begin
            if (m_rd_en && LAST_ENABLE && m_axis_tlast) begin
                m_good_frame_flag <= 1'b1;
            end
        end
    end

    assign s_status_good_frame = s_good_frame_flag;
    assign s_status_bad_frame = s_bad_frame_flag;
    assign m_status_good_frame = m_good_frame_flag;
    assign m_status_bad_frame = m_bad_frame_flag;

endmodule

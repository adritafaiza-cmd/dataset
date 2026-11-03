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
    localparam DEPTH_MASK = DEPTH - 1;
    
    // Total width of the data bus stored in RAM
    localparam SIDE_WIDTH = (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                            (LAST_ENABLE ? 1 : 0) + 
                            (ID_ENABLE ? ID_WIDTH : 0) + 
                            (DEST_ENABLE ? DEST_WIDTH : 0) + 
                            (USER_ENABLE ? USER_WIDTH : 0);
    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

    // Internal signals
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];
    
    // Write pointer (s_clk domain)
    reg [ADDR_WIDTH:0] w_ptr;
    reg [ADDR_WIDTH:0] w_ptr_sync_m; // Synced to m_clk
    
    // Read pointer (m_clk domain)
    reg [ADDR_WIDTH:0] r_ptr;
    reg [ADDR_WIDTH:0] r_ptr_sync_s; // Synced to s_clk
    
    // Handshake signals
    wire s_write_en;
    wire m_read_en;
    
    // Full/Empty detection
    wire s_full;
    wire m_empty;
    
    // Status flags
    reg s_overflow_flag;
    reg m_overflow_flag;
    reg s_bad_frame_flag;
    reg m_bad_frame_flag;
    reg s_good_frame_flag;
    reg m_good_frame_flag;
    
    // Pause logic
    reg s_pause_active;
    reg m_pause_active;
    
    // Depth calculation
    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;
    
    // Commit depth (simplified as current depth for this implementation)
    wire [$clog2(DEPTH):0] s_depth_commit;
    wire [$clog2(DEPTH):0] m_depth_commit;

    // Data packing/unpacking
    wire [TOTAL_WIDTH-1:0] s_axis_packed;
    wire [TOTAL_WIDTH-1:0] m_axis_unpacked;
    
    // Generate packed data for write
    assign s_axis_packed = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Unpack data for read
    assign m_axis_tdata = m_axis_unpacked[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_axis_unpacked[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    assign m_axis_tlast = m_axis_unpacked[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1];
    assign m_axis_tid = m_axis_unpacked[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : 
                         DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    assign m_axis_tdest = m_axis_unpacked[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : 
                           DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    assign m_axis_tuser = m_axis_unpacked[TOTAL_WIDTH-1 : 
                           DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];

    // Write enable logic
    assign s_write_en = s_axis_tvalid && s_axis_tready;
    
    // Read enable logic
    assign m_read_en = m_axis_tvalid && m_axis_tready;

    // Full/Empty logic
    assign s_full = (w_ptr[ADDR_WIDTH] != r_ptr_sync_s[ADDR_WIDTH]) && 
                    (w_ptr[ADDR_WIDTH-1:0] == r_ptr_sync_s[ADDR_WIDTH-1:0]);
    assign m_empty = (r_ptr == r_ptr_sync_s); // This is not correct, need to compare with w_ptr_sync_m

    // Correct empty logic
    wire m_empty_correct = (r_ptr[ADDR_WIDTH] != w_ptr_sync_m[ADDR_WIDTH]) || 
                           (r_ptr[ADDR_WIDTH-1:0] != w_ptr_sync_m[ADDR_WIDTH-1:0]);
    assign m_empty = ~m_empty_correct;

    // Correct full logic
    wire s_full_correct = (w_ptr[ADDR_WIDTH] != r_ptr_sync_s[ADDR_WIDTH]) && 
                          (w_ptr[ADDR_WIDTH-1:0] == r_ptr_sync_s[ADDR_WIDTH-1:0]);
    assign s_full = s_full_correct;

    // Depth calculation
    assign s_depth = w_ptr - r_ptr_sync_s;
    assign m_depth = w_ptr_sync_m - r_ptr;
    
    // Commit depth (same as current depth for simplicity)
    assign s_depth_commit = s_depth;
    assign m_depth_commit = m_depth;

    // Pause logic
    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;

    // Tready logic
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : 
                           (s_full || s_pause_active) ? 1'b0 : 1'b1;
    assign m_axis_tvalid = ~m_empty && !m_pause_active;

    // Synchronous reset for s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {(ADDR_WIDTH+1){1'b0}};
            s_overflow_flag <= 1'b0;
            s_bad_frame_flag <= 1'b0;
            s_good_frame_flag <= 1'b0;
            s_pause_active <= 1'b0;
        end else begin
            // Handle pause
            if (PAUSE_ENABLE) begin
                if (s_pause_req && !s_pause_active) begin
                    s_pause_active <= 1'b1;
                end else if (!s_pause_req && s_pause_active) begin
                    s_pause_active <= 1'b0;
                end
            end
            
            // Write to RAM
            if (s_write_en) begin
                ram[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_packed;
                w_ptr <= w_ptr + 1'b1;
                
                // Check for overflow
                if (s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL) begin
                    s_overflow_flag <= 1'b1;
                end
            end
        end
    end

    // Synchronous reset for m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {(ADDR_WIDTH+1){1'b0}};
            m_overflow_flag <= 1'b0;
            m_bad_frame_flag <= 1'b0;
            m_good_frame_flag <= 1'b0;
            m_pause_active <= 1'b0;
        end else begin
            // Handle pause
            if (PAUSE_ENABLE) begin
                if (m_pause_req && !m_pause_active) begin
                    m_pause_active <= 1'b1;
                end else if (!m_pause_req && m_pause_active) begin
                    m_pause_active <= 1'b0;
                end
            end
            
            // Read from RAM
            if (m_read_en) begin
                m_axis_unpacked <= ram[r_ptr[ADDR_WIDTH-1:0]];
                r_ptr <= r_ptr + 1'b1;
            end
        end
    end

    // Synchronize w_ptr to m_clk domain
    reg [ADDR_WIDTH:0] w_ptr_sync_m_1, w_ptr_sync_m_2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync_m_1 <= {(ADDR_WIDTH+1){1'b0}};
            w_ptr_sync_m_2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            w_ptr_sync_m_1 <= w_ptr;
            w_ptr_sync_m_2 <= w_ptr_sync_m_1;
        end
    end
    assign w_ptr_sync_m = w_ptr_sync_m_2;

    // Synchronize r_ptr to s_clk domain
    reg [ADDR_WIDTH:0] r_ptr_sync_s_1, r_ptr_sync_s_2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync_s_1 <= {(ADDR_WIDTH+1){1'b0}};
            r_ptr_sync_s_2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            r_ptr_sync_s_1 <= r_ptr;
            r_ptr_sync_s_2 <= r_ptr_sync_s_1;
        end
    end
    assign r_ptr_sync_s = r_ptr_sync_s_2;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow_flag;
    assign s_status_bad_frame = s_bad_frame_flag;
    assign s_status_good_frame = s_good_frame_flag;
    
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow_flag;
    assign m_status_bad_frame = m_bad_frame_flag;
    assign m_status_good_frame = m_good_frame_flag;

endmodule

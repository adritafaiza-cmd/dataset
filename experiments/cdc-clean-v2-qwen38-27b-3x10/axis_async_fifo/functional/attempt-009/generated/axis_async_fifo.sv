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
    
    // Total width of the data word stored in RAM
    localparam TOTAL_WIDTH = DATA_WIDTH + 
                             (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                             (LAST_ENABLE ? 1 : 0) + 
                             (ID_ENABLE ? ID_WIDTH : 0) + 
                             (DEST_ENABLE ? DEST_WIDTH : 0) + 
                             (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [ADDR_WIDTH:0] s_wr_ptr;
    wire [ADDR_WIDTH:0] m_rd_ptr;
    
    wire [ADDR_WIDTH:0] s_wr_ptr_sync_m;
    wire [ADDR_WIDTH:0] m_rd_ptr_sync_s;
    
    wire s_full;
    wire m_empty;
    
    wire s_wr_en;
    wire m_rd_en;
    
    wire [TOTAL_WIDTH-1:0] s_wr_data;
    wire [TOTAL_WIDTH-1:0] m_rd_data;
    
    // Status signals
    reg s_overflow_reg;
    reg m_overflow_reg;
    reg s_bad_frame_reg;
    reg m_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_good_frame_reg;
    
    // Pause signals
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    
    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    
    // Oversize frame tracking
    reg s_oversize_frame;
    reg m_oversize_frame;
    
    // Bad frame tracking
    reg s_bad_frame_active;
    reg m_bad_frame_active;
    
    // Depth calculation
    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;
    
    // Commit depth (simplified as current depth for this implementation)
    wire [$clog2(DEPTH):0] s_depth_commit;
    wire [$clog2(DEPTH):0] m_depth_commit;

    // RAM storage
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];
    
    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    
    // Synchronous FIFO write logic
    assign s_wr_en = s_axis_tvalid && s_axis_tready;
    
    // Build write data
    wire [TOTAL_WIDTH-1:0] wr_data;
    assign wr_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };
    
    assign s_wr_data = wr_data;
    
    // Write to RAM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_in_frame <= 1'b0;
            s_oversize_frame <= 1'b0;
            s_bad_frame_active <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            if (s_wr_en) begin
                ram[s_wr_addr] <= s_wr_data;
                s_wr_ptr <= s_wr_ptr + 1'b1;
            end
            
            // Overflow detection
            if (s_wr_en && s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL) begin
                s_overflow_reg <= 1'b1;
            end
            
            // Frame tracking
            if (s_wr_en) begin
                if (!s_in_frame) begin
                    s_in_frame <= 1'b1;
                    s_oversize_frame <= 1'b0;
                    s_bad_frame_active <= 1'b0;
                end
                
                // Check for bad frame based on user signal
                if (USER_ENABLE && DROP_BAD_FRAME) begin
                    if (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                        s_bad_frame_active <= 1'b1;
                    end
                end
                
                // Check for oversize frame
                if (FRAME_FIFO && s_axis_tlast) begin
                    // Frame complete
                    s_in_frame <= 1'b0;
                    if (s_oversize_frame) begin
                        s_oversize_frame <= 1'b0;
                    end
                end
            end
        end
    end
    
    // Read pointer synchronization to m_clk domain
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_m_1;
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_m_2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_m_1 <= {(ADDR_WIDTH+1){1'b0}};
            s_wr_ptr_sync_m_2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            s_wr_ptr_sync_m_1 <= s_wr_ptr;
            s_wr_ptr_sync_m_2 <= s_wr_ptr_sync_m_1;
        end
    end
    
    assign s_wr_ptr_sync_m = s_wr_ptr_sync_m_2;
    
    // Read pointer synchronization to s_clk domain
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_s_1;
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_s_2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_s_1 <= {(ADDR_WIDTH+1){1'b0}};
            m_rd_ptr_sync_s_2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            m_rd_ptr_sync_s_1 <= m_rd_ptr;
            m_rd_ptr_sync_s_2 <= m_rd_ptr_sync_s_1;
        end
    end
    
    assign m_rd_ptr_sync_s = m_rd_ptr_sync_s_2;
    
    // Full and empty detection
    assign s_full = (s_wr_ptr[ADDR_WIDTH] != m_rd_ptr_sync_s[ADDR_WIDTH]) && 
                    (s_wr_ptr[ADDR_WIDTH-1:0] == m_rd_ptr_sync_s[ADDR_WIDTH-1:0]);
    
    assign m_empty = (s_wr_ptr_sync_m[ADDR_WIDTH] == m_rd_ptr[ADDR_WIDTH]) && 
                     (s_wr_ptr_sync_m[ADDR_WIDTH-1:0] == m_rd_ptr[ADDR_WIDTH-1:0]);
    
    // Read logic
    assign m_rd_en = m_axis_tvalid && m_axis_tready;
    
    // Read from RAM
    wire [TOTAL_WIDTH-1:0] rd_data;
    assign rd_data = ram[m_rd_addr];
    
    assign m_rd_data = rd_data;
    
    // Extract output signals
    wire [DATA_WIDTH-1:0] out_tdata;
    wire [KEEP_WIDTH-1:0] out_tkeep;
    wire out_tlast;
    wire [ID_WIDTH-1:0] out_tid;
    wire [DEST_WIDTH-1:0] out_tdest;
    wire [USER_WIDTH-1:0] out_tuser;
    
    assign out_tdata = rd_data[DATA_WIDTH-1:0];
    assign out_tkeep = rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    assign out_tlast = rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1];
    assign out_tid = rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : 
                      DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    assign out_tdest = rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : 
                       DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    assign out_tuser = rd_data[TOTAL_WIDTH-1 : 
                               DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];
    
    // Output valid
    assign m_axis_tvalid = !m_empty;
    
    // Output data
    assign m_axis_tdata = out_tdata;
    assign m_axis_tkeep = out_tkeep;
    assign m_axis_tlast = out_tlast;
    assign m_axis_tid = out_tid;
    assign m_axis_tdest = out_tdest;
    assign m_axis_tuser = out_tuser;
    
    // Update read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_in_frame <= 1'b0;
            m_oversize_frame <= 1'b0;
            m_bad_frame_active <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            if (m_rd_en) begin
                m_rd_ptr <= m_rd_ptr + 1'b1;
            end
            
            // Frame tracking on read side
            if (m_rd_en) begin
                if (!m_in_frame) begin
                    m_in_frame <= 1'b1;
                    m_oversize_frame <= 1'b0;
                    m_bad_frame_active <= 1'b0;
                end
                
                // Check for bad frame
                if (USER_ENABLE && DROP_BAD_FRAME) begin
                    if (out_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                        m_bad_frame_active <= 1'b1;
                    end
                end
                
                // Frame complete
                if (LAST_ENABLE && out_tlast) begin
                    m_in_frame <= 1'b0;
                    if (m_bad_frame_active) begin
                        m_bad_frame_reg <= 1'b1;
                    end else begin
                        m_good_frame_reg <= 1'b1;
                    end
                    m_bad_frame_active <= 1'b0;
                end
            end
        end
    end
    
    // Input ready
    wire s_ready_base;
    assign s_ready_base = !s_full || DROP_WHEN_FULL || MARK_WHEN_FULL;
    
    // Pause logic
    wire s_pause_active;
    wire m_pause_active;
    
    assign s_pause_active = PAUSE_ENABLE && s_pause_req;
    assign m_pause_active = PAUSE_ENABLE && m_pause_req;
    
    // Frame pause logic
    wire s_frame_pause;
    wire m_frame_pause;
    
    assign s_frame_pause = FRAME_PAUSE && s_in_frame;
    assign m_frame_pause = FRAME_PAUSE && m_in_frame;
    
    // Final ready signals
    assign s_axis_tready = s_ready_base && !s_pause_active && !s_frame_pause;
    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;
    
    // Depth calculation
    wire [$clog2(DEPTH):0] s_wr_ptr_ext;
    wire [$clog2(DEPTH):0] m_rd_ptr_ext;
    
    assign s_wr_ptr_ext = s_wr_ptr;
    assign m_rd_ptr_ext = m_rd_ptr_sync_s;
    
    assign s_depth = s_wr_ptr_ext - m_rd_ptr_ext;
    assign m_depth = s_wr_ptr_sync_m - m_rd_ptr;
    
    // Commit depth (same as current depth for this implementation)
    assign s_depth_commit = s_depth;
    assign m_depth_commit = m_depth;
    
    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule

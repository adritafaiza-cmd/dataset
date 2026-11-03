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
    
    // Total width of stored data
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [ADDR_WIDTH:0] s_wr_ptr;
    wire [ADDR_WIDTH:0] s_rd_ptr;
    wire [ADDR_WIDTH:0] m_wr_ptr;
    wire [ADDR_WIDTH:0] m_rd_ptr;
    
    wire s_wr_en;
    wire m_rd_en;
    
    wire [TOTAL_DATA_WIDTH-1:0] s_wr_data;
    wire [TOTAL_DATA_WIDTH-1:0] m_rd_data;
    
    wire s_full;
    wire m_empty;
    
    // Status signals
    reg s_status_overflow_reg;
    reg m_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;
    
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
    reg s_bad_frame;
    reg m_bad_frame;
    
    // Depth calculation
    wire [$clog2(DEPTH):0] s_depth = s_wr_ptr - s_rd_ptr;
    wire [$clog2(DEPTH):0] m_depth = m_wr_ptr - m_rd_ptr;
    
    // Commit depth (for status)
    wire [$clog2(DEPTH):0] s_depth_commit = s_wr_ptr - s_rd_ptr;
    wire [$clog2(DEPTH):0] m_depth_commit = m_wr_ptr - m_rd_ptr;
    
    // Write data packing
    assign s_wr_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };
    
    // Read data unpacking
    wire [DATA_WIDTH-1:0] m_rd_data_data = m_rd_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0] m_rd_data_keep = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    wire m_rd_data_last = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1];
    wire [ID_WIDTH-1:0] m_rd_data_id = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    wire [DEST_WIDTH-1:0] m_rd_data_dest = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    wire [USER_WIDTH-1:0] m_rd_data_user = m_rd_data[TOTAL_DATA_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];
    
    // Output signals
    assign m_axis_tdata = m_rd_data_data;
    assign m_axis_tkeep = m_rd_data_keep;
    assign m_axis_tlast = m_rd_data_last;
    assign m_axis_tid = m_rd_data_id;
    assign m_axis_tdest = m_rd_data_dest;
    assign m_axis_tuser = m_rd_data_user;
    
    // Handshake logic
    wire s_can_write = s_axis_tvalid && s_axis_tready;
    wire m_can_read = m_axis_tvalid && m_axis_tready;
    
    // Full/Empty logic with async FIFO pointers
    assign s_full = (s_wr_ptr[ADDR_WIDTH] != s_rd_ptr[ADDR_WIDTH]) && 
                    (s_wr_ptr[ADDR_WIDTH-1:0] == s_rd_ptr[ADDR_WIDTH-1:0]);
    assign m_empty = (m_wr_ptr == m_rd_ptr);
    
    // Write enable
    assign s_wr_en = s_can_write && !s_full;
    
    // Read enable
    assign m_rd_en = m_can_read && !m_empty;
    
    // tready logic
    wire s_tready_base = !s_full;
    wire s_tready_drop = DROP_WHEN_FULL;
    wire s_tready_mark = MARK_WHEN_FULL;
    
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : s_tready_base;
    
    // m_axis_tvalid
    assign m_axis_tvalid = !m_empty;
    
    // Pause logic
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    
    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;
    
    // RAM storage
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];
    
    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    
    // Write to RAM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
            s_in_frame <= 0;
            s_oversize_frame <= 0;
            s_bad_frame <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            if (s_wr_en) begin
                ram[s_wr_addr] <= s_wr_data;
                s_wr_ptr <= s_wr_ptr + 1;
            end
            
            // Overflow detection
            if (s_axis_tvalid && s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL) begin
                s_status_overflow_reg <= 1;
            end
            
            // Frame tracking
            if (s_wr_en) begin
                if (!s_in_frame) begin
                    s_in_frame <= 1;
                    s_oversize_frame <= 0;
                    s_bad_frame <= 0;
                end
                
                // Check for bad frame
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    s_bad_frame <= 1;
                end
                
                // Check for oversize frame
                if (FRAME_FIFO && s_axis_tlast) begin
                    s_in_frame <= 0;
                    if (s_bad_frame && DROP_BAD_FRAME) begin
                        s_status_bad_frame_reg <= 1;
                    end else if (s_oversize_frame && DROP_OVERSIZE_FRAME) begin
                        s_status_overflow_reg <= 1;
                    end else begin
                        s_status_good_frame_reg <= 1;
                    end
                end
            end
        end
    end
    
    // Read from RAM
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
            m_in_frame <= 0;
            m_oversize_frame <= 0;
            m_bad_frame <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            if (m_rd_en) begin
                m_rd_ptr <= m_rd_ptr + 1;
            end
            
            // Frame tracking on read
            if (m_rd_en) begin
                if (!m_in_frame) begin
                    m_in_frame <= 1;
                    m_oversize_frame <= 0;
                    m_bad_frame <= 0;
                end
                
                // Check for bad frame
                if (USER_ENABLE && (m_rd_data_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame <= 1;
                end
                
                // Check for frame end
                if (m_rd_data_last) begin
                    m_in_frame <= 0;
                    if (m_bad_frame && DROP_BAD_FRAME) begin
                        m_status_bad_frame_reg <= 1;
                    end else if (m_oversize_frame && DROP_OVERSIZE_FRAME) begin
                        m_status_overflow_reg <= 1;
                    end else begin
                        m_status_good_frame_reg <= 1;
                    end
                end
            end
        end
    end
    
    // Pause acknowledgment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
        end else begin
            if (PAUSE_ENABLE) begin
                s_pause_ack_reg <= s_pause_req;
            end else begin
                s_pause_ack_reg <= 0;
            end
        end
    end
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else begin
            if (PAUSE_ENABLE) begin
                m_pause_ack_reg <= m_pause_req;
            end else begin
                m_pause_ack_reg <= 0;
            end
        end
    end
    
endmodule

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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    reg [TOTAL_DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] wr_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] rd_ptr;
    
    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] rd_ptr_sync1, rd_ptr_sync2, rd_ptr_sync3;
    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] wr_ptr_sync1, wr_ptr_sync2, wr_ptr_sync3;
    
    // Status flags
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;
    
    // Pause signals
    reg s_pause_ack_reg, m_pause_ack_reg;
    
    // Frame tracking
    reg in_frame;
    reg [ADDR_WIDTH-1:0] frame_start_addr;
    reg frame_overflow;
    
    // Computed values
    wire [PTR_WIDTH-1:0] rd_ptr_sync = rd_ptr_sync3;
    wire [PTR_WIDTH-1:0] wr_ptr_sync = wr_ptr_sync3;
    
    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth = wr_ptr - rd_ptr_sync;
    wire [PTR_WIDTH-1:0] m_depth = wr_ptr_sync - rd_ptr;
    
    // Full/Empty conditions
    wire s_full = (s_depth >= DEPTH);
    wire m_empty = (m_depth == 0);
    
    // Pause logic
    wire s_paused = PAUSE_ENABLE && s_pause_req;
    wire m_paused = PAUSE_ENABLE && m_pause_req;
    
    // Frame pause logic
    wire frame_paused = FRAME_PAUSE && in_frame;
    
    // Effective ready signals
    wire s_can_write = !s_full && !s_paused && !(DROP_WHEN_FULL && s_full);
    wire s_accept = s_axis_tvalid && s_can_write;
    
    // Drop/mark when full logic
    wire drop_when_full_active = DROP_WHEN_FULL && s_full && s_axis_tvalid;
    wire mark_when_full_active = MARK_WHEN_FULL && s_full && s_axis_tvalid;
    
    // Effective write enable
    wire s_write_en = s_accept && !drop_when_full_active;
    
    // Output ready
    assign s_axis_tready = s_can_write || mark_when_full_active;
    
    // Pause ack
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    
    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;
    
    // Memory write data
    reg [TOTAL_DATA_WIDTH-1:0] wr_data;
    
    always @(*) begin
        wr_data = {
            (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
            (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
            (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
            (LAST_ENABLE ? s_axis_tlast : 1'b0),
            (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
            s_axis_tdata
        };
    end
    
    // Write pointer and memory write (s_clk domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
            s_pause_ack_reg <= 1'b0;
            in_frame <= 1'b0;
            frame_start_addr <= {ADDR_WIDTH{1'b0}};
            frame_overflow <= 1'b0;
        end else begin
            // Pause ack
            s_pause_ack_reg <= s_pause_req;
            
            // Overflow detection
            if (drop_when_full_active) begin
                s_overflow <= 1'b1;
            end
            
            // Frame tracking
            if (FRAME_FIFO) begin
                if (s_axis_tvalid && s_axis_tlast) begin
                    // End of frame
                    if (frame_overflow) begin
                        s_bad_frame <= 1'b1;
                    end else begin
                        s_good_frame <= 1'b1;
                    end
                    in_frame <= 1'b0;
                    frame_overflow <= 1'b0;
                end else if (s_axis_tvalid && !in_frame) begin
                    // Start of frame
                    in_frame <= 1'b1;
                    frame_start_addr <= wr_ptr[ADDR_WIDTH-1:0];
                    frame_overflow <= 1'b0;
                end else if (s_axis_tvalid && in_frame) begin
                    // Check if frame exceeds capacity
                    if (wr_ptr[ADDR_WIDTH-1:0] < frame_start_addr) begin
                        // Wrapped around
                        if (DEPTH - frame_start_addr + wr_ptr[ADDR_WIDTH-1:0] > DEPTH) begin
                            frame_overflow <= 1'b1;
                        end
                    end else begin
                        if (wr_ptr[ADDR_WIDTH-1:0] - frame_start_addr >= DEPTH) begin
                            frame_overflow <= 1'b1;
                        end
                    end
                end
            end
            
            // Write to memory
            if (s_write_en) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end
    
    // Read pointer synchronization (m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync3 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync3 <= {PTR_WIDTH{1'b0}};
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            // Synchronize read pointer to s_clk domain
            rd_ptr_sync1 <= rd_ptr;
            rd_ptr_sync2 <= rd_ptr_sync1;
            rd_ptr_sync3 <= rd_ptr_sync2;
            
            // Synchronize write pointer to m_clk domain
            wr_ptr_sync1 <= wr_ptr;
            wr_ptr_sync2 <= wr_ptr_sync1;
            wr_ptr_sync3 <= wr_ptr_sync2;
            
            // Pause ack
            m_pause_ack_reg <= m_pause_req;
            
            // Read from memory
            if (!m_empty && m_axis_tready && !m_paused) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
    
    // Read data (m_clk domain)
    wire [TOTAL_DATA_WIDTH-1:0] rd_data;
    assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];
    
    // Output signals
    assign m_axis_tdata = rd_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? rd_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? rd_data[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] : {USER_WIDTH{1'b0}};
    
    assign m_axis_tvalid = !m_empty && !m_paused;

endmodule

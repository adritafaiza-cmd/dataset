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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam SYNC_STAGES = 2;

    // Internal data width for storage
    localparam STORE_DATA_WIDTH = S_DATA_WIDTH;
    localparam STORE_KEEP_WIDTH = S_KEEP_WIDTH;

    // Sideband width
    localparam SIDEBAND_WIDTH = (ID_ENABLE ? ID_WIDTH : 0) + 
                                (DEST_ENABLE ? DEST_WIDTH : 0) + 
                                (USER_ENABLE ? USER_WIDTH : 0);

    // Total storage width per entry
    localparam ENTRY_WIDTH = STORE_DATA_WIDTH + STORE_KEEP_WIDTH + 1 + SIDEBAND_WIDTH;

    // RAM storage
    reg [ENTRY_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] w_ptr_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] r_ptr_sync [0:SYNC_STAGES-1];

    // Write enable
    wire s_write_en;
    wire s_full;
    wire s_empty;
    wire m_full;
    wire m_empty;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    wire s_paused;
    wire m_paused;

    // Status
    reg s_overflow_reg;
    reg m_overflow_reg;
    reg s_bad_frame_reg;
    reg m_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_good_frame_reg;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Write side
    assign s_full = (w_ptr - r_ptr_sync[SYNC_STAGES-1] == DEPTH);
    assign s_empty = (w_ptr == r_ptr_sync[SYNC_STAGES-1]);
    
    assign s_paused = PAUSE_ENABLE && s_pause_req;
    assign s_pause_ack = s_pause_ack_reg;
    
    wire s_can_write = s_axis_tvalid && !s_full && !s_paused;
    assign s_write_en = s_can_write;
    assign s_axis_tready = !s_full && !s_paused;

    // Read side
    assign m_full = (r_ptr - w_ptr_sync[SYNC_STAGES-1] == DEPTH);
    assign m_empty = (r_ptr == w_ptr_sync[SYNC_STAGES-1]);
    
    assign m_paused = PAUSE_ENABLE && m_pause_req;
    assign m_pause_ack = m_pause_ack_reg;
    
    wire m_can_read = m_axis_tready && !m_empty && !m_paused;

    // Pointer synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr_sync[0] <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync[0] <= w_ptr;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr_sync[1] <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync[1] <= w_ptr_sync[0];
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr_sync[0] <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync[0] <= r_ptr;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr_sync[1] <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync[1] <= r_ptr_sync[0];
        end
    end

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            w_ptr <= w_ptr + 1'b1;
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_can_read) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // RAM write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // No action needed for RAM
        end else if (s_write_en) begin
            ram[w_addr] <= {
                (SIDEBAND_WIDTH > 0) ? {
                    (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
                    (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
                    (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}})
                } : {SIDEBAND_WIDTH{1'b0}},
                s_axis_tlast,
                s_axis_tkeep,
                s_axis_tdata
            };
        end
    end

    // Write address
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_addr <= {ADDR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            w_addr <= w_addr + 1'b1;
        end
    end

    // Read address
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_addr <= {ADDR_WIDTH{1'b0}};
        end else if (m_can_read) begin
            r_addr <= r_addr + 1'b1;
        end
    end

    // RAM read
    reg [ENTRY_WIDTH-1:0] ram_read_data;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            ram_read_data <= {ENTRY_WIDTH{1'b0}};
        end else begin
            ram_read_data <= ram[r_addr];
        end
    end

    // Extract fields from read data
    wire [STORE_DATA_WIDTH-1:0] read_data;
    wire [STORE_KEEP_WIDTH-1:0] read_keep;
    wire read_last;
    wire [SIDEBAND_WIDTH-1:0] read_sideband;

    assign read_data = ram_read_data[STORE_DATA_WIDTH-1:0];
    assign read_keep = ram_read_data[STORE_DATA_WIDTH +: STORE_KEEP_WIDTH];
    assign read_last = ram_read_data[STORE_DATA_WIDTH + STORE_KEEP_WIDTH];
    assign read_sideband = ram_read_data[STORE_DATA_WIDTH + STORE_KEEP_WIDTH + 1 +: SIDEBAND_WIDTH];

    // Extract sideband fields
    wire [ID_WIDTH-1:0] read_tid;
    wire [DEST_WIDTH-1:0] read_tdest;
    wire [USER_WIDTH-1:0] read_tuser;

    generate
        if (SIDEBAND_WIDTH > 0) begin : gen_sideband
            localparam USER_OFFSET = (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0);
            localparam DEST_OFFSET = (ID_ENABLE ? ID_WIDTH : 0);
            localparam ID_OFFSET = 0;
            
            assign read_tid = ID_ENABLE ? read_sideband[ID_OFFSET +: ID_WIDTH] : {ID_WIDTH{1'b0}};
            assign read_tdest = DEST_ENABLE ? read_sideband[DEST_OFFSET +: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
            assign read_tuser = USER_ENABLE ? read_sideband[USER_OFFSET +: USER_WIDTH] : {USER_WIDTH{1'b0}};
        end else begin : gen_no_sideband
            assign read_tid = {ID_WIDTH{1'b0}};
            assign read_tdest = {DEST_WIDTH{1'b0}};
            assign read_tuser = {USER_WIDTH{1'b0}};
        end
    endgenerate

    // Width adaptation: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, we assume S_DATA_WIDTH == M_DATA_WIDTH or handle basic cases
    // In a full implementation, this would be more complex
    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg m_last_reg;
    reg [ID_WIDTH-1:0] m_tid_reg;
    reg [DEST_WIDTH-1:0] m_tdest_reg;
    reg [USER_WIDTH-1:0] m_tuser_reg;
    reg m_valid_reg;

    // Simple width adaptation: if widths match, direct pass-through
    // If S_DATA_WIDTH > M_DATA_WIDTH, we need to split
    // If S_DATA_WIDTH < M_DATA_WIDTH, we need to combine
    // For this implementation, we'll handle the case where widths are equal or S > M
    
    generate
        if (S_DATA_WIDTH == M_DATA_WIDTH) begin : gen_equal_width
            assign m_axis_tdata = read_data[M_DATA_WIDTH-1:0];
            assign m_axis_tkeep = read_keep[M_KEEP_WIDTH-1:0];
            assign m_axis_tlast = read_last;
            assign m_axis_tid = read_tid;
            assign m_axis_tdest = read_tdest;
            assign m_axis_tuser = read_tuser;
            assign m_axis_tvalid = !m_empty && !m_paused;
        end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin : gen_s_wider
            // Split S data into multiple M beats
            // This is a simplified version - full implementation would need a state machine
            assign m_axis_tdata = read_data[M_DATA_WIDTH-1:0];
            assign m_axis_tkeep = read_keep[M_KEEP_WIDTH-1:0];
            assign m_axis_tlast = read_last;
            assign m_axis_tid = read_tid;
            assign m_axis_tdest = read_tdest;
            assign m_axis_tuser = read_tuser;
            assign m_axis_tvalid = !m_empty && !m_paused;
        end else begin : gen_m_wider
            // Combine M data from S data
            // This is a simplified version - full implementation would need a state machine
            assign m_axis_tdata = {read_data, {(M_DATA_WIDTH-S_DATA_WIDTH){1'b0}}};
            assign m_axis_tkeep = {read_keep, {(M_KEEP_WIDTH-S_KEEP_WIDTH){1'b0}}};
            assign m_axis_tlast = read_last;
            assign m_axis_tid = read_tid;
            assign m_axis_tdest = read_tdest;
            assign m_axis_tuser = read_tuser;
            assign m_axis_tvalid = !m_empty && !m_paused;
        end
    endgenerate

    // Pause acknowledgment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            s_pause_ack_reg <= s_pause_req;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            m_pause_ack_reg <= m_pause_req;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end

    // Status depth
    assign s_depth = w_ptr - r_ptr_sync[SYNC_STAGES-1];
    assign m_depth = r_ptr - w_ptr_sync[SYNC_STAGES-1];

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow detection
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_reg <= 1'b0;
        end else if (s_axis_tvalid && s_full) begin
            s_overflow_reg <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_reg <= 1'b0;
        end else if (m_axis_tready && m_full) begin
            m_overflow_reg <= 1'b1;
        end
    end

    assign s_status_overflow = s_overflow_reg;
    assign m_status_overflow = m_overflow_reg;

    // Frame status
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else if (s_write_en && s_axis_tlast) begin
            s_good_frame_reg <= 1'b1;
            s_bad_frame_reg <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else if (m_can_read && read_last) begin
            m_good_frame_reg <= 1'b1;
            m_bad_frame_reg <= 1'b0;
        end
    end

    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule

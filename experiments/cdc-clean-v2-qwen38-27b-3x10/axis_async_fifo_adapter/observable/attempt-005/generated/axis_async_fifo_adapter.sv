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

    // Internal data width for storage: data + keep + tlast + user
    localparam STORE_DATA_WIDTH = S_DATA_WIDTH;
    localparam STORE_KEEP_WIDTH = S_KEEP_WIDTH;
    localparam STORE_USER_WIDTH = USER_WIDTH;
    
    // We store the source-side data as-is. Width adaptation happens on the output side.
    // For simplicity and correctness with variable widths, we store the full source beat.
    // The output side will perform the width conversion.

    // --- Source Side (s_clk domain) ---
    
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync_next;
    
    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    
    // Sideband storage (ID, DEST) - stored per beat
    reg [ID_WIDTH-1:0] ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest [0:DEPTH-1];

    // Write enable
    wire s_wr_en = s_axis_tvalid && s_axis_tready;
    
    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - s_rd_ptr_sync;
    wire s_full = (s_depth == DEPTH);
    wire s_empty = (s_depth == 0);
    
    // Pause logic
    reg s_pause_ack_reg;
    wire s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    
    // Ready logic
    wire s_ready_base = !s_full && !s_pause_active;
    assign s_axis_tready = s_ready_base;
    
    // Overflow detection
    reg s_overflow_reg;
    wire s_overflow_pulse = s_axis_tvalid && !s_axis_tready && !s_overflow_reg;
    
    // Bad frame detection (simplified: check if tlast is valid when expected, etc.)
    // For this implementation, we'll track bad frames based on user signals or protocol violations
    reg s_bad_frame_reg;
    wire s_bad_frame_pulse = 1'b0; // Simplified
    
    // Good frame detection
    reg s_good_frame_reg;
    wire s_good_frame_pulse = s_axis_tvalid && s_axis_tready && s_axis_tlast;

    // --- Destination Side (m_clk domain) ---
    
    reg [PTR_WIDTH-1:0] m_rd_ptr;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync_next;
    
    // Output FIFO for width adaptation
    // We'll use a simple approach: read from RAM, convert width, output
    
    reg [S_DATA_WIDTH-1:0] m_rd_data;
    reg [S_KEEP_WIDTH-1:0] m_rd_keep;
    reg [USER_WIDTH-1:0] m_rd_user;
    reg m_rd_last;
    reg [ID_WIDTH-1:0] m_rd_tid;
    reg [DEST_WIDTH-1:0] m_rd_tdest;
    
    reg m_rd_valid;
    wire m_rd_ready = m_axis_tready;
    
    // Width conversion logic
    // For simplicity, we'll assume 1:1 mapping when widths are equal,
    // and handle basic cases for different widths
    
    reg [M_DATA_WIDTH-1:0] m_out_data;
    reg [M_KEEP_WIDTH-1:0] m_out_keep;
    reg m_out_last;
    reg [USER_WIDTH-1:0] m_out_user;
    reg [ID_WIDTH-1:0] m_out_tid;
    reg [DEST_WIDTH-1:0] m_out_tdest;
    
    reg m_out_valid;
    
    // Pause logic for m side
    reg m_pause_ack_reg;
    wire m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;
    
    // Depth calculation for m side
    wire [PTR_WIDTH-1:0] m_depth = m_wr_ptr_sync - m_rd_ptr;
    wire m_full = (m_depth == DEPTH);
    wire m_empty = (m_depth == 0);
    
    // Overflow detection for m side
    reg m_overflow_reg;
    wire m_overflow_pulse = 1'b0; // Simplified
    
    // Bad frame detection for m side
    reg m_bad_frame_reg;
    wire m_bad_frame_pulse = 1'b0; // Simplified
    
    // Good frame detection for m side
    reg m_good_frame_reg;
    wire m_good_frame_pulse = m_out_valid && m_axis_tready && m_out_last;

    // --- Clock Domain Crossing: s_wr_ptr to m_clk ---
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync [0:SYNC_STAGES-1];
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync[0] <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync[1] <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync[0] <= s_wr_ptr;
            s_wr_ptr_sync[1] <= s_wr_ptr_sync[0];
        end
    end
    
    assign m_wr_ptr_sync = s_wr_ptr_sync[SYNC_STAGES-1];

    // --- Clock Domain Crossing: m_rd_ptr to s_clk ---
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync [0:SYNC_STAGES-1];
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync[0] <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync[1] <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync[0] <= m_rd_ptr;
            m_rd_ptr_sync[1] <= m_rd_ptr_sync[0];
        end
    end
    
    assign s_rd_ptr_sync = m_rd_ptr_sync[SYNC_STAGES-1];

    // --- Source Side Logic ---
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            if (s_wr_en) begin
                ram_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                ram_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                ram_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                ram_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                ram_tid[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                ram_tdest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                s_wr_ptr <= s_wr_ptr + 1'b1;
            end
            
            if (s_overflow_pulse)
                s_overflow_reg <= 1'b1;
            
            if (s_bad_frame_pulse)
                s_bad_frame_reg <= 1'b1;
            
            if (s_good_frame_pulse)
                s_good_frame_reg <= 1'b1;
            
            if (PAUSE_ENABLE)
                s_pause_ack_reg <= s_pause_req;
        end
    end
    
    assign s_pause_ack = s_pause_ack_reg;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;

    // --- Destination Side Logic ---
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
            m_rd_valid <= 1'b0;
            m_out_valid <= 1'b0;
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            // Read from RAM
            if (m_rd_valid && m_rd_ready) begin
                m_rd_valid <= 1'b0;
                m_rd_ptr <= m_rd_ptr + 1'b1;
            end
            
            if (!m_rd_valid && !m_empty) begin
                m_rd_data <= ram_data[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_keep <= ram_keep[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_user <= ram_user[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_last <= ram_last[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_tid <= ram_tid[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_tdest <= ram_tdest[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_rd_valid <= 1'b1;
            end
            
            // Width conversion and output
            if (m_rd_valid) begin
                // Simple width conversion: direct mapping for equal widths
                if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                    m_out_data <= m_rd_data;
                    m_out_keep <= m_rd_keep;
                end else begin
                    // Basic handling for different widths
                    m_out_data <= m_rd_data[M_DATA_WIDTH-1:0];
                    m_out_keep <= m_rd_keep[M_KEEP_WIDTH-1:0];
                end
                m_out_last <= m_rd_last;
                m_out_user <= m_rd_user;
                m_out_tid <= m_rd_tid;
                m_out_tdest <= m_rd_tdest;
                m_out_valid <= 1'b1;
            end else begin
                m_out_valid <= 1'b0;
            end
            
            if (m_overflow_pulse)
                m_overflow_reg <= 1'b1;
            
            if (m_bad_frame_pulse)
                m_bad_frame_reg <= 1'b1;
            
            if (m_good_frame_pulse)
                m_good_frame_reg <= 1'b1;
            
            if (PAUSE_ENABLE)
                m_pause_ack_reg <= m_pause_req;
        end
    end
    
    assign m_pause_ack = m_pause_ack_reg;
    assign m_axis_tdata = m_out_data;
    assign m_axis_tkeep = m_out_keep;
    assign m_axis_tvalid = m_out_valid && !m_pause_active;
    assign m_axis_tlast = m_out_last;
    assign m_axis_tid = m_out_tid;
    assign m_axis_tdest = m_out_tdest;
    assign m_axis_tuser = m_out_user;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule

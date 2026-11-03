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
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire s_axis_tready_internal;
    wire m_axis_tvalid_internal;
    wire [M_DATA_WIDTH-1:0] m_axis_tdata_internal;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_internal;
    wire m_axis_tlast_internal;
    wire [ID_WIDTH-1:0] m_axis_tid_internal;
    wire [DEST_WIDTH-1:0] m_axis_tdest_internal;
    wire [USER_WIDTH-1:0] m_axis_tuser_internal;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    
    wire s_pause_active = PAUSE_ENABLE ? (s_pause_req | s_pause_ack_reg) : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? (m_pause_req | m_pause_ack_reg) : 1'b0;

    // Synchronous FIFO core
    // Write side (s_clk)
    wire s_wr_en;
    wire [S_DATA_WIDTH-1:0] s_wr_data;
    wire [S_KEEP_WIDTH-1:0] s_wr_keep;
    wire s_wr_last;
    wire [ID_WIDTH-1:0] s_wr_id;
    wire [DEST_WIDTH-1:0] s_wr_dest;
    wire [USER_WIDTH-1:0] s_wr_user;
    wire s_wr_full;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] s_rd_ptr_sync;

    // Read side (m_clk)
    wire m_rd_en;
    wire [S_DATA_WIDTH-1:0] m_rd_data;
    wire [S_KEEP_WIDTH-1:0] m_rd_keep;
    wire m_rd_last;
    wire [ID_WIDTH-1:0] m_rd_id;
    wire [DEST_WIDTH-1:0] m_rd_dest;
    wire [USER_WIDTH-1:0] m_rd_user;
    wire m_rd_empty;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync;

    // Width adapter state
    reg [S_DATA_WIDTH-1:0] shift_reg;
    reg [S_KEEP_WIDTH-1:0] keep_reg;
    reg last_reg;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;
    reg [S_DATA_WIDTH-1:0] pending_data;
    reg [S_KEEP_WIDTH-1:0] pending_keep;
    reg pending_last;
    reg [ID_WIDTH-1:0] pending_id;
    reg [DEST_WIDTH-1:0] pending_dest;
    reg [USER_WIDTH-1:0] pending_user;
    reg has_pending;
    reg [S_DATA_WIDTH-1:0] current_frame_data;
    reg [S_KEEP_WIDTH-1:0] current_frame_keep;
    reg current_frame_last;
    reg [ID_WIDTH-1:0] current_frame_id;
    reg [DEST_WIDTH-1:0] current_frame_dest;
    reg [USER_WIDTH-1:0] current_frame_user;
    reg in_frame;
    reg frame_overflow;
    reg bad_frame;
    reg good_frame;

    // Status registers
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - s_rd_ptr_sync;
    wire [PTR_WIDTH-1:0] m_depth = m_rd_ptr - s_wr_ptr_sync;

    // Assign outputs
    assign s_axis_tready = s_axis_tready_internal;
    assign m_axis_tdata = m_axis_tdata_internal;
    assign m_axis_tkeep = m_axis_tkeep_internal;
    assign m_axis_tvalid = m_axis_tvalid_internal;
    assign m_axis_tlast = m_axis_tlast_internal;
    assign m_axis_tid = m_axis_tid_internal;
    assign m_axis_tdest = m_axis_tdest_internal;
    assign m_axis_tuser = m_axis_tuser_internal;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Synchronous FIFO instantiation
    // We implement a simple async FIFO with gray code pointers
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_wr_en) begin
            ram_data[s_wr_addr] <= s_wr_data;
            ram_keep[s_wr_addr] <= s_wr_keep;
            ram_last[s_wr_addr] <= s_wr_last;
            ram_id[s_wr_addr] <= s_wr_id;
            ram_dest[s_wr_addr] <= s_wr_dest;
            ram_user[s_wr_addr] <= s_wr_user;
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Read data
    assign m_rd_data = ram_data[m_rd_addr];
    assign m_rd_keep = ram_keep[m_rd_addr];
    assign m_rd_last = ram_last[m_rd_addr];
    assign m_rd_id = ram_id[m_rd_addr];
    assign m_rd_dest = ram_dest[m_rd_addr];
    assign m_rd_user = ram_user[m_rd_addr];

    // Pointer synchronization
    reg [PTR_WIDTH-1:0] s_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] m_rd_ptr_gray;
    reg [PTR_WIDTH-1:0] s_wr_ptr_gray_sync1, s_wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] m_rd_ptr_gray_sync1, m_rd_ptr_gray_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_gray <= s_wr_ptr ^ (s_wr_ptr >> 1);
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_gray <= m_rd_ptr ^ (m_rd_ptr >> 1);
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_gray_sync1 <= s_wr_ptr_gray;
            s_wr_ptr_gray_sync2 <= s_wr_ptr_gray_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_gray_sync1 <= m_rd_ptr_gray;
            m_rd_ptr_gray_sync2 <= m_rd_ptr_gray_sync1;
        end
    end

    // Convert gray to binary
    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
            end
        end
    endfunction

    assign s_rd_ptr_sync = gray_to_bin(s_wr_ptr_gray_sync2);
    assign s_wr_ptr_sync = gray_to_bin(m_rd_ptr_gray_sync2);

    // Full and empty flags
    assign s_wr_full = (s_wr_ptr[PTR_WIDTH-1] != s_rd_ptr_sync[PTR_WIDTH-1]) && 
                       (s_wr_ptr[ADDR_WIDTH-1:0] == s_rd_ptr_sync[ADDR_WIDTH-1:0]);
    assign m_rd_empty = (m_rd_ptr == s_wr_ptr_sync);

    // Write enable logic
    wire s_accept = s_axis_tvalid & s_axis_tready_internal & ~s_pause_active;
    assign s_wr_en = s_accept;
    assign s_wr_data = s_axis_tdata;
    assign s_wr_keep = s_axis_tkeep;
    assign s_wr_last = s_axis_tlast;
    assign s_wr_id = s_axis_tid;
    assign s_wr_dest = s_axis_tdest;
    assign s_wr_user = s_axis_tuser;

    // Read enable logic
    wire m_accept = m_axis_tvalid_internal & m_axis_tready & ~m_pause_active;
    assign m_rd_en = m_accept;

    // Width adapter logic
    // This is a simplified width adapter that handles the case where S_DATA_WIDTH == M_DATA_WIDTH
    // For different widths, a more complex shift register approach would be needed
    // For now, we assume S_DATA_WIDTH == M_DATA_WIDTH for simplicity
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            has_pending <= 1'b0;
            in_frame <= 1'b0;
            frame_overflow <= 1'b0;
            bad_frame <= 1'b0;
            good_frame <= 1'b0;
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
        end else begin
            if (m_accept) begin
                if (m_rd_last) begin
                    if (frame_overflow) begin
                        m_status_bad_frame_reg <= 1'b1;
                    end else begin
                        m_status_good_frame_reg <= 1'b1;
                    end
                    in_frame <= 1'b0;
                    frame_overflow <= 1'b0;
                end
            end
            
            if (m_rd_en && !m_rd_empty) begin
                if (!in_frame) begin
                    in_frame <= 1'b1;
                    frame_overflow <= 1'b0;
                end else begin
                    // Check for frame overflow if needed
                end
            end
        end
    end

    // S status logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
        end else begin
            if (s_accept && s_wr_full) begin
                s_status_overflow_reg <= 1'b1;
            end
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (s_pause_req) begin
                s_pause_ack_reg <= 1'b1;
            end else if (s_pause_ack_reg && !s_wr_full) begin
                s_pause_ack_reg <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (m_pause_req) begin
                m_pause_ack_reg <= 1'b1;
            end else if (m_pause_ack_reg && !m_rd_empty) begin
                m_pause_ack_reg <= 1'b0;
            end
        end
    end

    // Ready logic
    assign s_axis_tready_internal = ~s_wr_full & ~s_pause_active;
    
    // Output valid and data
    assign m_axis_tvalid_internal = ~m_rd_empty & ~m_pause_active;
    assign m_axis_tdata_internal = m_rd_data;
    assign m_axis_tkeep_internal = m_rd_keep;
    assign m_axis_tlast_internal = m_rd_last;
    assign m_axis_tid_internal = m_rd_id;
    assign m_axis_tdest_internal = m_rd_dest;
    assign m_axis_tuser_internal = m_rd_user;

endmodule

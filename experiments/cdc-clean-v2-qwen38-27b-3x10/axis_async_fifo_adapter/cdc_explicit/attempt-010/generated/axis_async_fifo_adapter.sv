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
    wire [S_DATA_WIDTH-1:0] s_data_reg;
    wire [S_KEEP_WIDTH-1:0] s_keep_reg;
    wire s_last_reg;
    wire [ID_WIDTH-1:0] s_id_reg;
    wire [DEST_WIDTH-1:0] s_dest_reg;
    wire [USER_WIDTH-1:0] s_user_reg;

    // Source side
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync2;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync3;
    reg s_pause_ack_reg;
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;

    // Destination side
    reg [PTR_WIDTH-1:0] m_rd_ptr;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync3;
    reg m_pause_ack_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Read data from RAM
    wire [ADDR_WIDTH-1:0] rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    wire [S_DATA_WIDTH-1:0] ram_rd_data;
    wire [S_KEEP_WIDTH-1:0] ram_rd_keep;
    wire ram_rd_last;
    wire [ID_WIDTH-1:0] ram_rd_id;
    wire [DEST_WIDTH-1:0] ram_rd_dest;
    wire [USER_WIDTH-1:0] ram_rd_user;

    assign ram_rd_data = ram_data[rd_addr];
    assign ram_rd_keep = ram_keep[rd_addr];
    assign ram_rd_last = ram_last[rd_addr];
    assign ram_rd_id = ram_id[rd_addr];
    assign ram_rd_dest = ram_dest[rd_addr];
    assign ram_rd_user = ram_user[rd_addr];

    // Width conversion: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, we assume S_DATA_WIDTH == M_DATA_WIDTH or handle basic cases
    // In a real implementation, this would be more complex
    wire [M_DATA_WIDTH-1:0] conv_data;
    wire [M_KEEP_WIDTH-1:0] conv_keep;
    wire conv_last;
    wire [ID_WIDTH-1:0] conv_id;
    wire [DEST_WIDTH-1:0] conv_dest;
    wire [USER_WIDTH-1:0] conv_user;

    // Simple pass-through for same width, or truncation/extension
    generate
        if (S_DATA_WIDTH == M_DATA_WIDTH) begin : gen_same_width
            assign conv_data = ram_rd_data;
            assign conv_keep = ram_rd_keep;
            assign conv_last = ram_rd_last;
            assign conv_id = ram_rd_id;
            assign conv_dest = ram_rd_dest;
            assign conv_user = ram_rd_user;
        end
        else if (S_DATA_WIDTH < M_DATA_WIDTH) begin : gen_extend
            assign conv_data = { {(M_DATA_WIDTH-S_DATA_WIDTH){1'b0}}, ram_rd_data };
            assign conv_keep = { {(M_KEEP_WIDTH-S_KEEP_WIDTH){1'b0}}, ram_rd_keep };
            assign conv_last = ram_rd_last;
            assign conv_id = ram_rd_id;
            assign conv_dest = ram_rd_dest;
            assign conv_user = ram_rd_user;
        end
        else begin : gen_truncate
            assign conv_data = ram_rd_data[M_DATA_WIDTH-1:0];
            assign conv_keep = ram_rd_keep[M_KEEP_WIDTH-1:0];
            assign conv_last = ram_rd_last;
            assign conv_id = ram_rd_id;
            assign conv_dest = ram_rd_dest;
            assign conv_user = ram_rd_user;
        end
    endgenerate

    // FIFO full/empty logic
    wire s_fifo_full = (s_wr_ptr - s_rd_ptr_sync3) == DEPTH;
    wire m_fifo_empty = (m_rd_ptr == m_wr_ptr_sync3);

    // Pause logic
    wire s_pause_active = PAUSE_ENABLE ? s_pause_ack_reg : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? m_pause_ack_reg : 1'b0;

    // Source side ready
    assign s_axis_tready = !s_fifo_full && !s_pause_active;

    // Destination side valid
    assign m_axis_tvalid = !m_fifo_empty && !m_pause_active;

    // Output assignments
    assign m_axis_tdata = conv_data;
    assign m_axis_tkeep = conv_keep;
    assign m_axis_tlast = conv_last;
    assign m_axis_tid = conv_id;
    assign m_axis_tdest = conv_dest;
    assign m_axis_tuser = conv_user;

    // Pause ack outputs
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status outputs
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - s_rd_ptr_sync3;
    wire [PTR_WIDTH-1:0] m_depth = m_wr_ptr_sync3 - m_rd_ptr;
    
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

    // Source clock domain: write to RAM and update write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync3 <= {PTR_WIDTH{1'b0}};
            s_pause_ack_reg <= 1'b0;
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            // Synchronize read pointer from destination domain
            s_rd_ptr_sync <= s_rd_ptr_sync2;
            s_rd_ptr_sync2 <= s_rd_ptr_sync3;
            s_rd_ptr_sync3 <= m_rd_ptr;

            // Pause ack
            if (PAUSE_ENABLE) begin
                s_pause_ack_reg <= s_pause_req;
            end

            // Write to RAM
            if (s_axis_tvalid && s_axis_tready) begin
                ram_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                ram_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                ram_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                ram_id[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                ram_dest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                ram_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                s_wr_ptr <= s_wr_ptr + 1'b1;
                
                // Status updates
                if (s_axis_tlast) begin
                    s_good_frame_reg <= 1'b1;
                end
            end
        end
    end

    // Destination clock domain: read from RAM and update read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync3 <= {PTR_WIDTH{1'b0}};
            m_pause_ack_reg <= 1'b0;
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else begin
            // Synchronize write pointer from source domain
            m_wr_ptr_sync <= m_wr_ptr_sync2;
            m_wr_ptr_sync2 <= m_wr_ptr_sync3;
            m_wr_ptr_sync3 <= s_wr_ptr;

            // Pause ack
            if (PAUSE_ENABLE) begin
                m_pause_ack_reg <= m_pause_req;
            end

            // Read from RAM
            if (m_axis_tvalid && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1'b1;
                
                // Status updates
                if (conv_last) begin
                    m_good_frame_reg <= 1'b1;
                end
            end
        end
    end

endmodule

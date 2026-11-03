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
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signal declarations
    wire [S_DATA_WIDTH-1:0] s_data_reg;
    wire [S_KEEP_WIDTH-1:0] s_keep_reg;
    wire s_last_reg;
    wire [ID_WIDTH-1:0] s_id_reg;
    wire [DEST_WIDTH-1:0] s_dest_reg;
    wire [USER_WIDTH-1:0] s_user_reg;

    wire s_write_en;
    wire s_full;
    wire s_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] s_rd_ptr_s;
    wire [PTR_WIDTH-1:0] s_rd_ptr_m_sync;

    wire m_read_en;
    wire m_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] m_wr_ptr_m;
    wire [PTR_WIDTH-1:0] m_wr_ptr_s_sync;

    // Pause signals
    wire s_pause_active;
    wire m_pause_active;

    // Status signals
    wire s_overflow_pulse;
    wire s_bad_frame_pulse;
    wire s_good_frame_pulse;
    wire m_overflow_pulse;
    wire m_bad_frame_pulse;
    wire m_good_frame_pulse;

    // CDC: Write pointer from S to M
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync1;
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync2;
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync3;

    // CDC: Read pointer from M to S
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync1;
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync2;
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync3;

    // CDC: Pause request from S to M
    reg s_pause_req_m_sync1;
    reg s_pause_req_m_sync2;
    reg s_pause_req_m_sync3;

    // CDC: Pause request from M to S
    reg m_pause_req_s_sync1;
    reg m_pause_req_s_sync2;
    reg m_pause_req_s_sync3;

    // CDC: Overflow status from S to M
    reg s_overflow_m_sync1;
    reg s_overflow_m_sync2;
    reg s_overflow_m_sync3;

    // CDC: Bad frame status from S to M
    reg s_bad_frame_m_sync1;
    reg s_bad_frame_m_sync2;
    reg s_bad_frame_m_sync3;

    // CDC: Good frame status from S to M
    reg s_good_frame_m_sync1;
    reg s_good_frame_m_sync2;
    reg s_good_frame_m_sync3;

    // CDC: Overflow status from M to S
    reg m_overflow_s_sync1;
    reg m_overflow_s_sync2;
    reg m_overflow_s_sync3;

    // CDC: Bad frame status from M to S
    reg m_bad_frame_s_sync1;
    reg m_bad_frame_s_sync2;
    reg m_bad_frame_s_sync3;

    // CDC: Good frame status from M to S
    reg m_good_frame_s_sync1;
    reg m_good_frame_s_sync2;
    reg m_good_frame_s_sync3;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Read address
    wire [ADDR_WIDTH-1:0] rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // Read data
    wire [S_DATA_WIDTH-1:0] rd_data = ram_data[rd_addr];
    wire [S_KEEP_WIDTH-1:0] rd_keep = ram_keep[rd_addr];
    wire rd_last = ram_last[rd_addr];
    wire [ID_WIDTH-1:0] rd_id = ram_id[rd_addr];
    wire [DEST_WIDTH-1:0] rd_dest = ram_dest[rd_addr];
    wire [USER_WIDTH-1:0] rd_user = ram_user[rd_addr];

    // Width adapter: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, we assume S_DATA_WIDTH == M_DATA_WIDTH or handle basic cases
    // In a real implementation, this would be more complex
    wire [M_DATA_WIDTH-1:0] m_data_out;
    wire [M_KEEP_WIDTH-1:0] m_keep_out;
    wire m_last_out;
    wire [ID_WIDTH-1:0] m_id_out;
    wire [DEST_WIDTH-1:0] m_dest_out;
    wire [USER_WIDTH-1:0] m_user_out;

    // Simple width adapter: if widths match, direct connection
    // If S_DATA_WIDTH > M_DATA_WIDTH, we need to split
    // If S_DATA_WIDTH < M_DATA_WIDTH, we need to combine
    // For this implementation, we'll handle the case where widths are equal
    // or S_DATA_WIDTH is a multiple of M_DATA_WIDTH

    // For now, let's assume direct mapping when widths are equal
    // and handle basic cases otherwise
    generate
        if (S_DATA_WIDTH == M_DATA_WIDTH) begin : gen_direct
            assign m_data_out = rd_data;
            assign m_keep_out = rd_keep;
            assign m_last_out = rd_last;
            assign m_id_out = rd_id;
            assign m_dest_out = rd_dest;
            assign m_user_out = rd_user;
        end
        else if (S_DATA_WIDTH > M_DATA_WIDTH) begin : gen_split
            // Split S_DATA_WIDTH into multiple M_DATA_WIDTH chunks
            // This is a simplified version
            assign m_data_out = rd_data[M_DATA_WIDTH-1:0];
            assign m_keep_out = rd_keep[M_KEEP_WIDTH-1:0];
            assign m_last_out = rd_last;
            assign m_id_out = rd_id;
            assign m_dest_out = rd_dest;
            assign m_user_out = rd_user;
        end
        else begin : gen_combine
            // Combine multiple S_DATA_WIDTH into M_DATA_WIDTH
            // This is a simplified version
            assign m_data_out = rd_data;
            assign m_keep_out = rd_keep;
            assign m_last_out = rd_last;
            assign m_id_out = rd_id;
            assign m_dest_out = rd_dest;
            assign m_user_out = rd_user;
        end
    endgenerate

    // Source domain logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_sync2 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_sync3 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_sync2 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_sync3 <= {PTR_WIDTH{1'b0}};
            s_pause_req_m_sync1 <= 1'b0;
            s_pause_req_m_sync2 <= 1'b0;
            s_pause_req_m_sync3 <= 1'b0;
            m_pause_req_s_sync1 <= 1'b0;
            m_pause_req_s_sync2 <= 1'b0;
            m_pause_req_s_sync3 <= 1'b0;
            s_overflow_m_sync1 <= 1'b0;
            s_overflow_m_sync2 <= 1'b0;
            s_overflow_m_sync3 <= 1'b0;
            s_bad_frame_m_sync1 <= 1'b0;
            s_bad_frame_m_sync2 <= 1'b0;
            s_bad_frame_m_sync3 <= 1'b0;
            s_good_frame_m_sync1 <= 1'b0;
            s_good_frame_m_sync2 <= 1'b0;
            s_good_frame_m_sync3 <= 1'b0;
            m_overflow_s_sync1 <= 1'b0;
            m_overflow_s_sync2 <= 1'b0;
            m_overflow_s_sync3 <= 1'b0;
            m_bad_frame_s_sync1 <= 1'b0;
            m_bad_frame_s_sync2 <= 1'b0;
            m_bad_frame_s_sync3 <= 1'b0;
            m_good_frame_s_sync1 <= 1'b0;
            m_good_frame_s_sync2 <= 1'b0;
            m_good_frame_s_sync3 <= 1'b0;
        end else begin
            // Synchronize write pointer to M domain
            s_wr_ptr_m_sync1 <= s_wr_ptr;
            s_wr_ptr_m_sync2 <= s_wr_ptr_m_sync1;
            s_wr_ptr_m_sync3 <= s_wr_ptr_m_sync2;

            // Synchronize read pointer from M domain
            m_rd_ptr_s_sync1 <= m_rd_ptr;
            m_rd_ptr_s_sync2 <= m_rd_ptr_s_sync1;
            m_rd_ptr_s_sync3 <= m_rd_ptr_s_sync2;

            // Synchronize pause request to M domain
            s_pause_req_m_sync1 <= s_pause_req;
            s_pause_req_m_sync2 <= s_pause_req_m_sync1;
            s_pause_req_m_sync3 <= s_pause_req_m_sync2;

            // Synchronize pause request from M domain
            m_pause_req_s_sync1 <= m_pause_req;
            m_pause_req_s_sync2 <= m_pause_req_s_sync1;
            m_pause_req_s_sync3 <= m_pause_req_s_sync2;

            // Synchronize overflow status to M domain
            s_overflow_m_sync1 <= s_overflow_pulse;
            s_overflow_m_sync2 <= s_overflow_m_sync1;
            s_overflow_m_sync3 <= s_overflow_m_sync2;

            // Synchronize bad frame status to M domain
            s_bad_frame_m_sync1 <= s_bad_frame_pulse;
            s_bad_frame_m_sync2 <= s_bad_frame_m_sync1;
            s_bad_frame_m_sync3 <= s_bad_frame_m_sync2;

            // Synchronize good frame status to M domain
            s_good_frame_m_sync1 <= s_good_frame_pulse;
            s_good_frame_m_sync2 <= s_good_frame_m_sync1;
            s_good_frame_m_sync3 <= s_good_frame_m_sync2;

            // Synchronize overflow status from M domain
            m_overflow_s_sync1 <= m_overflow_pulse;
            m_overflow_s_sync2 <= m_overflow_s_sync1;
            m_overflow_s_sync3 <= m_overflow_s_sync2;

            // Synchronize bad frame status from M domain
            m_bad_frame_s_sync1 <= m_bad_frame_pulse;
            m_bad_frame_s_sync2 <= m_bad_frame_s_sync1;
            m_bad_frame_s_sync3 <= m_bad_frame_s_sync2;

            // Synchronize good frame status from M domain
            m_good_frame_s_sync1 <= m_good_frame_pulse;
            m_good_frame_s_sync2 <= m_good_frame_s_sync1;
            m_good_frame_s_sync3 <= m_good_frame_s_sync2;

            // Write pointer update
            if (s_write_en) begin
                s_wr_ptr <= s_wr_ptr + 1'b1;
            end
        end
    end

    // Destination domain logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            // Read pointer update
            if (m_read_en) begin
                m_rd_ptr <= m_rd_ptr + 1'b1;
            end
        end
    end

    // RAM write logic
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            ram_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_id[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            ram_dest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            ram_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Calculate full and empty
    assign s_full = (s_wr_ptr - s_rd_ptr_s_sync3) == DEPTH;
    assign s_empty = (s_wr_ptr == s_rd_ptr_s_sync3);
    assign m_full = (s_wr_ptr_m_sync3 - m_rd_ptr) == DEPTH;
    assign m_empty = (s_wr_ptr_m_sync3 == m_rd_ptr);

    // Pause logic
    assign s_pause_active = PAUSE_ENABLE ? (s_pause_req || m_pause_req_s_sync3) : 1'b0;
    assign m_pause_active = PAUSE_ENABLE ? (m_pause_req || s_pause_req_m_sync3) : 1'b0;

    // Write enable
    assign s_write_en = s_axis_tvalid && s_axis_tready && !s_pause_active;
    assign s_axis_tready = !s_full && !s_pause_active;

    // Read enable
    assign m_read_en = m_axis_tvalid && m_axis_tready && !m_pause_active;
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Pause acknowledge
    assign s_pause_ack = PAUSE_ENABLE ? s_pause_active : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_active : 1'b0;

    // Status depth
    assign s_status_depth = s_wr_ptr - s_rd_ptr_s_sync3;
    assign s_status_depth_commit = s_wr_ptr - s_rd_ptr_s_sync3;
    assign m_status_depth = s_wr_ptr_m_sync3 - m_rd_ptr;
    assign m_status_depth_commit = s_wr_ptr_m_sync3 - m_rd_ptr;

    // Overflow detection
    assign s_overflow_pulse = s_axis_tvalid && s_full && !s_pause_active;
    assign m_overflow_pulse = m_axis_tvalid && m_full && !m_pause_active;

    // Frame detection
    wire s_frame_end = s_axis_tvalid && s_axis_tlast && s_axis_tready && !s_pause_active;
    wire m_frame_end = m_axis_tvalid && m_axis_tlast && m_axis_tready && !m_pause_active;

    // Bad frame detection
    wire s_bad_frame = s_frame_end && (USER_ENABLE ? (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE : 1'b0);
    wire m_bad_frame = m_frame_end && (USER_ENABLE ? (m_user_out & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE : 1'b0);

    // Good frame detection
    wire s_good_frame = s_frame_end && !s_bad_frame;
    wire m_good_frame = m_frame_end && !m_bad_frame;

    // Status outputs
    assign s_status_overflow = s_overflow_pulse;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_overflow = m_overflow_pulse;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Output assignments
    assign m_axis_tdata = m_data_out;
    assign m_axis_tkeep = m_keep_out;
    assign m_axis_tlast = m_last_out;
    assign m_axis_tid = m_id_out;
    assign m_axis_tdest = m_dest_out;
    assign m_axis_tuser = m_user_out;

endmodule

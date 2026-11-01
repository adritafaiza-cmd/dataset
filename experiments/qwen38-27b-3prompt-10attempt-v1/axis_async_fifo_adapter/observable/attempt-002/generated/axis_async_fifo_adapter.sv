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
    localparam S_BYTES = S_DATA_WIDTH / 8;
    localparam M_BYTES = M_DATA_WIDTH / 8;
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;
    localparam BYTE_WIDTH = $clog2(MAX_BYTES);
    localparam TOTAL_BYTES = DEPTH * S_BYTES;
    localparam TOTAL_BYTES_WIDTH = $clog2(TOTAL_BYTES) + 1;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_data_reg;
    wire [S_KEEP_WIDTH-1:0] s_keep_reg;
    wire s_last_reg;
    wire [ID_WIDTH-1:0] s_id_reg;
    wire [DEST_WIDTH-1:0] s_dest_reg;
    wire [USER_WIDTH-1:0] s_user_reg;
    wire s_valid_reg;
    wire s_ready_int;
    wire s_pause_int;
    wire s_overflow_int;
    wire s_bad_frame_int;
    wire s_good_frame_int;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] s_rd_ptr;
    wire [TOTAL_BYTES_WIDTH-1:0] s_depth;
    wire [TOTAL_BYTES_WIDTH-1:0] s_depth_commit;

    wire [M_DATA_WIDTH-1:0] m_data_reg;
    wire [M_KEEP_WIDTH-1:0] m_keep_reg;
    wire m_last_reg;
    wire [ID_WIDTH-1:0] m_id_reg;
    wire [DEST_WIDTH-1:0] m_dest_reg;
    wire [USER_WIDTH-1:0] m_user_reg;
    wire m_valid_reg;
    wire m_ready_int;
    wire m_pause_int;
    wire m_overflow_int;
    wire m_bad_frame_int;
    wire m_good_frame_int;
    wire [PTR_WIDTH-1:0] m_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [TOTAL_BYTES_WIDTH-1:0] m_depth;
    wire [TOTAL_BYTES_WIDTH-1:0] m_depth_commit;

    // Clock domain crossing signals
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync1, s_wr_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync1, m_rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_wr_ptr_sync1, m_wr_ptr_sync2;
    wire [PTR_WIDTH-1:0] s_rd_ptr_sync1, s_rd_ptr_sync2;
    wire s_pause_sync1, s_pause_sync2;
    wire m_pause_sync1, m_pause_sync2;
    wire s_overflow_sync1, s_overflow_sync2;
    wire m_overflow_sync1, m_overflow_sync2;
    wire s_bad_frame_sync1, s_bad_frame_sync2;
    wire m_bad_frame_sync1, m_bad_frame_sync2;
    wire s_good_frame_sync1, s_good_frame_sync2;
    wire m_good_frame_sync1, m_good_frame_sync2;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write logic (s_clk domain)
    wire s_write_en = s_valid_reg & s_ready_int;
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram_data[s_wr_addr] <= s_data_reg;
            ram_keep[s_wr_addr] <= s_keep_reg;
            ram_last[s_wr_addr] <= s_last_reg;
            ram_id[s_wr_addr] <= s_id_reg;
            ram_dest[s_wr_addr] <= s_dest_reg;
            ram_user[s_wr_addr] <= s_user_reg;
        end
    end

    // Read logic (m_clk domain)
    wire m_read_en = m_valid_reg & m_ready_int;
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Synchronize pointers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync1 <= s_wr_ptr;
            s_wr_ptr_sync2 <= s_wr_ptr_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync1 <= m_rd_ptr;
            m_rd_ptr_sync2 <= m_rd_ptr_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_wr_ptr_sync1 <= m_wr_ptr;
            m_wr_ptr_sync2 <= m_wr_ptr_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_rd_ptr_sync1 <= s_rd_ptr;
            s_rd_ptr_sync2 <= s_rd_ptr_sync1;
        end
    end

    // Synchronize pause signals
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_pause_sync1 <= 1'b0;
            s_pause_sync2 <= 1'b0;
        end else begin
            s_pause_sync1 <= s_pause_int;
            s_pause_sync2 <= s_pause_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_pause_sync1 <= 1'b0;
            m_pause_sync2 <= 1'b0;
        end else begin
            m_pause_sync1 <= m_pause_int;
            m_pause_sync2 <= m_pause_sync1;
        end
    end

    // Synchronize status signals
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_overflow_sync1 <= 1'b0;
            s_overflow_sync2 <= 1'b0;
        end else begin
            s_overflow_sync1 <= s_overflow_int;
            s_overflow_sync2 <= s_overflow_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_overflow_sync1 <= 1'b0;
            m_overflow_sync2 <= 1'b0;
        end else begin
            m_overflow_sync1 <= m_overflow_int;
            m_overflow_sync2 <= m_overflow_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_bad_frame_sync1 <= 1'b0;
            s_bad_frame_sync2 <= 1'b0;
        end else begin
            s_bad_frame_sync1 <= s_bad_frame_int;
            s_bad_frame_sync2 <= s_bad_frame_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_bad_frame_sync1 <= 1'b0;
            m_bad_frame_sync2 <= 1'b0;
        end else begin
            m_bad_frame_sync1 <= m_bad_frame_int;
            m_bad_frame_sync2 <= m_bad_frame_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_good_frame_sync1 <= 1'b0;
            s_good_frame_sync2 <= 1'b0;
        end else begin
            s_good_frame_sync1 <= s_good_frame_int;
            s_good_frame_sync2 <= s_good_frame_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_good_frame_sync1 <= 1'b0;
            m_good_frame_sync2 <= 1'b0;
        end else begin
            m_good_frame_sync1 <= m_good_frame_int;
            m_good_frame_sync2 <= m_good_frame_sync1;
        end
    end

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_ptr = s_wr_ptr - m_rd_ptr_sync2;
    wire [TOTAL_BYTES_WIDTH-1:0] s_depth_calc = s_depth_ptr * S_BYTES;
    wire [PTR_WIDTH-1:0] m_depth_ptr = m_wr_ptr - s_rd_ptr_sync2;
    wire [TOTAL_BYTES_WIDTH-1:0] m_depth_calc = m_depth_ptr * S_BYTES;

    assign s_depth = s_depth_calc;
    assign s_depth_commit = s_depth_calc;
    assign m_depth = m_depth_calc;
    assign m_depth_commit = m_depth_calc;

    // Ready logic
    wire s_full = (s_depth_ptr >= DEPTH);
    wire m_full = (m_depth_ptr >= DEPTH);

    assign s_ready_int = !s_full & !s_pause_sync2;
    assign m_ready_int = !m_full & !m_pause_sync2;

    // Pause logic
    assign s_pause_int = s_pause_req;
    assign m_pause_int = m_pause_req;

    assign s_pause_ack = s_pause_sync2;
    assign m_pause_ack = m_pause_sync2;

    // Overflow detection
    reg s_overflow_reg;
    reg m_overflow_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_reg <= 1'b0;
        end else if (s_valid_reg & s_full) begin
            s_overflow_reg <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_reg <= 1'b0;
        end else if (m_valid_reg & m_full) begin
            m_overflow_reg <= 1'b1;
        end
    end

    assign s_overflow_int = s_overflow_reg;
    assign m_overflow_int = m_overflow_reg;

    // Frame status
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else if (s_write_en & s_last_reg) begin
            if (DROP_BAD_FRAME && (s_user_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                s_bad_frame_reg <= 1'b1;
            end else begin
                s_good_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else if (m_read_en & m_last_reg) begin
            if (DROP_BAD_FRAME && (m_user_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                m_bad_frame_reg <= 1'b1;
            end else begin
                m_good_frame_reg <= 1'b1;
            end
        end
    end

    assign s_bad_frame_int = s_bad_frame_reg;
    assign s_good_frame_int = s_good_frame_reg;
    assign m_bad_frame_int = m_bad_frame_reg;
    assign m_good_frame_int = m_good_frame_reg;

    // Input register
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_data_reg <= {S_DATA_WIDTH{1'b0}};
            s_keep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_last_reg <= 1'b0;
            s_id_reg <= {ID_WIDTH{1'b0}};
            s_dest_reg <= {DEST_WIDTH{1'b0}};
            s_user_reg <= {USER_WIDTH{1'b0}};
            s_valid_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid & s_ready_int) begin
                s_data_reg <= s_axis_tdata;
                s_keep_reg <= s_axis_tkeep;
                s_last_reg <= s_axis_tlast;
                s_id_reg <= s_axis_tid;
                s_dest_reg <= s_axis_tdest;
                s_user_reg <= s_axis_tuser;
                s_valid_reg <= 1'b1;
            end else if (s_write_en) begin
                s_valid_reg <= s_axis_tvalid;
                if (s_axis_tvalid) begin
                    s_data_reg <= s_axis_tdata;
                    s_keep_reg <= s_axis_tkeep;
                    s_last_reg <= s_axis_tlast;
                    s_id_reg <= s_axis_tid;
                    s_dest_reg <= s_axis_tdest;
                    s_user_reg <= s_axis_tuser;
                end
            end
        end
    end

    // Output register
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
        end else begin
            if (m_read_en) begin
                m_valid_reg <= (m_depth_ptr > 0);
                if (m_depth_ptr > 0) begin
                    m_data_reg <= ram_data[m_rd_addr];
                    m_keep_reg <= ram_keep[m_rd_addr];
                    m_last_reg <= ram_last[m_rd_addr];
                    m_id_reg <= ram_id[m_rd_addr];
                    m_dest_reg <= ram_dest[m_rd_addr];
                    m_user_reg <= ram_user[m_rd_addr];
                end
            end else if (!m_valid_reg && m_depth_ptr > 0) begin
                m_valid_reg <= 1'b1;
                m_data_reg <= ram_data[m_rd_addr];
                m_keep_reg <= ram_keep[m_rd_addr];
                m_last_reg <= ram_last[m_rd_addr];
                m_id_reg <= ram_id[m_rd_addr];
                m_dest_reg <= ram_dest[m_rd_addr];
                m_user_reg <= ram_user[m_rd_addr];
            end
        end
    end

    // Output assignments
    assign m_axis_tdata = m_data_reg;
    assign m_axis_tkeep = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = m_id_reg;
    assign m_axis_tdest = m_dest_reg;
    assign m_axis_tuser = m_user_reg;

    // Input ready
    assign s_axis_tready = s_ready_int;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow_sync2;
    assign s_status_bad_frame = s_bad_frame_sync2;
    assign s_status_good_frame = s_good_frame_sync2;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow_sync2;
    assign m_status_bad_frame = m_bad_frame_sync2;
    assign m_status_good_frame = m_good_frame_sync2;

endmodule

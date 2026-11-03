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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // Storage arrays
    reg [DATA_WIDTH-1:0]  mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  mem_keep [0:DEPTH-1];
    reg                   mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    mem_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  mem_user [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;

    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;
    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;

    // Synchronizers for pause signals
    reg s_pause_req_sync1, s_pause_req_sync2, s_pause_req_sync3;
    reg m_pause_req_sync1, m_pause_req_sync2, m_pause_req_sync3;

    // Pause ack registers
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Status registers
    reg s_overflow_reg;
    reg m_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;

    // Depth calculations
    wire [PTR_WIDTH-1:0] r_ptr_in_s = r_ptr_sync3;
    wire [PTR_WIDTH-1:0] w_ptr_in_m = w_ptr_sync3;

    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_in_s;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_in_m - r_ptr;

    // Full/Empty conditions
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    wire s_paused = (PAUSE_ENABLE == 1) && s_pause_req_sync3;
    wire m_paused = (PAUSE_ENABLE == 1) && m_pause_req_sync3;

    // Frame tracking for s_clk domain
    reg s_in_frame;
    reg s_frame_overflow;
    reg s_frame_bad;

    // Frame tracking for m_clk domain
    reg m_in_frame;
    reg m_frame_overflow;
    reg m_frame_bad;

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready && !s_paused;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready && !m_paused;

    // tready generation
    assign s_axis_tready = !s_full && !s_paused;
    assign m_axis_tvalid = !m_empty && !m_paused;

    // Pause ack
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status outputs
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

    // Output data
    assign m_axis_tdata = mem_data[r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = mem_keep[r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tlast = mem_last[r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tid   = mem_id[r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tdest = mem_dest[r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tuser = mem_user[r_ptr[ADDR_WIDTH-1:0]];

    // Synchronizer processes
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_pause_req_sync1 <= 1'b0;
            s_pause_req_sync2 <= 1'b0;
            s_pause_req_sync3 <= 1'b0;
        end else begin
            s_pause_req_sync1 <= s_pause_req;
            s_pause_req_sync2 <= s_pause_req_sync1;
            s_pause_req_sync3 <= s_pause_req_sync2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_pause_req_sync1 <= 1'b0;
            m_pause_req_sync2 <= 1'b0;
            m_pause_req_sync3 <= 1'b0;
        end else begin
            m_pause_req_sync1 <= m_pause_req;
            m_pause_req_sync2 <= m_pause_req_sync1;
            m_pause_req_sync3 <= m_pause_req_sync2;
        end
    end

    // Write pointer and memory write (s_clk domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_in_frame <= 1'b0;
            s_frame_overflow <= 1'b0;
            s_frame_bad <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            // Pause ack
            if (PAUSE_ENABLE) begin
                s_pause_ack_reg <= s_pause_req;
            end

            // Overflow detection
            if (s_axis_tvalid && s_full) begin
                s_overflow_reg <= 1'b1;
            end

            // Frame tracking
            if (s_write_en) begin
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    if (s_frame_overflow) begin
                        s_bad_frame_reg <= 1'b1;
                    end else if (s_frame_bad) begin
                        s_bad_frame_reg <= 1'b1;
                    end else begin
                        s_good_frame_reg <= 1'b1;
                    end
                    s_frame_overflow <= 1'b0;
                    s_frame_bad <= 1'b0;
                end else begin
                    s_in_frame <= 1'b1;
                    if (s_full) begin
                        s_frame_overflow <= 1'b1;
                    end
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        s_frame_bad <= 1'b1;
                    end
                end
            end

            // Write to memory
            if (s_write_en) begin
                mem_data[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_keep[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_last[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                mem_id[w_ptr[ADDR_WIDTH-1:0]]   <= s_axis_tid;
                mem_dest[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                mem_user[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                w_ptr <= w_ptr + 1'b1;
            end
        end
    end

    // Read pointer (m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_in_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
            m_frame_bad <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            // Pause ack
            if (PAUSE_ENABLE) begin
                m_pause_ack_reg <= m_pause_req;
            end

            // Frame tracking
            if (m_read_en) begin
                if (mem_last[r_ptr[ADDR_WIDTH-1:0]]) begin
                    m_in_frame <= 1'b0;
                    if (m_frame_overflow) begin
                        m_bad_frame_reg <= 1'b1;
                    end else if (m_frame_bad) begin
                        m_bad_frame_reg <= 1'b1;
                    end else begin
                        m_good_frame_reg <= 1'b1;
                    end
                    m_frame_overflow <= 1'b0;
                    m_frame_bad <= 1'b0;
                end else begin
                    m_in_frame <= 1'b1;
                    if (USER_ENABLE && (mem_user[r_ptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        m_frame_bad <= 1'b1;
                    end
                end
            end

            // Advance read pointer
            if (m_read_en) begin
                r_ptr <= r_ptr + 1'b1;
            end
        end
    end

endmodule

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

    // Sideband widths
    localparam ID_W = ID_ENABLE ? ID_WIDTH : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;
    localparam KEEP_W = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = S_DATA_WIDTH + KEEP_W + ID_W + DEST_W + USER_W + 1; // +1 for tlast

    // Internal signals
    wire [TOTAL_DATA_WIDTH-1:0] s_write_data;
    wire s_write_en;
    wire s_full;
    wire s_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] s_rd_ptr;

    wire [TOTAL_DATA_WIDTH-1:0] m_read_data;
    wire m_read_en;
    wire m_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] m_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;

    // Pause signals
    wire s_pause_active;
    wire m_pause_active;

    // Status signals
    wire s_overflow_pulse;
    wire m_overflow_pulse;
    wire s_bad_frame_pulse;
    wire m_bad_frame_pulse;
    wire s_good_frame_pulse;
    wire m_good_frame_pulse;

    // Build write data
    assign s_write_data = {
        s_axis_tlast,
        USER_ENABLE ? s_axis_tuser : {USER_W{1'b0}},
        DEST_ENABLE ? s_axis_tdest : {DEST_W{1'b0}},
        ID_ENABLE ? s_axis_tid : {ID_W{1'b0}},
        S_KEEP_ENABLE ? s_axis_tkeep : {KEEP_W{1'b0}},
        s_axis_tdata
    };

    // Write enable: valid and not full (or drop when full)
    wire s_can_write = s_axis_tvalid && (!s_full || DROP_WHEN_FULL);
    assign s_write_en = s_can_write && !s_pause_active;

    // Read enable: not empty and m_ready
    assign m_read_en = !m_empty && m_axis_tready && !m_pause_active;

    // Async FIFO core
    async_fifo #(
        .DEPTH (DEPTH),
        .DATA_WIDTH (TOTAL_DATA_WIDTH)
    ) u_async_fifo (
        .wr_clk (s_clk),
        .wr_rst (s_rst),
        .wr_en (s_write_en),
        .wr_data (s_write_data),
        .wr_full (s_full),
        .wr_empty (s_empty),
        .wr_ptr (s_wr_ptr),
        .rd_clk (m_clk),
        .rd_rst (m_rst),
        .rd_en (m_read_en),
        .rd_data (m_read_data),
        .rd_full (m_full),
        .rd_empty (m_empty),
        .rd_ptr (m_rd_ptr)
    );

    // Extract fields from read data
    wire [S_DATA_WIDTH-1:0] rd_data;
    wire [KEEP_W-1:0] rd_keep;
    wire [ID_W-1:0] rd_id;
    wire [DEST_W-1:0] rd_dest;
    wire [USER_W-1:0] rd_user;
    wire rd_tlast;

    assign rd_data = m_read_data[S_DATA_WIDTH-1:0];
    assign rd_keep = m_read_data[S_DATA_WIDTH + KEEP_W - 1 : S_DATA_WIDTH];
    assign rd_id = m_read_data[S_DATA_WIDTH + KEEP_W + ID_W - 1 : S_DATA_WIDTH + KEEP_W];
    assign rd_dest = m_read_data[S_DATA_WIDTH + KEEP_W + ID_W + DEST_W - 1 : S_DATA_WIDTH + KEEP_W + ID_W];
    assign rd_user = m_read_data[S_DATA_WIDTH + KEEP_W + ID_W + DEST_W + USER_W - 1 : S_DATA_WIDTH + KEEP_W + ID_W + DEST_W];
    assign rd_tlast = m_read_data[TOTAL_DATA_WIDTH-1];

    // Width adapter: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, assume M_DATA_WIDTH >= S_DATA_WIDTH or handle byte alignment
    // If M_DATA_WIDTH == S_DATA_WIDTH, direct pass
    // If M_DATA_WIDTH > S_DATA_WIDTH, zero-extend
    // If M_DATA_WIDTH < S_DATA_WIDTH, truncate (with keep adjustment)

    wire [M_DATA_WIDTH-1:0] m_tdata;
    wire [M_KEEP_WIDTH-1:0] m_tkeep;
    wire m_tlast;
    wire [ID_WIDTH-1:0] m_tid;
    wire [DEST_WIDTH-1:0] m_tdest;
    wire [USER_WIDTH-1:0] m_tuser;

    generate
        if (M_DATA_WIDTH >= S_DATA_WIDTH) begin : gen_widen
            assign m_tdata = { {M_DATA_WIDTH - S_DATA_WIDTH{1'b0}}, rd_data };
            if (M_KEEP_ENABLE) begin : gen_widen_keep
                // Adjust keep: if S_KEEP_ENABLE, map bytes
                if (S_KEEP_ENABLE) begin : gen_widen_keep_map
                    // Simple mapping: assume byte-aligned
                    assign m_tkeep = { {M_KEEP_WIDTH - S_KEEP_WIDTH{1'b0}}, rd_keep };
                end else begin : gen_widen_keep_zero
                    assign m_tkeep = {M_KEEP_WIDTH{1'b0}};
                end
            end else begin : gen_widen_no_keep
                assign m_tkeep = {M_KEEP_WIDTH{1'b0}};
            end
        end else begin : gen_narrow
            assign m_tdata = rd_data[M_DATA_WIDTH-1:0];
            if (M_KEEP_ENABLE) begin : gen_narrow_keep
                if (S_KEEP_ENABLE) begin : gen_narrow_keep_map
                    assign m_tkeep = rd_keep[M_KEEP_WIDTH-1:0];
                end else begin : gen_narrow_keep_zero
                    assign m_tkeep = {M_KEEP_WIDTH{1'b0}};
                end
            end else begin : gen_narrow_no_keep
                assign m_tkeep = {M_KEEP_WIDTH{1'b0}};
            end
        end
    endgenerate

    assign m_tlast = rd_tlast;
    assign m_tid = ID_ENABLE ? rd_id : {ID_WIDTH{1'b0}};
    assign m_tdest = DEST_ENABLE ? rd_dest : {DEST_WIDTH{1'b0}};
    assign m_tuser = USER_ENABLE ? rd_user : {USER_WIDTH{1'b0}};

    // Output valid
    assign m_axis_tvalid = !m_empty && !m_pause_active;
    assign m_axis_tdata = m_tdata;
    assign m_axis_tkeep = m_tkeep;
    assign m_axis_tlast = m_tlast;
    assign m_axis_tid = m_tid;
    assign m_axis_tdest = m_tdest;
    assign m_axis_tuser = m_tuser;

    // Input ready
    assign s_axis_tready = !s_full && !s_pause_active;

    // Pause logic
    generate
        if (PAUSE_ENABLE) begin : gen_pause
            // Simple pause: ack when request is stable
            reg s_pause_ack_reg;
            reg m_pause_ack_reg;

            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst)
                    s_pause_ack_reg <= 1'b0;
                else
                    s_pause_ack_reg <= s_pause_req;
            end

            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst)
                    m_pause_ack_reg <= 1'b0;
                else
                    m_pause_ack_reg <= m_pause_req;
            end

            assign s_pause_ack = s_pause_ack_reg;
            assign m_pause_ack = m_pause_ack_reg;
            assign s_pause_active = s_pause_req;
            assign m_pause_active = m_pause_req;
        end else begin : gen_no_pause
            assign s_pause_ack = 1'b0;
            assign m_pause_ack = 1'b0;
            assign s_pause_active = 1'b0;
            assign m_pause_active = 1'b0;
        end
    endgenerate

    // Status: depth
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    assign s_depth = s_wr_ptr - s_rd_ptr;
    assign m_depth = m_wr_ptr - m_rd_ptr;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow detection
    reg s_overflow_reg;
    reg m_overflow_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_reg <= 1'b0;
        else if (s_axis_tvalid && s_full && !DROP_WHEN_FULL)
            s_overflow_reg <= 1'b1;
        else
            s_overflow_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_reg <= 1'b0;
        else
            m_overflow_reg <= 1'b0; // No overflow on read side
    end

    assign s_status_overflow = s_overflow_reg;
    assign m_status_overflow = m_overflow_reg;

    // Frame detection
    reg s_bad_frame_reg;
    reg m_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            if (s_write_en && s_axis_tlast) begin
                // Check for bad frame
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    s_bad_frame_reg <= 1'b1;
                else
                    s_good_frame_reg <= 1'b1;
            end else begin
                s_bad_frame_reg <= 1'b0;
                s_good_frame_reg <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else begin
            if (m_read_en && rd_tlast) begin
                if (USER_ENABLE && (rd_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    m_bad_frame_reg <= 1'b1;
                else
                    m_good_frame_reg <= 1'b1;
            end else begin
                m_bad_frame_reg <= 1'b0;
                m_good_frame_reg <= 1'b0;
            end
        end
    end

    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule

// Async FIFO module
module async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
) (
    input  wire                     wr_clk,
    input  wire                     wr_rst,
    input  wire                     wr_en,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    output wire                     wr_full,
    output wire                     wr_empty,
    output wire [$clog2(DEPTH):0]   wr_ptr,
    input  wire                     rd_clk,
    input  wire                     rd_rst,
    input  wire                     rd_en,
    output wire [DATA_WIDTH-1:0]    rd_data,
    output wire                     rd_full,
    output wire                     rd_empty,
    output wire [$clog2(DEPTH):0]   rd_ptr
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer
    reg [PTR_WIDTH-1:0] wr_ptr_reg;
    wire [PTR_WIDTH-1:0] wr_ptr_next = wr_ptr_reg + 1'b1;

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst)
            wr_ptr_reg <= {PTR_WIDTH{1'b0}};
        else if (wr_en && !wr_full)
            wr_ptr_reg <= wr_ptr_next;
    end

    // Read pointer
    reg [PTR_WIDTH-1:0] rd_ptr_reg;
    wire [PTR_WIDTH-1:0] rd_ptr_next = rd_ptr_reg + 1'b1;

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst)
            rd_ptr_reg <= {PTR_WIDTH{1'b0}};
        else if (rd_en && !rd_empty)
            rd_ptr_reg <= rd_ptr_next;
    end

    // CDC: Synchronize read pointer to write domain
    reg [PTR_WIDTH-1:0] rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] rd_ptr_sync2;
    reg [PTR_WIDTH-1:0] rd_ptr_sync3;

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync1 <= rd_ptr_reg;
            rd_ptr_sync2 <= rd_ptr_sync1;
            rd_ptr_sync3 <= rd_ptr_sync2;
        end
    end

    // CDC: Synchronize write pointer to read domain
    reg [PTR_WIDTH-1:0] wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] wr_ptr_sync3;

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync1 <= wr_ptr_reg;
            wr_ptr_sync2 <= wr_ptr_sync1;
            wr_ptr_sync3 <= wr_ptr_sync2;
        end
    end

    // Full and empty detection
    wire wr_full = (wr_ptr_next[PTR_WIDTH-1] == rd_ptr_sync3[PTR_WIDTH-1]) &&
                   (wr_ptr_next[ADDR_WIDTH-1:0] == rd_ptr_sync3[ADDR_WIDTH-1:0]);

    wire rd_empty = (rd_ptr_reg == wr_ptr_sync3);

    // Memory write
    always @(posedge wr_clk) begin
        if (wr_en && !wr_full)
            mem[wr_ptr_reg[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // Memory read
    reg [DATA_WIDTH-1:0] rd_data_reg;

    always @(posedge rd_clk) begin
        if (rd_en && !rd_empty)
            rd_data_reg <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]];
    end

    assign rd_data = rd_data_reg;
    assign wr_ptr = wr_ptr_reg;
    assign rd_ptr = rd_ptr_reg;
    assign wr_empty = rd_empty;
    assign rd_full = wr_full;

endmodule

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
    localparam DEPTH_POW2 = (DEPTH == 1) ? 1 : (1 << ADDR_WIDTH);
    localparam DEPTH_MASK = DEPTH_POW2 - 1;
    localparam DEPTH_LIMIT = DEPTH;

    // Total width of the data word stored in RAM
    localparam TOTAL_WIDTH = DATA_WIDTH 
        + (KEEP_ENABLE ? KEEP_WIDTH : 0)
        + (LAST_ENABLE ? 1 : 0)
        + (ID_ENABLE ? ID_WIDTH : 0)
        + (DEST_ENABLE ? DEST_WIDTH : 0)
        + (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_WIDTH-1:0] s_ram_data;
    wire [TOTAL_WIDTH-1:0] m_ram_data;
    wire [ADDR_WIDTH:0] s_wr_ptr;
    wire [ADDR_WIDTH:0] m_rd_ptr;
    wire [ADDR_WIDTH:0] s_wr_ptr_sync_m;
    wire [ADDR_WIDTH:0] m_rd_ptr_sync_s;
    wire s_full;
    wire m_empty;
    wire s_wr_en;
    wire m_rd_en;
    wire s_pause_active;
    wire m_pause_active;
    wire s_overflow_pulse;
    wire m_overflow_pulse;
    wire s_bad_frame_pulse;
    wire m_bad_frame_pulse;
    wire s_good_frame_pulse;
    wire m_good_frame_pulse;

    // Pack input data
    assign s_ram_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Unpack output data
    assign m_axis_tdata = m_ram_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_ram_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    assign m_axis_tlast = m_ram_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)];
    assign m_axis_tid = m_ram_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    assign m_axis_tdest = m_ram_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    assign m_axis_tuser = m_ram_data[TOTAL_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];

    // Source domain logic
    reg [ADDR_WIDTH:0] s_wr_ptr_reg;
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg s_pause_ack_reg;

    assign s_wr_ptr = s_wr_ptr_reg;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign s_pause_ack = s_pause_ack_reg;

    // Synchronize m_rd_ptr to source domain
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_r1;
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_r2;
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_r3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_r1 <= {(ADDR_WIDTH+1){1'b0}};
            m_rd_ptr_sync_r2 <= {(ADDR_WIDTH+1){1'b0}};
            m_rd_ptr_sync_r3 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            m_rd_ptr_sync_r1 <= m_rd_ptr;
            m_rd_ptr_sync_r2 <= m_rd_ptr_sync_r1;
            m_rd_ptr_sync_r3 <= m_rd_ptr_sync_r2;
        end
    end

    assign m_rd_ptr_sync_s = m_rd_ptr_sync_r3;

    // Calculate depth in source domain
    wire [ADDR_WIDTH:0] s_depth = s_wr_ptr - m_rd_ptr_sync_s;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;

    // Full condition
    assign s_full = (s_depth >= DEPTH_LIMIT);

    // Pause logic in source domain
    reg s_pause_req_sync_r1;
    reg s_pause_req_sync_r2;
    reg s_pause_req_sync_r3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req_sync_r1 <= 1'b0;
            s_pause_req_sync_r2 <= 1'b0;
            s_pause_req_sync_r3 <= 1'b0;
        end else begin
            s_pause_req_sync_r1 <= s_pause_req;
            s_pause_req_sync_r2 <= s_pause_req_sync_r1;
            s_pause_req_sync_r3 <= s_pause_req_sync_r2;
        end
    end

    assign s_pause_active = PAUSE_ENABLE ? s_pause_req_sync_r3 : 1'b0;

    // Write enable
    assign s_wr_en = s_axis_tvalid && s_axis_tready && !s_pause_active;

    // tready logic
    wire s_tready_base = !s_full || DROP_WHEN_FULL || MARK_WHEN_FULL;
    assign s_axis_tready = s_tready_base && !s_pause_active;

    // Overflow detection
    wire s_overflow_cond = s_axis_tvalid && s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL;
    assign s_overflow_pulse = s_overflow_cond;

    // Frame tracking in source domain
    reg s_in_frame;
    reg [USER_WIDTH-1:0] s_frame_user;
    reg s_frame_bad;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_user <= {USER_WIDTH{1'b0}};
            s_frame_bad <= 1'b0;
        end else if (s_wr_en) begin
            if (!s_in_frame) begin
                s_in_frame <= 1'b1;
                s_frame_user <= s_axis_tuser;
                s_frame_bad <= 1'b0;
            end else begin
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    s_frame_bad <= 1'b0;
                end
            end
        end
    end

    // Bad frame detection (simplified: check if user bits match bad pattern on last beat)
    wire s_bad_frame_cond = s_wr_en && s_axis_tlast && 
        (USER_ENABLE ? ((s_axis_tuser & USER_BAD_FRAME_MASK) == (USER_BAD_FRAME_VALUE & USER_BAD_FRAME_MASK)) : 1'b0);
    assign s_bad_frame_pulse = s_bad_frame_cond;

    // Good frame detection
    wire s_good_frame_cond = s_wr_en && s_axis_tlast && !s_bad_frame_cond;
    assign s_good_frame_pulse = s_good_frame_cond;

    // Update status registers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_reg <= {(ADDR_WIDTH+1){1'b0}};
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            if (s_wr_en) begin
                s_wr_ptr_reg <= s_wr_ptr_reg + 1'b1;
            end
            if (s_overflow_pulse) begin
                s_overflow_reg <= 1'b1;
            end
            if (s_bad_frame_pulse) begin
                s_bad_frame_reg <= 1'b1;
            end
            if (s_good_frame_pulse) begin
                s_good_frame_reg <= 1'b1;
            end
            if (PAUSE_ENABLE) begin
                s_pause_ack_reg <= s_pause_req_sync_r3;
            end else begin
                s_pause_ack_reg <= 1'b0;
            end
        end
    end

    // Destination domain logic
    reg [ADDR_WIDTH:0] m_rd_ptr_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;
    reg m_pause_ack_reg;

    assign m_rd_ptr = m_rd_ptr_reg;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Synchronize s_wr_ptr to destination domain
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_r1;
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_r2;
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_r3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_r1 <= {(ADDR_WIDTH+1){1'b0}};
            s_wr_ptr_sync_r2 <= {(ADDR_WIDTH+1){1'b0}};
            s_wr_ptr_sync_r3 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            s_wr_ptr_sync_r1 <= s_wr_ptr;
            s_wr_ptr_sync_r2 <= s_wr_ptr_sync_r1;
            s_wr_ptr_sync_r3 <= s_wr_ptr_sync_r2;
        end
    end

    assign s_wr_ptr_sync_m = s_wr_ptr_sync_r3;

    // Calculate depth in destination domain
    wire [ADDR_WIDTH:0] m_depth = s_wr_ptr_sync_m - m_rd_ptr;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Empty condition
    assign m_empty = (m_depth == 0);

    // Pause logic in destination domain
    reg m_pause_req_sync_r1;
    reg m_pause_req_sync_r2;
    reg m_pause_req_sync_r3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req_sync_r1 <= 1'b0;
            m_pause_req_sync_r2 <= 1'b0;
            m_pause_req_sync_r3 <= 1'b0;
        end else begin
            m_pause_req_sync_r1 <= m_pause_req;
            m_pause_req_sync_r2 <= m_pause_req_sync_r1;
            m_pause_req_sync_r3 <= m_pause_req_sync_r2;
        end
    end

    assign m_pause_active = PAUSE_ENABLE ? m_pause_req_sync_r3 : 1'b0;

    // Read enable
    assign m_rd_en = m_axis_tvalid && m_axis_tready && !m_pause_active;

    // tvalid logic
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Overflow detection in destination domain (shouldn't happen normally, but for status)
    assign m_overflow_pulse = 1'b0;

    // Bad frame detection in destination domain
    wire m_bad_frame_cond = m_rd_en && m_axis_tlast && 
        (USER_ENABLE ? ((m_axis_tuser & USER_BAD_FRAME_MASK) == (USER_BAD_FRAME_VALUE & USER_BAD_FRAME_MASK)) : 1'b0);
    assign m_bad_frame_pulse = m_bad_frame_cond;

    // Good frame detection in destination domain
    wire m_good_frame_cond = m_rd_en && m_axis_tlast && !m_bad_frame_cond;
    assign m_good_frame_pulse = m_good_frame_cond;

    // Update status registers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr_reg <= {(ADDR_WIDTH+1){1'b0}};
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            if (m_rd_en) begin
                m_rd_ptr_reg <= m_rd_ptr_reg + 1'b1;
            end
            if (m_overflow_pulse) begin
                m_overflow_reg <= 1'b1;
            end
            if (m_bad_frame_pulse) begin
                m_bad_frame_reg <= 1'b1;
            end
            if (m_good_frame_pulse) begin
                m_good_frame_reg <= 1'b1;
            end
            if (PAUSE_ENABLE) begin
                m_pause_ack_reg <= m_pause_req_sync_r3;
            end else begin
                m_pause_ack_reg <= 1'b0;
            end
        end
    end

    // RAM implementation
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH_POW2-1];

    // Write in source domain
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_ram_data;
        end
    end

    // Read in destination domain
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    wire [TOTAL_WIDTH-1:0] m_ram_data_raw;

    if (RAM_PIPELINE) begin
        reg [TOTAL_WIDTH-1:0] m_ram_data_pipe_r1;
        reg [TOTAL_WIDTH-1:0] m_ram_data_pipe_r2;
        reg m_rd_en_pipe_r1;
        reg m_rd_en_pipe_r2;

        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                m_ram_data_pipe_r1 <= {TOTAL_WIDTH{1'b0}};
                m_ram_data_pipe_r2 <= {TOTAL_WIDTH{1'b0}};
                m_rd_en_pipe_r1 <= 1'b0;
                m_rd_en_pipe_r2 <= 1'b0;
            end else begin
                m_ram_data_pipe_r1 <= ram[m_rd_addr];
                m_ram_data_pipe_r2 <= m_ram_data_pipe_r1;
                m_rd_en_pipe_r1 <= m_rd_en;
                m_rd_en_pipe_r2 <= m_rd_en_pipe_r1;
            end
        end

        assign m_ram_data = m_ram_data_pipe_r2;
    end else begin
        assign m_ram_data = ram[m_rd_addr];
    end

endmodule

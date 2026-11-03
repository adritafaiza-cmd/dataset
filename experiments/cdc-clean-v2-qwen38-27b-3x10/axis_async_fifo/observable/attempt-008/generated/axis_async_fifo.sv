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

    // Internal storage width
    localparam STORE_WIDTH = DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);

    // Storage array
    reg [STORE_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] wr_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] rd_ptr;

    // Synchronizers for read pointer into s_clk domain
    reg [PTR_WIDTH-1:0] rd_ptr_sync0, rd_ptr_sync1, rd_ptr_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_sync0 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync0 <= rd_ptr;
            rd_ptr_sync1 <= rd_ptr_sync0;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end

    // Synchronizers for write pointer into m_clk domain
    reg [PTR_WIDTH-1:0] wr_ptr_sync0, wr_ptr_sync1, wr_ptr_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_sync0 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync0 <= wr_ptr;
            wr_ptr_sync1 <= wr_ptr_sync0;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end

    // Depth calculations
    wire [PTR_WIDTH-1:0] depth_s = wr_ptr - rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] depth_m = wr_ptr_sync2 - rd_ptr;

    // Full and empty flags
    wire s_full = (depth_s == DEPTH);
    wire m_empty = (depth_m == 0);

    // Pause logic
    reg s_pause_active;
    reg m_pause_active;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            s_pause_active <= s_pause_req;
        else
            s_pause_active <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            m_pause_active <= m_pause_req;
        else
            m_pause_active <= 1'b0;
    end

    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;

    // Frame tracking for FRAME_FIFO
    reg s_in_frame;
    reg m_in_frame;
    reg s_frame_overflow;
    reg m_frame_overflow;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_overflow <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast)
                    s_in_frame <= 1'b0;
                else
                    s_in_frame <= 1'b1;
            end
            if (FRAME_FIFO && s_in_frame && s_full && s_axis_tvalid && !s_axis_tready)
                s_frame_overflow <= 1'b1;
            else if (s_axis_tvalid && s_axis_tready && s_axis_tlast)
                s_frame_overflow <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tlast)
                    m_in_frame <= 1'b0;
                else
                    m_in_frame <= 1'b1;
            end
            if (FRAME_FIFO && m_in_frame && m_empty && !m_axis_tvalid)
                m_frame_overflow <= 1'b0;
        end
    end

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready;

    // tready generation
    wire s_can_accept = !s_full && !s_pause_active && !(FRAME_PAUSE && s_in_frame && s_full);
    assign s_axis_tready = s_can_accept;

    // Write to memory
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= {
                (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
                (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
                (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
                (LAST_ENABLE ? s_axis_tlast : 1'b0),
                (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
                s_axis_tdata
            };
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read from memory
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];
    wire [STORE_WIDTH-1:0] rd_data = mem[rd_addr];

    // Extract fields from read data
    wire [DATA_WIDTH-1:0] rd_tdata = rd_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0] rd_tkeep = KEEP_ENABLE ? rd_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    wire rd_tlast = LAST_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    wire [ID_WIDTH-1:0] rd_tid = ID_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    wire [DEST_WIDTH-1:0] rd_tdest = DEST_ENABLE ? rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    wire [USER_WIDTH-1:0] rd_tuser = USER_ENABLE ? rd_data[STORE_WIDTH-1:STORE_WIDTH-USER_WIDTH] : {USER_WIDTH{1'b0}};

    // Output valid
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Output data
    assign m_axis_tdata = rd_tdata;
    assign m_axis_tkeep = rd_tkeep;
    assign m_axis_tlast = rd_tlast;
    assign m_axis_tid = rd_tid;
    assign m_axis_tdest = rd_tdest;
    assign m_axis_tuser = rd_tuser;

    // Update read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Status outputs
    assign s_status_depth = depth_s;
    assign s_status_depth_commit = depth_s;
    assign m_status_depth = depth_m;
    assign m_status_depth_commit = depth_m;

    // Overflow status
    reg s_overflow_reg;
    reg m_overflow_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_reg <= 1'b0;
        else if (s_axis_tvalid && s_full)
            s_overflow_reg <= 1'b1;
        else if (s_axis_tvalid && s_axis_tready)
            s_overflow_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_reg <= 1'b0;
        else if (m_axis_tvalid && m_empty)
            m_overflow_reg <= 1'b0;
        else
            m_overflow_reg <= m_overflow_reg;
    end

    assign s_status_overflow = s_overflow_reg;
    assign m_status_overflow = m_overflow_reg;

    // Bad frame status
    reg s_bad_frame_reg;
    reg m_bad_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_bad_frame_reg <= 1'b0;
        else if (FRAME_FIFO && s_in_frame && s_full && s_axis_tvalid && !s_axis_tready)
            s_bad_frame_reg <= 1'b1;
        else if (s_axis_tvalid && s_axis_tready && s_axis_tlast)
            s_bad_frame_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_bad_frame_reg <= 1'b0;
        else if (m_axis_tvalid && m_axis_tready && m_axis_tlast)
            m_bad_frame_reg <= 1'b0;
    end

    assign s_status_bad_frame = s_bad_frame_reg;
    assign m_status_bad_frame = m_bad_frame_reg;

    // Good frame status
    reg s_good_frame_reg;
    reg m_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_good_frame_reg <= 1'b0;
        else if (s_axis_tvalid && s_axis_tready && s_axis_tlast)
            s_good_frame_reg <= 1'b1;
        else if (s_axis_tvalid && s_axis_tready)
            s_good_frame_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_good_frame_reg <= 1'b0;
        else if (m_axis_tvalid && m_axis_tready && m_axis_tlast)
            m_good_frame_reg <= 1'b1;
        else if (m_axis_tvalid && m_axis_tready)
            m_good_frame_reg <= 1'b0;
    end

    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule

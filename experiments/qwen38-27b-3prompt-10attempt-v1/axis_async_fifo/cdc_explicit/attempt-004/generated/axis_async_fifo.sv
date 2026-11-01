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

    // Total width for storage
    localparam TOTAL_WIDTH = DATA_WIDTH + 
                             (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                             (LAST_ENABLE ? 1 : 0) + 
                             (ID_ENABLE ? ID_WIDTH : 0) + 
                             (DEST_ENABLE ? DEST_WIDTH : 0) + 
                             (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_WIDTH-1:0] s_wr_data;
    wire [TOTAL_WIDTH-1:0] m_rd_data;
    wire [ADDR_WIDTH-1:0] s_wr_addr;
    wire [ADDR_WIDTH-1:0] m_rd_addr;
    wire s_wr_en;
    wire m_rd_en;
    wire s_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_m;
    wire [PTR_WIDTH-1:0] m_rd_ptr_s;
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Build write data
    assign s_wr_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Extract read data
    assign m_axis_tdata = m_rd_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    assign m_axis_tlast = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1];
    assign m_axis_tid = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    assign m_axis_tdest = m_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    assign m_axis_tuser = m_rd_data[TOTAL_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];

    // Write enable
    assign s_wr_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    assign m_rd_en = m_axis_tvalid & m_axis_tready;

    // FIFO control
    assign s_full = (s_wr_ptr_m == m_rd_ptr_s) && (s_wr_ptr[PTR_WIDTH-1] != m_rd_ptr_s[PTR_WIDTH-1]);
    assign m_empty = (m_rd_ptr == s_wr_ptr_m);

    // Depth calculation
    assign s_depth = s_wr_ptr - m_rd_ptr_s;
    assign m_depth = s_wr_ptr_m - m_rd_ptr;

    // Status outputs
    assign s_status_depth = s_depth;
    assign m_status_depth = m_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth_commit = m_depth;
    assign s_status_overflow = 1'b0;
    assign m_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    // Pause logic
    assign s_pause_ack = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_req : 1'b0;

    // Ready logic
    wire s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;

    assign s_axis_tready = !s_full && !s_pause_active;
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // RAM
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];

    // Write port
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram[s_wr_addr] <= s_wr_data;
        end
    end

    // Read port
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= ram[m_rd_addr];
        end
    end

    // Write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_wr_en) begin
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Address generation
    assign s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    assign m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // CDC synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_reg [0:2];
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_m_reg[0] <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_reg[1] <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_reg[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_m_reg[0] <= s_wr_ptr;
            s_wr_ptr_m_reg[1] <= s_wr_ptr_m_reg[0];
            s_wr_ptr_m_reg[2] <= s_wr_ptr_m_reg[1];
        end
    end
    assign s_wr_ptr_m = s_wr_ptr_m_reg[2];

    // CDC synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_reg [0:2];
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_s_reg[0] <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_reg[1] <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_reg[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_s_reg[0] <= m_rd_ptr;
            m_rd_ptr_s_reg[1] <= m_rd_ptr_s_reg[0];
            m_rd_ptr_s_reg[2] <= m_rd_ptr_s_reg[1];
        end
    end
    assign m_rd_ptr_s = m_rd_ptr_s_reg[2];

endmodule

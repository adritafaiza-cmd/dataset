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

    // Internal signals for AXI input
    reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;
    wire s_axis_tready_int;

    // Internal signals for AXI output
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    wire m_axis_tready_int;

    // Internal signals for FIFO control
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg full;
    reg empty;
    reg [1:0] status;

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // AXI input FIFO
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
            s_axis_tready <= 1;
        end else begin
            if (s_axis_tvalid && s_axis_tready_int) begin
                mem[wr_ptr] <= s_axis_tdata;
                wr_ptr <= wr_ptr + 1;
                full <= (wr_ptr == rd_ptr);
                empty <= 0;
            end else if (s_axis_tready_int) begin
                rd_ptr <= rd_ptr + 1;
                empty <= (wr_ptr == rd_ptr);
                full <= 0;
            end
        end
    end

    // AXI output FIFO
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
            m_axis_tready <= 1;
        end else begin
            if (m_axis_tready && m_axis_tvalid_int) begin
                mem[wr_ptr] <= m_axis_tdata;
                wr_ptr <= wr_ptr + 1;
                full <= (wr_ptr == rd_ptr);
                empty <= 0;
            end else if (m_axis_tvalid_int) begin
                rd_ptr <= rd_ptr + 1;
                empty <= (wr_ptr == rd_ptr);
                full <= 0;
            end
        end
    end

    // AXI input handshake
    always @(posedge s_clk) begin
        s_axis_tready <= s_axis_tready_int;
    end

    // AXI output handshake
    always @(posedge m_clk) begin
        m_axis_tready <= m_axis_tready_int;
    end

    // AXI input interface
    assign s_axis_tready_int = ~full;

    // AXI output interface
    assign m_axis_tready_int = ~full;

    // Status signals
    assign s_status_depth = wr_ptr;
    assign s_status_depth_commit = rd_ptr;
    assign s_status_overflow = full;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_depth = wr_ptr;
    assign m_status_depth_commit = rd_ptr;
    assign m_status_overflow = full;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

endmodule

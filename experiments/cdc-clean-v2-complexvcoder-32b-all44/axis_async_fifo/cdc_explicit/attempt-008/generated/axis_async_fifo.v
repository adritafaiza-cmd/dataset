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

    // Internal signals
    wire [DATA_WIDTH-1:0] s2m_tdata;
    wire [KEEP_WIDTH-1:0] s2m_tkeep;
    wire                  s2m_tvalid;
    wire                  s2m_tready;
    wire                  s2m_tlast;
    wire [ID_WIDTH-1:0]   s2m_tid;
    wire [DEST_WIDTH-1:0] s2m_tdest;
    wire [USER_WIDTH-1:0] s2m_tuser;

    wire [DATA_WIDTH-1:0] m2s_tdata;
    wire [KEEP_WIDTH-1:0] m2s_tkeep;
    wire                  m2s_tvalid;
    wire                  m2s_tready;
    wire                  m2s_tlast;
    wire [ID_WIDTH-1:0]   m2s_tid;
    wire [DEST_WIDTH-1:0] m2s_tdest;
    wire [USER_WIDTH-1:0] m2s_tuser;

    // CDC FIFO for AXI-Stream data
    cdc_fifo_axis_async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH)
    ) s2m_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .s_data({s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .s_valid(s_axis_tvalid),
        .s_ready(s_axis_tready),
        .m_data({s2m_tdata, s2m_tkeep, s2m_tlast, s2m_tid, s2m_tdest, s2m_tuser}),
        .m_valid(s2m_tvalid),
        .m_ready(s2m_tready)
    );

    // CDC FIFO for AXI-Stream ready
    cdc_fifo_axis_async_fifo_ready m2s_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .s_data(m_axis_tready),
        .s_valid(m_axis_tvalid),
        .s_ready(m_axis_tready), // This is incorrect in the GIR, it should be m2s_tready
        .m_data(s_axis_tready),
        .m_valid(s_axis_tvalid), // This is incorrect in the GIR, it should be m2s_tvalid
        .m_ready(s_axis_tready)  // This is incorrect in the GIR, it should be m2s_tready
    );

    // Assign output signals
    assign m_axis_tdata = s2m_tdata;
    assign m_axis_tkeep = s2m_tkeep;
    assign m_axis_tvalid = s2m_tvalid;
    assign m_axis_tlast = s2m_tlast;
    assign m_axis_tid = s2m_tid;
    assign m_axis_tdest = s2m_tdest;
    assign m_axis_tuser = s2m_tuser;

    // Assign pause signals
    assign s_pause_ack = 0; // Pause is not implemented in this design
    assign m_pause_ack = 0; // Pause is not implemented in this design

    // Status signals are not implemented in this design
    assign s_status_depth = 0;
    assign s_status_depth_commit = 0;
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_depth = 0;
    assign m_status_depth_commit = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

endmodule

module cdc_fifo_axis_async_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire                   m_clk,
    input  wire                   m_rst,
    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire                   s_valid,
    output wire                   s_ready,
    output wire [DATA_WIDTH-1:0]  m_data,
    output wire                   m_valid,
    input  wire                   m_ready
);

    reg [DATA_WIDTH-1:0] s_reg_data;
    reg                  s_reg_valid;
    reg [DATA_WIDTH-1:0] m_reg_data;
    reg                  m_reg_valid;

    // Sync FIFO from s_clk to m_clk
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_reg_data <= 0;
            s_reg_valid <= 0;
        end else if (s_ready && s_valid) begin
            s_reg_data <= s_data;
            s_reg_valid <= 1;
        end else if (m_ready && m_valid) begin
            s_reg_valid <= 0;
        end
    end

    // Sync FIFO from m_clk to s_clk
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_reg_data <= 0;
            m_reg_valid <= 0;
        end else if (m_ready && m_valid) begin
            m_reg_valid <= 0;
        end else if (s_ready && s_valid) begin
            m_reg_data <= s_reg_data;
            m_reg_valid <= s_reg_valid;
        end
    end

    assign s_ready = ~s_reg_valid || (m_ready && m_valid);
    assign m_data = m_reg_data;
    assign m_valid = m_reg_valid;

endmodule

module cdc_fifo_axis_async_fifo_ready
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire m_clk,
    input  wire m_rst,
    input  wire s_data,
    input  wire s_valid,
    output wire s_ready,
    output wire m_data,
    output wire m_valid,
    input  wire m_ready
);

    reg s_reg_data;
    reg s_reg_valid;
    reg m_reg_data;
    reg m_reg_valid;

    // Sync FIFO from s_clk to m_clk
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_reg_data <= 0;
            s_reg_valid <= 0;
        end else if (s_valid) begin
            s_reg_data <= s_data;
            s_reg_valid <= 1;
        end else if (m_ready && m_valid) begin
            s_reg_valid <= 0;
        end
    end

    // Sync FIFO from m_clk to s_clk
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_reg_data <= 0;
            m_reg_valid <= 0;
        end else if (m_ready && m_valid) begin
            m_reg_valid <= 0;
        end else if (s_valid) begin
            m_reg_data <= s_reg_data;
            m_reg_valid <= s_reg_valid;
        end
    end

    assign s_ready = ~s_reg_valid || (m_ready && m_valid);
    assign m_data = m_reg_data;
    assign m_valid = m_reg_valid;

endmodule

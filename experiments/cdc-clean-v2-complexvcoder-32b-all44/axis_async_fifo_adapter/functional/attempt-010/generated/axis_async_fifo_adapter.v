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

    /*
     * Internal signals
     */
    wire [M_DATA_WIDTH-1:0]         width_converter_m_axis_tdata;
    wire [M_KEEP_WIDTH-1:0]         width_converter_m_axis_tkeep;
    wire                            width_converter_m_axis_tvalid;
    wire                            width_converter_m_axis_tready;
    wire                            width_converter_m_axis_tlast;
    wire [ID_WIDTH-1:0]             width_converter_m_axis_tid;
    wire [DEST_WIDTH-1:0]           width_converter_m_axis_tdest;
    wire [USER_WIDTH-1:0]           width_converter_m_axis_tuser;

    wire                            s_to_m_async_fifo_s_axis_tready;
    wire                            s_to_m_async_fifo_m_axis_tvalid;
    wire [M_DATA_WIDTH-1:0]         s_to_m_async_fifo_m_axis_tdata;
    wire [M_KEEP_WIDTH-1:0]         s_to_m_async_fifo_m_axis_tkeep;
    wire                            s_to_m_async_fifo_m_axis_tlast;
    wire [ID_WIDTH-1:0]             s_to_m_async_fifo_m_axis_tid;
    wire [DEST_WIDTH-1:0]           s_to_m_async_fifo_m_axis_tdest;
    wire [USER_WIDTH-1:0]           s_to_m_async_fifo_m_axis_tuser;

    wire [$clog2(DEPTH):0]          s_to_m_async_fifo_s_status_depth;
    wire [$clog2(DEPTH):0]          s_to_m_async_fifo_s_status_depth_commit;
    wire                            s_to_m_async_fifo_s_status_overflow;
    wire                            s_to_m_async_fifo_s_status_bad_frame;
    wire                            s_to_m_async_fifo_s_status_good_frame;
    wire [$clog2(DEPTH):0]          s_to_m_async_fifo_m_status_depth;
    wire [$clog2(DEPTH):0]          s_to_m_async_fifo_m_status_depth_commit;
    wire                            s_to_m_async_fifo_m_status_overflow;
    wire                            s_to_m_async_fifo_m_status_bad_frame;
    wire                            s_to_m_async_fifo_m_status_good_frame;

    wire                            pause_control_s_pause_ack;
    wire                            pause_control_m_pause_ack;

    /*
     * Instances
     */

    // Width Adapter
    width_adapter #(
        .S_DATA_WIDTH ( S_DATA_WIDTH ),
        .S_KEEP_ENABLE ( S_KEEP_ENABLE ),
        .S_KEEP_WIDTH ( S_KEEP_WIDTH ),
        .M_DATA_WIDTH ( M_DATA_WIDTH ),
        .M_KEEP_ENABLE ( M_KEEP_ENABLE ),
        .M_KEEP_WIDTH ( M_KEEP_WIDTH ),
        .ID_ENABLE ( ID_ENABLE ),
        .ID_WIDTH ( ID_WIDTH ),
        .DEST_ENABLE ( DEST_ENABLE ),
        .DEST_WIDTH ( DEST_WIDTH ),
        .USER_ENABLE ( USER_ENABLE ),
        .USER_WIDTH ( USER_WIDTH )
    ) width_converter (
        .s_clk ( s_clk ),
        .s_rst ( s_rst ),
        .s_axis_tdata ( s_axis_tdata ),
        .s_axis_tkeep ( s_axis_tkeep ),
        .s_axis_tvalid ( s_axis_tvalid ),
        .s_axis_tready ( width_converter_m_axis_tready ),
        .s_axis_tlast ( s_axis_tlast ),
        .s_axis_tid ( s_axis_tid ),
        .s_axis_tdest ( s_axis_tdest ),
        .s_axis_tuser ( s_axis_tuser ),
        .m_axis_tdata ( width_converter_m_axis_tdata ),
        .m_axis_tkeep ( width_converter_m_axis_tkeep ),
        .m_axis_tvalid ( width_converter_m_axis_tvalid ),
        .m_axis_tready ( s_to_m_async_fifo_s_axis_tready ),
        .m_axis_tlast ( width_converter_m_axis_tlast ),
        .m_axis_tid ( width_converter_m_axis_tid ),
        .m_axis_tdest ( width_converter_m_axis_tdest ),
        .m_axis_tuser ( width_converter_m_axis_tuser )
    );

    // Asynchronous FIFO
    async_fifo #(
        .DATA_WIDTH ( M_DATA_WIDTH ),
        .KEEP_ENABLE ( M_KEEP_ENABLE ),
        .KEEP_WIDTH ( M_KEEP_WIDTH ),
        .ID_ENABLE ( ID_ENABLE ),
        .ID_WIDTH ( ID_WIDTH ),
        .DEST_ENABLE ( DEST_ENABLE ),
        .DEST_WIDTH ( DEST_WIDTH ),
        .USER_ENABLE ( USER_ENABLE ),
        .USER_WIDTH ( USER_WIDTH ),
        .DEPTH ( DEPTH ),
        .RAM_PIPELINE ( RAM_PIPELINE ),
        .OUTPUT_FIFO_ENABLE ( OUTPUT_FIFO_ENABLE ),
        .FRAME_FIFO ( FRAME_FIFO ),
        .USER_BAD_FRAME_VALUE ( USER_BAD_FRAME_VALUE ),
        .USER_BAD_FRAME_MASK ( USER_BAD_FRAME_MASK ),
        .DROP_OVERSIZE_FRAME ( DROP_OVERSIZE_FRAME ),
        .DROP_BAD_FRAME ( DROP_BAD_FRAME ),
        .DROP_WHEN_FULL ( DROP_WHEN_FULL ),
        .MARK_WHEN_FULL ( MARK_WHEN_FULL ),
        .PAUSE_ENABLE ( PAUSE_ENABLE ),
        .FRAME_PAUSE ( FRAME_PAUSE )
    ) s_to_m_async_fifo (
        .s_clk ( s_clk ),
        .s_rst ( s_rst ),
        .s_axis_tdata ( width_converter_m_axis_tdata ),
        .s_axis_tkeep ( width_converter_m_axis_tkeep ),
        .s_axis_tvalid ( width_converter_m_axis_tvalid ),
        .s_axis_tready ( s_to_m_async_fifo_s_axis_tready ),
        .s_axis_tlast ( width_converter_m_axis_tlast ),
        .s_axis_tid ( width_converter_m_axis_tid ),
        .s_axis_tdest ( width_converter_m_axis_tdest ),
        .s_axis_tuser ( width_converter_m_axis_tuser ),
        .m_clk ( m_clk ),
        .m_rst ( m_rst ),
        .m_axis_tdata ( s_to_m_async_fifo_m_axis_tdata ),
        .m_axis_tkeep ( s_to_m_async_fifo_m_axis_tkeep ),
        .m_axis_tvalid ( s_to_m_async_fifo_m_axis_tvalid ),
        .m_axis_tready ( m_axis_tready ),
        .m_axis_tlast ( s_to_m_async_fifo_m_axis_tlast ),
        .m_axis_tid ( s_to_m_async_fifo_m_axis_tid ),
        .m_axis_tdest ( s_to_m_async_fifo_m_axis_tdest ),
        .m_axis_tuser ( s_to_m_async_fifo_m_axis_tuser ),
        .s_status_depth ( s_to_m_async_fifo_s_status_depth ),
        .s_status_depth_commit ( s_to_m_async_fifo_s_status_depth_commit ),
        .s_status_overflow ( s_to_m_async_fifo_s_status_overflow ),
        .s_status_bad_frame ( s_to_m_async_fifo_s_status_bad_frame ),
        .s_status_good_frame ( s_to_m_async_fifo_s_status_good_frame ),
        .m_status_depth ( s_to_m_async_fifo_m_status_depth ),
        .m_status_depth_commit ( s_to_m_async_fifo_m_status_depth_commit ),
        .m_status_overflow ( s_to_m_async_fifo_m_status_overflow ),
        .m_status_bad_frame ( s_to_m_async_fifo_m_status_bad_frame ),
        .m_status_good_frame ( s_to_m_async_fifo_m_status_good_frame )
    );

    // Status Monitor for Slave Interface
    status_monitor status_monitor_s (
        .clk ( s_clk ),
        .rst ( s_rst ),
        .fifo_depth ( s_to_m_async_fifo_s_status_depth ),
        .fifo_depth_commit ( s_to_m_async_fifo_s_status_depth_commit ),
        .overflow ( s_to_m_async_fifo_s_status_overflow ),
        .bad_frame ( s_to_m_async_fifo_s_status_bad_frame ),
        .good_frame ( s_to_m_async_fifo_s_status_good_frame ),
        .status_depth ( s_status_depth ),
        .status_depth_commit ( s_status_depth_commit ),
        .status_overflow ( s_status_overflow ),
        .status_bad_frame ( s_status_bad_frame ),
        .status_good_frame ( s_status_good_frame )
    );

    // Status Monitor for Master Interface
    status_monitor status_monitor_m (
        .clk ( m_clk ),
        .rst ( m_rst ),
        .fifo_depth ( s_to_m_async_fifo_m_status_depth ),
        .fifo_depth_commit ( s_to_m_async_fifo_m_status_depth_commit ),
        .overflow ( s_to_m_async_fifo_m_status_overflow ),
        .bad_frame ( s_to_m_async_fifo_m_status_bad_frame ),
        .good_frame ( s_to_m_async_fifo_m_status_good_frame ),
        .status_depth ( m_status_depth ),
        .status_depth_commit ( m_status_depth_commit ),
        .status_overflow ( m_status_overflow ),
        .status_bad_frame ( m_status_bad_frame ),
        .status_good_frame ( m_status_good_frame )
    );

    // Pause Control for Slave Interface
    pause_control pause_control_s (
        .clk ( s_clk ),
        .rst ( s_rst ),
        .pause_req ( s_pause_req ),
        .pause_ack ( pause_control_s_pause_ack )
    );

    // Pause Control for Master Interface
    pause_control pause_control_m (
        .clk ( m_clk ),
        .rst ( m_rst ),
        .pause_req ( m_pause_req ),
        .pause_ack ( pause_control_m_pause_ack )
    );

    /*
     * Connections
     */
    assign s_axis_tready = width_converter_m_axis_tready;
    assign m_axis_tdata = s_to_m_async_fifo_m_axis_tdata;
    assign m_axis_tkeep = s_to_m_async_fifo_m_axis_tkeep;
    assign m_axis_tvalid = s_to_m_async_fifo_m_axis_tvalid;
    assign m_axis_tlast = s_to_m_async_fifo_m_axis_tlast;
    assign m_axis_tid = s_to_m_async_fifo_m_axis_tid;
    assign m_axis_tdest = s_to_m_async_fifo_m_axis_tdest;
    assign m_axis_tuser = s_to_m_async_fifo_m_axis_tuser;
    assign s_pause_ack = pause_control_s_pause_ack;
    assign m_pause_ack = pause_control_m_pause_ack;

endmodule

// Width Adapter Module
module width_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = 0,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = 0,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    /*
     * Internal signals
     */
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
    reg                             s_axis_tvalid_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;

    /*
     * FIFO for width conversion
     */
    reg [S_DATA_WIDTH-1:0]          fifo_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0]          fifo_keep [0:DEPTH-1];
    reg                             fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]              fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]            fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]            fifo_user [0:DEPTH-1];
    reg [$clog2(DEPTH):0]           fifo_wr_ptr;
    reg [$clog2(DEPTH):0]           fifo_rd_ptr;
    reg                             fifo_full;
    reg                             fifo_empty;

    /*
     * FIFO control
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            if (s_axis_tvalid && !fifo_full) begin
                fifo_data[fifo_wr_ptr] <= s_axis_tdata;
                fifo_keep[fifo_wr_ptr] <= s_axis_tkeep;
                fifo_last[fifo_wr_ptr] <= s_axis_tlast;
                fifo_id[fifo_wr_ptr] <= s_axis_tid;
                fifo_dest[fifo_wr_ptr] <= s_axis_tdest;
                fifo_user[fifo_wr_ptr] <= s_axis_tuser;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_empty <= 0;
                if (fifo_wr_ptr == fifo_rd_ptr - 1)
                    fifo_full <= 1;
            end
            if (m_axis_tready && !fifo_empty) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_full <= 0;
                if (fifo_wr_ptr == fifo_rd_ptr)
                    fifo_empty <= 1;
            end
        end
    end

    /*
     * Output signals
     */
    assign s_axis_tready = !fifo_full;
    assign m_axis_tdata = fifo_data[fifo_rd_ptr];
    assign m_axis_tkeep = fifo_keep[fifo_rd_ptr];
    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tlast = fifo_last[fifo_rd_ptr];
    assign m_axis_tid = fifo_id[fifo_rd_ptr];
    assign m_axis_tdest = fifo_dest[fifo_rd_ptr];
    assign m_axis_tuser = fifo_user[fifo_rd_ptr];

endmodule

// Asynchronous FIFO Module
module async_fifo #
(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1,
    parameter DEPTH = 4096,
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
    input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
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

    /*
     * Internal signals
     */
    reg [DATA_WIDTH-1:0]            fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]            fifo_keep [0:DEPTH-1];
    reg                             fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]              fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]            fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]            fifo_user [0:DEPTH-1];
    reg [$clog2(DEPTH):0]           s_fifo_wr_ptr;
    reg [$clog2(DEPTH):0]           s_fifo_rd_ptr;
    reg [$clog2(DEPTH):0]           m_fifo_rd_ptr;
    reg [$clog2(DEPTH):0]           s_fifo_depth;
    reg [$clog2(DEPTH):0]           m_fifo_depth;
    reg [$clog2(DEPTH):0]           s_fifo_depth_commit;
    reg [$clog2(DEPTH):0]           m_fifo_depth_commit;
    reg                             s_fifo_full;
    reg                             s_fifo_empty;
    reg                             m_fifo_empty;

    /*
     * FIFO control for slave interface
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_wr_ptr <= 0;
            s_fifo_depth <= 0;
            s_fifo_depth_commit <= 0;
            s_fifo_full <= 0;
            s_fifo_empty <= 1;
        end else begin
            if (s_axis_tvalid && !s_fifo_full) begin
                fifo_data[s_fifo_wr_ptr] <= s_axis_tdata;
                fifo_keep[s_fifo_wr_ptr] <= s_axis_tkeep;
                fifo_last[s_fifo_wr_ptr] <= s_axis_tlast;
                fifo_id[s_fifo_wr_ptr] <= s_axis_tid;
                fifo_dest[s_fifo_wr_ptr] <= s_axis_tdest;
                fifo_user[s_fifo_wr_ptr] <= s_axis_tuser;
                s_fifo_wr_ptr <= s_fifo_wr_ptr + 1;
                s_fifo_depth <= s_fifo_depth + 1;
                s_fifo_empty <= 0;
                if (s_fifo_depth == DEPTH - 1)
                    s_fifo_full <= 1;
            end
            if (m_axis_tready && !s_fifo_empty) begin
                s_fifo_depth_commit <= s_fifo_depth_commit + 1;
                if (s_fifo_depth_commit == s_fifo_depth) begin
                    s_fifo_depth <= s_fifo_depth - 1;
                    s_fifo_depth_commit <= 0;
                end
                if (s_fifo_depth == 1)
                    s_fifo_empty <= 1;
            end
        end
    end

    /*
     * FIFO control for master interface
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_fifo_rd_ptr <= 0;
            m_fifo_depth <= 0;
            m_fifo_empty <= 1;
        end else begin
            if (m_axis_tready && !m_fifo_empty) begin
                m_fifo_rd_ptr <= m_fifo_rd_ptr + 1;
                m_fifo_depth <= m_fifo_depth - 1;
                m_fifo_empty <= 0;
                if (m_fifo_depth == 1)
                    m_fifo_empty <= 1;
            end
        end
    end

    /*
     * Output signals
     */
    assign s_axis_tready = !s_fifo_full;
    assign m_axis_tdata = fifo_data[m_fifo_rd_ptr];
    assign m_axis_tkeep = fifo_keep[m_fifo_rd_ptr];
    assign m_axis_tvalid = !m_fifo_empty;
    assign m_axis_tlast = fifo_last[m_fifo_rd_ptr];
    assign m_axis_tid = fifo_id[m_fifo_rd_ptr];
    assign m_axis_tdest = fifo_dest[m_fifo_rd_ptr];
    assign m_axis_tuser = fifo_user[m_fifo_rd_ptr];

    assign s_status_depth = s_fifo_depth;
    assign s_status_depth_commit = s_fifo_depth_commit;
    assign s_status_overflow = s_fifo_full;
    assign s_status_bad_frame = 1'b0; // Placeholder for bad frame detection
    assign s_status_good_frame = 1'b0; // Placeholder for good frame detection
    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_fifo_depth_commit;
    assign m_status_overflow = s_fifo_full; // Master overflow is same as slave full
    assign m_status_bad_frame = 1'b0; // Placeholder for bad frame detection
    assign m_status_good_frame = 1'b0; // Placeholder for good frame detection

endmodule

// Status Monitor Module
module status_monitor (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [$clog2(DEPTH):0]   fifo_depth,
    input  wire [$clog2(DEPTH):0]   fifo_depth_commit,
    input  wire                     overflow,
    input  wire                     bad_frame,
    input  wire                     good_frame,
    output wire [$clog2(DEPTH):0]   status_depth,
    output wire [$clog2(DEPTH):0]   status_depth_commit,
    output wire                     status_overflow,
    output wire                     status_bad_frame,
    output wire                     status_good_frame
);

    /*
     * Internal signals
     */
    reg [$clog2(DEPTH):0]           status_depth_reg;
    reg [$clog2(DEPTH):0]           status_depth_commit_reg;
    reg                             status_overflow_reg;
    reg                             status_bad_frame_reg;
    reg                             status_good_frame_reg;

    /*
     * Status monitoring
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_depth_reg <= 0;
            status_depth_commit_reg <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            status_depth_reg <= fifo_depth;
            status_depth_commit_reg <= fifo_depth_commit;
            status_overflow_reg <= overflow;
            status_bad_frame_reg <= bad_frame;
            status_good_frame_reg <= good_frame;
        end
    end

    /*
     * Output signals
     */
    assign status_depth = status_depth_reg;
    assign status_depth_commit = status_depth_commit_reg;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

endmodule

// Pause Control Module
module pause_control (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     pause_req,
    output wire                     pause_ack
);

    /*
     * Internal signals
     */
    reg                             pause_ack_reg;

    /*
     * Pause control logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst)
            pause_ack_reg <= 0;
        else
            pause_ack_reg <= pause_req;
    end

    /*
     * Output signals
     */
    assign pause_ack = pause_ack_reg;

endmodule

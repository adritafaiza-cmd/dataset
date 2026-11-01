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
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_DATA_WIDTH-1:0] s_axis_tdata_packed;
    wire [TOTAL_DATA_WIDTH-1:0] m_axis_tdata_packed;

    // Pack input data
    assign s_axis_tdata_packed = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Unpack output data
    assign m_axis_tdata = m_axis_tdata_packed[DATA_WIDTH-1:0];
    assign m_axis_tkeep = (KEEP_ENABLE ? m_axis_tdata_packed[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}});
    assign m_axis_tlast = (LAST_ENABLE ? m_axis_tdata_packed[DATA_WIDTH + KEEP_WIDTH] : 1'b0);
    assign m_axis_tid = (ID_ENABLE ? m_axis_tdata_packed[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1] : {ID_WIDTH{1'b0}});
    assign m_axis_tdest = (DEST_ENABLE ? m_axis_tdata_packed[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH] : {DEST_WIDTH{1'b0}});
    assign m_axis_tuser = (USER_ENABLE ? m_axis_tdata_packed[TOTAL_DATA_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH] : {USER_WIDTH{1'b0}});

    // FIFO pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr;

    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync3;

    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync2;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync3;

    // Synchronizers for pause signals
    reg s_pause_req_sync1;
    reg s_pause_req_sync2;
    reg s_pause_req_sync3;
    reg m_pause_req_sync1;
    reg m_pause_req_sync2;
    reg m_pause_req_sync3;

    // Synchronizers for status flags
    reg s_status_overflow_sync1;
    reg s_status_overflow_sync2;
    reg s_status_overflow_sync3;
    reg s_status_bad_frame_sync1;
    reg s_status_bad_frame_sync2;
    reg s_status_bad_frame_sync3;
    reg s_status_good_frame_sync1;
    reg s_status_good_frame_sync2;
    reg s_status_good_frame_sync3;
    reg m_status_overflow_sync1;
    reg m_status_overflow_sync2;
    reg m_status_overflow_sync3;
    reg m_status_bad_frame_sync1;
    reg m_status_bad_frame_sync2;
    reg m_status_bad_frame_sync3;
    reg m_status_good_frame_sync1;
    reg m_status_good_frame_sync2;
    reg m_status_good_frame_sync3;

    // Status flags
    reg s_status_overflow;
    reg s_status_bad_frame;
    reg s_status_good_frame;
    reg m_status_overflow;
    reg m_status_bad_frame;
    reg m_status_good_frame;

    // Pause ack
    reg s_pause_ack;
    reg m_pause_ack;

    // RAM
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write enable
    wire s_axis_tready_internal;
    wire s_axis_tready_pause;
    wire s_axis_tready_full;
    wire s_axis_tready_drop;
    wire s_axis_tready_mark;
    wire s_axis_tready;

    // Read enable
    wire m_axis_tvalid_internal;
    wire m_axis_tvalid_pause;
    wire m_axis_tvalid;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_wr_ptr_m;
    wire [PTR_WIDTH-1:0] m_rd_ptr_s;
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [TOTAL_DATA_WIDTH-1:0] s_frame_data;
    reg [TOTAL_DATA_WIDTH-1:0] m_frame_data;
    reg s_frame_overflow;
    reg m_frame_overflow;

    // Assign synchronizer outputs
    assign s_wr_ptr_m = s_wr_ptr_sync3;
    assign m_rd_ptr_s = m_rd_ptr_sync3;

    // Depth calculation
    assign s_depth = s_wr_ptr - m_rd_ptr_s;
    assign m_depth = s_wr_ptr_m - m_rd_ptr;

    // Synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync1 <= s_wr_ptr;
            s_wr_ptr_sync2 <= s_wr_ptr_sync1;
            s_wr_ptr_sync3 <= s_wr_ptr_sync2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync1 <= m_rd_ptr;
            m_rd_ptr_sync2 <= m_rd_ptr_sync1;
            m_rd_ptr_sync3 <= m_rd_ptr_sync2;
        end
    end

    // Pause synchronizers
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

    // Status synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_status_overflow_sync1 <= 1'b0;
            s_status_overflow_sync2 <= 1'b0;
            s_status_overflow_sync3 <= 1'b0;
            s_status_bad_frame_sync1 <= 1'b0;
            s_status_bad_frame_sync2 <= 1'b0;
            s_status_bad_frame_sync3 <= 1'b0;
            s_status_good_frame_sync1 <= 1'b0;
            s_status_good_frame_sync2 <= 1'b0;
            s_status_good_frame_sync3 <= 1'b0;
        end else begin
            s_status_overflow_sync1 <= s_status_overflow;
            s_status_overflow_sync2 <= s_status_overflow_sync1;
            s_status_overflow_sync3 <= s_status_overflow_sync2;
            s_status_bad_frame_sync1 <= s_status_bad_frame;
            s_status_bad_frame_sync2 <= s_status_bad_frame_sync1;
            s_status_bad_frame_sync3 <= s_status_bad_frame_sync2;
            s_status_good_frame_sync1 <= s_status_good_frame;
            s_status_good_frame_sync2 <= s_status_good_frame_sync1;
            s_status_good_frame_sync3 <= s_status_good_frame_sync2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_status_overflow_sync1 <= 1'b0;
            m_status_overflow_sync2 <= 1'b0;
            m_status_overflow_sync3 <= 1'b0;
            m_status_bad_frame_sync1 <= 1'b0;
            m_status_bad_frame_sync2 <= 1'b0;
            m_status_bad_frame_sync3 <= 1'b0;
            m_status_good_frame_sync1 <= 1'b0;
            m_status_good_frame_sync2 <= 1'b0;
            m_status_good_frame_sync3 <= 1'b0;
        end else begin
            m_status_overflow_sync1 <= m_status_overflow;
            m_status_overflow_sync2 <= m_status_overflow_sync1;
            m_status_overflow_sync3 <= m_status_overflow_sync2;
            m_status_bad_frame_sync1 <= m_status_bad_frame;
            m_status_bad_frame_sync2 <= m_status_bad_frame_sync1;
            m_status_bad_frame_sync3 <= m_status_bad_frame_sync2;
            m_status_good_frame_sync1 <= m_status_good_frame;
            m_status_good_frame_sync2 <= m_status_good_frame_sync1;
            m_status_good_frame_sync3 <= m_status_good_frame_sync2;
        end
    end

    // Pause ack logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 1'b0;
        end else begin
            if (s_pause_req) begin
                s_pause_ack <= 1'b1;
            end else begin
                s_pause_ack <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 1'b0;
        end else begin
            if (m_pause_req) begin
                m_pause_ack <= 1'b1;
            end else begin
                m_pause_ack <= 1'b0;
            end
        end
    end

    // Status flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow <= 1'b0;
            s_status_bad_frame <= 1'b0;
            s_status_good_frame <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && s_depth >= DEPTH) begin
                s_status_overflow <= 1'b1;
            end
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    s_status_bad_frame <= 1'b1;
                end else begin
                    s_status_good_frame <= 1'b1;
                end
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow <= 1'b0;
            m_status_bad_frame <= 1'b0;
            m_status_good_frame <= 1'b0;
        end else begin
            if (m_axis_tvalid && m_axis_tready && m_depth >= DEPTH) begin
                m_status_overflow <= 1'b1;
            end
            if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                if (DROP_BAD_FRAME && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_status_bad_frame <= 1'b1;
                end else begin
                    m_status_good_frame <= 1'b1;
                end
            end
        end
    end

    // Write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // RAM write
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            ram[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata_packed;
        end
    end

    // RAM read
    wire [TOTAL_DATA_WIDTH-1:0] ram_read_data;
    assign ram_read_data = ram[m_rd_ptr[ADDR_WIDTH-1:0]];

    assign m_axis_tdata_packed = ram_read_data;

    // Tready logic
    wire s_full;
    wire s_empty;
    assign s_full = (s_depth >= DEPTH);
    assign s_empty = (s_depth == 0);

    assign s_axis_tready_full = !s_full;
    assign s_axis_tready_pause = (PAUSE_ENABLE ? !s_pause_req : 1'b1);
    assign s_axis_tready_drop = (DROP_WHEN_FULL ? 1'b1 : 1'b0);
    assign s_axis_tready_mark = (MARK_WHEN_FULL ? 1'b1 : 1'b0);
    assign s_axis_tready_internal = s_axis_tready_full | s_axis_tready_drop | s_axis_tready_mark;
    assign s_axis_tready = s_axis_tready_internal & s_axis_tready_pause;

    // Tvalid logic
    assign m_axis_tvalid_internal = !s_empty;
    assign m_axis_tvalid_pause = (PAUSE_ENABLE ? !m_pause_req : 1'b1);
    assign m_axis_tvalid = m_axis_tvalid_internal & m_axis_tvalid_pause;

    // Status depth
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Status flags output
    assign s_status_overflow = s_status_overflow_sync3;
    assign s_status_bad_frame = s_status_bad_frame_sync3;
    assign s_status_good_frame = s_status_good_frame_sync3;
    assign m_status_overflow = m_status_overflow_sync3;
    assign m_status_bad_frame = m_status_bad_frame_sync3;
    assign m_status_good_frame = m_status_good_frame_sync3;

endmodule

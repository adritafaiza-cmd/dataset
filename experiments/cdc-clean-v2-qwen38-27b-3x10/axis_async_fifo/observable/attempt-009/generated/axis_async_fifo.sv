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

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // RAM storage
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] wr_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] rd_ptr;

    // Synchronizers
    reg [PTR_WIDTH-1:0] wr_ptr_sync1, wr_ptr_sync2, wr_ptr_sync3;
    reg [PTR_WIDTH-1:0] rd_ptr_sync1, rd_ptr_sync2, rd_ptr_sync3;

    // Pause synchronizers
    reg s_pause_req_sync1, s_pause_req_sync2;
    reg m_pause_req_sync1, m_pause_req_sync2;

    // Frame tracking (s_clk domain)
    reg in_frame;
    reg frame_overflow;
    reg frame_bad;
    reg frame_good;

    // Frame tracking (m_clk domain)
    reg m_in_frame;
    reg m_frame_overflow;
    reg m_frame_bad;
    reg m_frame_good;

    // Status latches
    reg s_overflow_latch;
    reg s_bad_frame_latch;
    reg s_good_frame_latch;
    reg m_overflow_latch;
    reg m_bad_frame_latch;
    reg m_good_frame_latch;

    // Write enable
    wire s_write_en;
    wire s_full;
    wire s_empty;
    wire m_full;
    wire m_empty;

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Read data
    wire [TOTAL_DATA_WIDTH-1:0] rd_data;
    wire [ADDR_WIDTH-1:0] rd_addr;

    // Output register
    reg [TOTAL_DATA_WIDTH-1:0] out_reg;
    reg out_valid;

    // Frame drop logic
    wire drop_current;
    wire mark_current;

    // Pause logic
    wire s_paused;
    wire m_paused;

    // Write pointer sync to m_clk
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync1 <= wr_ptr;
            wr_ptr_sync2 <= wr_ptr_sync1;
            wr_ptr_sync3 <= wr_ptr_sync2;
        end
    end

    // Read pointer sync to s_clk
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync1 <= rd_ptr;
            rd_ptr_sync2 <= rd_ptr_sync1;
            rd_ptr_sync3 <= rd_ptr_sync2;
        end
    end

    // Pause request sync
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_pause_req_sync1 <= 1'b0;
            s_pause_req_sync2 <= 1'b0;
        end else begin
            s_pause_req_sync1 <= s_pause_req;
            s_pause_req_sync2 <= s_pause_req_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_pause_req_sync1 <= 1'b0;
            m_pause_req_sync2 <= 1'b0;
        end else begin
            m_pause_req_sync1 <= m_pause_req;
            m_pause_req_sync2 <= m_pause_req_sync1;
        end
    end

    // Depth calculations
    assign s_depth = wr_ptr - rd_ptr_sync3;
    assign m_depth = wr_ptr_sync3 - rd_ptr;

    // Full/Empty
    assign s_full = (s_depth >= DEPTH);
    assign s_empty = (s_depth == 0);
    assign m_full = (m_depth >= DEPTH);
    assign m_empty = (m_depth == 0);

    // Pause logic
    assign s_paused = (PAUSE_ENABLE && s_pause_req_sync2);
    assign m_paused = (PAUSE_ENABLE && m_pause_req_sync2);

    // Frame drop/mark logic
    wire drop_oversize = (DROP_OVERSIZE_FRAME && in_frame && s_full && !s_axis_tlast);
    wire drop_bad = (DROP_BAD_FRAME && frame_bad && in_frame);
    wire drop_when_full = (DROP_WHEN_FULL && s_full);
    wire mark_when_full = (MARK_WHEN_FULL && s_full);

    assign drop_current = drop_oversize || drop_bad || drop_when_full;
    assign mark_current = mark_when_full;

    // Write enable
    assign s_write_en = s_axis_tvalid && s_axis_tready && !drop_current;

    // tready logic
    assign s_axis_tready = !s_full && !s_paused && !drop_oversize && !drop_bad;

    // Write to RAM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
            in_frame <= 1'b0;
            frame_overflow <= 1'b0;
            frame_bad <= 1'b0;
            frame_good <= 1'b0;
            s_overflow_latch <= 1'b0;
            s_bad_frame_latch <= 1'b0;
            s_good_frame_latch <= 1'b0;
        end else begin
            if (s_write_en) begin
                ram[wr_ptr[ADDR_WIDTH-1:0]] <= {
                    s_axis_tdata,
                    s_axis_tkeep,
                    s_axis_tlast,
                    s_axis_tid,
                    s_axis_tdest,
                    s_axis_tuser
                };
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Frame tracking
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    in_frame <= 1'b0;
                    if (frame_overflow) begin
                        frame_overflow <= 1'b0;
                        s_overflow_latch <= 1'b1;
                    end
                    if (frame_bad) begin
                        frame_bad <= 1'b0;
                        s_bad_frame_latch <= 1'b1;
                    end
                    if (!frame_overflow && !frame_bad) begin
                        s_good_frame_latch <= 1'b1;
                    end
                end else begin
                    in_frame <= 1'b1;
                    if (s_full) begin
                        frame_overflow <= 1'b1;
                    end
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        frame_bad <= 1'b1;
                    end
                end
            end
        end
    end

    // Read address
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];
    assign rd_data = ram[rd_addr];

    // Read pointer and output logic (m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= {PTR_WIDTH{1'b0}};
            out_valid <= 1'b0;
            out_reg <= {TOTAL_DATA_WIDTH{1'b0}};
            m_in_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
            m_frame_bad <= 1'b0;
            m_frame_good <= 1'b0;
            m_overflow_latch <= 1'b0;
            m_bad_frame_latch <= 1'b0;
            m_good_frame_latch <= 1'b0;
        end else begin
            // Read from RAM
            if (m_axis_tvalid && m_axis_tready) begin
                // Pop from output
                out_valid <= 1'b0;
                rd_ptr <= rd_ptr + 1'b1;

                // Frame tracking on pop
                if (out_reg[DATA_WIDTH+KEEP_WIDTH]) begin
                    // tlast
                    m_in_frame <= 1'b0;
                    if (m_frame_overflow) begin
                        m_frame_overflow <= 1'b0;
                        m_overflow_latch <= 1'b1;
                    end
                    if (m_frame_bad) begin
                        m_frame_bad <= 1'b0;
                        m_bad_frame_latch <= 1'b1;
                    end
                    if (!m_frame_overflow && !m_frame_bad) begin
                        m_good_frame_latch <= 1'b1;
                    end
                end else begin
                    m_in_frame <= 1'b1;
                end
            end

            // Load new data into output
            if (!out_valid && !m_empty && !m_paused) begin
                out_reg <= rd_data;
                out_valid <= 1'b1;

                // Track frame state for output
                if (rd_data[DATA_WIDTH+KEEP_WIDTH]) begin
                    // This is a tlast beat
                    if (m_frame_overflow) begin
                        m_frame_overflow <= 1'b0;
                        m_overflow_latch <= 1'b1;
                    end
                    if (m_frame_bad) begin
                        m_frame_bad <= 1'b0;
                        m_bad_frame_latch <= 1'b1;
                    end
                    if (!m_frame_overflow && !m_frame_bad) begin
                        m_good_frame_latch <= 1'b1;
                    end
                    m_in_frame <= 1'b0;
                end else begin
                    m_in_frame <= 1'b1;
                    if (USER_ENABLE && (rd_data[TOTAL_DATA_WIDTH-1-USER_WIDTH+USER_WIDTH-1 -: USER_WIDTH] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        m_frame_bad <= 1'b1;
                    end
                end
            end
        end
    end

    // Output assignments
    assign m_axis_tdata = out_reg[DATA_WIDTH-1:0];
    assign m_axis_tkeep = out_reg[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = out_reg[DATA_WIDTH+KEEP_WIDTH];
    assign m_axis_tid = out_reg[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1];
    assign m_axis_tdest = out_reg[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH];
    assign m_axis_tuser = out_reg[TOTAL_DATA_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH];
    assign m_axis_tvalid = out_valid;

    // Pause ack
    assign s_pause_ack = s_pause_req_sync2;
    assign m_pause_ack = m_pause_req_sync2;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_latch;
    assign s_status_bad_frame = s_bad_frame_latch;
    assign s_status_good_frame = s_good_frame_latch;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow_latch;
    assign m_status_bad_frame = m_bad_frame_latch;
    assign m_status_good_frame = m_good_frame_latch;

endmodule

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

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // RAM storage
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] wr_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] rd_ptr;

    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] rd_ptr_sync1, rd_ptr_sync2, rd_ptr_sync3;
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

    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] wr_ptr_sync1, wr_ptr_sync2, wr_ptr_sync3;
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

    // Compute depth in each domain
    wire [PTR_WIDTH-1:0] s_depth = wr_ptr - rd_ptr_sync3;
    wire [PTR_WIDTH-1:0] m_depth = wr_ptr_sync3 - rd_ptr;

    // Full/Empty conditions
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    reg s_pause_active;
    reg m_pause_active;
    wire s_pause = PAUSE_ENABLE ? (s_pause_req | s_pause_active) : 1'b0;
    wire m_pause = PAUSE_ENABLE ? (m_pause_req | m_pause_active) : 1'b0;

    // Synchronizers for pause requests
    reg s_pause_req_sync1, s_pause_req_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_pause_req_sync1 <= 1'b0;
            s_pause_req_sync2 <= 1'b0;
        end else begin
            s_pause_req_sync1 <= s_pause_req;
            s_pause_req_sync2 <= s_pause_req_sync1;
        end
    end

    reg m_pause_req_sync1, m_pause_req_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_pause_req_sync1 <= 1'b0;
            m_pause_req_sync2 <= 1'b0;
        end else begin
            m_pause_req_sync1 <= m_pause_req;
            m_pause_req_sync2 <= m_pause_req_sync1;
        end
    end

    // Pause ack logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_active <= 1'b0;
        end else if (s_pause_req) begin
            s_pause_active <= 1'b1;
        end else if (s_depth == 0) begin
            s_pause_active <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_active <= 1'b0;
        end else if (m_pause_req) begin
            m_pause_active <= 1'b1;
        end else if (m_depth == 0) begin
            m_pause_active <= 1'b0;
        end
    end

    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;

    // Frame tracking in s_clk domain
    reg s_in_frame;
    reg s_frame_overflow;
    reg s_frame_bad;
    reg s_frame_good;

    // Frame tracking in m_clk domain
    reg m_in_frame;
    reg m_frame_overflow;
    reg m_frame_bad;
    reg m_frame_good;

    // Write enable
    wire s_write_en = s_axis_tvalid & s_axis_tready & ~s_pause;
    wire s_can_write = ~s_full & ~s_pause;

    // Handle drop/mark when full
    wire s_drop_when_full = DROP_WHEN_FULL & s_full & s_axis_tvalid;
    wire s_mark_when_full = MARK_WHEN_FULL & s_full & s_axis_tvalid;

    // Frame FIFO logic
    wire s_frame_overflow_drop = FRAME_FIFO & s_in_frame & s_full & s_axis_tvalid;
    wire s_frame_bad_drop = FRAME_FIFO & s_in_frame & s_frame_bad & s_axis_tvalid;

    // Determine if we should accept the beat
    wire s_accept = s_axis_tvalid & s_can_write & ~s_drop_when_full & ~s_frame_overflow_drop & ~s_frame_bad_drop;

    // tready
    assign s_axis_tready = s_can_write & ~s_drop_when_full & ~s_frame_overflow_drop & ~s_frame_bad_drop;

    // Write to RAM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
            s_in_frame <= 1'b0;
            s_frame_overflow <= 1'b0;
            s_frame_bad <= 1'b0;
            s_frame_good <= 1'b0;
        end else begin
            if (s_accept) begin
                ram[wr_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
                wr_ptr <= wr_ptr + 1'b1;

                // Frame tracking
                if (FRAME_FIFO) begin
                    if (s_in_frame) begin
                        if (s_axis_tlast) begin
                            s_in_frame <= 1'b0;
                            // Check for bad frame
                            if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                                s_frame_bad <= 1'b1;
                            end else begin
                                s_frame_good <= 1'b1;
                            end
                        end
                    end else begin
                        s_in_frame <= 1'b1;
                    end
                end
            end else if (s_drop_when_full || s_frame_overflow_drop || s_frame_bad_drop) begin
                // Drop the beat
                if (FRAME_FIFO) begin
                    if (s_in_frame) begin
                        if (s_axis_tlast) begin
                            s_in_frame <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    // Read enable
    wire m_read_en = m_axis_tvalid & m_axis_tready & ~m_pause;

    // Read from RAM
    wire [TOTAL_DATA_WIDTH-1:0] m_ram_data;
    wire [ADDR_WIDTH-1:0] m_rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    assign m_ram_data = ram[m_rd_addr];

    // Output FIFO logic
    reg [TOTAL_DATA_WIDTH-1:0] m_out_fifo [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] m_out_wr_ptr, m_out_rd_ptr;
    reg [PTR_WIDTH-1:0] m_out_wr_ptr_sync1, m_out_wr_ptr_sync2, m_out_wr_ptr_sync3;
    reg [PTR_WIDTH-1:0] m_out_rd_ptr_sync1, m_out_rd_ptr_sync2, m_out_rd_ptr_sync3;

    // For simplicity, we'll use a direct read approach without output FIFO
    // The output FIFO is optional and can be added if needed

    // Read from RAM and output
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= {PTR_WIDTH{1'b0}};
            m_in_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
            m_frame_bad <= 1'b0;
            m_frame_good <= 1'b0;
        end else begin
            if (m_read_en) begin
                rd_ptr <= rd_ptr + 1'b1;

                // Frame tracking
                if (FRAME_FIFO) begin
                    if (m_in_frame) begin
                        if (m_ram_data[DATA_WIDTH+KEEP_WIDTH]) begin
                            m_in_frame <= 1'b0;
                            // Check for bad frame
                            if (USER_ENABLE && (m_ram_data[TOTAL_DATA_WIDTH-1:TOTAL_DATA_WIDTH-USER_WIDTH] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                                m_frame_bad <= 1'b1;
                            end else begin
                                m_frame_good <= 1'b1;
                            end
                        end
                    end else begin
                        m_in_frame <= 1'b1;
                    end
                end
            end
        end
    end

    // Output signals
    assign m_axis_tdata = m_ram_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_ram_data[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = m_ram_data[DATA_WIDTH+KEEP_WIDTH];
    assign m_axis_tid = m_ram_data[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1];
    assign m_axis_tdest = m_ram_data[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH];
    assign m_axis_tuser = m_ram_data[TOTAL_DATA_WIDTH-1:TOTAL_DATA_WIDTH-USER_WIDTH];

    assign m_axis_tvalid = ~m_empty & ~m_pause;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_drop_when_full | s_frame_overflow_drop;
    assign s_status_bad_frame = s_frame_bad;
    assign s_status_good_frame = s_frame_good;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = m_frame_bad;
    assign m_status_good_frame = m_frame_good;

endmodule

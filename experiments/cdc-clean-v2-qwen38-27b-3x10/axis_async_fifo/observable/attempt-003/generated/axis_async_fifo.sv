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
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                                   (LAST_ENABLE ? 1 : 0) + 
                                   (ID_ENABLE ? ID_WIDTH : 0) + 
                                   (DEST_ENABLE ? DEST_WIDTH : 0) + 
                                   (USER_ENABLE ? USER_WIDTH : 0);

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

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth = wr_ptr - rd_ptr_sync3;
    wire [PTR_WIDTH-1:0] m_depth = wr_ptr_sync3 - rd_ptr;

    // Full and empty conditions
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    reg s_paused, m_paused;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_paused <= 1'b0;
        else if (PAUSE_ENABLE) s_paused <= s_pause_req;
        else s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_paused <= 1'b0;
        else if (PAUSE_ENABLE) m_paused <= m_pause_req;
        else m_paused <= 1'b0;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Frame tracking for FRAME_FIFO
    reg s_in_frame;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_in_frame <= 1'b0;
        else if (s_axis_tvalid && s_axis_tready) begin
            if (s_axis_tlast) s_in_frame <= 1'b0;
            else s_in_frame <= 1'b1;
        end
    end

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready && !s_paused;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready && !m_paused;

    // Output register
    reg [TOTAL_DATA_WIDTH-1:0] out_reg;
    reg out_valid;

    // RAM read address
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // RAM read
    reg [TOTAL_DATA_WIDTH-1:0] ram_rd_data;
    always @(posedge m_clk) begin
        ram_rd_data <= ram[rd_addr];
    end

    // Output valid logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_valid <= 1'b0;
            out_reg <= {TOTAL_DATA_WIDTH{1'b0}};
        end else begin
            if (m_read_en) begin
                out_valid <= 1'b0;
            end else if (!out_valid && !m_empty) begin
                out_valid <= 1'b1;
                out_reg <= ram_rd_data;
            end
        end
    end

    // Output signals
    assign m_axis_tdata = out_reg[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? out_reg[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1:
                                    DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1:
                                       DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? out_reg[TOTAL_DATA_WIDTH-1:
                                                 DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] : {USER_WIDTH{1'b0}};
    assign m_axis_tvalid = out_valid;

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_write_en) wr_ptr <= wr_ptr + 1'b1;
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (m_read_en) rd_ptr <= rd_ptr + 1'b1;
    end

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram[wr_ptr[ADDR_WIDTH-1:0]] <= {
                (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
                (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
                (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
                (LAST_ENABLE ? s_axis_tlast : 1'b0),
                (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
                s_axis_tdata
            };
        end
    end

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow and frame status (simplified)
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_full && !s_paused) s_overflow <= 1'b1;
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                s_good_frame <= 1'b1;
                s_bad_frame <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_read_en && m_axis_tlast) begin
                m_good_frame <= 1'b1;
                m_bad_frame <= 1'b0;
            end
        end
    end

    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Ready signal
    assign s_axis_tready = !s_full && !s_paused;

endmodule

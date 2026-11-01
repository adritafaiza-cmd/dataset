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
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // Internal signals
    reg [TOTAL_DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;

    // Pause synchronizers
    reg s_pause_req_sync1, s_pause_req_sync2;
    reg m_pause_req_sync1, m_pause_req_sync2;

    // Status flags
    reg s_overflow;
    reg m_overflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [USER_WIDTH-1:0] s_frame_user;
    reg [USER_WIDTH-1:0] m_frame_user;

    // Write enable
    wire s_write_en;
    // Read enable
    wire m_read_en;

    // Full/Empty detection
    wire s_full;
    wire m_empty;

    // Committed depth
    wire [PTR_WIDTH-1:0] s_committed_depth;
    wire [PTR_WIDTH-1:0] m_committed_depth;

    // Current depth
    wire [PTR_WIDTH-1:0] s_current_depth;
    wire [PTR_WIDTH-1:0] m_current_depth;

    // Pause logic
    wire s_paused;
    wire m_paused;

    // Frame pause logic
    wire s_frame_paused;
    wire m_frame_paused;

    // Drop/mark logic
    wire s_drop;
    wire s_mark;
    wire m_drop;
    wire m_mark;

    // Output FIFO logic
    reg [TOTAL_DATA_WIDTH-1:0] out_fifo [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] out_w_ptr;
    reg [PTR_WIDTH-1:0] out_r_ptr;
    reg [PTR_WIDTH-1:0] out_w_ptr_sync1, out_w_ptr_sync2, out_w_ptr_sync3;
    reg [PTR_WIDTH-1:0] out_r_ptr_sync1, out_r_ptr_sync2, out_r_ptr_sync3;
    wire out_full;
    wire out_empty;
    wire [TOTAL_DATA_WIDTH-1:0] out_data;

    // RAM pipeline
    reg [TOTAL_DATA_WIDTH-1:0] ram_pipe_reg;
    reg ram_pipe_valid;

    // Assignments
    assign s_axis_tready = ~s_full & ~s_paused & ~s_frame_paused & ~s_drop;
    assign s_pause_ack = s_pause_req_sync2;
    assign m_pause_ack = m_pause_req_sync2;

    assign s_status_depth = s_current_depth;
    assign s_status_depth_commit = s_committed_depth;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_current_depth;
    assign m_status_depth_commit = m_committed_depth;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Full/Empty
    assign s_full = (w_ptr[PTR_WIDTH-1] == r_ptr_sync3[PTR_WIDTH-1]) && 
                    (w_ptr[ADDR_WIDTH-1:0] == r_ptr_sync3[ADDR_WIDTH-1:0]);
    assign m_empty = (r_ptr == w_ptr_sync3);

    // Depth calculations
    assign s_current_depth = w_ptr - r_ptr_sync3;
    assign m_current_depth = w_ptr_sync3 - r_ptr;

    // Committed depth (using synchronized pointers)
    assign s_committed_depth = w_ptr - r_ptr_sync3;
    assign m_committed_depth = w_ptr_sync3 - r_ptr;

    // Pause logic
    assign s_paused = PAUSE_ENABLE ? s_pause_req_sync2 : 1'b0;
    assign m_paused = PAUSE_ENABLE ? m_pause_req_sync2 : 1'b0;

    // Frame pause logic
    assign s_frame_paused = FRAME_PAUSE ? (s_in_frame && s_pause_req_sync2) : 1'b0;
    assign m_frame_paused = FRAME_PAUSE ? (m_in_frame && m_pause_req_sync2) : 1'b0;

    // Drop/mark logic
    assign s_drop = (DROP_WHEN_FULL && s_full) || 
                    (DROP_OVERSIZE_FRAME && s_in_frame && s_axis_tlast) ||
                    (DROP_BAD_FRAME && s_bad_frame);
    assign s_mark = MARK_WHEN_FULL && s_full;
    assign m_drop = 1'b0;
    assign m_mark = 1'b0;

    // Write enable
    assign s_write_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    assign m_read_en = m_axis_tready & m_axis_tvalid;

    // Synchronizers for write pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end

    // Synchronizers for read pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end

    // Synchronizers for pause requests
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req_sync1 <= 1'b0;
            s_pause_req_sync2 <= 1'b0;
        end else begin
            s_pause_req_sync1 <= s_pause_req;
            s_pause_req_sync2 <= s_pause_req_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req_sync1 <= 1'b0;
            m_pause_req_sync2 <= 1'b0;
        end else begin
            m_pause_req_sync1 <= m_pause_req;
            m_pause_req_sync2 <= m_pause_req_sync1;
        end
    end

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            w_ptr <= w_ptr + 1'b1;
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // Memory write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // No action needed for memory
        end else if (s_write_en) begin
            mem[w_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
        end
    end

    // Memory read
    wire [TOTAL_DATA_WIDTH-1:0] mem_read_data;
    assign mem_read_data = mem[r_ptr[ADDR_WIDTH-1:0]];

    // RAM pipeline
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            ram_pipe_reg <= {TOTAL_DATA_WIDTH{1'b0}};
            ram_pipe_valid <= 1'b0;
        end else if (RAM_PIPELINE) begin
            ram_pipe_reg <= mem_read_data;
            ram_pipe_valid <= ~m_empty;
        end else begin
            ram_pipe_reg <= mem_read_data;
            ram_pipe_valid <= ~m_empty;
        end
    end

    // Output FIFO logic
    wire out_write_en;
    wire out_read_en;
    wire [TOTAL_DATA_WIDTH-1:0] out_fifo_data;

    assign out_write_en = m_read_en;
    assign out_read_en = m_axis_tready & m_axis_tvalid;
    assign out_full = (out_w_ptr[PTR_WIDTH-1] == out_r_ptr_sync3[PTR_WIDTH-1]) && 
                      (out_w_ptr[ADDR_WIDTH-1:0] == out_r_ptr_sync3[ADDR_WIDTH-1:0]);
    assign out_empty = (out_r_ptr == out_w_ptr_sync3);
    assign out_data = out_fifo[out_r_ptr[ADDR_WIDTH-1:0]];

    // Output FIFO write
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_w_ptr <= {PTR_WIDTH{1'b0}};
        end else if (out_write_en) begin
            out_fifo[out_w_ptr[ADDR_WIDTH-1:0]] <= ram_pipe_reg;
            out_w_ptr <= out_w_ptr + 1'b1;
        end
    end

    // Output FIFO read
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (out_read_en) begin
            out_r_ptr <= out_r_ptr + 1'b1;
        end
    end

    // Output FIFO synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            out_w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            out_w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            out_w_ptr_sync1 <= out_w_ptr;
            out_w_ptr_sync2 <= out_w_ptr_sync1;
            out_w_ptr_sync3 <= out_w_ptr_sync2;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            out_r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            out_r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            out_r_ptr_sync1 <= out_r_ptr;
            out_r_ptr_sync2 <= out_r_ptr_sync1;
            out_r_ptr_sync3 <= out_r_ptr_sync2;
        end
    end

    // Output data assignment
    wire [TOTAL_DATA_WIDTH-1:0] final_out_data;
    assign final_out_data = OUTPUT_FIFO_ENABLE ? out_data : ram_pipe_reg;

    // Output signals
    assign m_axis_tdata = final_out_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = final_out_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = final_out_data[DATA_WIDTH + KEEP_WIDTH];
    assign m_axis_tid = final_out_data[DATA_WIDTH + KEEP_WIDTH + 1 +: ID_WIDTH];
    assign m_axis_tdest = final_out_data[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH +: DEST_WIDTH];
    assign m_axis_tuser = final_out_data[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH +: USER_WIDTH];

    // Output valid
    assign m_axis_tvalid = OUTPUT_FIFO_ENABLE ? ~out_empty : ~m_empty;

    // Frame tracking in s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_user <= {USER_WIDTH{1'b0}};
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_write_en) begin
                if (!s_in_frame) begin
                    s_in_frame <= 1'b1;
                    s_frame_user <= s_axis_tuser;
                end
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    if (s_mark) begin
                        s_bad_frame <= 1'b1;
                    end else begin
                        s_good_frame <= 1'b1;
                    end
                end
            end
            if (s_full && s_axis_tvalid) begin
                s_overflow <= 1'b1;
            end
        end
    end

    // Frame tracking in m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_user <= {USER_WIDTH{1'b0}};
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_read_en) begin
                if (!m_in_frame) begin
                    m_in_frame <= 1'b1;
                    m_frame_user <= final_out_data[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH +: USER_WIDTH];
                end
                if (final_out_data[DATA_WIDTH + KEEP_WIDTH]) begin
                    m_in_frame <= 1'b0;
                    if (m_mark) begin
                        m_bad_frame <= 1'b1;
                    end else begin
                        m_good_frame <= 1'b1;
                    end
                end
            end
            if (m_empty && m_axis_tready) begin
                m_overflow <= 1'b0;
            end
        end
    end

endmodule

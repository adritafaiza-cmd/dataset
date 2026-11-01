module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
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
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] rd_ptr_commit;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Pipeline registers for RAM read
    reg [DATA_WIDTH-1:0] pipe_data;
    reg [KEEP_WIDTH-1:0] pipe_keep;
    reg                  pipe_last;
    reg [ID_WIDTH-1:0]   pipe_id;
    reg [DEST_WIDTH-1:0] pipe_dest;
    reg [USER_WIDTH-1:0] pipe_user;
    reg                  pipe_valid;

    // Output FIFO (if enabled)
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg                  out_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   out_fifo_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   out_wr_ptr;
    reg [ADDR_WIDTH:0]   out_rd_ptr;

    // Frame tracking
    reg                  in_frame;
    reg [ADDR_WIDTH:0]   frame_start_ptr;
    reg                  frame_bad;
    reg                  frame_oversize;

    // Status latches
    reg                  status_overflow_reg;
    reg                  status_bad_frame_reg;
    reg                  status_good_frame_reg;

    // Pause logic
    reg                  pause_active;

    // Derived signals
    wire [ADDR_WIDTH:0] depth = wr_ptr - rd_ptr;
    wire [ADDR_WIDTH:0] depth_commit = wr_ptr - rd_ptr_commit;
    wire                full = (depth == DEPTH);
    wire                empty = (depth == 0);

    // Handshake signals
    wire                s_axis_tready_int;
    wire                m_axis_tvalid_int;
    wire                m_axis_tready_int;

    // Write enable
    wire                wr_en;
    // Read enable
    wire                rd_en;

    // Frame drop logic
    wire                drop_frame;
    wire                mark_frame;

    // Pause logic
    wire                pause_block;

    // Calculate pause block
    assign pause_block = PAUSE_ENABLE && pause_active;

    // Frame drop decision
    assign drop_frame = (DROP_OVERSIZE_FRAME && frame_oversize) || 
                        (DROP_BAD_FRAME && frame_bad);

    // Mark when full
    assign mark_frame = MARK_WHEN_FULL && full;

    // Write enable: accept data if not full, not paused, and not dropping
    assign wr_en = s_axis_tvalid && s_axis_tready_int && !pause_block;

    // Read enable: output valid and ready
    assign rd_en = m_axis_tvalid_int && m_axis_tready_int;

    // Input ready
    assign s_axis_tready_int = !full && !pause_block;
    assign s_axis_tready = s_axis_tready_int;

    // Output valid
    assign m_axis_tvalid_int = !empty;
    assign m_axis_tvalid = m_axis_tvalid_int;

    // Output ready
    assign m_axis_tready_int = m_axis_tready;

    // Pause acknowledge
    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    // Status outputs
    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Output data
    assign m_axis_tdata = OUTPUT_FIFO_ENABLE ? out_fifo_data[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_data;
    assign m_axis_tkeep = OUTPUT_FIFO_ENABLE ? out_fifo_keep[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_keep;
    assign m_axis_tlast = OUTPUT_FIFO_ENABLE ? out_fifo_last[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_last;
    assign m_axis_tid   = OUTPUT_FIFO_ENABLE ? out_fifo_id[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_id;
    assign m_axis_tdest = OUTPUT_FIFO_ENABLE ? out_fifo_dest[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_dest;
    assign m_axis_tuser = OUTPUT_FIFO_ENABLE ? out_fifo_user[out_rd_ptr[ADDR_WIDTH-1:0]] : pipe_user;

    // RAM read address
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // RAM write address
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];

    // Pipeline read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipe_data  <= {DATA_WIDTH{1'b0}};
            pipe_keep  <= {KEEP_WIDTH{1'b0}};
            pipe_last  <= 1'b0;
            pipe_id    <= {ID_WIDTH{1'b0}};
            pipe_dest  <= {DEST_WIDTH{1'b0}};
            pipe_user  <= {USER_WIDTH{1'b0}};
            pipe_valid <= 1'b0;
        end else begin
            if (rd_en) begin
                pipe_data  <= ram_data[rd_addr];
                pipe_keep  <= ram_keep[rd_addr];
                pipe_last  <= ram_last[rd_addr];
                pipe_id    <= ram_id[rd_addr];
                pipe_dest  <= ram_dest[rd_addr];
                pipe_user  <= ram_user[rd_addr];
                pipe_valid <= 1'b1;
            end else if (!empty) begin
                pipe_valid <= 1'b1;
            end else begin
                pipe_valid <= 1'b0;
            end
        end
    end

    // RAM write
    always @(posedge clk) begin
        if (wr_en) begin
            ram_data[wr_addr] <= s_axis_tdata;
            ram_keep[wr_addr] <= s_axis_tkeep;
            ram_last[wr_addr] <= s_axis_tlast;
            ram_id[wr_addr]   <= s_axis_tid;
            ram_dest[wr_addr] <= s_axis_tdest;
            ram_user[wr_addr] <= s_axis_tuser;
        end
    end

    // Write pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (wr_en) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Read pointer commit (for depth_commit)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr_commit <= {(ADDR_WIDTH+1){1'b0}};
        end else if (rd_en) begin
            rd_ptr_commit <= rd_ptr_commit + 1'b1;
        end
    end

    // Output FIFO write
    always @(posedge clk) begin
        if (rd_en && OUTPUT_FIFO_ENABLE) begin
            out_fifo_data[out_wr_ptr[ADDR_WIDTH-1:0]] <= pipe_data;
            out_fifo_keep[out_wr_ptr[ADDR_WIDTH-1:0]] <= pipe_keep;
            out_fifo_last[out_wr_ptr[ADDR_WIDTH-1:0]] <= pipe_last;
            out_fifo_id[out_wr_ptr[ADDR_WIDTH-1:0]]   <= pipe_id;
            out_fifo_dest[out_wr_ptr[ADDR_WIDTH-1:0]] <= pipe_dest;
            out_fifo_user[out_wr_ptr[ADDR_WIDTH-1:0]] <= pipe_user;
        end
    end

    // Output FIFO pointers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
            out_rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (rd_en && OUTPUT_FIFO_ENABLE) begin
                out_wr_ptr <= out_wr_ptr + 1'b1;
            end
            if (m_axis_tvalid && m_axis_tready && OUTPUT_FIFO_ENABLE) begin
                out_rd_ptr <= out_rd_ptr + 1'b1;
            end
        end
    end

    // Frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame        <= 1'b0;
            frame_start_ptr <= {(ADDR_WIDTH+1){1'b0}};
            frame_bad       <= 1'b0;
            frame_oversize  <= 1'b0;
        end else begin
            if (wr_en) begin
                if (!in_frame) begin
                    in_frame        <= 1'b1;
                    frame_start_ptr <= wr_ptr;
                    frame_bad       <= 1'b0;
                    frame_oversize  <= 1'b0;
                end else begin
                    // Check for bad frame
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        frame_bad <= 1'b1;
                    end
                    // Check for oversize frame
                    if (FRAME_FIFO) begin
                        if ((wr_ptr - frame_start_ptr) >= DEPTH) begin
                            frame_oversize <= 1'b1;
                        end
                    end
                end
                if (s_axis_tlast) begin
                    in_frame <= 1'b0;
                end
            end
        end
    end

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg   <= 1'b0;
            status_bad_frame_reg  <= 1'b0;
            status_good_frame_reg <= 1'b0;
        end else begin
            // Overflow: write when full
            if (s_axis_tvalid && full) begin
                status_overflow_reg <= 1'b1;
            end
            // Bad frame: frame ends with bad flag
            if (wr_en && s_axis_tlast && frame_bad) begin
                status_bad_frame_reg <= 1'b1;
            end
            // Good frame: frame ends without bad flag
            if (wr_en && s_axis_tlast && !frame_bad) begin
                status_good_frame_reg <= 1'b1;
            end
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (pause_req) begin
                pause_active <= 1'b1;
            end else if (empty) begin
                pause_active <= 1'b0;
            end
        end
    end

endmodule

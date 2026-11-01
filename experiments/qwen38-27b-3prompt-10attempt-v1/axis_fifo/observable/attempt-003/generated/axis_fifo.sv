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
    wire wr_en;
    wire rd_en;
    wire full;
    wire empty;
    wire [ADDR_WIDTH-1:0] wr_ptr;
    wire [ADDR_WIDTH-1:0] rd_ptr;
    wire [$clog2(DEPTH):0] depth;

    // Frame tracking
    reg frame_active;
    reg frame_overflow;
    reg frame_bad;
    reg frame_drop;

    // Status latches
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Pause logic
    reg pause_active;

    // Write side
    wire write_allowed;
    wire frame_complete;

    // Read side
    wire read_allowed;

    // Memory
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg                  mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    // Pipeline registers for RAM_PIPELINE
    reg [DATA_WIDTH-1:0] pipe_data;
    reg [KEEP_WIDTH-1:0] pipe_keep;
    reg                  pipe_last;
    reg [ID_WIDTH-1:0]   pipe_id;
    reg [DEST_WIDTH-1:0] pipe_dest;
    reg [USER_WIDTH-1:0] pipe_user;
    reg                  pipe_valid;

    // Output FIFO
    reg [DATA_WIDTH-1:0] ofifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ofifo_keep [0:DEPTH-1];
    reg                  ofifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ofifo_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ofifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ofifo_user [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] ofifo_wr_ptr;
    reg [ADDR_WIDTH-1:0] ofifo_rd_ptr;
    reg [$clog2(DEPTH):0] ofifo_count;

    // Compute depth
    assign depth = wr_ptr - rd_ptr;

    assign full  = (depth == DEPTH);
    assign empty = (depth == 0);

    // Frame logic
    wire frame_start = s_axis_tvalid && s_axis_tready && !frame_active;
    wire frame_end   = s_axis_tvalid && s_axis_tready && s_axis_tlast;

    // Determine if frame is bad based on user sideband
    wire user_bad = (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);

    // Frame drop decision
    wire drop_this_frame = frame_drop;

    // Write enable logic
    wire input_accepted = s_axis_tvalid && s_axis_tready;

    // Frame state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_active   <= 1'b0;
            frame_overflow <= 1'b0;
            frame_bad      <= 1'b0;
            frame_drop     <= 1'b0;
        end else begin
            if (input_accepted) begin
                if (!frame_active) begin
                    // Start of new frame
                    frame_active   <= 1'b1;
                    frame_overflow <= 1'b0;
                    frame_bad      <= user_bad;
                    frame_drop     <= (DROP_BAD_FRAME && user_bad) || 
                                      (DROP_OVERSIZE_FRAME && frame_overflow);
                end else begin
                    // Continue frame
                    if (user_bad) begin
                        frame_bad <= 1'b1;
                    end
                    if (frame_overflow) begin
                        frame_drop <= (DROP_OVERSIZE_FRAME) ? 1'b1 : frame_drop;
                    end
                end
                if (s_axis_tlast) begin
                    frame_active   <= 1'b0;
                    frame_overflow <= 1'b0;
                    frame_bad      <= 1'b0;
                    frame_drop     <= 1'b0;
                end
            end
        end
    end

    // Overflow detection for frame
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_overflow <= 1'b0;
        end else if (input_accepted && frame_active) begin
            // Check if adding this beat would exceed DEPTH
            if (depth >= DEPTH - 1) begin
                frame_overflow <= 1'b1;
            end
        end else if (!input_accepted) begin
            frame_overflow <= 1'b0;
        end
    end

    // Write enable
    assign write_allowed = input_accepted && !drop_this_frame;

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg   <= 1'b0;
            status_bad_frame_reg  <= 1'b0;
            status_good_frame_reg <= 1'b0;
        end else begin
            if (input_accepted && s_axis_tlast) begin
                if (frame_bad || frame_overflow) begin
                    status_bad_frame_reg  <= 1'b1;
                    status_good_frame_reg <= 1'b0;
                end else begin
                    status_bad_frame_reg  <= 1'b0;
                    status_good_frame_reg <= 1'b1;
                end
            end
            if (full && s_axis_tvalid) begin
                status_overflow_reg <= 1'b1;
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
        end else begin
            pause_active <= 1'b0;
        end
    end

    assign pause_ack = pause_active;

    // Input ready
    wire paused = PAUSE_ENABLE && pause_active;
    wire frame_paused = FRAME_PAUSE && frame_active && paused;
    
    assign s_axis_tready = !full && !paused && !frame_paused;

    // Memory write
    always @(posedge clk) begin
        if (write_allowed) begin
            mem_data[wr_ptr] <= s_axis_tdata;
            mem_keep[wr_ptr] <= s_axis_tkeep;
            mem_last[wr_ptr] <= s_axis_tlast;
            mem_id[wr_ptr]   <= s_axis_tid;
            mem_dest[wr_ptr] <= s_axis_tdest;
            mem_user[wr_ptr] <= s_axis_tuser;
        end
    end

    // Write pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (write_allowed) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read logic
    wire rd_data_valid;
    wire [DATA_WIDTH-1:0] rd_data;
    wire [KEEP_WIDTH-1:0] rd_keep;
    wire                  rd_last;
    wire [ID_WIDTH-1:0]   rd_id;
    wire [DEST_WIDTH-1:0] rd_dest;
    wire [USER_WIDTH-1:0] rd_user;

    if (RAM_PIPELINE) begin
        // Pipelined read
        assign rd_data  = pipe_data;
        assign rd_keep  = pipe_keep;
        assign rd_last  = pipe_last;
        assign rd_id    = pipe_id;
        assign rd_dest  = pipe_dest;
        assign rd_user  = pipe_user;
        assign rd_data_valid = pipe_valid;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                pipe_valid <= 1'b0;
            end else begin
                if (rd_en) begin
                    pipe_valid <= 1'b0;
                end else if (!empty) begin
                    pipe_data  <= mem_data[rd_ptr];
                    pipe_keep  <= mem_keep[rd_ptr];
                    pipe_last  <= mem_last[rd_ptr];
                    pipe_id    <= mem_id[rd_ptr];
                    pipe_dest  <= mem_dest[rd_ptr];
                    pipe_user  <= mem_user[rd_ptr];
                    pipe_valid <= 1'b1;
                end
            end
        end
    end else begin
        // Direct read
        assign rd_data  = mem_data[rd_ptr];
        assign rd_keep  = mem_keep[rd_ptr];
        assign rd_last  = mem_last[rd_ptr];
        assign rd_id    = mem_id[rd_ptr];
        assign rd_dest  = mem_dest[rd_ptr];
        assign rd_user  = mem_user[rd_ptr];
        assign rd_data_valid = !empty;
    end

    // Output FIFO logic
    wire ofifo_full;
    wire ofifo_empty;
    wire ofifo_wr_en;
    wire ofifo_rd_en;

    if (OUTPUT_FIFO_ENABLE) begin
        assign ofifo_full  = (ofifo_count == DEPTH);
        assign ofifo_empty = (ofifo_count == 0);

        // Write to output FIFO when data is available from main FIFO
        assign ofifo_wr_en = rd_data_valid && !ofifo_full;

        // Read from output FIFO when downstream is ready
        assign ofifo_rd_en = !ofifo_empty && m_axis_tready;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                ofifo_wr_ptr <= {ADDR_WIDTH{1'b0}};
                ofifo_rd_ptr <= {ADDR_WIDTH{1'b0}};
                ofifo_count  <= {($clog2(DEPTH)+1){1'b0}};
            end else begin
                case ({ofifo_wr_en, ofifo_rd_en})
                    2'b10: begin
                        ofifo_wr_ptr <= ofifo_wr_ptr + 1'b1;
                        ofifo_count  <= ofifo_count + 1'b1;
                    end
                    2'b01: begin
                        ofifo_rd_ptr <= ofifo_rd_ptr + 1'b1;
                        ofifo_count  <= ofifo_count - 1'b1;
                    end
                    2'b11: begin
                        ofifo_wr_ptr <= ofifo_wr_ptr + 1'b1;
                        ofifo_rd_ptr <= ofifo_rd_ptr + 1'b1;
                    end
                    default: ;
                endcase
            end
        end

        always @(posedge clk) begin
            if (ofifo_wr_en) begin
                ofifo_data[ofifo_wr_ptr] <= rd_data;
                ofifo_keep[ofifo_wr_ptr] <= rd_keep;
                ofifo_last[ofifo_wr_ptr] <= rd_last;
                ofifo_id[ofifo_wr_ptr]   <= rd_id;
                ofifo_dest[ofifo_wr_ptr] <= rd_dest;
                ofifo_user[ofifo_wr_ptr] <= rd_user;
            end
        end

        assign m_axis_tdata  = ofifo_data[ofifo_rd_ptr];
        assign m_axis_tkeep  = ofifo_keep[ofifo_rd_ptr];
        assign m_axis_tlast  = ofifo_last[ofifo_rd_ptr];
        assign m_axis_tid    = ofifo_id[ofifo_rd_ptr];
        assign m_axis_tdest  = ofifo_dest[ofifo_rd_ptr];
        assign m_axis_tuser  = ofifo_user[ofifo_rd_ptr];
        assign m_axis_tvalid = !ofifo_empty;

        // Read from main FIFO when output FIFO has space
        assign rd_en = rd_data_valid && !ofifo_full;
    end else begin
        assign m_axis_tdata  = rd_data;
        assign m_axis_tkeep  = rd_keep;
        assign m_axis_tlast  = rd_last;
        assign m_axis_tid    = rd_id;
        assign m_axis_tdest  = rd_dest;
        assign m_axis_tuser  = rd_user;
        assign m_axis_tvalid = rd_data_valid;

        assign rd_en = rd_data_valid && m_axis_tready;
    end

    // Read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Status outputs
    assign status_depth        = depth;
    assign status_depth_commit = depth;
    assign status_overflow     = status_overflow_reg;
    assign status_bad_frame    = status_bad_frame_reg;
    assign status_good_frame   = status_good_frame_reg;

endmodule

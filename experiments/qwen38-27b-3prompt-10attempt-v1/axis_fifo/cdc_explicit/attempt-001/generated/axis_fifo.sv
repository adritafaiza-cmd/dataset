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
    localparam DEPTH_FULL = DEPTH;

    // Total width of the stored word
    localparam TOTAL_WIDTH = DATA_WIDTH 
        + (KEEP_ENABLE ? KEEP_WIDTH : 0)
        + (LAST_ENABLE ? 1 : 0)
        + (ID_ENABLE ? ID_WIDTH : 0)
        + (DEST_ENABLE ? DEST_WIDTH : 0)
        + (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wr_en;
    wire rd_en;

    // Full/Empty logic
    wire full;
    wire empty;

    // Frame tracking
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_count;

    // Pause logic
    reg pause_active;
    reg pause_pending;

    // Status latches
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Output registers
    reg [TOTAL_WIDTH-1:0] out_reg;
    reg out_valid;

    // Compute full and empty
    assign full = (wr_ptr == rd_ptr) && (mem[0] != 0 || wr_ptr[ADDR_WIDTH-1] != rd_ptr[ADDR_WIDTH-1]);
    // Simpler full/empty for power-of-2 depth
    wire [ADDR_WIDTH:0] wr_ptr_ext = {wr_ptr[ADDR_WIDTH-1], wr_ptr[ADDR_WIDTH-1:0]};
    wire [ADDR_WIDTH:0] rd_ptr_ext = {rd_ptr[ADDR_WIDTH-1], rd_ptr[ADDR_WIDTH-1:0]};
    
    // For power-of-2 DEPTH, use standard FIFO full/empty
    wire is_full = (wr_ptr == rd_ptr) && (wr_ptr[ADDR_WIDTH-1] != rd_ptr[ADDR_WIDTH-1]);
    wire is_empty = (wr_ptr == rd_ptr) && (wr_ptr[ADDR_WIDTH-1] == rd_ptr[ADDR_WIDTH-1]);

    // Actually, let's use a simpler approach with a count or standard pointer comparison
    // For DEPTH that is power of 2:
    // full: wr_ptr[ADDR_WIDTH-1] != rd_ptr[ADDR_WIDTH-1] && wr_ptr[ADDR_WIDTH-2:0] == rd_ptr[ADDR_WIDTH-2:0]
    // empty: wr_ptr == rd_ptr

    wire fifo_full = (wr_ptr[ADDR_WIDTH-1] != rd_ptr[ADDR_WIDTH-1]) && 
                     (wr_ptr[ADDR_WIDTH-2:0] == rd_ptr[ADDR_WIDTH-2:0]);
    wire fifo_empty = (wr_ptr == rd_ptr);

    // Pause logic
    wire pause_active_eff = PAUSE_ENABLE ? (pause_active || pause_pending) : 1'b0;
    
    // Frame pause: pause when frame is complete
    wire frame_pause_active = FRAME_PAUSE ? (in_frame && frame_count > 0) : 1'b0;
    
    // Effective pause
    wire eff_pause = pause_active_eff || frame_pause_active;

    // Write ready
    wire can_write = !fifo_full && !eff_pause;
    
    // Drop when full
    wire drop_when_full_eff = DROP_WHEN_FULL ? fifo_full : 1'b0;
    
    // Mark when full
    wire mark_when_full_eff = MARK_WHEN_FULL ? fifo_full : 1'b0;

    // Write enable
    assign wr_en = s_axis_tvalid && can_write && !drop_when_full_eff;

    // Read enable
    assign rd_en = m_axis_tready && out_valid;

    // Build the word to write
    wire [TOTAL_WIDTH-1:0] wr_data;
    assign wr_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Memory write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (wr_en) begin
            mem[wr_ptr[ADDR_WIDTH-2:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Memory read
    wire [TOTAL_WIDTH-1:0] rd_data;
    assign rd_data = mem[rd_ptr[ADDR_WIDTH-2:0]];

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_reg <= {TOTAL_WIDTH{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (rd_en) begin
                out_valid <= 1'b0;
            end
            if (!fifo_empty && !rd_en) begin
                out_reg <= rd_data;
                out_valid <= 1'b1;
            end else if (!fifo_empty && rd_en) begin
                out_reg <= rd_data;
                out_valid <= 1'b1;
            end
        end
    end

    // Read pointer update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Frame tracking
    wire cur_tlast = LAST_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    wire cur_tuser = USER_ENABLE ? out_reg[TOTAL_WIDTH-1 -: USER_WIDTH] : {USER_WIDTH{1'b0}};
    
    wire is_bad_frame = USER_ENABLE ? (cur_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE : 1'b0;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 1'b0;
            frame_bad <= 1'b0;
            frame_oversize <= 1'b0;
            frame_count <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            if (rd_en) begin
                if (cur_tlast) begin
                    // Frame complete
                    if (frame_bad || frame_oversize) begin
                        status_bad_frame_reg <= 1'b1;
                    end else begin
                        status_good_frame_reg <= 1'b1;
                    end
                    in_frame <= 1'b0;
                    frame_bad <= 1'b0;
                    frame_oversize <= 1'b0;
                    frame_count <= {ADDR_WIDTH+1{1'b0}};
                end else begin
                    frame_count <= frame_count + 1'b1;
                    if (DROP_OVERSIZE_FRAME && frame_count >= DEPTH) begin
                        frame_oversize <= 1'b1;
                    end
                    if (DROP_BAD_FRAME && is_bad_frame) begin
                        frame_bad <= 1'b1;
                    end
                end
            end else if (out_valid && !in_frame) begin
                in_frame <= 1'b1;
                frame_count <= 1'b1;
                if (DROP_BAD_FRAME && is_bad_frame) begin
                    frame_bad <= 1'b1;
                end
            end
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
            pause_pending <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (pause_req && !pause_active) begin
                    pause_pending <= 1'b1;
                end
                if (pause_pending && !fifo_empty) begin
                    pause_active <= 1'b1;
                end
                if (pause_active && fifo_empty) begin
                    pause_active <= 1'b0;
                    pause_pending <= 1'b0;
                end
            end
        end
    end

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg <= 1'b0;
            status_bad_frame_reg <= 1'b0;
            status_good_frame_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && fifo_full && !DROP_WHEN_FULL) begin
                status_overflow_reg <= 1'b1;
            end
        end
    end

    // Outputs
    assign s_axis_tready = can_write && !drop_when_full_eff;
    assign m_axis_tdata = out_reg[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? out_reg[DATA_WIDTH + KEEP_WIDTH-1 -: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast = LAST_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1 -: ID_WIDTH] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1 -: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? out_reg[TOTAL_WIDTH-1 -: USER_WIDTH] : {USER_WIDTH{1'b0}};
    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;
    assign status_depth = fifo_empty ? 0 : (fifo_full ? DEPTH : (wr_ptr - rd_ptr));
    assign status_depth_commit = status_depth;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

endmodule

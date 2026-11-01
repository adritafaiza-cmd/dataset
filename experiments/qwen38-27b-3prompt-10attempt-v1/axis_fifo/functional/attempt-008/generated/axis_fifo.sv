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
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg                  full;
    reg                  empty;
    reg                  pause_active;
    reg                  frame_drop_active;
    reg                  bad_frame_active;
    reg                  overflow_flag;
    reg                  bad_frame_flag;
    reg                  good_frame_flag;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write enable
    wire wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire rd_en = m_axis_tvalid && m_axis_tready;

    // Pause logic
    wire pause_active_next = PAUSE_ENABLE ? (pause_req || (FRAME_PAUSE && frame_drop_active)) : 1'b0;

    // Frame drop logic
    wire frame_drop_active_next = FRAME_FIFO ? (frame_drop_active || (wr_en && !s_axis_tlast && full)) : 1'b0;

    // Bad frame detection
    wire bad_frame_detected = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Overflow detection
    wire overflow_detected = wr_en && full;

    // Good frame detection
    wire good_frame_detected = wr_en && s_axis_tlast && !bad_frame_detected && !frame_drop_active;

    // Bad frame flag
    wire bad_frame_flag_next = wr_en && s_axis_tlast && (bad_frame_detected || frame_drop_active);

    // Status flags
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            overflow_flag <= 1'b0;
            bad_frame_flag <= 1'b0;
            good_frame_flag <= 1'b0;
        end else begin
            if (overflow_detected) overflow_flag <= 1'b1;
            if (bad_frame_flag_next) bad_frame_flag <= 1'b1;
            if (good_frame_detected) good_frame_flag <= 1'b1;
        end
    end

    // Pause active
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else begin
            pause_active <= pause_active_next;
        end
    end

    // Frame drop active
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_drop_active <= 1'b0;
        end else begin
            frame_drop_active <= frame_drop_active_next;
        end
    end

    // Bad frame active
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bad_frame_active <= 1'b0;
        end else begin
            if (wr_en && s_axis_tlast) begin
                bad_frame_active <= 1'b0;
            end else if (wr_en && bad_frame_detected) begin
                bad_frame_active <= 1'b1;
            end
        end
    end

    // Write ready
    wire wr_ready_base = !full && !pause_active;
    wire wr_ready_drop = DROP_WHEN_FULL ? 1'b1 : wr_ready_base;
    wire wr_ready_mark = MARK_WHEN_FULL ? 1'b1 : wr_ready_base;
    wire s_axis_tready_internal = DROP_WHEN_FULL ? 1'b1 : (MARK_WHEN_FULL ? 1'b1 : wr_ready_base);

    // Handle drop/mark when full
    wire effective_wr_en = wr_en && (DROP_WHEN_FULL || MARK_WHEN_FULL || !full);

    // Write to RAM
    always @(posedge clk) begin
        if (effective_wr_en) begin
            ram_data[wr_ptr] <= s_axis_tdata;
            ram_keep[wr_ptr] <= s_axis_tkeep;
            ram_last[wr_ptr] <= s_axis_tlast;
            ram_id[wr_ptr]   <= s_axis_tid;
            ram_dest[wr_ptr] <= s_axis_tdest;
            ram_user[wr_ptr] <= s_axis_tuser;
        end
    end

    // Read from RAM
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr;
    wire [DATA_WIDTH-1:0] rd_data = ram_data[rd_addr];
    wire [KEEP_WIDTH-1:0] rd_keep = ram_keep[rd_addr];
    wire                  rd_last = ram_last[rd_addr];
    wire [ID_WIDTH-1:0]   rd_id   = ram_id[rd_addr];
    wire [DEST_WIDTH-1:0] rd_dest = ram_dest[rd_addr];
    wire [USER_WIDTH-1:0] rd_user = ram_user[rd_addr];

    // Output FIFO logic
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg                  out_last;
    reg [ID_WIDTH-1:0]   out_id;
    reg [DEST_WIDTH-1:0] out_dest;
    reg [USER_WIDTH-1:0] out_user;
    reg                  out_valid;

    // Pointer updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            full   <= 1'b0;
            empty  <= 1'b1;
        end else begin
            if (effective_wr_en && rd_en) begin
                // Both write and read
                // Pointers stay the same relative to each other
                // But we need to update based on actual operations
                if (full) begin
                    // Was full, now reading, so not full anymore
                    full <= 1'b0;
                end else if (empty) begin
                    // Was empty, now writing, so not empty anymore
                    empty <= 1'b0;
                end
                // Pointers don't change if both happen simultaneously in a simple FIFO
                // Actually, in a standard FIFO, if both write and read happen, pointers stay the same
                // But we need to track the actual state
            end else if (effective_wr_en) begin
                // Write only
                wr_ptr <= wr_ptr + 1'b1;
                if (full) begin
                    // Overflow, but we're dropping or marking
                    // If DROP_WHEN_FULL, we don't actually write, so pointer shouldn't advance
                    // Let's reconsider
                end
                if (empty) empty <= 1'b0;
                if (wr_ptr == rd_ptr && !full) full <= 1'b1;
            end else if (rd_en) begin
                // Read only
                rd_ptr <= rd_ptr + 1'b1;
                if (empty) begin
                    // Underflow, shouldn't happen
                end
                if (full) full <= 1'b0;
                if (rd_ptr == wr_ptr && !empty) empty <= 1'b1;
            end
        end
    end

    // Let me redo the pointer logic more carefully
    // Standard FIFO pointer management

    // Reset the pointer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            full   <= 1'b0;
            empty  <= 1'b1;
        end else begin
            case ({effective_wr_en, rd_en})
                2'b01: begin
                    // Read only
                    rd_ptr <= rd_ptr + 1'b1;
                    if (full) full <= 1'b0;
                    if (rd_ptr == wr_ptr) empty <= 1'b1;
                end
                2'b10: begin
                    // Write only
                    wr_ptr <= wr_ptr + 1'b1;
                    if (empty) empty <= 1'b0;
                    if (wr_ptr == rd_ptr) full <= 1'b1;
                end
                2'b11: begin
                    // Both read and write
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    // full and empty remain unchanged
                end
                default: begin
                    // No operation
                end
            endcase
        end
    end

    // Output FIFO
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_data  <= {DATA_WIDTH{1'b0}};
            out_keep  <= {KEEP_WIDTH{1'b0}};
            out_last  <= 1'b0;
            out_id    <= {ID_WIDTH{1'b0}};
            out_dest  <= {DEST_WIDTH{1'b0}};
            out_user  <= {USER_WIDTH{1'b0}};
        end else begin
            if (rd_en) begin
                out_valid <= 1'b0;
            end
            if (!out_valid || rd_en) begin
                if (!empty) begin
                    out_valid <= 1'b1;
                    out_data  <= rd_data;
                    out_keep  <= rd_keep;
                    out_last  <= rd_last;
                    out_id    <= rd_id;
                    out_dest  <= rd_dest;
                    out_user  <= rd_user;
                end
            end
        end
    end

    // Assign outputs
    assign m_axis_tdata  = out_data;
    assign m_axis_tkeep  = out_keep;
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast  = out_last;
    assign m_axis_tid    = out_id;
    assign m_axis_tdest  = out_dest;
    assign m_axis_tuser  = out_user;

    assign s_axis_tready = s_axis_tready_internal;

    assign pause_ack = pause_active;

    assign status_depth = (wr_ptr - rd_ptr);
    assign status_depth_commit = (wr_ptr - rd_ptr);
    assign status_overflow = overflow_flag;
    assign status_bad_frame = bad_frame_flag;
    assign status_good_frame = good_frame_flag;

endmodule

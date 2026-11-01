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
    localparam DEPTH_POW2 = (DEPTH == (1 << ADDR_WIDTH)) ? DEPTH : (1 << (ADDR_WIDTH + 1));
    localparam FULL_DEPTH = DEPTH_POW2;
    localparam FULL_ADDR_WIDTH = $clog2(FULL_DEPTH);
    localparam FULL_MASK = FULL_DEPTH - 1;

    // Sideband width calculation
    localparam SIDE_WIDTH = (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                            (LAST_ENABLE ? 1 : 0) +
                            (ID_ENABLE ? ID_WIDTH : 0) +
                            (DEST_ENABLE ? DEST_WIDTH : 0) +
                            (USER_ENABLE ? USER_WIDTH : 0);

    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

    // Pack sideband
    wire [SIDE_WIDTH-1:0] side_in;
    assign side_in = {
        (USER_ENABLE ? s_axis_tuser : {}),
        (DEST_ENABLE ? s_axis_tdest : {}),
        (ID_ENABLE ? s_axis_tid : {}),
        (LAST_ENABLE ? s_axis_tlast : {}),
        (KEEP_ENABLE ? s_axis_tkeep : {})
    };

    wire [TOTAL_WIDTH-1:0] data_in;
    assign data_in = {side_in, s_axis_tdata};

    // Unpack sideband from output
    wire [SIDE_WIDTH-1:0] side_out;
    wire [DATA_WIDTH-1:0] data_out;
    assign {side_out, data_out} = m_axis_tdata_internal;

    wire [DATA_WIDTH-1:0] m_axis_tdata_internal;

    // Extract sideband fields
    wire [KEEP_WIDTH-1:0] keep_out;
    wire last_out;
    wire [ID_WIDTH-1:0] id_out;
    wire [DEST_WIDTH-1:0] dest_out;
    wire [USER_WIDTH-1:0] user_out;

    // We need to unpack based on the packing order
    // side_in = {user, dest, id, last, keep}
    // So side_out has the same structure
    wire [USER_WIDTH-1:0] user_out_w;
    wire [DEST_WIDTH-1:0] dest_out_w;
    wire [ID_WIDTH-1:0] id_out_w;
    wire last_out_w;
    wire [KEEP_WIDTH-1:0] keep_out_w;

    // Unpack from side_out
    // The width of each field is known
    // We'll use a recursive unpack or just assign based on known widths
    // Since we can't easily do variable-width unpack in Verilog-2001 without generate,
    // let's use a different approach: store fields separately or use a packed vector with known offsets.

    // Let's define offsets
    localparam KEEP_OFF = 0;
    localparam LAST_OFF = KEEP_OFF + (KEEP_ENABLE ? KEEP_WIDTH : 0);
    localparam ID_OFF = LAST_OFF + (LAST_ENABLE ? 1 : 0);
    localparam DEST_OFF = ID_OFF + (ID_ENABLE ? ID_WIDTH : 0);
    localparam USER_OFF = DEST_OFF + (DEST_ENABLE ? DEST_WIDTH : 0);

    assign keep_out_w = side_out[KEEP_OFF + (KEEP_ENABLE ? KEEP_WIDTH-1 : 0) : KEEP_OFF];
    assign last_out_w = side_out[LAST_OFF];
    assign id_out_w = side_out[ID_OFF + (ID_ENABLE ? ID_WIDTH-1 : 0) : ID_OFF];
    assign dest_out_w = side_out[DEST_OFF + (DEST_ENABLE ? DEST_WIDTH-1 : 0) : DEST_OFF];
    assign user_out_w = side_out[USER_OFF + (USER_ENABLE ? USER_WIDTH-1 : 0) : USER_OFF];

    assign m_axis_tkeep = keep_out_w;
    assign m_axis_tlast = last_out_w;
    assign m_axis_tid = id_out_w;
    assign m_axis_tdest = dest_out_w;
    assign m_axis_tuser = user_out_w;

    // FIFO implementation
    reg [TOTAL_WIDTH-1:0] mem [0:FULL_DEPTH-1];
    reg [FULL_ADDR_WIDTH:0] wr_ptr;
    reg [FULL_ADDR_WIDTH:0] rd_ptr;

    wire [FULL_ADDR_WIDTH-1:0] wr_addr = wr_ptr[FULL_ADDR_WIDTH-1:0];
    wire [FULL_ADDR_WIDTH-1:0] rd_addr = rd_ptr[FULL_ADDR_WIDTH-1:0];

    wire full = (wr_ptr[FULL_ADDR_WIDTH] != rd_ptr[FULL_ADDR_WIDTH]) &&
                (wr_ptr[FULL_ADDR_WIDTH-1:0] == rd_ptr[FULL_ADDR_WIDTH-1:0]);
    wire empty = (wr_ptr == rd_ptr);

    wire [FULL_ADDR_WIDTH:0] depth = wr_ptr - rd_ptr;

    // Pause logic
    reg pause_active;
    wire pause_block = PAUSE_ENABLE && pause_active;

    // Frame tracking for FRAME_FIFO
    reg in_frame;
    reg frame_overflow;
    reg frame_bad;

    // Write enable
    wire wr_en = s_axis_tvalid && s_axis_tready && !pause_block;

    // Read enable
    wire rd_en = m_axis_tvalid && m_axis_tready;

    // Frame logic
    wire frame_start = !in_frame && wr_en;
    wire frame_end = in_frame && wr_en && s_axis_tlast;

    // Bad frame detection
    wire bad_frame_det = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Oversize frame detection (simplified: if frame exceeds DEPTH)
    // For simplicity, we'll track frame length
    reg [FULL_ADDR_WIDTH:0] frame_len;

    // Status registers
    reg status_overflow_r;
    reg status_bad_frame_r;
    reg status_good_frame_r;

    // Pause acknowledgment
    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    // Input ready
    wire input_full = full;
    wire drop_when_full = DROP_WHEN_FULL && input_full;
    wire mark_when_full = MARK_WHEN_FULL && input_full;

    // Frame-based pause
    wire frame_pause_active = FRAME_PAUSE && in_frame;

    // Overall ready
    assign s_axis_tready = !input_full && !pause_block && !(FRAME_PAUSE && in_frame && !s_axis_tlast);

    // Output valid
    assign m_axis_tvalid = !empty;

    // Read data
    wire [TOTAL_WIDTH-1:0] rd_data;
    assign rd_data = mem[rd_addr];
    assign m_axis_tdata_internal = rd_data;

    // Frame tracking logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 1'b0;
            frame_len <= {FULL_ADDR_WIDTH+1{1'b0}};
            frame_overflow <= 1'b0;
            frame_bad <= 1'b0;
        end else begin
            if (wr_en) begin
                if (!in_frame) begin
                    in_frame <= 1'b1;
                    frame_len <= 1;
                    frame_overflow <= 1'b0;
                    frame_bad <= bad_frame_det;
                end else begin
                    frame_len <= frame_len + 1;
                    if (bad_frame_det)
                        frame_bad <= 1'b1;
                    if (frame_len >= DEPTH)
                        frame_overflow <= 1'b1;
                end
                if (s_axis_tlast) begin
                    in_frame <= 1'b0;
                    frame_len <= {FULL_ADDR_WIDTH+1{1'b0}};
                end
            end
        end
    end

    // Status logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_r <= 1'b0;
            status_bad_frame_r <= 1'b0;
            status_good_frame_r <= 1'b0;
        end else begin
            // Overflow: write when full
            if (wr_en && full)
                status_overflow_r <= 1'b1;

            // Bad frame: frame ended with bad flag
            if (frame_end && frame_bad)
                status_bad_frame_r <= 1'b1;

            // Good frame: frame ended without bad flag
            if (frame_end && !frame_bad)
                status_good_frame_r <= 1'b1;
        end
    end

    assign status_overflow = status_overflow_r;
    assign status_bad_frame = status_bad_frame_r;
    assign status_good_frame = status_good_frame_r;

    // Depth status
    assign status_depth = depth;
    assign status_depth_commit = depth;

    // Memory write
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= data_in;
        end
    end

    // Pointers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {FULL_ADDR_WIDTH+1{1'b0}};
            rd_ptr <= {FULL_ADDR_WIDTH+1{1'b0}};
        end else begin
            if (wr_en)
                wr_ptr <= wr_ptr + 1;
            if (rd_en)
                rd_ptr <= rd_ptr + 1;
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (pause_req)
                pause_active <= 1'b1;
            else if (!pause_req && empty)
                pause_active <= 1'b0;
        end
    end

endmodule

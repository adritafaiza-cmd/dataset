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
    reg [ADDR_WIDTH:0] depth;
    reg [ADDR_WIDTH:0] depth_commit;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write enable
    wire wr_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    wire rd_en = m_axis_tvalid & m_axis_tready;

    // Full and empty
    wire full  = (depth == DEPTH);
    wire empty = (depth == 0);

    // Pause logic
    reg pause_active;
    wire pause_block = PAUSE_ENABLE && pause_active;

    // Frame tracking for FRAME_FIFO
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_count;

    // Status registers
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Output registers
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg                  out_last;
    reg [ID_WIDTH-1:0]   out_id;
    reg [DEST_WIDTH-1:0] out_dest;
    reg [USER_WIDTH-1:0] out_user;
    reg                  out_valid;

    // RAM read pipeline
    reg [ADDR_WIDTH:0] rd_addr_reg;
    reg                rd_valid_reg;

    // Compute tready
    wire can_write = !full && !pause_block;
    assign s_axis_tready = can_write;

    // Compute m_axis_tvalid
    assign m_axis_tvalid = out_valid;

    // Assign outputs
    assign m_axis_tdata  = out_data;
    assign m_axis_tkeep  = out_keep;
    assign m_axis_tlast  = out_last;
    assign m_axis_tid    = out_id;
    assign m_axis_tdest  = out_dest;
    assign m_axis_tuser  = out_user;

    assign pause_ack = pause_active;

    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Write to RAM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
            in_frame <= 0;
            frame_bad <= 0;
            frame_oversize <= 0;
            frame_count <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
            out_valid <= 0;
            rd_valid_reg <= 0;
            pause_active <= 0;
        end else begin
            // Update pause
            if (PAUSE_ENABLE) begin
                if (pause_req) begin
                    pause_active <= 1;
                end else if (empty) begin
                    pause_active <= 0;
                end
            end

            // Write
            if (wr_en) begin
                ram_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                ram_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                ram_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                ram_id[wr_ptr[ADDR_WIDTH-1:0]]   <= s_axis_tid;
                ram_dest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                ram_user[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
            end

            // Read
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
            end

            // Depth update
            if (wr_en && rd_en) begin
                depth <= depth;
            end else if (wr_en) begin
                depth <= depth + 1;
            end else if (rd_en) begin
                depth <= depth - 1;
            end

            // Depth commit (for status)
            if (wr_en && rd_en) begin
                depth_commit <= depth_commit;
            end else if (wr_en) begin
                depth_commit <= depth_commit + 1;
            end else if (rd_en) begin
                depth_commit <= depth_commit - 1;
            end

            // Frame tracking
            if (FRAME_FIFO) begin
                if (wr_en) begin
                    if (!in_frame) begin
                        in_frame <= 1;
                        frame_count <= 1;
                        frame_bad <= 0;
                        frame_oversize <= 0;
                    end else begin
                        frame_count <= frame_count + 1;
                        if (frame_count >= DEPTH) begin
                            frame_oversize <= 1;
                        end
                    end
                    if (s_axis_tlast) begin
                        in_frame <= 0;
                        if (frame_oversize || (DROP_OVERSIZE_FRAME && frame_count > DEPTH)) begin
                            // Drop frame
                        end
                        if (DROP_BAD_FRAME && frame_bad) begin
                            // Drop frame
                        end
                    end
                end
            end

            // Overflow detection
            if (wr_en && full) begin
                status_overflow_reg <= 1;
            end

            // Bad frame detection
            if (USER_ENABLE && wr_en && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                frame_bad <= 1;
                status_bad_frame_reg <= 1;
            end

            // Good frame detection
            if (wr_en && s_axis_tlast && !frame_bad && !frame_oversize) begin
                status_good_frame_reg <= 1;
            end
        end
    end

    // RAM read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_addr_reg <= 0;
            rd_valid_reg <= 0;
        end else begin
            if (rd_en) begin
                rd_addr_reg <= rd_ptr;
                rd_valid_reg <= 1;
            end else begin
                rd_valid_reg <= 0;
            end
        end
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= 0;
            out_keep <= 0;
            out_last <= 0;
            out_id <= 0;
            out_dest <= 0;
            out_user <= 0;
            out_valid <= 0;
        end else begin
            if (rd_en) begin
                out_valid <= 0;
            end else if (rd_valid_reg && !out_valid) begin
                out_data  <= ram_data[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_keep  <= ram_keep[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_last  <= ram_last[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_id    <= ram_id[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_dest  <= ram_dest[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_user  <= ram_user[rd_addr_reg[ADDR_WIDTH-1:0]];
                out_valid <= 1;
            end
        end
    end

endmodule

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
    wire rd_en = m_axis_tvalid & m_axis_tready;

    // Full/Empty
    wire full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    wire empty = (wr_ptr == rd_ptr);

    // Pause logic
    reg pause_active;
    wire pause_block = PAUSE_ENABLE && pause_active;

    // Frame tracking for FRAME_FIFO
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_count;

    // Status latches
    reg status_overflow_r;
    reg status_bad_frame_r;
    reg status_good_frame_r;

    // Output registers
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg                  out_last;
    reg [ID_WIDTH-1:0]   out_id;
    reg [DEST_WIDTH-1:0] out_dest;
    reg [USER_WIDTH-1:0] out_user;
    reg                  out_valid;

    // Read address
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // RAM read
    wire [DATA_WIDTH-1:0] ram_rd_data;
    wire [KEEP_WIDTH-1:0] ram_rd_keep;
    wire                  ram_rd_last;
    wire [ID_WIDTH-1:0]   ram_rd_id;
    wire [DEST_WIDTH-1:0] ram_rd_dest;
    wire [USER_WIDTH-1:0] ram_rd_user;

    assign ram_rd_data  = ram_data[rd_addr];
    assign ram_rd_keep  = ram_keep[rd_addr];
    assign ram_rd_last  = ram_last[rd_addr];
    assign ram_rd_id    = ram_id[rd_addr];
    assign ram_rd_dest  = ram_dest[rd_addr];
    assign ram_rd_user  = ram_user[rd_addr];

    // Determine if we should accept write
    wire can_write = !full && !pause_block;
    wire drop_write = DROP_WHEN_FULL && full;
    wire mark_write = MARK_WHEN_FULL && full;

    // Frame logic
    wire frame_start = !in_frame;
    wire frame_end   = in_frame && s_axis_tlast;
    wire frame_bad_detected = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire frame_oversize_detected = FRAME_FIFO && (frame_count == DEPTH[ADDR_WIDTH:0]);

    // s_axis_tready
    assign s_axis_tready = can_write && !drop_write;

    // m_axis_tvalid
    assign m_axis_tvalid = !empty && !pause_block;

    // Outputs
    assign m_axis_tdata  = out_data;
    assign m_axis_tkeep  = out_keep;
    assign m_axis_tlast  = out_last;
    assign m_axis_tid    = out_id;
    assign m_axis_tdest  = out_dest;
    assign m_axis_tuser  = out_user;

    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = status_overflow_r;
    assign status_bad_frame = status_bad_frame_r;
    assign status_good_frame = status_good_frame_r;

    // Pause active register
    always @(posedge clk or posedge rst) begin
        if (rst)
            pause_active <= 1'b0;
        else if (PAUSE_ENABLE) begin
            if (pause_req)
                pause_active <= 1'b1;
            else if (empty)
                pause_active <= 1'b0;
        end
    end

    // Frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 1'b0;
            frame_bad <= 1'b0;
            frame_oversize <= 1'b0;
            frame_count <= {ADDR_WIDTH+1{1'b0}};
        end else if (wr_en) begin
            if (frame_start) begin
                in_frame <= 1'b1;
                frame_bad <= frame_bad_detected;
                frame_oversize <= 1'b0;
                frame_count <= 1;
            end else if (in_frame) begin
                if (frame_bad_detected)
                    frame_bad <= 1'b1;
                if (frame_count == DEPTH[ADDR_WIDTH:0])
                    frame_oversize <= 1'b1;
                else
                    frame_count <= frame_count + 1;
                if (s_axis_tlast) begin
                    in_frame <= 1'b0;
                    frame_count <= {ADDR_WIDTH+1{1'b0}};
                end
            end
        end
    end

    // Write to RAM
    always @(posedge clk) begin
        if (wr_en) begin
            ram_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            ram_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_id[wr_ptr[ADDR_WIDTH-1:0]]   <= s_axis_tid;
            ram_dest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            ram_user[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Update pointers and depth
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH+1{1'b0}};
            rd_ptr <= {ADDR_WIDTH+1{1'b0}};
            depth <= {ADDR_WIDTH+1{1'b0}};
            depth_commit <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            if (wr_en) begin
                wr_ptr <= wr_ptr + 1;
                depth <= depth + 1;
            end
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
                depth <= depth - 1;
            end
            depth_commit <= depth;
        end
    end

    // Read from RAM and update output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= {DATA_WIDTH{1'b0}};
            out_keep <= {KEEP_WIDTH{1'b0}};
            out_last <= 1'b0;
            out_id   <= {ID_WIDTH{1'b0}};
            out_dest <= {DEST_WIDTH{1'b0}};
            out_user <= {USER_WIDTH{1'b0}};
        end else if (rd_en) begin
            out_data <= ram_rd_data;
            out_keep <= ram_rd_keep;
            out_last <= ram_rd_last;
            out_id   <= ram_rd_id;
            out_dest <= ram_rd_dest;
            out_user <= ram_rd_user;
        end
    end

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_r <= 1'b0;
            status_bad_frame_r <= 1'b0;
            status_good_frame_r <= 1'b0;
        end else begin
            // Overflow
            if (s_axis_tvalid && !s_axis_tready)
                status_overflow_r <= 1'b1;

            // Frame completion
            if (wr_en && s_axis_tlast) begin
                if (frame_bad || (DROP_BAD_FRAME && frame_bad_detected))
                    status_bad_frame_r <= 1'b1;
                else if (!frame_oversize || !DROP_OVERSIZE_FRAME)
                    status_good_frame_r <= 1'b1;
            end
        end
    end

endmodule

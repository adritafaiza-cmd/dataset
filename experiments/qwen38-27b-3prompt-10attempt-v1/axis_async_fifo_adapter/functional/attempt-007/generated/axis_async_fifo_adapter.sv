module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_data_in;
    wire [S_KEEP_WIDTH-1:0] s_keep_in;
    wire s_last_in;
    wire [ID_WIDTH-1:0] s_id_in;
    wire [DEST_WIDTH-1:0] s_dest_in;
    wire [USER_WIDTH-1:0] s_user_in;
    wire s_valid_in;
    wire s_ready_in;

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [PTR_WIDTH-1:0] w_ptr_sync;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg [S_DATA_WIDTH-1:0] w_data;
    reg [S_KEEP_WIDTH-1:0] w_keep;
    reg w_last;
    reg [ID_WIDTH-1:0] w_id;
    reg [DEST_WIDTH-1:0] w_dest;
    reg [USER_WIDTH-1:0] w_user;
    reg w_valid;
    reg w_ready;
    reg w_overflow;
    reg w_bad_frame;
    reg w_good_frame;
    reg w_pause_ack;
    reg w_pause_req_sync;
    reg [1:0] w_pause_req_sync_reg;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [PTR_WIDTH-1:0] r_ptr_sync;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [S_DATA_WIDTH-1:0] r_data;
    reg [S_KEEP_WIDTH-1:0] r_keep;
    reg r_last;
    reg [ID_WIDTH-1:0] r_id;
    reg [DEST_WIDTH-1:0] r_dest;
    reg [USER_WIDTH-1:0] r_user;
    reg r_valid;
    reg r_ready;
    reg r_overflow;
    reg r_bad_frame;
    reg r_good_frame;
    reg r_pause_ack;
    reg r_pause_req_sync;
    reg [1:0] r_pause_req_sync_reg;

    // RAM
    reg [S_DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Width adapter state
    reg [S_DATA_WIDTH-1:0] acc_data;
    reg [S_KEEP_WIDTH-1:0] acc_keep;
    reg acc_last;
    reg [ID_WIDTH-1:0] acc_id;
    reg [DEST_WIDTH-1:0] acc_dest;
    reg [USER_WIDTH-1:0] acc_user;
    reg acc_valid;
    reg acc_ready;
    reg acc_overflow;
    reg acc_bad_frame;
    reg acc_good_frame;

    // Output FIFO (if enabled)
    reg [M_DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [M_KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] out_w_ptr;
    reg [PTR_WIDTH-1:0] out_r_ptr;
    reg [PTR_WIDTH-1:0] out_w_ptr_sync;
    reg [PTR_WIDTH-1:0] out_r_ptr_sync;

    // Synchronization signals
    wire [PTR_WIDTH-1:0] w_ptr_to_m;
    wire [PTR_WIDTH-1:0] r_ptr_to_s;
    wire [PTR_WIDTH-1:0] out_w_ptr_to_m;
    wire [PTR_WIDTH-1:0] out_r_ptr_to_s;

    // 2-stage synchronizers
    reg [1:0] w_ptr_sync_reg;
    reg [1:0] r_ptr_sync_reg;
    reg [1:0] out_w_ptr_sync_reg;
    reg [1:0] out_r_ptr_sync_reg;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_raw;
    wire [PTR_WIDTH-1:0] m_depth_raw;
    wire [PTR_WIDTH-1:0] s_depth_commit_raw;
    wire [PTR_WIDTH-1:0] m_depth_commit_raw;

    assign s_depth_raw = w_ptr - r_ptr_sync;
    assign m_depth_raw = r_ptr - w_ptr_sync;
    assign s_depth_commit_raw = w_ptr_sync - r_ptr;
    assign m_depth_commit_raw = r_ptr_sync - w_ptr;

    assign s_status_depth = s_depth_raw;
    assign s_status_depth_commit = s_depth_commit_raw;
    assign m_status_depth = m_depth_raw;
    assign m_status_depth_commit = m_depth_commit_raw;

    // Pause logic
    assign s_pause_ack = w_pause_ack;
    assign m_pause_ack = r_pause_ack;

    // Write side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_data <= {S_DATA_WIDTH{1'b0}};
            w_keep <= {S_KEEP_WIDTH{1'b0}};
            w_last <= 1'b0;
            w_id <= {ID_WIDTH{1'b0}};
            w_dest <= {DEST_WIDTH{1'b0}};
            w_user <= {USER_WIDTH{1'b0}};
            w_valid <= 1'b0;
            w_ready <= 1'b0;
            w_overflow <= 1'b0;
            w_bad_frame <= 1'b0;
            w_good_frame <= 1'b0;
            w_pause_ack <= 1'b0;
            w_pause_req_sync_reg <= 2'b00;
            w_pause_req_sync <= 1'b0;
        end else begin
            // Synchronize pause request
            w_pause_req_sync_reg <= {w_pause_req_sync_reg[0], s_pause_req};
            w_pause_req_sync <= w_pause_req_sync_reg[1];

            // Pause acknowledgment
            if (w_pause_req_sync) begin
                w_pause_ack <= 1'b1;
            end else begin
                w_pause_ack <= 1'b0;
            end

            // Write ready logic
            if (w_pause_req_sync) begin
                w_ready <= 1'b0;
            end else begin
                w_ready <= (w_ptr - r_ptr_sync) < DEPTH;
            end

            // Write valid
            w_valid <= s_axis_tvalid & w_ready;

            // Write data
            if (w_valid) begin
                w_data <= s_axis_tdata;
                w_keep <= s_axis_tkeep;
                w_last <= s_axis_tlast;
                w_id <= s_axis_tid;
                w_dest <= s_axis_tdest;
                w_user <= s_axis_tuser;
                w_addr <= w_ptr[ADDR_WIDTH-1:0];
                w_ptr <= w_ptr + 1'b1;
            end

            // Status
            w_overflow <= w_overflow | (s_axis_tvalid & ~w_ready);
            w_bad_frame <= w_bad_frame | (s_axis_tvalid & s_axis_tlast & (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            w_good_frame <= w_good_frame | (s_axis_tvalid & s_axis_tlast & ~((s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE));
        end
    end

    // RAM write
    always @(posedge s_clk) begin
        if (w_valid) begin
            ram[w_addr] <= w_data;
            ram_keep[w_addr] <= w_keep;
            ram_last[w_addr] <= w_last;
            ram_id[w_addr] <= w_id;
            ram_dest[w_addr] <= w_dest;
            ram_user[w_addr] <= w_user;
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            r_data <= {S_DATA_WIDTH{1'b0}};
            r_keep <= {S_KEEP_WIDTH{1'b0}};
            r_last <= 1'b0;
            r_id <= {ID_WIDTH{1'b0}};
            r_dest <= {DEST_WIDTH{1'b0}};
            r_user <= {USER_WIDTH{1'b0}};
            r_valid <= 1'b0;
            r_ready <= 1'b0;
            r_overflow <= 1'b0;
            r_bad_frame <= 1'b0;
            r_good_frame <= 1'b0;
            r_pause_ack <= 1'b0;
            r_pause_req_sync_reg <= 2'b00;
            r_pause_req_sync <= 1'b0;
        end else begin
            // Synchronize pause request
            r_pause_req_sync_reg <= {r_pause_req_sync_reg[0], m_pause_req};
            r_pause_req_sync <= r_pause_req_sync_reg[1];

            // Pause acknowledgment
            if (r_pause_req_sync) begin
                r_pause_ack <= 1'b1;
            end else begin
                r_pause_ack <= 1'b0;
            end

            // Read ready logic
            if (r_pause_req_sync) begin
                r_ready <= 1'b0;
            end else begin
                r_ready <= (r_ptr - w_ptr_sync) < DEPTH;
            end

            // Read valid
            r_valid <= (r_ptr - w_ptr_sync) > 0;

            // Read data
            if (r_valid & r_ready) begin
                r_data <= ram[r_addr];
                r_keep <= ram_keep[r_addr];
                r_last <= ram_last[r_addr];
                r_id <= ram_id[r_addr];
                r_dest <= ram_dest[r_addr];
                r_user <= ram_user[r_addr];
                r_addr <= r_ptr[ADDR_WIDTH-1:0];
                r_ptr <= r_ptr + 1'b1;
            end

            // Status
            r_overflow <= r_overflow | (r_valid & ~r_ready);
            r_bad_frame <= r_bad_frame | (r_valid & r_last & (r_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            r_good_frame <= r_good_frame | (r_valid & r_last & ~((r_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE));
        end
    end

    // Width adapter
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            acc_data <= {S_DATA_WIDTH{1'b0}};
            acc_keep <= {S_KEEP_WIDTH{1'b0}};
            acc_last <= 1'b0;
            acc_id <= {ID_WIDTH{1'b0}};
            acc_dest <= {DEST_WIDTH{1'b0}};
            acc_user <= {USER_WIDTH{1'b0}};
            acc_valid <= 1'b0;
            acc_ready <= 1'b0;
            acc_overflow <= 1'b0;
            acc_bad_frame <= 1'b0;
            acc_good_frame <= 1'b0;
        end else begin
            // Accumulate data
            if (r_valid & r_ready) begin
                acc_data <= r_data;
                acc_keep <= r_keep;
                acc_last <= r_last;
                acc_id <= r_id;
                acc_dest <= r_dest;
                acc_user <= r_user;
                acc_valid <= 1'b1;
            end else if (acc_valid & acc_ready) begin
                acc_valid <= 1'b0;
            end

            // Output ready
            acc_ready <= m_axis_tready;

            // Status
            acc_overflow <= acc_overflow | (r_valid & ~r_ready);
            acc_bad_frame <= acc_bad_frame | (r_valid & r_last & (r_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            acc_good_frame <= acc_good_frame | (r_valid & r_last & ~((r_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE));
        end
    end

    // Output assignment
    assign m_axis_tdata = acc_data[M_DATA_WIDTH-1:0];
    assign m_axis_tkeep = acc_keep[M_KEEP_WIDTH-1:0];
    assign m_axis_tvalid = acc_valid;
    assign m_axis_tlast = acc_last;
    assign m_axis_tid = acc_id;
    assign m_axis_tdest = acc_dest;
    assign m_axis_tuser = acc_user;

    // Synchronization of pointers
    always @(posedge m_clk) begin
        w_ptr_sync_reg <= {w_ptr_sync_reg[0], w_ptr};
        w_ptr_sync <= w_ptr_sync_reg[1];
    end

    always @(posedge s_clk) begin
        r_ptr_sync_reg <= {r_ptr_sync_reg[0], r_ptr};
        r_ptr_sync <= r_ptr_sync_reg[1];
    end

    // Output FIFO logic (if enabled)
    generate
        if (OUTPUT_FIFO_ENABLE) begin
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    out_w_ptr <= {PTR_WIDTH{1'b0}};
                    out_r_ptr <= {PTR_WIDTH{1'b0}};
                    out_w_ptr_sync_reg <= 2'b00;
                    out_r_ptr_sync_reg <= 2'b00;
                    out_w_ptr_sync <= {PTR_WIDTH{1'b0}};
                    out_r_ptr_sync <= {PTR_WIDTH{1'b0}};
                end else begin
                    // Synchronize pointers
                    out_w_ptr_sync_reg <= {out_w_ptr_sync_reg[0], out_w_ptr};
                    out_w_ptr_sync <= out_w_ptr_sync_reg[1];
                    out_r_ptr_sync_reg <= {out_r_ptr_sync_reg[0], out_r_ptr};
                    out_r_ptr_sync <= out_r_ptr_sync_reg[1];

                    // Write to output FIFO
                    if (acc_valid & acc_ready) begin
                        out_fifo_data[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_data[M_DATA_WIDTH-1:0];
                        out_fifo_keep[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_keep[M_KEEP_WIDTH-1:0];
                        out_fifo_last[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_last;
                        out_fifo_id[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_id;
                        out_fifo_dest[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_dest;
                        out_fifo_user[out_w_ptr[ADDR_WIDTH-1:0]] <= acc_user;
                        out_w_ptr <= out_w_ptr + 1'b1;
                    end

                    // Read from output FIFO
                    if ((out_r_ptr - out_w_ptr_sync) > 0 & m_axis_tready) begin
                        out_r_ptr <= out_r_ptr + 1'b1;
                    end
                end
            end

            assign m_axis_tdata = out_fifo_data[out_r_ptr[ADDR_WIDTH-1:0]];
            assign m_axis_tkeep = out_fifo_keep[out_r_ptr[ADDR_WIDTH-1:0]];
            assign m_axis_tvalid = (out_r_ptr - out_w_ptr_sync) > 0;
            assign m_axis_tlast = out_fifo_last[out_r_ptr[ADDR_WIDTH-1:0]];
            assign m_axis_tid = out_fifo_id[out_r_ptr[ADDR_WIDTH-1:0]];
            assign m_axis_tdest = out_fifo_dest[out_r_ptr[ADDR_WIDTH-1:0]];
            assign m_axis_tuser = out_fifo_user[out_r_ptr[ADDR_WIDTH-1:0]];
        end else begin
            // Direct output
        end
    endgenerate

    // Input ready
    assign s_axis_tready = w_ready;

    // Status outputs
    assign s_status_overflow = w_overflow;
    assign s_status_bad_frame = w_bad_frame;
    assign s_status_good_frame = w_good_frame;
    assign m_status_overflow = r_overflow;
    assign m_status_bad_frame = r_bad_frame;
    assign m_status_good_frame = r_good_frame;

endmodule

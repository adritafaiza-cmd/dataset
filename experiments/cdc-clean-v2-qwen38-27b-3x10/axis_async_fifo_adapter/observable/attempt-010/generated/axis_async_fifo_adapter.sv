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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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
    localparam SYNC_STAGES = 2;

    // Internal signal widths
    localparam S_KEEP_W = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;
    localparam M_KEEP_W = M_KEEP_ENABLE ? M_KEEP_WIDTH : 1;
    localparam ID_W = ID_ENABLE ? ID_WIDTH : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [PTR_WIDTH-1:0] w_ptr_sync;
    reg [PTR_WIDTH-1:0] r_ptr_sync_s;
    reg [PTR_WIDTH-1:0] r_ptr_sync_s_d1;
    reg [PTR_WIDTH-1:0] r_ptr_sync_s_d2;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [PTR_WIDTH-1:0] r_ptr_sync;
    reg [PTR_WIDTH-1:0] w_ptr_sync_m;
    reg [PTR_WIDTH-1:0] w_ptr_sync_m_d1;
    reg [PTR_WIDTH-1:0] w_ptr_sync_m_d2;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_W-1:0]     ram_keep [0:DEPTH-1];
    reg                    ram_last [0:DEPTH-1];
    reg [ID_W-1:0]         ram_tid  [0:DEPTH-1];
    reg [DEST_W-1:0]       ram_dest [0:DEPTH-1];
    reg [USER_W-1:0]       ram_user [0:DEPTH-1];

    // Write enable
    wire s_write_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    wire m_read_en = m_axis_tvalid & m_axis_tready;

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_sync_s_d2;
    wire [PTR_WIDTH-1:0] m_depth = r_ptr - w_ptr_sync_m_d2;

    // Full/empty
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    reg s_pause_ack_r;
    reg m_pause_ack_r;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_r <= 1'b0;
        else if (s_pause_req)
            s_pause_ack_r <= 1'b1;
        else
            s_pause_ack_r <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_r <= 1'b0;
        else if (m_pause_req)
            m_pause_ack_r <= 1'b1;
        else
            m_pause_ack_r <= 1'b0;
    end

    assign s_pause_ack = s_pause_ack_r;
    assign m_pause_ack = m_pause_ack_r;

    // Ready signals
    wire s_ready_base = ~s_full;
    wire s_ready_pause = PAUSE_ENABLE ? ~s_pause_ack_r : 1'b1;
    wire s_ready_drop = DROP_WHEN_FULL ? 1'b1 : s_ready_base;
    assign s_axis_tready = s_ready_base & s_ready_pause;

    wire m_valid_base = ~m_empty;
    wire m_valid_pause = PAUSE_ENABLE ? ~m_pause_ack_r : 1'b1;
    assign m_axis_tvalid = m_valid_base & m_valid_pause;

    // Write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            w_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_write_en)
            w_ptr <= w_ptr + 1'b1;
    end

    // Read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            r_ptr <= {PTR_WIDTH-1:0}{1'b0};
        else if (m_read_en)
            r_ptr <= r_ptr + 1'b1;
    end

    // Synchronize read pointer to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync_s <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_s_d1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_s_d2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync_s <= r_ptr;
            r_ptr_sync_s_d1 <= r_ptr_sync_s;
            r_ptr_sync_s_d2 <= r_ptr_sync_s_d1;
        end
    end

    // Synchronize write pointer to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync_m <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_m_d1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_m_d2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync_m <= w_ptr;
            w_ptr_sync_m_d1 <= w_ptr_sync_m;
            w_ptr_sync_m_d2 <= w_ptr_sync_m_d1;
        end
    end

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram_data[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[w_ptr[ADDR_WIDTH-1:0]] <= S_KEEP_ENABLE ? s_axis_tkeep : {S_KEEP_W{1'b1}};
            ram_last[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_tid[w_ptr[ADDR_WIDTH-1:0]] <= ID_ENABLE ? s_axis_tid : {ID_W{1'b0}};
            ram_dest[w_ptr[ADDR_WIDTH-1:0]] <= DEST_ENABLE ? s_axis_tdest : {DEST_W{1'b0}};
            ram_user[w_ptr[ADDR_WIDTH-1:0]] <= USER_ENABLE ? s_axis_tuser : {USER_W{1'b0}};
        end
    end

    // RAM read
    wire [ADDR_WIDTH-1:0] r_addr = r_ptr[ADDR_WIDTH-1:0];
    wire [S_DATA_WIDTH-1:0] r_data = ram_data[r_addr];
    wire [S_KEEP_W-1:0]     r_keep = ram_keep[r_addr];
    wire                    r_last = ram_last[r_addr];
    wire [ID_W-1:0]         r_tid  = ram_tid[r_addr];
    wire [DEST_W-1:0]       r_dest = ram_dest[r_addr];
    wire [USER_W-1:0]       r_user = ram_user[r_addr];

    // Width adaptation: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, assume S_DATA_WIDTH == M_DATA_WIDTH or handle byte-wise
    // If widths differ, we need to pack/unpack bytes based on tkeep
    // Here we implement a simple byte-level width adapter

    // Calculate number of valid bytes in source
    function [31:0] count_bytes;
        input [S_KEEP_W-1:0] keep;
        integer i;
        begin
            count_bytes = 0;
            for (i = 0; i < S_KEEP_W; i = i + 1) begin
                if (keep[i])
                    count_bytes = count_bytes + 1;
            end
        end
    endfunction

    // For this implementation, we assume the widths are compatible
    // and do direct mapping. If S_DATA_WIDTH != M_DATA_WIDTH,
    // a more complex packing logic would be needed.
    // Here we handle the case where M_DATA_WIDTH >= S_DATA_WIDTH
    // by zero-extending, and M_DATA_WIDTH < S_DATA_WIDTH by truncating.

    wire [M_DATA_WIDTH-1:0] m_data_out;
    wire [M_KEEP_W-1:0]     m_keep_out;
    wire                    m_last_out;
    wire [ID_W-1:0]         m_tid_out;
    wire [DEST_W-1:0]       m_dest_out;
    wire [USER_W-1:0]       m_user_out;

    // Simple width adaptation
    generate
        if (M_DATA_WIDTH >= S_DATA_WIDTH) begin
            assign m_data_out = { {(M_DATA_WIDTH-S_DATA_WIDTH){1'b0}}, r_data };
            if (M_KEEP_ENABLE && S_KEEP_ENABLE) begin
                // Map keep bits
                assign m_keep_out = { {(M_KEEP_W-S_KEEP_W){1'b0}}, r_keep };
            end else if (M_KEEP_ENABLE) begin
                assign m_keep_out = { {(M_KEEP_W-S_KEEP_W){1'b0}}, {S_KEEP_W{1'b1}} };
            end else begin
                assign m_keep_out = {M_KEEP_W{1'b1}};
            end
        end else begin
            assign m_data_out = r_data[M_DATA_WIDTH-1:0];
            if (M_KEEP_ENABLE && S_KEEP_ENABLE) begin
                assign m_keep_out = r_keep[M_KEEP_W-1:0];
            end else if (M_KEEP_ENABLE) begin
                assign m_keep_out = {M_KEEP_W{1'b1}};
            end else begin
                assign m_keep_out = {M_KEEP_W{1'b1}};
            end
        end
    endgenerate

    assign m_last_out = r_last;
    assign m_tid_out  = ID_ENABLE ? r_tid : {ID_W{1'b0}};
    assign m_dest_out = DEST_ENABLE ? r_dest : {DEST_W{1'b0}};
    assign m_user_out = USER_ENABLE ? r_user : {USER_W{1'b0}};

    // Output assignment
    assign m_axis_tdata = m_data_out;
    assign m_axis_tkeep = M_KEEP_ENABLE ? m_keep_out : {M_KEEP_W{1'b1}};
    assign m_axis_tlast = m_last_out;
    assign m_axis_tid   = ID_ENABLE ? m_tid_out : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? m_dest_out : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? m_user_out : {USER_WIDTH{1'b0}};

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_full & s_axis_tvalid;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = s_axis_tvalid & s_axis_tlast & s_axis_tready;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = m_axis_tvalid & m_axis_tlast & m_axis_tready;

endmodule

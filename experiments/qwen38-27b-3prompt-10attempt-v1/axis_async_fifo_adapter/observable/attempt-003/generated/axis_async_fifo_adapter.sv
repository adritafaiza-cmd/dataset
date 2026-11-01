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
    wire [S_DATA_WIDTH-1:0] s_tdata;
    wire [S_KEEP_WIDTH-1:0] s_tkeep;
    wire s_tvalid;
    wire s_tready;
    wire s_tlast;
    wire [ID_WIDTH-1:0] s_tid;
    wire [DEST_WIDTH-1:0] s_tdest;
    wire [USER_WIDTH-1:0] s_tuser;

    assign s_tdata = s_axis_tdata;
    assign s_tkeep = s_axis_tkeep;
    assign s_tvalid = s_axis_tvalid;
    assign s_tlast = s_axis_tlast;
    assign s_tid = s_axis_tid;
    assign s_tdest = s_axis_tdest;
    assign s_tuser = s_axis_tuser;

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg w_ptr_sync_reg [0:1];
    reg w_ptr_sync_reg2 [0:1];

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg r_ptr_sync_reg [0:1];
    reg r_ptr_sync_reg2 [0:1];

    // RAM
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser [0:DEPTH-1];

    // Write enable
    wire w_en = s_tvalid & s_tready;

    // Read enable
    wire r_en = m_axis_tvalid & m_axis_tready;

    // Full/Empty logic
    wire [PTR_WIDTH-1:0] w_ptr_synced;
    wire [PTR_WIDTH-1:0] r_ptr_synced;

    assign w_ptr_synced = w_ptr_sync_reg2[1];
    assign r_ptr_synced = r_ptr_sync_reg2[1];

    wire fifo_full = (w_ptr_synced == {r_ptr_synced[ADDR_WIDTH], ~r_ptr_synced[ADDR_WIDTH-1:0]});
    wire fifo_empty = (w_ptr_synced == r_ptr_synced);

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status registers
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;

    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_synced;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_synced - r_ptr;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Synchronous reset for write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_reg2[0] <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_reg2[1] <= {PTR_WIDTH{1'b0}};
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            w_ptr_sync_reg[0] <= w_ptr;
            w_ptr_sync_reg[1] <= w_ptr_sync_reg[0];
            w_ptr_sync_reg2[0] <= w_ptr_sync_reg[1];
            w_ptr_sync_reg2[1] <= w_ptr_sync_reg2[0];

            if (s_pause_req) begin
                s_pause_ack_reg <= 1'b1;
            end else begin
                s_pause_ack_reg <= 1'b0;
            end

            if (w_en) begin
                ram_data[w_addr] <= s_tdata;
                ram_keep[w_addr] <= s_tkeep;
                ram_last[w_addr] <= s_tlast;
                ram_tid[w_addr] <= s_tid;
                ram_tdest[w_addr] <= s_tdest;
                ram_tuser[w_addr] <= s_tuser;

                w_addr <= w_addr + 1'b1;
                w_ptr <= w_ptr + 1'b1;

                if (s_tlast) begin
                    s_good_frame_reg <= 1'b1;
                end
            end
        end
    end

    // Synchronous reset for read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            r_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_reg2[0] <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_reg2[1] <= {PTR_WIDTH{1'b0}};
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            r_ptr_sync_reg[0] <= r_ptr;
            r_ptr_sync_reg[1] <= r_ptr_sync_reg[0];
            r_ptr_sync_reg2[0] <= r_ptr_sync_reg[1];
            r_ptr_sync_reg2[1] <= r_ptr_sync_reg2[0];

            if (m_pause_req) begin
                m_pause_ack_reg <= 1'b1;
            end else begin
                m_pause_ack_reg <= 1'b0;
            end

            if (r_en) begin
                r_addr <= r_addr + 1'b1;
                r_ptr <= r_ptr + 1'b1;

                if (ram_last[r_addr]) begin
                    m_good_frame_reg <= 1'b1;
                end
            end
        end
    end

    // Output data
    assign m_axis_tdata = ram_data[r_addr];
    assign m_axis_tkeep = ram_keep[r_addr];
    assign m_axis_tlast = ram_last[r_addr];
    assign m_axis_tid = ram_tid[r_addr];
    assign m_axis_tdest = ram_tdest[r_addr];
    assign m_axis_tuser = ram_tuser[r_addr];

    // Valid/Ready logic
    assign m_axis_tvalid = ~fifo_empty;
    assign s_axis_tready = ~fifo_full;

endmodule

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
    localparam S_BYTES = S_DATA_WIDTH / 8;
    localparam M_BYTES = M_DATA_WIDTH / 8;
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;
    localparam ACC_WIDTH = MAX_BYTES * 8;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_tdata_int = s_axis_tdata;
    wire [S_KEEP_WIDTH-1:0] s_tkeep_int = S_KEEP_ENABLE ? s_axis_tkeep : {S_KEEP_WIDTH{1'b1}};
    wire [ID_WIDTH-1:0]     s_tid_int   = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    wire [DEST_WIDTH-1:0]   s_tdest_int = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    wire [USER_WIDTH-1:0]   s_tuser_int = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [PTR_WIDTH-1:0] w_ptr_commit;
    reg [PTR_WIDTH-1:0] r_ptr_sync;
    reg [PTR_WIDTH-1:0] r_ptr_commit_sync;
    reg [PTR_WIDTH-1:0] r_ptr_sync_d1, r_ptr_sync_d2;
    reg [PTR_WIDTH-1:0] r_ptr_commit_sync_d1, r_ptr_commit_sync_d2;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [PTR_WIDTH-1:0] r_ptr_commit;
    reg [PTR_WIDTH-1:0] w_ptr_sync;
    reg [PTR_WIDTH-1:0] w_ptr_commit_sync;
    reg [PTR_WIDTH-1:0] w_ptr_sync_d1, w_ptr_sync_d2;
    reg [PTR_WIDTH-1:0] w_ptr_commit_sync_d1, w_ptr_commit_sync_d2;

    // RAM
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                    ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]     ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]   ram_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]   ram_tuser [0:DEPTH-1];

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_sync;
    wire [PTR_WIDTH-1:0] s_depth_commit = w_ptr_commit - r_ptr_commit_sync;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_sync - r_ptr;
    wire [PTR_WIDTH-1:0] m_depth_commit = w_ptr_commit_sync - r_ptr_commit;

    // Full/Empty
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    reg s_paused;
    reg m_paused;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_paused <= 1'b0;
        else if (PAUSE_ENABLE)
            s_paused <= s_pause_req;
        else
            s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_paused <= 1'b0;
        else if (PAUSE_ENABLE)
            m_paused <= m_pause_req;
        else
            m_paused <= 1'b0;
    end

    // Frame tracking for write side
    reg s_in_frame;
    reg [ACC_WIDTH-1:0] s_frame_bytes;
    reg s_bad_frame;
    reg s_overflow;
    reg s_good_frame;

    // Frame tracking for read side
    reg m_in_frame;
    reg [ACC_WIDTH-1:0] m_frame_bytes;
    reg m_bad_frame;
    reg m_overflow;
    reg m_good_frame;

    // Width adaptation accumulator
    reg [ACC_WIDTH-1:0] acc_data;
    reg [MAX_BYTES-1:0] acc_keep;
    reg [ACC_WIDTH-1:0] acc_bytes;
    reg                 acc_last;
    reg [ID_WIDTH-1:0]  acc_tid;
    reg [DEST_WIDTH-1:0] acc_tdest;
    reg [USER_WIDTH-1:0] acc_tuser;
    reg                 acc_valid;

    // Output register
    reg [M_DATA_WIDTH-1:0] out_tdata;
    reg [M_KEEP_WIDTH-1:0] out_tkeep;
    reg                    out_tlast;
    reg [ID_WIDTH-1:0]     out_tid;
    reg [DEST_WIDTH-1:0]   out_tdest;
    reg [USER_WIDTH-1:0]   out_tuser;
    reg                    out_valid;

    // RAM read pipeline
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [S_DATA_WIDTH-1:0] rd_data;
    reg [S_KEEP_WIDTH-1:0] rd_keep;
    reg                    rd_last;
    reg [ID_WIDTH-1:0]     rd_tid;
    reg [DEST_WIDTH-1:0]   rd_tdest;
    reg [USER_WIDTH-1:0]   rd_tuser;
    reg                    rd_valid;

    // Synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync_d1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync_d2 <= {PTR_WIDTH{1'b0}};
            r_ptr_commit_sync_d1 <= {PTR_WIDTH{1'b0}};
            r_ptr_commit_sync_d2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync_d1 <= r_ptr;
            r_ptr_sync_d2 <= r_ptr_sync_d1;
            r_ptr_commit_sync_d1 <= r_ptr_commit;
            r_ptr_commit_sync_d2 <= r_ptr_commit_sync_d1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync_d1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync_d2 <= {PTR_WIDTH{1'b0}};
            w_ptr_commit_sync_d1 <= {PTR_WIDTH{1'b0}};
            w_ptr_commit_sync_d2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync_d1 <= w_ptr;
            w_ptr_sync_d2 <= w_ptr_sync_d1;
            w_ptr_commit_sync_d1 <= w_ptr_commit;
            w_ptr_commit_sync_d2 <= w_ptr_commit_sync_d1;
        end
    end

    assign r_ptr_sync = r_ptr_sync_d2;
    assign r_ptr_commit_sync = r_ptr_commit_sync_d2;
    assign w_ptr_sync = w_ptr_sync_d2;
    assign w_ptr_commit_sync = w_ptr_commit_sync_d2;

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_ptr_commit <= {PTR_WIDTH{1'b0}};
        end else begin
            if (s_write_en) begin
                w_ptr <= w_ptr + 1'b1;
                w_ptr_commit <= w_ptr + 1'b1;
            end
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_ptr_commit <= {PTR_WIDTH{1'b0}};
        end else begin
            if (m_read_en) begin
                r_ptr <= r_ptr + 1'b1;
                r_ptr_commit <= r_ptr + 1'b1;
            end
        end
    end

    // RAM write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // No reset needed for RAM
        end else if (s_write_en) begin
            ram_data[w_ptr[ADDR_WIDTH-1:0]] <= s_tdata_int;
            ram_keep[w_ptr[ADDR_WIDTH-1:0]] <= s_tkeep_int;
            ram_last[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_tid[w_ptr[ADDR_WIDTH-1:0]] <= s_tid_int;
            ram_tdest[w_ptr[ADDR_WIDTH-1:0]] <= s_tdest_int;
            ram_tuser[w_ptr[ADDR_WIDTH-1:0]] <= s_tuser_int;
        end
    end

    // RAM read
    assign rd_addr = r_ptr[ADDR_WIDTH-1:0];

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= m_read_en;
            if (m_read_en) begin
                rd_data <= ram_data[rd_addr];
                rd_keep <= ram_keep[rd_addr];
                rd_last <= ram_last[rd_addr];
                rd_tid <= ram_tid[rd_addr];
                rd_tdest <= ram_tdest[rd_addr];
                rd_tuser <= ram_tuser[rd_addr];
            end
        end
    end

    // Width adaptation logic
    // Calculate number of valid bytes in input
    function [MAX_BYTES-1:0] count_bytes;
        input [S_KEEP_WIDTH-1:0] keep;
        integer i;
        begin
            count_bytes = 0;
            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                if (keep[i])
                    count_bytes = count_bytes + 1'b1;
            end
        end
    endfunction

    wire [MAX_BYTES-1:0] s_valid_bytes = count_bytes(s_tkeep_int);

    // Accumulate data
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            acc_data <= {ACC_WIDTH{1'b0}};
            acc_keep <= {MAX_BYTES{1'b0}};
            acc_bytes <= {ACC_WIDTH{1'b0}};
            acc_last <= 1'b0;
            acc_tid <= {ID_WIDTH{1'b0}};
            acc_tdest <= {DEST_WIDTH{1'b0}};
            acc_tuser <= {USER_WIDTH{1'b0}};
            acc_valid <= 1'b0;
        end else begin
            // Shift in new data if available
            if (rd_valid) begin
                // Append new data to accumulator
                // Simple approach: store in a shift register
                // For simplicity, we'll use a basic accumulation
                // This is a simplified version - in practice, you'd need proper byte alignment
                acc_data <= {rd_data, acc_data[ACC_WIDTH-1:S_DATA_WIDTH]};
                acc_keep <= {rd_keep, acc_keep[MAX_BYTES-1:S_KEEP_WIDTH]};
                acc_bytes <= acc_bytes + s_valid_bytes;
                acc_last <= acc_last | rd_last;
                acc_tid <= rd_tid;
                acc_tdest <= rd_tdest;
                acc_tuser <= rd_tuser;
                acc_valid <= 1'b1;
            end

            // Output if we have enough bytes
            if (acc_valid && (acc_bytes >= M_BYTES)) begin
                // Output M_BYTES worth of data
                out_tdata <= acc_data[M_DATA_WIDTH-1:0];
                out_tkeep <= acc_keep[M_KEEP_WIDTH-1:0];
                out_tlast <= acc_last && (acc_bytes == M_BYTES);
                out_tid <= acc_tid;
                out_tdest <= acc_tdest;
                out_tuser <= acc_tuser;
                out_valid <= 1'b1;

                // Shift out M_BYTES
                acc_data <= acc_data[ACC_WIDTH-1:M_DATA_WIDTH];
                acc_keep <= acc_keep[MAX_BYTES-1:M_KEEP_WIDTH];
                acc_bytes <= acc_bytes - M_BYTES;
                if (acc_bytes == M_BYTES) begin
                    acc_last <= 1'b0;
                    acc_valid <= 1'b0;
                end
            end else begin
                out_valid <= 1'b0;
            end
        end
    end

    // Output
    assign m_axis_tdata = out_tdata;
    assign m_axis_tkeep = out_tkeep;
    assign m_axis_tvalid = out_valid && !m_paused;
    assign m_axis_tlast = out_tlast;
    assign m_axis_tid = out_tid;
    assign m_axis_tdest = out_tdest;
    assign m_axis_tuser = out_tuser;

    // Ready signals
    assign s_axis_tready = !s_full && !s_paused && !s_overflow;
    assign m_axis_tready = 1'b1;

    // Status
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Pause ack
    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Frame tracking (simplified)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_bytes <= {ACC_WIDTH{1'b0}};
            s_bad_frame <= 1'b0;
            s_overflow <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_write_en) begin
                s_frame_bytes <= s_frame_bytes + s_valid_bytes;
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    s_frame_bytes <= {ACC_WIDTH{1'b0}};
                    s_good_frame <= 1'b1;
                end else begin
                    s_in_frame <= 1'b1;
                end
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_bytes <= {ACC_WIDTH{1'b0}};
            m_bad_frame <= 1'b0;
            m_overflow <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_read_en) begin
                m_frame_bytes <= m_frame_bytes + M_BYTES;
                if (out_tlast) begin
                    m_in_frame <= 1'b0;
                    m_frame_bytes <= {ACC_WIDTH{1'b0}};
                    m_good_frame <= 1'b1;
                end else begin
                    m_in_frame <= 1'b1;
                end
            end
        end
    end

endmodule

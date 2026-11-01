module axis_async_fifo #
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
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
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
    input  wire                   m_clk,
    input  wire                   m_rst,
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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire [DATA_WIDTH-1:0] ram_data;
    wire [KEEP_WIDTH-1:0] ram_keep;
    wire s_axis_tlast_ram;
    wire [ID_WIDTH-1:0] ram_tid;
    wire [DEST_WIDTH-1:1] ram_tdest;
    wire [USER_WIDTH-1:0] ram_tuser;

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg w_ram_en;
    reg [DATA_WIDTH-1:0] w_ram_data;
    reg [KEEP_WIDTH-1:0] w_ram_keep;
    reg w_ram_tlast;
    reg [ID_WIDTH-1:0] w_ram_tid;
    reg [DEST_WIDTH-1:0] w_ram_tdest;
    reg [USER_WIDTH-1:0] w_ram_tuser;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg r_ram_en;

    // Gray code pointers for CDC
    wire [PTR_WIDTH-1:0] w_ptr_gray;
    wire [PTR_WIDTH-1:0] r_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_gray_m_sync1, w_ptr_gray_m_sync2;
    reg [PTR_WIDTH-1:0] r_ptr_gray_s_sync1, r_ptr_gray_s_sync2;

    // Depth calculation
    wire [PTR_WIDTH-1:0] w_ptr_gray_m_sync2_inv;
    wire [PTR_WIDTH-1:0] r_ptr_gray_s_sync2_inv;
    wire [PTR_WIDTH-1:0] depth_s_raw;
    wire [PTR_WIDTH-1:0] depth_m_raw;

    // Status flags
    reg s_status_overflow_r;
    reg s_status_bad_frame_r;
    reg s_status_good_frame_r;
    reg m_status_overflow_r;
    reg m_status_bad_frame_r;
    reg m_status_good_frame_r;

    // Pause logic
    reg s_pause_ack_r;
    reg m_pause_ack_r;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [USER_WIDTH-1:0] s_frame_user;
    reg [USER_WIDTH-1:0] m_frame_user;

    // Bad frame detection
    wire s_bad_frame;
    wire m_bad_frame;

    // Drop logic
    wire s_drop;
    wire m_drop;

    // Full/Empty
    wire s_full;
    wire m_empty;

    // Assignments
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : ~s_full;
    assign s_pause_ack = s_pause_ack_r;
    assign m_pause_ack = m_pause_ack_r;

    assign s_status_depth = depth_s_raw;
    assign s_status_depth_commit = depth_s_raw;
    assign s_status_overflow = s_status_overflow_r;
    assign s_status_bad_frame = s_status_bad_frame_r;
    assign s_status_good_frame = s_status_good_frame_r;

    assign m_status_depth = depth_m_raw;
    assign m_status_depth_commit = depth_m_raw;
    assign m_status_overflow = m_status_overflow_r;
    assign m_status_bad_frame = m_status_bad_frame_r;
    assign m_status_good_frame = m_status_good_frame_r;

    // Gray code conversion
    assign w_ptr_gray = w_ptr ^ (w_ptr >> 1);
    assign r_ptr_gray = r_ptr ^ (r_ptr >> 1);

    // Synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_m_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_gray_m_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray_m_sync1 <= w_ptr_gray;
            w_ptr_gray_m_sync2 <= w_ptr_gray_m_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_s_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_gray_s_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray_s_sync1 <= r_ptr_gray;
            r_ptr_gray_s_sync2 <= r_ptr_gray_s_sync1;
        end
    end

    // Binary conversion from gray
    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray[i] ^ gray_to_bin[i+1];
            end
        end
    endfunction

    wire [PTR_WIDTH-1:0] w_ptr_m_bin;
    wire [PTR_WIDTH-1:0] r_ptr_s_bin;

    assign w_ptr_m_bin = gray_to_bin(w_ptr_gray_m_sync2);
    assign r_ptr_s_bin = gray_to_bin(r_ptr_gray_s_sync2);

    // Depth calculation
    assign depth_s_raw = w_ptr - r_ptr_s_bin;
    assign depth_m_raw = w_ptr_m_bin - r_ptr;

    // Full/Empty
    assign s_full = (depth_s_raw == DEPTH);
    assign m_empty = (depth_m_raw == 0);

    // Write enable
    assign w_ram_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire r_ram_en;
    assign r_ram_en = m_axis_tvalid && m_axis_tready;

    // RAM
    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep_reg [0:DEPTH-1];
    reg ram_tlast_reg [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_tid_reg [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest_reg [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser_reg [0:DEPTH-1];

    always @(posedge s_clk) begin
        if (w_ram_en) begin
            ram[w_addr] <= w_ram_data;
            ram_keep_reg[w_addr] <= w_ram_keep;
            ram_tlast_reg[w_addr] <= w_ram_tlast;
            ram_tid_reg[w_addr] <= w_ram_tid;
            ram_tdest_reg[w_addr] <= w_ram_tdest;
            ram_tuser_reg[w_addr] <= w_ram_tuser;
        end
    end

    // Read data
    wire [DATA_WIDTH-1:0] ram_data_out;
    wire [KEEP_WIDTH-1:0] ram_keep_out;
    wire ram_tlast_out;
    wire [ID_WIDTH-1:0] ram_tid_out;
    wire [DEST_WIDTH-1:0] ram_tdest_out;
    wire [USER_WIDTH-1:0] ram_tuser_out;

    assign ram_data_out = ram[r_addr];
    assign ram_keep_out = ram_keep_reg[r_addr];
    assign ram_tlast_out = ram_tlast_reg[r_addr];
    assign ram_tid_out = ram_tid_reg[r_addr];
    assign ram_tdest_out = ram_tdest_reg[r_addr];
    assign ram_tuser_out = ram_tuser_reg[r_addr];

    // Output FIFO
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg out_fifo_tlast [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_tuser [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] out_fifo_w_ptr;
    reg [PTR_WIDTH-1:0] out_fifo_r_ptr;
    reg out_fifo_w_en;
    reg out_fifo_r_en;

    wire out_fifo_full;
    wire out_fifo_empty;

    assign out_fifo_full = (out_fifo_w_ptr - out_fifo_r_ptr == DEPTH);
    assign out_fifo_empty = (out_fifo_w_ptr == out_fifo_r_ptr);

    // Output FIFO write
    assign out_fifo_w_en = r_ram_en;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_fifo_w_ptr <= {PTR_WIDTH{1'b0}};
            out_fifo_r_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (out_fifo_w_en) begin
                out_fifo_w_ptr <= out_fifo_w_ptr + 1'b1;
                out_fifo_data[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_data_out;
                out_fifo_keep[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_keep_out;
                out_fifo_tlast[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_tlast_out;
                out_fifo_tid[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_tid_out;
                out_fifo_tdest[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_tdest_out;
                out_fifo_tuser[out_fifo_w_ptr[ADDR_WIDTH-1:0]] <= ram_tuser_out;
            end
            if (out_fifo_r_en) begin
                out_fifo_r_ptr <= out_fifo_r_ptr + 1'b1;
            end
        end
    end

    // Output FIFO read
    assign out_fifo_r_en = m_axis_tvalid && m_axis_tready;

    // Output signals
    assign m_axis_tdata = out_fifo_data[out_fifo_r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = out_fifo_keep[out_fifo_r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tlast = out_fifo_tlast[out_fifo_r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tid = out_fifo_tid[out_fifo_r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tdest = out_fifo_tdest[out_fifo_r_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tuser = out_fifo_tuser[out_fifo_r_ptr[ADDR_WIDTH-1:0]];

    assign m_axis_tvalid = ~out_fifo_empty;

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_ram_data <= {DATA_WIDTH{1'b0}};
            w_ram_keep <= {KEEP_WIDTH{1'b0}};
            w_ram_tlast <= 1'b0;
            w_ram_tid <= {ID_WIDTH{1'b0}};
            w_ram_tdest <= {DEST_WIDTH{1'b0}};
            w_ram_tuser <= {USER_WIDTH{1'b0}};
            s_status_overflow_r <= 1'b0;
            s_status_bad_frame_r <= 1'b0;
            s_status_good_frame_r <= 1'b0;
            s_pause_ack_r <= 1'b0;
            s_in_frame <= 1'b0;
            s_frame_user <= {USER_WIDTH{1'b0}};
        end else begin
            if (w_ram_en) begin
                w_ptr <= w_ptr + 1'b1;
                w_addr <= w_addr + 1'b1;
                w_ram_data <= s_axis_tdata;
                w_ram_keep <= s_axis_tkeep;
                w_ram_tlast <= s_axis_tlast;
                w_ram_tid <= s_axis_tid;
                w_ram_tdest <= s_axis_tdest;
                w_ram_tuser <= s_axis_tuser;
            end

            // Status updates
            if (s_full && s_axis_tvalid) begin
                s_status_overflow_r <= 1'b1;
            end

            // Frame tracking
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    s_status_good_frame_r <= 1'b1;
                end else begin
                    s_in_frame <= 1'b1;
                end
            end

            // Pause
            if (PAUSE_ENABLE) begin
                if (s_pause_req) begin
                    s_pause_ack_r <= 1'b1;
                end else begin
                    s_pause_ack_r <= 1'b0;
                end
            end
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            m_status_overflow_r <= 1'b0;
            m_status_bad_frame_r <= 1'b0;
            m_status_good_frame_r <= 1'b0;
            m_pause_ack_r <= 1'b0;
            m_in_frame <= 1'b0;
            m_frame_user <= {USER_WIDTH{1'b0}};
        end else begin
            if (r_ram_en) begin
                r_ptr <= r_ptr + 1'b1;
                r_addr <= r_addr + 1'b1;
            end

            // Status updates
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tlast) begin
                    m_in_frame <= 1'b0;
                    m_status_good_frame_r <= 1'b1;
                end else begin
                    m_in_frame <= 1'b1;
                end
            end

            // Pause
            if (PAUSE_ENABLE) begin
                if (m_pause_req) begin
                    m_pause_ack_r <= 1'b1;
                end else begin
                    m_pause_ack_r <= 1'b0;
                end
            end
        end
    end

endmodule

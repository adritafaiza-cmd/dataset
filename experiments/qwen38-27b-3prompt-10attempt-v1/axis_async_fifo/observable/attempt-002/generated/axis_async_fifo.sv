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

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_DATA_WIDTH-1:0] ram_data;
    wire [ADDR_WIDTH-1:0] ram_addr;
    wire ram_we;
    wire [TOTAL_DATA_WIDTH-1:0] ram_rdata;
    wire [ADDR_WIDTH-1:0] ram_raddr;
    wire ram_re;

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg w_valid;
    reg w_last;
    reg w_bad_frame;
    reg w_overflow;
    reg w_good_frame;
    reg w_bad_frame_pulse;
    reg w_good_frame_pulse;

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg r_valid;
    reg r_last;
    reg r_bad_frame;
    reg r_overflow;
    reg r_good_frame;
    reg r_bad_frame_pulse;
    reg r_good_frame_pulse;

    // Gray code pointers for CDC
    wire [PTR_WIDTH-1:0] w_ptr_gray;
    wire [PTR_WIDTH-1:0] r_ptr_gray;
    wire [PTR_WIDTH-1:0] w_ptr_gray_sync1;
    wire [PTR_WIDTH-1:0] w_ptr_gray_sync2;
    wire [PTR_WIDTH-1:0] r_ptr_gray_sync1;
    wire [PTR_WIDTH-1:0] r_ptr_gray_sync2;

    // Binary pointers from gray code
    wire [PTR_WIDTH-1:0] w_ptr_bin_sync;
    wire [PTR_WIDTH-1:0] r_ptr_bin_sync;

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;
    wire [PTR_WIDTH-1:0] s_depth_commit;
    wire [PTR_WIDTH-1:0] m_depth_commit;

    // Full/Empty
    wire s_full;
    wire m_empty;

    // Pause signals
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    wire s_paused;
    wire m_paused;

    // Frame tracking
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg frame_drop;
    reg frame_mark;

    // Output register
    reg [DATA_WIDTH-1:0] out_tdata;
    reg [KEEP_WIDTH-1:0] out_tkeep;
    reg out_tlast;
    reg [ID_WIDTH-1:0] out_tid;
    reg [DEST_WIDTH-1:0] out_tdest;
    reg [USER_WIDTH-1:0] out_tuser;
    reg out_tvalid;
    reg out_tready_int;

    // Helper functions
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Gray code conversion
    assign w_ptr_gray = bin2gray(w_ptr);
    assign r_ptr_gray = bin2gray(r_ptr);

    // Synchronizers for write pointer (to m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    // Synchronizers for read pointer (to s_clk domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

    // Convert gray to binary
    assign w_ptr_bin_sync = gray2bin(w_ptr_gray_sync2);
    assign r_ptr_bin_sync = gray2bin(r_ptr_gray_sync2);

    // Depth calculations
    assign s_depth = w_ptr - r_ptr_bin_sync;
    assign m_depth = w_ptr_bin_sync - r_ptr;
    assign s_depth_commit = w_ptr - r_ptr_bin_sync;
    assign m_depth_commit = w_ptr_bin_sync - r_ptr;

    // Full/Empty
    assign s_full = (s_depth >= DEPTH);
    assign m_empty = (m_depth == 0);

    // Pause logic
    assign s_paused = (PAUSE_ENABLE && s_pause_req);
    assign m_paused = (PAUSE_ENABLE && m_pause_req);

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_reg <= 1'b0;
        else
            s_pause_ack_reg <= s_pause_req;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_reg <= 1'b0;
        else
            m_pause_ack_reg <= m_pause_req;
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Frame tracking in s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            in_frame <= 1'b0;
            frame_bad <= 1'b0;
            frame_oversize <= 1'b0;
            frame_drop <= 1'b0;
            frame_mark <= 1'b0;
        end else begin
            if (w_valid && w_last) begin
                in_frame <= 1'b0;
                frame_bad <= 1'b0;
                frame_oversize <= 1'b0;
                frame_drop <= 1'b0;
                frame_mark <= 1'b0;
            end else if (w_valid && !in_frame) begin
                in_frame <= 1'b1;
                frame_bad <= 1'b0;
                frame_oversize <= 1'b0;
                frame_drop <= 1'b0;
                frame_mark <= 1'b0;
            end else if (w_valid && in_frame) begin
                // Check for bad frame
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    frame_bad <= 1'b1;
                // Check for oversize frame
                if (FRAME_FIFO && (s_depth >= DEPTH))
                    frame_oversize <= 1'b1;
            end
        end
    end

    // Determine if current beat should be dropped or marked
    wire drop_beat = (DROP_WHEN_FULL && s_full) || 
                     (DROP_BAD_FRAME && frame_bad) ||
                     (DROP_OVERSIZE_FRAME && frame_oversize);
    wire mark_beat = (MARK_WHEN_FULL && s_full) ||
                     (DROP_BAD_FRAME && frame_bad) ||
                     (DROP_OVERSIZE_FRAME && frame_oversize);

    // Write enable
    assign w_valid = s_axis_tvalid && s_axis_tready && !s_paused;
    assign s_axis_tready = !s_full && !s_paused;

    // RAM write
    assign ram_we = w_valid;
    assign ram_addr = w_addr;

    // Pack data for RAM
    wire [TOTAL_DATA_WIDTH-1:0] packed_data;
    wire [DATA_WIDTH-1:0] data_part;
    wire [KEEP_WIDTH-1:0] keep_part;
    wire last_part;
    wire [ID_WIDTH-1:0] id_part;
    wire [DEST_WIDTH-1:0] dest_part;
    wire [USER_WIDTH-1:0] user_part;

    assign data_part = s_axis_tdata;
    assign keep_part = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}};
    assign last_part = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign id_part = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign dest_part = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign user_part = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};

    // Pack into single vector
    genvar gi;
    generate
        if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE && DEST_ENABLE && USER_ENABLE) begin : gen_pack_all
            assign packed_data = {user_part, dest_part, id_part, last_part, keep_part, data_part};
        end else if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE && DEST_ENABLE) begin : gen_pack_no_user
            assign packed_data = {dest_part, id_part, last_part, keep_part, data_part};
        end else if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE) begin : gen_pack_no_dest
            assign packed_data = {id_part, last_part, keep_part, data_part};
        end else if (KEEP_ENABLE && LAST_ENABLE) begin : gen_pack_no_id
            assign packed_data = {last_part, keep_part, data_part};
        end else if (KEEP_ENABLE) begin : gen_pack_no_last
            assign packed_data = {keep_part, data_part};
        end else if (LAST_ENABLE) begin : gen_pack_no_keep
            assign packed_data = {last_part, data_part};
        end else begin : gen_pack_data_only
            assign packed_data = data_part;
        end
    endgenerate

    // RAM read
    assign ram_re = r_valid && m_axis_tready && !m_paused;
    assign ram_raddr = r_addr;

    // Unpack data from RAM
    wire [DATA_WIDTH-1:0] unpacked_data;
    wire [KEEP_WIDTH-1:0] unpacked_keep;
    wire unpacked_last;
    wire [ID_WIDTH-1:0] unpacked_id;
    wire [DEST_WIDTH-1:0] unpacked_dest;
    wire [USER_WIDTH-1:0] unpacked_user;

    generate
        if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE && DEST_ENABLE && USER_ENABLE) begin : gen_unpack_all
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_keep = ram_rdata[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH];
            assign unpacked_last = ram_rdata[DATA_WIDTH + KEEP_WIDTH];
            assign unpacked_id = ram_rdata[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1];
            assign unpacked_dest = ram_rdata[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH];
            assign unpacked_user = ram_rdata[TOTAL_DATA_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH];
        end else if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE && DEST_ENABLE) begin : gen_unpack_no_user
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_keep = ram_rdata[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH];
            assign unpacked_last = ram_rdata[DATA_WIDTH + KEEP_WIDTH];
            assign unpacked_id = ram_rdata[DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1];
            assign unpacked_dest = ram_rdata[TOTAL_DATA_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH];
        end else if (KEEP_ENABLE && LAST_ENABLE && ID_ENABLE) begin : gen_unpack_no_dest
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_keep = ram_rdata[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH];
            assign unpacked_last = ram_rdata[DATA_WIDTH + KEEP_WIDTH];
            assign unpacked_id = ram_rdata[TOTAL_DATA_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + 1];
        end else if (KEEP_ENABLE && LAST_ENABLE) begin : gen_unpack_no_id
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_keep = ram_rdata[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH];
            assign unpacked_last = ram_rdata[DATA_WIDTH + KEEP_WIDTH];
        end else if (KEEP_ENABLE) begin : gen_unpack_no_last
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_keep = ram_rdata[TOTAL_DATA_WIDTH-1:DATA_WIDTH];
        end else if (LAST_ENABLE) begin : gen_unpack_no_keep
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
            assign unpacked_last = ram_rdata[DATA_WIDTH];
        end else begin : gen_unpack_data_only
            assign unpacked_data = ram_rdata[DATA_WIDTH-1:0];
        end
    endgenerate

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_overflow <= 1'b0;
            w_bad_frame_pulse <= 1'b0;
            w_good_frame_pulse <= 1'b0;
        end else begin
            if (w_valid) begin
                w_ptr <= w_ptr + 1'b1;
                w_addr <= w_addr + 1'b1;
            end
            // Overflow detection
            if (s_axis_tvalid && s_full && !s_paused)
                w_overflow <= 1'b1;
            else
                w_overflow <= 1'b0;
            // Frame pulses
            if (w_valid && w_last) begin
                if (frame_bad || frame_oversize)
                    w_bad_frame_pulse <= 1'b1;
                else
                    w_good_frame_pulse <= 1'b1;
            end else begin
                w_bad_frame_pulse <= 1'b0;
                w_good_frame_pulse <= 1'b0;
            end
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            r_overflow <= 1'b0;
            r_bad_frame_pulse <= 1'b0;
            r_good_frame_pulse <= 1'b0;
        end else begin
            if (ram_re) begin
                r_ptr <= r_ptr + 1'b1;
                r_addr <= r_addr + 1'b1;
            end
            // Frame pulses based on read data
            if (ram_re && unpacked_last) begin
                if (USER_ENABLE && (unpacked_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    r_bad_frame_pulse <= 1'b1;
                else
                    r_good_frame_pulse <= 1'b1;
            end else begin
                r_bad_frame_pulse <= 1'b0;
                r_good_frame_pulse <= 1'b0;
            end
        end
    end

    // Output register
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_tdata <= {DATA_WIDTH{1'b0}};
            out_tkeep <= {KEEP_WIDTH{1'b0}};
            out_tlast <= 1'b0;
            out_tid <= {ID_WIDTH{1'b0}};
            out_tdest <= {DEST_WIDTH{1'b0}};
            out_tuser <= {USER_WIDTH{1'b0}};
            out_tvalid <= 1'b0;
        end else begin
            if (ram_re) begin
                out_tdata <= unpacked_data;
                out_tkeep <= unpacked_keep;
                out_tlast <= unpacked_last;
                out_tid <= unpacked_id;
                out_tdest <= unpacked_dest;
                out_tuser <= unpacked_user;
                out_tvalid <= 1'b1;
            end else if (m_axis_tready) begin
                out_tvalid <= 1'b0;
            end
        end
    end

    // Output assignments
    assign m_axis_tdata = out_tdata;
    assign m_axis_tkeep = out_tkeep;
    assign m_axis_tvalid = out_tvalid;
    assign m_axis_tlast = out_tlast;
    assign m_axis_tid = out_tid;
    assign m_axis_tdest = out_tdest;
    assign m_axis_tuser = out_tuser;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = w_overflow;
    assign s_status_bad_frame = w_bad_frame_pulse;
    assign s_status_good_frame = w_good_frame_pulse;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = r_overflow;
    assign m_status_bad_frame = r_bad_frame_pulse;
    assign m_status_good_frame = r_good_frame_pulse;

    // RAM instantiation
    reg [TOTAL_DATA_WIDTH-1:0] ram_mem [0:DEPTH-1];

    always @(posedge s_clk) begin
        if (ram_we)
            ram_mem[ram_addr] <= packed_data;
    end

    always @(posedge m_clk) begin
        ram_rdata <= ram_mem[ram_raddr];
    end

endmodule

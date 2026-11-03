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

    // FIFO signals
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH)-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] fifo_depth;
    reg [$clog2(DEPTH):0] fifo_depth_commit;
    reg fifo_full, fifo_empty;
    reg [DATA_WIDTH-1:0] mem_tdata [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_tkeep [DEPTH-1:0];
    reg mem_tlast [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];

    // Frame control
    reg frame_start, frame_end;
    reg frame_drop, frame_valid;
    reg [$clog2(DEPTH):0] frame_length;
    reg frame_bad;

    // Status signals
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Pause control
    reg pause_state;

    // Write enable
    wire fifo_wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire fifo_rd_en = m_axis_tvalid && m_axis_tready;

    // Binary to Gray code conversion
    function [($clog2(DEPTH))-1:0] bin_to_gray;
        input [($clog2(DEPTH))-1:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Gray to Binary code conversion
    function [($clog2(DEPTH))-1:0] gray_to_bin;
        input [($clog2(DEPTH))-1:0] gray;
        integer i;
        reg [($clog2(DEPTH))-1:0] bin;
        bin = gray;
        for (i = $clog2(DEPTH) - 2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // FIFO write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            fifo_depth <= 0;
            fifo_depth_commit <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            status_overflow_reg <= 0;
        end else begin
            if (fifo_wr_en && !fifo_full) begin
                mem_tdata[wr_ptr] <= s_axis_tdata;
                mem_tkeep[wr_ptr] <= s_axis_tkeep;
                mem_tlast[wr_ptr] <= s_axis_tlast;
                mem_tid[wr_ptr] <= s_axis_tid;
                mem_tdest[wr_ptr] <= s_axis_tdest;
                mem_tuser[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
                fifo_depth <= fifo_depth + 1;
                fifo_empty <= 0;
                if (fifo_depth + 1 == DEPTH)
                    fifo_full <= 1;
            end
            if (fifo_rd_en && !fifo_empty) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
                fifo_depth <= fifo_depth - 1;
                fifo_full <= 0;
                if (fifo_depth - 1 == 0)
                    fifo_empty <= 1;
            end
            if (fifo_wr_en && fifo_full) begin
                status_overflow_reg <= 1;
            end else begin
                status_overflow_reg <= 0;
            end
        end
    end

    // FIFO read logic
    assign m_axis_tdata = mem_tdata[rd_ptr];
    assign m_axis_tkeep = mem_tkeep[rd_ptr];
    assign m_axis_tlast = mem_tlast[rd_ptr];
    assign m_axis_tid = mem_tid[rd_ptr];
    assign m_axis_tdest = mem_tdest[rd_ptr];
    assign m_axis_tuser = mem_tuser[rd_ptr];

    // Handshake
    assign s_axis_tready = !fifo_full && !pause_state;
    assign m_axis_tvalid = !fifo_empty;

    // Frame control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_start <= 0;
            frame_end <= 0;
            frame_drop <= 0;
            frame_valid <= 0;
            frame_length <= 0;
            frame_bad <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            if (fifo_wr_en && s_axis_tlast) begin
                frame_start <= 1;
                frame_length <= fifo_depth + 1;
            end else begin
                frame_start <= 0;
            end
            if (fifo_rd_en && m_axis_tlast) begin
                frame_end <= 1;
                frame_length <= fifo_depth_commit - 1;
            end else begin
                frame_end <= 0;
            end
            if (frame_start) begin
                frame_valid <= 1;
            end
            if (frame_end) begin
                frame_valid <= 0;
            end
            if (frame_start && DROP_BAD_FRAME && (mem_tuser[wr_ptr] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                frame_drop <= 1;
                frame_bad <= 1;
            end else if (frame_start && DROP_OVERSIZE_FRAME && frame_length > DEPTH) begin
                frame_drop <= 1;
                frame_bad <= 1;
            end else begin
                frame_drop <= 0;
                frame_bad <= 0;
            end
            if (frame_drop) begin
                status_bad_frame_reg <= 1;
            end else if (frame_end && frame_valid) begin
                status_good_frame_reg <= 1;
            end else begin
                status_bad_frame_reg <= 0;
                status_good_frame_reg <= 0;
            end
        end
    end

    // Commit depth
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_depth_commit <= 0;
        end else begin
            fifo_depth_commit <= fifo_depth;
        end
    end

    // Pause control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_state <= 0;
        end else begin
            if (pause_req && !pause_state) begin
                pause_state <= 1;
            end else if (!pause_req && pause_state) begin
                pause_state <= 0;
            end
        end
    end

    // Status outputs
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;
    assign pause_ack = pause_state;

endmodule

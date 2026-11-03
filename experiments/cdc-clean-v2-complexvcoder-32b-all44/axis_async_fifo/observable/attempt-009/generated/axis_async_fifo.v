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

    // Internal signals
    wire [$clog2(DEPTH)-1:0] s_wr_ptr, s_rd_ptr_sync;
    wire [$clog2(DEPTH)-1:0] m_wr_ptr_sync, m_rd_ptr;
    wire [$clog2(DEPTH):0] s_depth, s_depth_commit;
    wire [$clog2(DEPTH):0] m_depth, m_depth_commit;
    wire s_full, s_empty, s_overflow;
    wire m_full, m_empty, m_overflow;
    wire s_good_frame, s_bad_frame;
    wire m_good_frame, m_bad_frame;

    // CDC synchronization
    cdc_sync #() s_wr_ptr_sync_inst (
        .async_in(s_wr_ptr),
        .sync_out(s_wr_ptr_sync),
        .clk(m_clk),
        .rst(m_rst)
    );

    cdc_sync #() m_rd_ptr_sync_inst (
        .async_in(m_rd_ptr),
        .sync_out(m_rd_ptr_sync),
        .clk(s_clk),
        .rst(s_rst)
    );

    // FIFO buffer
    fifo_buffer #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) fifo_buf_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
        .wr_ptr_sync(m_rd_ptr_sync),
        .rd_ptr_sync(s_wr_ptr_sync),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr),
        .full(s_full),
        .empty(s_empty),
        .overflow(s_overflow),
        .good_frame(s_good_frame),
        .bad_frame(s_bad_frame)
    );

    // Status counters
    status_counter #(
        .DEPTH(DEPTH)
    ) s_status_counter_inst (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(s_wr_ptr_sync),
        .depth(s_depth),
        .depth_commit(s_depth_commit),
        .overflow(s_status_overflow),
        .bad_frame(s_status_bad_frame),
        .good_frame(s_status_good_frame)
    );

    status_counter #(
        .DEPTH(DEPTH)
    ) m_status_counter_inst (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr_sync),
        .rd_ptr(m_rd_ptr),
        .depth(m_depth),
        .depth_commit(m_depth_commit),
        .overflow(m_status_overflow),
        .bad_frame(m_status_bad_frame),
        .good_frame(m_status_good_frame)
    );

    // Pause signals
    assign s_pause_ack = s_pause_req & s_axis_tready;
    assign m_pause_ack = m_pause_req & m_axis_tready;

    // Status outputs
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

endmodule

module cdc_sync #() (
    input  wire async_in,
    output wire sync_out,
    input  wire clk,
    input  wire rst
);
    reg sync_reg1, sync_reg2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
        end else begin
            sync_reg1 <= async_in;
            sync_reg2 <= sync_reg1;
        end
    end

    assign sync_out = sync_reg2;
endmodule

module fifo_buffer #(
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
    input  wire [$clog2(DEPTH)-1:0] wr_ptr_sync,
    input  wire [$clog2(DEPTH)-1:0] rd_ptr_sync,
    output wire [$clog2(DEPTH)-1:0] wr_ptr,
    output wire [$clog2(DEPTH)-1:0] rd_ptr,
    output wire                   full,
    output wire                   empty,
    output wire                   overflow,
    output wire                   good_frame,
    output wire                   bad_frame
);

    // Internal signals
    reg [$clog2(DEPTH)-1:0] wr_ptr_reg, rd_ptr_reg;
    reg [$clog2(DEPTH)-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] mem [DEPTH-1:0];
    reg frame_start, frame_end, frame_bad;
    reg frame_start_reg, frame_end_reg, frame_bad_reg;
    reg frame_start_sync, frame_end_sync, frame_bad_sync;
    reg [$clog2(DEPTH):0] depth;

    // Gray code conversion
    function [$clog2(DEPTH)-1:0] bin2gray;
        input [$clog2(DEPTH)-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // FIFO control
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_reg <= 0;
            wr_ptr_gray <= 0;
            frame_start <= 0;
            frame_end <= 0;
            frame_bad <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem[wr_ptr_reg] = {s_axis_tdata, s_axis_tkeep, LAST_ENABLE ? s_axis_tlast : 1'b0, ID_ENABLE ? s_axis_tid : 0, DEST_ENABLE ? s_axis_tdest : 0, USER_ENABLE ? s_axis_tuser : 0};
                wr_ptr_reg <= wr_ptr_reg + 1;
                wr_ptr_gray <= bin2gray(wr_ptr_reg + 1);
                frame_start <= frame_end;
                frame_end <= s_axis_tlast;
                frame_bad <= (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr_reg <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr_reg <= rd_ptr_reg + 1;
                rd_ptr_gray <= bin2gray(rd_ptr_reg + 1);
            end
        end
    end

    // Ready signals
    assign s_axis_tready = !full || (DROP_WHEN_FULL && full);
    assign m_axis_tvalid = !empty;

    // Full and empty flags
    assign full = (wr_ptr_gray == {~rd_ptr_sync[$clog2(DEPTH)-1:0], rd_ptr_sync[$clog2(DEPTH)-1]});
    assign empty = (rd_ptr_gray == {~wr_ptr_sync[$clog2(DEPTH)-1:0], wr_ptr_sync[$clog2(DEPTH)-1]});

    // Overflow detection
    reg overflow_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            overflow_reg <= 0;
        else if (s_axis_tvalid && s_axis_tready && full)
            overflow_reg <= 1;
        else if (s_axis_tready)
            overflow_reg <= 0;
    end

    assign overflow = overflow_reg;

    // Frame tracking
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            frame_start_reg <= 0;
            frame_end_reg <= 0;
            frame_bad_reg <= 0;
        end else begin
            frame_start_reg <= frame_start;
            frame_end_reg <= frame_end;
            frame_bad_reg <= frame_bad;
        end
    end

    cdc_sync #() frame_start_sync_inst (
        .async_in(frame_start_reg),
        .sync_out(frame_start_sync),
        .clk(m_clk),
        .rst(m_rst)
    );

    cdc_sync #() frame_end_sync_inst (
        .async_in(frame_end_reg),
        .sync_out(frame_end_sync),
        .clk(m_clk),
        .rst(m_rst)
    );

    cdc_sync #() frame_bad_sync_inst (
        .async_in(frame_bad_reg),
        .sync_out(frame_bad_sync),
        .clk(m_clk),
        .rst(m_rst)
    );

    // Output signals
    assign m_axis_tdata = mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH];
    assign m_axis_tkeep = mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH];
    assign m_axis_tlast = LAST_ENABLE ? mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : 0;
    assign m_axis_tdest = DEST_ENABLE ? mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH] : 0;
    assign m_axis_tuser = USER_ENABLE ? mem[rd_ptr_reg][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH] : 0;

    // Depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            depth <= 0;
        else if (s_axis_tvalid && s_axis_tready && !m_axis_tvalid)
            depth <= depth + 1;
        else if (!s_axis_tvalid && m_axis_tvalid && m_axis_tready)
            depth <= depth - 1;
        else if (s_axis_tvalid && s_axis_tready && m_axis_tvalid && m_axis_tready)
            depth <= depth;
    end

    assign good_frame = frame_end_sync & !frame_bad_sync;
    assign bad_frame = frame_end_sync & frame_bad_sync;

    // Output register (if enabled)
    generate
        if (RAM_PIPELINE) begin
            reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] mem_out;
            reg m_axis_tvalid_reg;

            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    mem_out <= 0;
                    m_axis_tvalid_reg <= 0;
                end else begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        mem_out <= mem[rd_ptr_reg];
                        m_axis_tvalid_reg <= 1;
                    end else if (m_axis_tready) begin
                        m_axis_tvalid_reg <= 0;
                    end
                end
            end

            assign m_axis_tdata = mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH];
            assign m_axis_tkeep = mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH];
            assign m_axis_tlast = LAST_ENABLE ? mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH] : 1'b0;
            assign m_axis_tid = ID_ENABLE ? mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : 0;
            assign m_axis_tdest = DEST_ENABLE ? mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH] : 0;
            assign m_axis_tuser = USER_ENABLE ? mem_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH] : 0;
            assign m_axis_tvalid = m_axis_tvalid_reg;
        end
    endgenerate

    // Output FIFO (if enabled)
    generate
        if (OUTPUT_FIFO_ENABLE) begin
            reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] output_mem [DEPTH-1:0];
            reg [$clog2(DEPTH)-1:0] output_wr_ptr, output_rd_ptr;
            reg [$clog2(DEPTH)-1:0] output_wr_ptr_gray, output_rd_ptr_gray;
            reg output_full, output_empty;

            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    output_wr_ptr <= 0;
                    output_wr_ptr_gray <= 0;
                end else begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        output_mem[output_wr_ptr] = mem[rd_ptr_reg];
                        output_wr_ptr <= output_wr_ptr + 1;
                        output_wr_ptr_gray <= bin2gray(output_wr_ptr + 1);
                    end
                end
            end

            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    output_rd_ptr <= 0;
                    output_rd_ptr_gray <= 0;
                end else begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        output_rd_ptr <= output_rd_ptr + 1;
                        output_rd_ptr_gray <= bin2gray(output_rd_ptr + 1);
                    end
                end
            end

            assign output_full = (output_wr_ptr_gray == {~output_rd_ptr_gray[$clog2(DEPTH)-1:0], output_rd_ptr_gray[$clog2(DEPTH)-1]});
            assign output_empty = (output_rd_ptr_gray == {~output_wr_ptr_gray[$clog2(DEPTH)-1:0], output_wr_ptr_gray[$clog2(DEPTH)-1]});

            assign m_axis_tdata = output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH];
            assign m_axis_tkeep = output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH];
            assign m_axis_tlast = LAST_ENABLE ? output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH] : 1'b0;
            assign m_axis_tid = ID_ENABLE ? output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : 0;
            assign m_axis_tdest = DEST_ENABLE ? output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH] : 0;
            assign m_axis_tuser = USER_ENABLE ? output_mem[output_rd_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH] : 0;
            assign m_axis_tvalid = !output_empty;
        end
    endgenerate

    // Assign output pointers
    assign wr_ptr = wr_ptr_reg;
    assign rd_ptr = rd_ptr_reg;

endmodule

module status_counter #(
    parameter DEPTH = 4096
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [$clog2(DEPTH)-1:0] wr_ptr,
    input  wire [$clog2(DEPTH)-1:0] rd_ptr,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit,
    output wire                   overflow,
    output wire                   bad_frame,
    output wire                   good_frame
);

    // Internal signals
    reg [$clog2(DEPTH):0] depth_reg, depth_commit_reg;
    reg overflow_reg, bad_frame_reg, good_frame_reg;

    // Depth calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth_reg <= 0;
            depth_commit_reg <= 0;
            overflow_reg <= 0;
            bad_frame_reg <= 0;
            good_frame_reg <= 0;
        end else begin
            if (wr_ptr > rd_ptr) begin
                depth_reg <= wr_ptr - rd_ptr;
            end else begin
                depth_reg <= DEPTH - (rd_ptr - wr_ptr);
            end
            depth_commit_reg <= depth_reg;
            if (depth_reg > DEPTH)
                overflow_reg <= 1;
            else
                overflow_reg <= 0;
            // Frame status handling (simplified)
            // These signals should be connected from the FIFO buffer module
            // bad_frame_reg <= bad_frame;
            // good_frame_reg <= good_frame;
        end
    end

    assign depth = depth_reg;
    assign depth_commit = depth_commit_reg;
    assign overflow = overflow_reg;
    assign bad_frame = bad_frame_reg;
    assign good_frame = good_frame_reg;

endmodule

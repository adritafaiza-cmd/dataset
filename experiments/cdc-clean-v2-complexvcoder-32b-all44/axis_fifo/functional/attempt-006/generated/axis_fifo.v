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

    reg [ADDR_WIDTH:0] write_ptr;
    reg [ADDR_WIDTH:0] read_ptr;
    reg [ADDR_WIDTH:0] fifo_depth;
    reg [ADDR_WIDTH:0] fifo_depth_commit;
    reg fifo_full;
    reg fifo_empty;
    reg frame_bad;
    reg frame_good;
    reg frame_ongoing;
    reg frame_pause;
    reg pause_state;
    reg write_en;
    reg read_en;
    reg [DATA_WIDTH-1:0] tdata_reg [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] tkeep_reg [0:DEPTH-1];
    reg tlast_reg [0:DEPTH-1];
    reg [ID_WIDTH-1:0] tid_reg [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] tdest_reg [0:DEPTH-1];
    reg [USER_WIDTH-1:0] tuser_reg [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] tdata_out;
    reg [KEEP_WIDTH-1:0] tkeep_out;
    reg tlast_out;
    reg [ID_WIDTH-1:0] tid_out;
    reg [DEST_WIDTH-1:0] tdest_out;
    reg [USER_WIDTH-1:0] tuser_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;
            fifo_depth <= 0;
            fifo_depth_commit <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            frame_bad <= 0;
            frame_good <= 0;
            frame_ongoing <= 0;
            frame_pause <= 0;
            pause_state <= 0;
            write_en <= 0;
            read_en <= 0;
        end else begin
            write_en <= s_axis_tvalid & s_axis_tready;
            read_en <= m_axis_tvalid & m_axis_tready;

            if (write_en & ~fifo_full) begin
                tdata_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) tkeep_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE) tlast_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE) tid_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) tdest_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) tuser_reg[write_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                write_ptr <= write_ptr + 1;
            end

            if (read_en & ~fifo_empty) begin
                read_ptr <= read_ptr + 1;
            end

            fifo_depth <= write_ptr - read_ptr;
            fifo_empty <= (write_ptr == read_ptr);
            fifo_full <= (fifo_depth == DEPTH);

            if (s_axis_tvalid & s_axis_tready & s_axis_tlast) begin
                frame_ongoing <= 0;
                frame_good <= 1;
                frame_bad <= 0;
            end else if (s_axis_tvalid & s_axis_tready & ~frame_ongoing) begin
                frame_ongoing <= 1;
                frame_good <= 0;
                frame_bad <= 0;
            end

            if (frame_ongoing & read_en & tlast_out) begin
                frame_ongoing <= 0;
                if (frame_pause) begin
                    frame_bad <= 1;
                    frame_good <= 0;
                end else begin
                    frame_good <= 1;
                    frame_bad <= 0;
                end
            end

            if (PAUSE_ENABLE) begin
                pause_ack <= pause_req;
                frame_pause <= pause_req;
            end else begin
                pause_ack <= 0;
                frame_pause <= 0;
            end

            if (USER_ENABLE) begin
                if (tuser_reg[read_ptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    frame_bad <= 1;
                    frame_good <= 0;
                end
            end

            if (DROP_OVERSIZE_FRAME & frame_ongoing & fifo_full) begin
                frame_bad <= 1;
                frame_good <= 0;
            end

            if (DROP_BAD_FRAME & frame_bad) begin
                read_en <= 1;
            end

            if (MARK_WHEN_FULL & fifo_full) begin
                frame_bad <= 1;
                frame_good <= 0;
            end

            if (DROP_WHEN_FULL & fifo_full) begin
                write_en <= 0;
            end
        end
    end

    assign s_axis_tready = ~fifo_full;
    assign m_axis_tvalid = ~fifo_empty;
    assign m_axis_tdata = tdata_reg[read_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? tkeep_reg[read_ptr[ADDR_WIDTH-1:0]] : {KEEP_WIDTH{1'b1}};
    assign m_axis_tlast = LAST_ENABLE ? tlast_reg[read_ptr[ADDR_WIDTH-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? tid_reg[read_ptr[ADDR_WIDTH-1:0]] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? tdest_reg[read_ptr[ADDR_WIDTH-1:0]] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? tuser_reg[read_ptr[ADDR_WIDTH-1:0]] : {USER_WIDTH{1'b0}};

    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = fifo_full;
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_good;

endmodule

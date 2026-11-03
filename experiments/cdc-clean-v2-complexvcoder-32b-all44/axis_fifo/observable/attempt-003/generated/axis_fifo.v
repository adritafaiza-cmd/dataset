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

    reg [ADDR_WIDTH-1:0] write_pointer;
    reg [ADDR_WIDTH-1:0] read_pointer;
    reg [ADDR_WIDTH-1:0] write_pointer_next;
    reg [ADDR_WIDTH-1:0] read_pointer_next;
    reg fifo_full;
    reg fifo_empty;
    reg [$clog2(DEPTH):0] fifo_depth;
    reg [$clog2(DEPTH):0] fifo_depth_commit;
    reg write_enable;
    reg read_enable;
    reg frame_start;
    reg frame_end;
    reg bad_frame;
    reg good_frame;
    reg pause_state;
    reg pause_ack_reg;
    reg [$clog2(DEPTH):0] frame_count;
    reg [$clog2(DEPTH):0] frame_count_max;
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] fifo_user [0:DEPTH-1];

    assign s_axis_tready = ~fifo_full & ~pause_state;
    assign m_axis_tdata = fifo_data[read_pointer];
    assign m_axis_tkeep = fifo_keep[read_pointer];
    assign m_axis_tvalid = ~fifo_empty;
    assign m_axis_tlast = fifo_last[read_pointer];
    assign m_axis_tid = fifo_id[read_pointer];
    assign m_axis_tdest = fifo_dest[read_pointer];
    assign m_axis_tuser = fifo_user[read_pointer];
    assign pause_ack = pause_ack_reg;
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = fifo_full;
    assign status_bad_frame = bad_frame;
    assign status_good_frame = good_frame;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_pointer <= 0;
            read_pointer <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            fifo_depth <= 0;
            fifo_depth_commit <= 0;
            pause_state <= 0;
            pause_ack_reg <= 0;
            frame_count <= 0;
            frame_count_max <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            write_pointer <= write_pointer_next;
            read_pointer <= read_pointer_next;
            fifo_full <= (write_pointer_next == read_pointer) & write_enable;
            fifo_empty <= (write_pointer == read_pointer);
            fifo_depth <= (write_pointer >= read_pointer) ? (write_pointer - read_pointer) : (DEPTH - read_pointer + write_pointer);
            fifo_depth_commit <= read_enable ? fifo_depth : fifo_depth_commit;
            pause_state <= PAUSE_ENABLE ? pause_req : 0;
            pause_ack_reg <= pause_req ? pause_state : pause_ack_reg;

            if (frame_start)
                frame_count <= frame_count + 1;

            if (frame_end) begin
                frame_count_max <= frame_count_max < frame_count ? frame_count : frame_count_max;
                frame_count <= 0;
            end

            if (write_enable) begin
                fifo_data[write_pointer] <= s_axis_tdata;
                fifo_keep[write_pointer] <= s_axis_tkeep;
                fifo_last[write_pointer] <= s_axis_tlast;
                fifo_id[write_pointer] <= s_axis_tid;
                fifo_dest[write_pointer] <= s_axis_tdest;
                fifo_user[write_pointer] <= s_axis_tuser;
            end

            if (bad_frame)
                frame_count <= 0;

            bad_frame <= DROP_BAD_FRAME & USER_ENABLE & (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE);
            good_frame <= frame_end & ~bad_frame;
        end
    end

    always @(*) begin
        write_pointer_next = write_pointer;
        read_pointer_next = read_pointer;
        write_enable = 0;
        read_enable = 0;

        if (~fifo_full & ~pause_state)
            write_enable = s_axis_tvalid;

        if (~fifo_empty & ~frame_end)
            read_enable = m_axis_tready;

        if (write_enable)
            write_pointer_next = write_pointer == DEPTH-1 ? 0 : write_pointer + 1;

        if (read_enable)
            read_pointer_next = read_pointer == DEPTH-1 ? 0 : read_pointer + 1;

        frame_start = s_axis_tvalid & ~s_axis_tlast & ~frame_end;
        frame_end = s_axis_tvalid & s_axis_tlast;
    end

endmodule

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

    reg [ADDR_WIDTH:0] write_pointer, write_pointer_next;
    reg [ADDR_WIDTH:0] read_pointer, read_pointer_next;
    reg [ADDR_WIDTH:0] fifo_count, fifo_count_next;
    reg fifo_full, fifo_empty;
    reg frame_active, frame_active_next;
    reg [ADDR_WIDTH:0] frame_length, frame_length_next;
    reg frame_good, frame_good_next;
    reg frame_bad, frame_bad_next;
    reg s_axis_tready_int, m_axis_tvalid_int;
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg pause_ack_int;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_pointer <= 0;
            read_pointer <= 0;
            fifo_count <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            frame_active <= 0;
            frame_length <= 0;
            frame_good <= 1;
            frame_bad <= 0;
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            pause_ack_int <= 0;
        end else begin
            write_pointer <= write_pointer_next;
            read_pointer <= read_pointer_next;
            fifo_count <= fifo_count_next;
            fifo_full <= (fifo_count_next == DEPTH);
            fifo_empty <= (fifo_count_next == 0);
            frame_active <= frame_active_next;
            frame_length <= frame_length_next;
            frame_good <= frame_good_next;
            frame_bad <= frame_bad_next;
            s_axis_tready_int <= (fifo_full == 0);
            m_axis_tvalid_int <= (fifo_empty == 0);
            pause_ack_int <= (PAUSE_ENABLE && fifo_full);
        end
    end

    always @(*) begin
        write_pointer_next = write_pointer;
        read_pointer_next = read_pointer;
        fifo_count_next = fifo_count;
        frame_active_next = frame_active;
        frame_length_next = frame_length;
        frame_good_next = frame_good;
        frame_bad_next = frame_bad;

        if (s_axis_tvalid && s_axis_tready_int) begin
            write_pointer_next = write_pointer + 1;
            fifo_count_next = fifo_count + 1;
            if (s_axis_tlast) begin
                frame_active_next = 0;
                if (frame_length_next > DEPTH) begin
                    frame_bad_next = 1;
                end else begin
                    frame_good_next = 1;
                end
            end else begin
                frame_active_next = 1;
                frame_length_next = frame_length + 1;
            end
        end

        if (m_axis_tvalid_int && m_axis_tready) begin
            read_pointer_next = read_pointer + 1;
            fifo_count_next = fifo_count - 1;
            if (m_axis_tlast_reg) begin
                frame_good_next = 0;
                frame_bad_next = 0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else if (m_axis_tvalid_int && m_axis_tready) begin
            m_axis_tdata_reg <= mem_data[read_pointer];
            m_axis_tkeep_reg <= mem_keep[read_pointer];
            m_axis_tlast_reg <= mem_last[read_pointer];
            m_axis_tid_reg <= mem_tid[read_pointer];
            m_axis_tdest_reg <= mem_tdest[read_pointer];
            m_axis_tuser_reg <= mem_tuser[read_pointer];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data[write_pointer] <= 0;
            mem_keep[write_pointer] <= 0;
            mem_last[write_pointer] <= 0;
            mem_tid[write_pointer] <= 0;
            mem_tdest[write_pointer] <= 0;
            mem_tuser[write_pointer] <= 0;
        end else if (s_axis_tvalid && s_axis_tready_int) begin
            mem_data[write_pointer] <= s_axis_tdata;
            mem_keep[write_pointer] <= s_axis_tkeep;
            mem_last[write_pointer] <= s_axis_tlast;
            mem_tid[write_pointer] <= s_axis_tid;
            mem_tdest[write_pointer] <= s_axis_tdest;
            mem_tuser[write_pointer] <= s_axis_tuser;
        end
    end

    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign pause_ack = pause_ack_int;
    assign status_depth = fifo_count;
    assign status_depth_commit = fifo_count;
    assign status_overflow = (DROP_WHEN_FULL && fifo_full) || (MARK_WHEN_FULL && fifo_full);
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_good;

endmodule

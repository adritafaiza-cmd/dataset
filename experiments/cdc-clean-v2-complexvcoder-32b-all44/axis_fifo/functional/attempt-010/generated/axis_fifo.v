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
    reg [ADDR_WIDTH:0] fifo_count;
    reg fifo_full;
    reg fifo_empty;
    reg write_enable;
    reg read_enable;
    reg [DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH+1+1-1:0] fifo_data [0:DEPTH-1];
    reg frame_start;
    reg frame_end;
    reg frame_error;
    reg pause_state;
    reg [ADDR_WIDTH-1:0] pause_counter;

    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg [$clog2(DEPTH):0] status_depth_reg;
    reg [$clog2(DEPTH):0] status_depth_commit_reg;
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_pointer <= 0;
            read_pointer <= 0;
            fifo_count <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            frame_start <= 0;
            frame_end <= 0;
            frame_error <= 0;
            pause_state <= 0;
            pause_counter <= 0;
            status_depth_reg <= 0;
            status_depth_commit_reg <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            // Write pointer and FIFO full/empty logic
            if (write_enable && !fifo_full) begin
                fifo_data[write_pointer] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
                write_pointer <= write_pointer + 1;
                fifo_count <= fifo_count + 1;
                fifo_empty <= 0;
                if (fifo_count == DEPTH - 1) begin
                    fifo_full <= 1;
                end
            end

            // Read pointer and FIFO full/empty logic
            if (read_enable && !fifo_empty) begin
                read_pointer <= read_pointer + 1;
                fifo_count <= fifo_count - 1;
                fifo_full <= 0;
                if (fifo_count == 0) begin
                    fifo_empty <= 1;
                end
            end

            // Frame detection and error handling
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    frame_end <= 1;
                end else if (frame_start) begin
                    frame_error <= frame_error | (frame_end == 0);
                end
            end

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                frame_start <= 0;
                frame_end <= 0;
                if (frame_error) begin
                    status_bad_frame_reg <= 1;
                end else begin
                    status_good_frame_reg <= 1;
                end
                frame_error <= 0;
            end

            if (s_axis_tvalid && s_axis_tready && !frame_start) begin
                frame_start <= 1;
            end

            // Pause handling
            if (pause_req && !pause_state) begin
                pause_state <= 1;
                pause_counter <= fifo_count;
            end else if (!pause_req && pause_state) begin
                pause_state <= 0;
            end

            // Status registers
            status_depth_reg <= fifo_count;
            status_depth_commit_reg <= pause_counter;
            status_overflow_reg <= fifo_full && s_axis_tvalid && s_axis_tready;
            status_bad_frame_reg <= status_bad_frame_reg && !status_good_frame_reg;
            status_good_frame_reg <= status_good_frame_reg && !status_bad_frame_reg;
        end
    end

    assign s_axis_tready = !fifo_full;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign pause_ack = pause_state;
    assign status_depth = status_depth_reg;
    assign status_depth_commit = status_depth_commit_reg;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Output FIFO read logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else if (read_enable && !fifo_empty) begin
            m_axis_tdata_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH+1+1-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH+1];
            m_axis_tkeep_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH+1-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH];
            m_axis_tlast_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH];
            m_axis_tid_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH];
            m_axis_tdest_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH];
            m_axis_tuser_reg <= fifo_data[read_pointer][DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
            m_axis_tvalid_reg <= 1;
        end else if (m_axis_tready) begin
            m_axis_tvalid_reg <= 0;
        end
    end

    // Write and read enable logic
    assign write_enable = s_axis_tvalid && s_axis_tready && !fifo_full;
    assign read_enable = m_axis_tready && m_axis_tvalid_reg && !fifo_empty;

endmodule

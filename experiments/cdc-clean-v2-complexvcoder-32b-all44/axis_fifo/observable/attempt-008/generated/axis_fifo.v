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

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] fifo_count;
    reg fifo_full;
    reg fifo_empty;
    reg write_en;
    reg read_en;
    reg frame_start;
    reg frame_end;
    reg frame_valid;
    reg bad_frame;
    reg good_frame;
    reg overflow;
    reg pause_ack_reg;
    reg [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH - 1:0] write_data;
    reg [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH - 1:0] read_data;

    wire [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH - 1:0] mem_dout;

    assign s_axis_tready = ~fifo_full;
    assign m_axis_tdata = read_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = read_data[DATA_WIDTH + KEEP_WIDTH - 1:DATA_WIDTH];
    assign m_axis_tvalid = ~fifo_empty;
    assign m_axis_tlast = read_data[DATA_WIDTH + KEEP_WIDTH - 1 + LAST_ENABLE];
    assign m_axis_tid = ID_ENABLE ? read_data[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? read_data[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? read_data[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH] : {USER_WIDTH{1'b0}};

    assign status_depth = fifo_count;
    assign status_depth_commit = fifo_count;
    assign status_overflow = overflow;
    assign status_bad_frame = bad_frame;
    assign status_good_frame = good_frame;
    assign pause_ack = pause_ack_reg;

    assign write_data = {s_axis_tdata, s_axis_tkeep, LAST_ENABLE ? s_axis_tlast : 1'b0, ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}, DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}, USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            frame_start <= 0;
            frame_end <= 0;
            frame_valid <= 0;
            bad_frame <= 0;
            good_frame <= 0;
            overflow <= 0;
            pause_ack_reg <= 0;
        end else begin
            if (write_en && ~read_en) begin
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                fifo_count <= fifo_count + 1;
                if (fifo_count == DEPTH-1)
                    fifo_full <= 1;
                if (fifo_count == 1)
                    fifo_empty <= 0;
            end else if (~write_en && read_en) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                fifo_count <= fifo_count - 1;
                if (fifo_count == DEPTH)
                    fifo_full <= 0;
                if (fifo_count == 0)
                    fifo_empty <= 1;
            end else if (write_en && read_en) begin
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end

            if (s_axis_tvalid && s_axis_tlast)
                frame_end <= 1;
            else if (s_axis_tvalid && ~frame_start)
                frame_start <= 1;

            if (frame_end && frame_valid && ~bad_frame)
                good_frame <= 1;
            else
                good_frame <= 0;

            if (frame_end && bad_frame)
                bad_frame <= 1;
            else
                bad_frame <= 0;

            if (frame_end)
                frame_valid <= 0;
            else if (s_axis_tvalid)
                frame_valid <= 1;

            if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                bad_frame <= 1;

            if (write_en && fifo_full)
                overflow <= 1;

            if (PAUSE_ENABLE && pause_req && fifo_empty)
                pause_ack_reg <= 1;
            else
                pause_ack_reg <= 0;
        end
    end

    always @(*) begin
        write_en = s_axis_tvalid && ~fifo_full;
        read_en = m_axis_tready && ~fifo_empty;
    end

    ram_1r1w #
    (
        .WIDTH (DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH),
        .DEPTH (DEPTH)
    )
    ram_1r1w_inst (
        .clk    (clk),
        .wr_en  (write_en),
        .rd_en  (read_en),
        .wr_addr(wr_ptr),
        .rd_addr(rd_ptr),
        .din    (write_data),
        .dout   (mem_dout)
    );

    assign read_data = mem_dout;

endmodule

module ram_1r1w #
(
    parameter WIDTH = 8,
    parameter DEPTH = 1024
)
(
    input  wire                   clk,
    input  wire                   wr_en,
    input  wire                   rd_en,
    input  wire [$clog2(DEPTH)-1:0] wr_addr,
    input  wire [$clog2(DEPTH)-1:0] rd_addr,
    input  wire [WIDTH-1:0]       din,
    output wire [WIDTH-1:0]       dout
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= din;
    end

    assign dout = rd_en ? mem[rd_addr] : {WIDTH{1'b0}};

endmodule

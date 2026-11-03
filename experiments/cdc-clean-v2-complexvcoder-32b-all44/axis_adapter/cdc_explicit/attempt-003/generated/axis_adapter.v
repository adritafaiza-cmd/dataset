module axis_adapter #
(
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
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    /*
     * Internal signals
     */
    reg [S_DATA_WIDTH-1:0]          buffer;
    reg                             buffer_valid;
    reg                             buffer_last;
    reg [S_KEEP_WIDTH-1:0]          buffer_keep;
    reg [ID_WIDTH-1:0]              buffer_id;
    reg [DEST_WIDTH-1:0]            buffer_dest;
    reg [USER_WIDTH-1:0]            buffer_user;

    reg [M_DATA_WIDTH-1:0]          shift_reg;
    reg                             shift_reg_valid;
    reg                             shift_reg_last;
    reg [M_KEEP_WIDTH-1:0]          shift_reg_keep;
    reg [ID_WIDTH-1:0]              shift_reg_id;
    reg [DEST_WIDTH-1:0]            shift_reg_dest;
    reg [USER_WIDTH-1:0]            shift_reg_user;
    reg [$clog2(M_DATA_WIDTH/S_DATA_WIDTH):0] shift_count;
    reg                             shift_last;

    /*
     * Output assignments
     */
    assign s_axis_tready = ~buffer_valid;
    assign m_axis_tdata  = shift_reg;
    assign m_axis_tkeep  = shift_reg_keep;
    assign m_axis_tvalid = shift_reg_valid;
    assign m_axis_tlast  = shift_reg_last;
    assign m_axis_tid    = shift_reg_id;
    assign m_axis_tdest  = shift_reg_dest;
    assign m_axis_tuser  = shift_reg_user;

    /*
     * Buffering incoming data
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_valid <= 0;
        end else begin
            if (s_axis_tvalid && !buffer_valid) begin
                buffer <= s_axis_tdata;
                buffer_valid <= 1;
                buffer_last <= s_axis_tlast;
                buffer_keep <= s_axis_tkeep;
                buffer_id <= s_axis_tid;
                buffer_dest <= s_axis_tdest;
                buffer_user <= s_axis_tuser;
            end else if (m_axis_tready && shift_reg_valid) begin
                buffer_valid <= 0;
            end
        end
    end

    /*
     * Shifting data to match M_DATA_WIDTH
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg_valid <= 0;
            shift_reg_last <= 0;
            shift_reg_keep <= 0;
            shift_reg_id <= 0;
            shift_reg_dest <= 0;
            shift_reg_user <= 0;
            shift_count <= 0;
            shift_last <= 0;
        end else begin
            if (m_axis_tready && shift_reg_valid) begin
                shift_reg_valid <= 0;
                if (shift_last) begin
                    shift_last <= 0;
                end
            end else if (buffer_valid && !shift_reg_valid) begin
                shift_reg <= buffer;
                shift_reg_valid <= 1;
                shift_reg_last <= buffer_last;
                shift_reg_keep <= buffer_keep;
                shift_reg_id <= buffer_id;
                shift_reg_dest <= buffer_dest;
                shift_reg_user <= buffer_user;
                shift_count <= $clog2(M_DATA_WIDTH/S_DATA_WIDTH);
                shift_last <= buffer_last;
            end else if (shift_count > 0) begin
                shift_reg <= {shift_reg[M_DATA_WIDTH-S_DATA_WIDTH-1:0], buffer};
                shift_count <= shift_count - 1;
                if (shift_last) begin
                    shift_last <= 0;
                end
            end
        end
    end

endmodule

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

reg [S_DATA_WIDTH-1:0] shift_reg;
reg [S_KEEP_WIDTH-1:0] keep_shift_reg;
reg [ID_WIDTH-1:0] id_shift_reg;
reg [DEST_WIDTH-1:0] dest_shift_reg;
reg [USER_WIDTH-1:0] user_shift_reg;
reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg m_axis_tvalid_reg;
reg m_axis_tlast_reg;
reg s_axis_tready_reg;
integer i;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg <= 0;
        keep_shift_reg <= 0;
        id_shift_reg <= 0;
        dest_shift_reg <= 0;
        user_shift_reg <= 0;
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tvalid_reg <= 0;
        m_axis_tlast_reg <= 0;
        s_axis_tready_reg <= 0;
    end else if (s_axis_tvalid && s_axis_tready_reg) begin
        if (S_DATA_WIDTH < M_DATA_WIDTH) begin
            shift_reg <= {shift_reg, s_axis_tdata};
            keep_shift_reg <= {keep_shift_reg, s_axis_tkeep};
            id_shift_reg <= s_axis_tid;
            dest_shift_reg <= s_axis_tdest;
            user_shift_reg <= s_axis_tuser;
            if (shift_reg[M_DATA_WIDTH-1] == 1'b1) begin
                m_axis_tdata_reg <= shift_reg[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= keep_shift_reg[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= (s_axis_tlast && (shift_reg[M_DATA_WIDTH-1] == 1'b1));
                shift_reg <= shift_reg >> M_DATA_WIDTH;
                keep_shift_reg <= keep_shift_reg >> M_KEEP_WIDTH;
            end else begin
                m_axis_tdata_reg <= 0;
                m_axis_tkeep_reg <= 0;
                m_axis_tvalid_reg <= 0;
                m_axis_tlast_reg <= 0;
            end
        end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
            if (s_axis_tlast) begin
                m_axis_tdata_reg <= s_axis_tdata[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= s_axis_tkeep[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= 1'b1;
                id_shift_reg <= s_axis_tid;
                dest_shift_reg <= s_axis_tdest;
                user_shift_reg <= s_axis_tuser;
            end else begin
                m_axis_tdata_reg <= s_axis_tdata[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= s_axis_tkeep[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= 1'b0;
                id_shift_reg <= s_axis_tid;
                dest_shift_reg <= s_axis_tdest;
                user_shift_reg <= s_axis_tuser;
            end
        end else begin
            m_axis_tdata_reg <= s_axis_tdata;
            m_axis_tkeep_reg <= s_axis_tkeep;
            m_axis_tvalid_reg <= 1'b1;
            m_axis_tlast_reg <= s_axis_tlast;
            id_shift_reg <= s_axis_tid;
            dest_shift_reg <= s_axis_tdest;
            user_shift_reg <= s_axis_tuser;
        end
    end else begin
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tvalid_reg <= 0;
        m_axis_tlast_reg <= 0;
    end

    if (m_axis_tvalid_reg && m_axis_tready) begin
        s_axis_tready_reg <= 1'b1;
    end else begin
        s_axis_tready_reg <= 1'b0;
    end
end

assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg && m_axis_tready;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tid = id_shift_reg;
assign m_axis_tdest = dest_shift_reg;
assign m_axis_tuser = user_shift_reg;

endmodule

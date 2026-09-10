module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    reg [S_COUNT-1:0] s_axis_tready_reg;
    reg [M_COUNT-1:0] m_axis_tvalid_reg;
    reg [M_COUNT*DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_COUNT*KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [M_COUNT-1:0] m_axis_tlast_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0] m_axis_tid_reg;
    reg [M_COUNT*M_DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [M_COUNT*USER_WIDTH-1:0] m_axis_tuser_reg;

    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < S_COUNT; i = i + 1) begin
                s_axis_tready_reg[i] <= 0;
            end
            for (i = 0; i < M_COUNT; i = i + 1) begin
                m_axis_tvalid_reg[i] <= 0;
                m_axis_tdata_reg[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= 0;
                m_axis_tkeep_reg[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH] <= 0;
                m_axis_tlast_reg[i] <= 0;
                m_axis_tid_reg[(i+1)*M_ID_WIDTH-1:i*M_ID_WIDTH] <= 0;
                m_axis_tdest_reg[(i+1)*M_DEST_WIDTH-1:i*M_DEST_WIDTH] <= 0;
                m_axis_tuser_reg[(i+1)*USER_WIDTH-1:i*USER_WIDTH] <= 0;
            end
        end else begin
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (s_axis_tvalid[i] && m_axis_tready[M_CONNECT[i]]) begin
                    s_axis_tready_reg[i] <= 1;
                end else begin
                    s_axis_tready_reg[i] <= 0;
                end
            end
            for (i = 0; i < M_COUNT; i = i + 1) begin
                for (j = 0; j < S_COUNT; j = j + 1) begin
                    if (M_CONNECT[j] == i && s_axis_tvalid[j] && s_axis_tready_reg[j]) begin
                        m_axis_tvalid_reg[i] <= 1;
                        m_axis_tdata_reg[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= s_axis_tdata[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH];
                        if (KEEP_ENABLE) begin
                            m_axis_tkeep_reg[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH] <= s_axis_tkeep[(j+1)*KEEP_WIDTH-1:j*KEEP_WIDTH];
                        end
                        m_axis_tlast_reg[i] <= s_axis_tlast[j];
                        if (ID_ENABLE) begin
                            m_axis_tid_reg[(i+1)*M_ID_WIDTH-1:i*M_ID_WIDTH] <= s_axis_tid[(j+1)*S_ID_WIDTH-1:j*S_ID_WIDTH];
                        end
                        m_axis_tdest_reg[(i+1)*M_DEST_WIDTH-1:i*M_DEST_WIDTH] <= s_axis_tdest[(j+1)*S_DEST_WIDTH-1:j*S_DEST_WIDTH];
                        if (USER_ENABLE) begin
                            m_axis_tuser_reg[(i+1)*USER_WIDTH-1:i*USER_WIDTH] <= s_axis_tuser[(j+1)*USER_WIDTH-1:j*USER_WIDTH];
                        end
                    end else begin
                        m_axis_tvalid_reg[i] <= 0;
                    end
                end
            end
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

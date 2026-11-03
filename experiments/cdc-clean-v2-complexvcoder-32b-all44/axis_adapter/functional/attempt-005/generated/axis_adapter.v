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

    reg                             s_axis_tready_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg [3:0]                       buffer_count;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_next;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            data_buffer <= 0;
            keep_buffer <= 0;
            buffer_count <= 0;
            m_axis_tdata_next <= 0;
            m_axis_tkeep_next <= 0;
        end else begin
            s_axis_tready_reg <= 0;
            m_axis_tvalid_reg <= 0;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                if (buffer_count == 0) begin
                    data_buffer <= s_axis_tdata;
                    keep_buffer <= s_axis_tkeep;
                    buffer_count <= S_DATA_WIDTH / M_DATA_WIDTH;
                    m_axis_tid_reg <= s_axis_tid;
                    m_axis_tdest_reg <= s_axis_tdest;
                    m_axis_tuser_reg <= s_axis_tuser;
                end else begin
                    buffer_count <= buffer_count - 1;
                end
            end

            if (m_axis_tready && m_axis_tvalid_reg) begin
                if (buffer_count == 1) begin
                    m_axis_tlast_reg <= s_axis_tlast;
                end
            end

            if (m_axis_tready && buffer_count > 0) begin
                m_axis_tvalid_reg <= 1;
                m_axis_tdata_next <= data_buffer[M_DATA_WIDTH*buffer_count-1:M_DATA_WIDTH*(buffer_count-1)];
                if (S_KEEP_ENABLE && M_KEEP_ENABLE) begin
                    m_axis_tkeep_next <= keep_buffer[S_KEEP_WIDTH*buffer_count-1:S_KEEP_WIDTH*(buffer_count-1)];
                end
            end

            if (s_axis_tvalid && (buffer_count == 0 || buffer_count == S_DATA_WIDTH / M_DATA_WIDTH)) begin
                s_axis_tready_reg <= m_axis_tready || !m_axis_tvalid_reg;
            end
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_next;
    assign m_axis_tkeep = m_axis_tkeep_next;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

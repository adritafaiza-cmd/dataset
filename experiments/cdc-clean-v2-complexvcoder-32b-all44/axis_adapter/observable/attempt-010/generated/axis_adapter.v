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

    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg                             s_axis_tvalid_reg;

    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg                             m_axis_tvalid_reg;

    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg                             buffer_valid;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] data_cnt;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] data_cnt_max;

    assign s_axis_tready = !s_axis_tvalid_reg | m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_axis_tvalid_reg <= 0;

            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_axis_tvalid_reg <= 0;

            data_buffer <= 0;
            keep_buffer <= 0;
            buffer_valid <= 0;
            data_cnt <= 0;
            data_cnt_max <= (S_DATA_WIDTH / M_DATA_WIDTH) - 1;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                s_axis_tvalid_reg <= 1;
            end else if (m_axis_tready) begin
                s_axis_tvalid_reg <= 0;
            end

            if (s_axis_tvalid && s_axis_tready && !buffer_valid) begin
                data_buffer <= s_axis_tdata;
                keep_buffer <= s_axis_tkeep;
                buffer_valid <= 1;
                data_cnt <= data_cnt_max;
            end else if (m_axis_tready && buffer_valid) begin
                if (data_cnt == 0) begin
                    buffer_valid <= 0;
                end else begin
                    data_cnt <= data_cnt - 1;
                end
            end

            if (m_axis_tready) begin
                m_axis_tvalid_reg <= buffer_valid || s_axis_tvalid_reg;
            end

            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tdata_reg <= data_buffer[(data_cnt+1)*M_DATA_WIDTH-1:data_cnt*M_DATA_WIDTH];
                m_axis_tkeep_reg <= keep_buffer[(data_cnt+1)*M_KEEP_WIDTH/M_DATA_WIDTH-1:data_cnt*M_KEEP_WIDTH/M_DATA_WIDTH];
                m_axis_tlast_reg <= (data_cnt == 0) && s_axis_tlast_reg;
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;
            end
        end
    end

    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

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
    reg                             s_axis_tready_int;
    reg                             m_axis_tvalid_int;
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg                             last_buffer;
    reg [ID_WIDTH-1:0]              id_buffer;
    reg [DEST_WIDTH-1:0]            dest_buffer;
    reg [USER_WIDTH-1:0]            user_buffer;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] data_index;
    reg                             packet_done;
    reg                             m_axis_tlast_int;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;

    /*
     * Main logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            packet_done <= 0;
            data_index <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
        end else begin
            if (s_axis_tready_int && s_axis_tvalid) begin
                data_buffer <= s_axis_tdata;
                keep_buffer <= s_axis_tkeep;
                last_buffer <= s_axis_tlast;
                if (packet_done) begin
                    id_buffer <= s_axis_tid;
                    dest_buffer <= s_axis_tdest;
                    user_buffer <= s_axis_tuser;
                end
            end

            if (m_axis_tvalid_int && m_axis_tready) begin
                m_axis_tvalid_int <= 0;
                if (packet_done) begin
                    packet_done <= 0;
                end else begin
                    data_index <= data_index + 1;
                    if (data_index == S_DATA_WIDTH/M_DATA_WIDTH - 1) begin
                        packet_done <= last_buffer;
                    end
                end
            end

            if (!m_axis_tvalid_int && s_axis_tvalid && s_axis_tready_int) begin
                m_axis_tvalid_int <= 1;
                m_axis_tdata_int <= data_buffer[(data_index+1)*M_DATA_WIDTH-1:data_index*M_DATA_WIDTH];
                m_axis_tkeep_int <= (M_KEEP_ENABLE) ? keep_buffer[(data_index+1)*M_KEEP_WIDTH-1:data_index*M_KEEP_WIDTH] : 1'b1;
                m_axis_tlast_int <= (data_index == S_DATA_WIDTH/M_DATA_WIDTH - 1) ? last_buffer : 0;
                if (data_index == 0) begin
                    m_axis_tid_int <= id_buffer;
                    m_axis_tdest_int <= dest_buffer;
                    m_axis_tuser_int <= user_buffer;
                end
            end
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

    /*
     * Generate s_axis_tready based on m_axis_tready and internal state
     */
    always @(*) begin
        if (m_axis_tvalid_int && !m_axis_tready) begin
            s_axis_tready_int = 0;
        end else begin
            s_axis_tready_int = 1;
        end
    end

endmodule

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

    // Internal signals
    reg [S_DATA_WIDTH-1:0]          s_axis_data_buffer;
    reg [S_KEEP_WIDTH-1:0]          s_axis_keep_buffer;
    reg                             s_axis_last_buffer;
    reg [ID_WIDTH-1:0]              s_axis_id_buffer;
    reg [DEST_WIDTH-1:0]            s_axis_dest_buffer;
    reg [USER_WIDTH-1:0]            s_axis_user_buffer;
    reg                             s_axis_buffer_valid;
    reg                             s_axis_buffer_ready;

    reg [M_DATA_WIDTH-1:0]          m_axis_data_buffer;
    reg [M_KEEP_WIDTH-1:0]          m_axis_keep_buffer;
    reg                             m_axis_last_buffer;
    reg [ID_WIDTH-1:0]              m_axis_id_buffer;
    reg [DEST_WIDTH-1:0]            m_axis_dest_buffer;
    reg [USER_WIDTH-1:0]            m_axis_user_buffer;
    reg                             m_axis_buffer_valid;
    reg                             m_axis_buffer_ready;

    reg [$clog2(S_DATA_WIDTH/8)-1:0] s_axis_byte_index;
    reg [$clog2(M_DATA_WIDTH/8)-1:0] m_axis_byte_index;

    reg                             s_axis_packet_done;
    reg                             m_axis_packet_done;
    reg [ID_WIDTH-1:0]              s_axis_packet_id;
    reg [DEST_WIDTH-1:0]            s_axis_packet_dest;
    reg [USER_WIDTH-1:0]            s_axis_packet_user;

    // AXI Stream Input Buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_data_buffer <= 0;
            s_axis_keep_buffer <= 0;
            s_axis_last_buffer <= 0;
            s_axis_id_buffer <= 0;
            s_axis_dest_buffer <= 0;
            s_axis_user_buffer <= 0;
            s_axis_buffer_valid <= 0;
            s_axis_byte_index <= 0;
            s_axis_packet_done <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_data_buffer <= s_axis_tdata;
                s_axis_keep_buffer <= s_axis_tkeep;
                s_axis_last_buffer <= s_axis_tlast;
                s_axis_id_buffer <= s_axis_tid;
                s_axis_dest_buffer <= s_axis_tdest;
                s_axis_user_buffer <= s_axis_tuser;
                s_axis_buffer_valid <= 1;
                s_axis_byte_index <= 0;
                if (s_axis_tlast)
                    s_axis_packet_done <= 1;
            end else if (m_axis_buffer_ready) begin
                if (s_axis_byte_index == S_KEEP_WIDTH - 1) begin
                    s_axis_buffer_valid <= 0;
                    s_axis_byte_index <= 0;
                    if (s_axis_packet_done)
                        s_axis_packet_done <= 0;
                end else begin
                    s_axis_byte_index <= s_axis_byte_index + 1;
                end
            end
        end
    end

    // AXI Stream Output Buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_data_buffer <= 0;
            m_axis_keep_buffer <= 0;
            m_axis_last_buffer <= 0;
            m_axis_id_buffer <= 0;
            m_axis_dest_buffer <= 0;
            m_axis_user_buffer <= 0;
            m_axis_buffer_valid <= 0;
            m_axis_byte_index <= 0;
            m_axis_packet_done <= 0;
        end else begin
            if (s_axis_buffer_valid && !m_axis_buffer_valid) begin
                m_axis_data_buffer <= s_axis_data_buffer;
                m_axis_keep_buffer <= s_axis_keep_buffer;
                m_axis_last_buffer <= s_axis_last_buffer;
                m_axis_id_buffer <= s_axis_id_buffer;
                m_axis_dest_buffer <= s_axis_dest_buffer;
                m_axis_user_buffer <= s_axis_user_buffer;
                m_axis_buffer_valid <= 1;
                m_axis_byte_index <= 0;
                if (s_axis_packet_done)
                    m_axis_packet_done <= 1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_byte_index == M_KEEP_WIDTH - 1) begin
                    m_axis_buffer_valid <= 0;
                    m_axis_byte_index <= 0;
                    if (m_axis_packet_done)
                        m_axis_packet_done <= 0;
                end else begin
                    m_axis_byte_index <= m_axis_byte_index + 1;
                end
            end
        end
    end

    // Handshake signals
    assign s_axis_tready = !s_axis_buffer_valid;
    assign m_axis_tvalid = m_axis_buffer_valid;

    // Output assignments
    assign m_axis_tdata = m_axis_data_buffer;
    assign m_axis_tkeep = m_axis_keep_buffer;
    assign m_axis_tlast = m_axis_last_buffer;
    assign m_axis_tid = m_axis_id_buffer;
    assign m_axis_tdest = m_axis_dest_buffer;
    assign m_axis_tuser = m_axis_user_buffer;

endmodule

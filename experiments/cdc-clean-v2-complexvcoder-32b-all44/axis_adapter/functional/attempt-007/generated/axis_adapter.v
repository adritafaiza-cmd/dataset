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
    reg                             s_axis_tready_int;
    reg                             m_axis_tvalid_int;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_int;
    reg                             m_axis_tlast_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;
    reg [S_DATA_WIDTH-1:0]          buffered_data;
    reg [S_KEEP_WIDTH-1:0]          buffered_keep;
    reg                             buffered_last;
    reg [ID_WIDTH-1:0]              buffered_id;
    reg [DEST_WIDTH-1:0]            buffered_dest;
    reg [USER_WIDTH-1:0]            buffered_user;
    reg                             buffer_valid;
    reg                             buffer_ready;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] pack_counter;

    // Output assignments
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

    // State machine to handle data packing/unpacking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            m_axis_tdata_int <= 0;
            m_axis_tkeep_int <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
            buffered_data <= 0;
            buffered_keep <= 0;
            buffered_last <= 0;
            buffered_id <= 0;
            buffered_dest <= 0;
            buffered_user <= 0;
            buffer_valid <= 0;
            buffer_ready <= 0;
            pack_counter <= 0;
        end else begin
            // Buffer input data if not ready to send
            if (s_axis_tvalid && !buffer_valid && !m_axis_tready) begin
                buffered_data <= s_axis_tdata;
                buffered_keep <= s_axis_tkeep;
                buffered_last <= s_axis_tlast;
                buffered_id <= s_axis_tid;
                buffered_dest <= s_axis_tdest;
                buffered_user <= s_axis_tuser;
                buffer_valid <= 1;
            end

            // Handle output data
            if (m_axis_tready) begin
                if (m_axis_tvalid_int) begin
                    if (pack_counter == 0) begin
                        buffer_valid <= 0;
                        pack_counter <= pack_counter + 1;
                    end else if (pack_counter < (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                        pack_counter <= pack_counter + 1;
                    end else begin
                        pack_counter <= 0;
                    end
                end
            end

            // Pack data
            if (buffer_valid && !m_axis_tvalid_int) begin
                m_axis_tdata_int <= buffered_data[(pack_counter + 1) * M_DATA_WIDTH - 1 -: M_DATA_WIDTH];
                m_axis_tkeep_int <= buffered_keep[(pack_counter + 1) / 8 - 1 -: 1];
                m_axis_tvalid_int <= 1;
                m_axis_tlast_int <= (pack_counter == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) && buffered_last;
                m_axis_tid_int <= buffered_id;
                m_axis_tdest_int <= buffered_dest;
                m_axis_tuser_int <= buffered_user;
            end

            // Deassert valid signal when data is accepted
            if (m_axis_tready && m_axis_tvalid_int) begin
                m_axis_tvalid_int <= 0;
            end

            // Assert ready signal when buffer is empty
            s_axis_tready_int <= !buffer_valid;
        end
    end

endmodule

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
    reg [S_DATA_WIDTH*2-1:0]        data_buffer;
    reg [S_KEEP_WIDTH*2-1:0]        keep_buffer;
    reg [1:0]                       data_buffer_ptr;
    reg                             data_buffer_full;
    reg                             data_buffer_empty;
    reg                             packet_ending;
    reg                             packet_ending_reg;
    reg [ID_WIDTH-1:0]              packet_id;
    reg [DEST_WIDTH-1:0]            packet_dest;
    reg [USER_WIDTH-1:0]            packet_user;
    reg [M_DATA_WIDTH-1:0]          m_axis_fifo_data;
    reg [M_KEEP_WIDTH-1:0]          m_axis_fifo_keep;
    reg                             m_axis_fifo_valid;
    reg                             m_axis_fifo_ready;
    reg                             m_axis_fifo_last;
    reg [ID_WIDTH-1:0]              m_axis_fifo_id;
    reg [DEST_WIDTH-1:0]            m_axis_fifo_dest;
    reg [USER_WIDTH-1:0]            m_axis_fifo_user;

    // Control signals
    wire                            s_axis_tready_int;
    wire                            m_axis_tvalid_int;

    // FIFO control
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;

    // Buffer control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer <= 0;
            keep_buffer <= 0;
            data_buffer_ptr <= 0;
            data_buffer_full <= 0;
            data_buffer_empty <= 1;
            packet_ending <= 0;
            packet_ending_reg <= 0;
            packet_id <= 0;
            packet_dest <= 0;
            packet_user <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_int) begin
                if (data_buffer_ptr == 0) begin
                    data_buffer[S_DATA_WIDTH*2-1:S_DATA_WIDTH] <= s_axis_tdata;
                    keep_buffer[S_KEEP_WIDTH*2-1:S_KEEP_WIDTH] <= s_axis_tkeep;
                end else begin
                    data_buffer[S_DATA_WIDTH-1:0] <= s_axis_tdata;
                    keep_buffer[S_KEEP_WIDTH-1:0] <= s_axis_tkeep;
                end

                if (data_buffer_ptr == 1 || s_axis_tlast) begin
                    data_buffer_full <= 1;
                    data_buffer_empty <= 0;
                end

                data_buffer_ptr <= data_buffer_ptr + 1;

                if (s_axis_tlast) begin
                    packet_ending <= 1;
                    packet_id <= s_axis_tid;
                    packet_dest <= s_axis_tdest;
                    packet_user <= s_axis_tuser;
                end
            end

            if (m_axis_tvalid_int && m_axis_tready) begin
                if (data_buffer_ptr == 0) begin
                    data_buffer[S_DATA_WIDTH*2-1:S_DATA_WIDTH] <= 0;
                    keep_buffer[S_KEEP_WIDTH*2-1:S_KEEP_WIDTH] <= 0;
                end else begin
                    data_buffer[S_DATA_WIDTH-1:0] <= 0;
                    keep_buffer[S_KEEP_WIDTH-1:0] <= 0;
                end

                if (data_buffer_ptr == 1 || packet_ending_reg) begin
                    data_buffer_full <= 0;
                    data_buffer_empty <= 1;
                end

                data_buffer_ptr <= data_buffer_ptr - 1;

                if (packet_ending_reg) begin
                    packet_ending <= 0;
                    packet_ending_reg <= 0;
                end
            end
        end
    end

    // Output control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_fifo_data <= 0;
            m_axis_fifo_keep <= 0;
            m_axis_fifo_valid <= 0;
            m_axis_fifo_last <= 0;
            m_axis_fifo_id <= 0;
            m_axis_fifo_dest <= 0;
            m_axis_fifo_user <= 0;
            m_axis_fifo_ready <= 1;
            packet_ending_reg <= 0;
        end else begin
            if (!data_buffer_empty && !m_axis_fifo_valid) begin
                if (data_buffer_ptr == 0) begin
                    m_axis_fifo_data <= data_buffer[S_DATA_WIDTH*2-1:S_DATA_WIDTH];
                    m_axis_fifo_keep <= keep_buffer[S_KEEP_WIDTH*2-1:S_KEEP_WIDTH];
                end else begin
                    m_axis_fifo_data <= data_buffer[S_DATA_WIDTH-1:0];
                    m_axis_fifo_keep <= keep_buffer[S_KEEP_WIDTH-1:0];
                end

                m_axis_fifo_valid <= 1;
                m_axis_fifo_last <= packet_ending;
                m_axis_fifo_id <= packet_id;
                m_axis_fifo_dest <= packet_dest;
                m_axis_fifo_user <= packet_user;
                packet_ending_reg <= packet_ending;
            end

            if (m_axis_tvalid_int && m_axis_tready) begin
                m_axis_fifo_valid <= 0;
            end
        end
    end

    // Ready and valid signals
    assign s_axis_tready_int = !data_buffer_full;
    assign m_axis_tvalid_int = m_axis_fifo_valid;

endmodule

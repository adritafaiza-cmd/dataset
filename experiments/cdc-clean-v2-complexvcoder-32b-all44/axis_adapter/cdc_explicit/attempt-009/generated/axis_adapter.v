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
    reg  [S_DATA_WIDTH-1:0]         s_axis_tdata_reg;
    reg  [S_KEEP_WIDTH-1:0]         s_axis_tkeep_reg;
    reg                             s_axis_tlast_reg;
    reg  [ID_WIDTH-1:0]             s_axis_tid_reg;
    reg  [DEST_WIDTH-1:0]           s_axis_tdest_reg;
    reg  [USER_WIDTH-1:0]           s_axis_tuser_reg;
    reg                             s_axis_tvalid_reg;

    reg  [S_DATA_WIDTH * (M_DATA_WIDTH/S_DATA_WIDTH) - 1:0] data_buffer;
    reg  [S_KEEP_WIDTH * (M_DATA_WIDTH/S_DATA_WIDTH) - 1:0] keep_buffer;
    reg  [$clog2(M_DATA_WIDTH/S_DATA_WIDTH) - 1:0] buffer_ptr;

    reg                             s_axis_tready_int;
    reg                             m_axis_tvalid_int;
    reg                             m_axis_tlast_int;
    reg  [ID_WIDTH-1:0]             m_axis_tid_int;
    reg  [DEST_WIDTH-1:0]           m_axis_tdest_int;
    reg  [USER_WIDTH-1:0]           m_axis_tuser_int;
    reg  [M_DATA_WIDTH-1:0]         m_axis_tdata_int;
    reg  [M_KEEP_WIDTH-1:0]         m_axis_tkeep_int;

    reg                             packet_last;
    reg  [ID_WIDTH-1:0]             packet_id;
    reg  [DEST_WIDTH-1:0]           packet_dest;
    reg  [USER_WIDTH-1:0]           packet_user;

    // Register inputs on the rising edge of the clock
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg    <= 0;
            s_axis_tkeep_reg    <= 0;
            s_axis_tlast_reg    <= 0;
            s_axis_tid_reg      <= 0;
            s_axis_tdest_reg    <= 0;
            s_axis_tuser_reg    <= 0;
            s_axis_tvalid_reg   <= 0;
        end else begin
            if (s_axis_tready_int && s_axis_tvalid) begin
                s_axis_tdata_reg    <= s_axis_tdata;
                s_axis_tkeep_reg    <= s_axis_tkeep;
                s_axis_tlast_reg    <= s_axis_tlast;
                s_axis_tid_reg      <= s_axis_tid;
                s_axis_tdest_reg    <= s_axis_tdest;
                s_axis_tuser_reg    <= s_axis_tuser;
                s_axis_tvalid_reg   <= s_axis_tvalid;
            end
        end
    end

    // Buffering logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer       <= 0;
            keep_buffer       <= 0;
            buffer_ptr        <= 0;
            packet_last       <= 0;
            packet_id         <= 0;
            packet_dest       <= 0;
            packet_user       <= 0;
        end else begin
            if (s_axis_tready_int && s_axis_tvalid_reg) begin
                data_buffer[S_DATA_WIDTH * buffer_ptr +: S_DATA_WIDTH] <= s_axis_tdata_reg;
                keep_buffer[S_KEEP_WIDTH * buffer_ptr +: S_KEEP_WIDTH] <= s_axis_tkeep_reg;
                if (buffer_ptr == (M_DATA_WIDTH/S_DATA_WIDTH - 1)) begin
                    buffer_ptr <= 0;
                    if (s_axis_tlast_reg) begin
                        packet_last <= 1;
                        packet_id   <= s_axis_tid_reg;
                        packet_dest <= s_axis_tdest_reg;
                        packet_user <= s_axis_tuser_reg;
                    end
                end else begin
                    buffer_ptr <= buffer_ptr + 1;
                end
            end
        end
    end

    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid_int <= 0;
            m_axis_tlast_int  <= 0;
            m_axis_tid_int    <= 0;
            m_axis_tdest_int  <= 0;
            m_axis_tuser_int  <= 0;
            m_axis_tdata_int  <= 0;
            m_axis_tkeep_int  <= 0;
        end else begin
            if (m_axis_tready && m_axis_tvalid_int) begin
                m_axis_tvalid_int <= 0;
            end else if (buffer_ptr == 0 && s_axis_tvalid_reg) begin
                m_axis_tvalid_int <= 1;
                m_axis_tdata_int  <= data_buffer[M_DATA_WIDTH - 1:0];
                m_axis_tkeep_int  <= keep_buffer[M_KEEP_WIDTH - 1:0];
                m_axis_tlast_int  <= packet_last;
                m_axis_tid_int    <= packet_id;
                m_axis_tdest_int  <= packet_dest;
                m_axis_tuser_int  <= packet_user;
                packet_last       <= 0;
            end
        end
    end

    // Handshake signals
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tdata  = m_axis_tdata_int;
    assign m_axis_tkeep  = m_axis_tkeep_int;
    assign m_axis_tlast  = m_axis_tlast_int;
    assign m_axis_tid    = m_axis_tid_int;
    assign m_axis_tdest  = m_axis_tdest_int;
    assign m_axis_tuser  = m_axis_tuser_int;

endmodule

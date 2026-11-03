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
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg                             buffer_valid;
    reg                             buffer_last;
    reg [ID_WIDTH-1:0]              buffer_tid;
    reg [DEST_WIDTH-1:0]            buffer_tdest;
    reg [USER_WIDTH-1:0]            buffer_tuser;
    reg [31:0]                      buffer_count;
    reg [31:0]                      pack_count;
    reg [31:0]                      unpack_count;
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
    reg                             s_axis_tvalid_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;

    /*
     * AXI input handshake
     */
    assign s_axis_tready = ~buffer_valid & ~m_axis_tvalid_reg;

    /*
     * AXI output handshake
     */
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    /*
     * Main state machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_valid <= 0;
            buffer_last <= 0;
            buffer_tid <= 0;
            buffer_tdest <= 0;
            buffer_tuser <= 0;
            buffer_count <= 0;
            pack_count <= 0;
            unpack_count <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid & s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= 1;
                s_axis_tlast_reg <= s_axis_tlast;
                if (ID_ENABLE)
                    s_axis_tid_reg <= s_axis_tid;
                if (DEST_ENABLE)
                    s_axis_tdest_reg <= s_axis_tdest;
                if (USER_ENABLE)
                    s_axis_tuser_reg <= s_axis_tuser;
            end

            if (m_axis_tvalid_reg & m_axis_tready) begin
                m_axis_tvalid_reg <= 0;
                m_axis_tlast_reg <= 0;
                if (buffer_valid) begin
                    if (buffer_count == unpack_count) begin
                        buffer_valid <= 0;
                    end else begin
                        buffer_count <= buffer_count + 1;
                    end
                end
            end

            if (s_axis_tvalid_reg & ~m_axis_tvalid_reg & m_axis_tready) begin
                if (buffer_valid) begin
                    if (buffer_count == unpack_count) begin
                        buffer_valid <= 0;
                    end else begin
                        buffer_count <= buffer_count + 1;
                    end
                end else begin
                    data_buffer <= s_axis_tdata_reg;
                    keep_buffer <= s_axis_tkeep_reg;
                    buffer_last <= s_axis_tlast_reg;
                    buffer_tid <= s_axis_tid_reg;
                    buffer_tdest <= s_axis_tdest_reg;
                    buffer_tuser <= s_axis_tuser_reg;
                    buffer_valid <= 1;
                    buffer_count <= 1;
                    unpack_count <= (S_DATA_WIDTH + M_DATA_WIDTH - 1) / M_DATA_WIDTH;
                end

                m_axis_tdata_reg <= data_buffer[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= keep_buffer[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= s_axis_tlast_reg & (unpack_count == 1);
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;

                if (unpack_count > 1) begin
                    pack_count <= 1;
                    s_axis_tvalid_reg <= 0;
                end
            end else if (buffer_valid & ~m_axis_tvalid_reg & m_axis_tready) begin
                m_axis_tdata_reg <= data_buffer[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= keep_buffer[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= buffer_last & (unpack_count == buffer_count);
                m_axis_tid_reg <= buffer_tid;
                m_axis_tdest_reg <= buffer_tdest;
                m_axis_tuser_reg <= buffer_tuser;

                if (unpack_count > buffer_count) begin
                    pack_count <= pack_count + 1;
                end else begin
                    buffer_valid <= 0;
                end
            end
        end
    end

endmodule

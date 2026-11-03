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
    reg [S_DATA_WIDTH*2-1:0]      s_axis_tdata_shift_reg;
    reg [S_KEEP_WIDTH*2-1:0]      s_axis_tkeep_shift_reg;
    reg [1:0]                       s_axis_tlast_shift_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg                             s_axis_tready_reg;
    reg                             m_axis_tvalid_reg;
    reg [7:0]                       s_axis_data_count;
    reg [7:0]                       m_axis_data_count;
    reg                             packet_complete;
    reg                             s_axis_tdata_valid;
    reg                             m_axis_tdata_ready;

    // Shift register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_shift_reg <= 0;
            s_axis_tkeep_shift_reg <= 0;
            s_axis_tlast_shift_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_axis_data_count <= 0;
            s_axis_tdata_valid <= 0;
        end else begin
            if (s_axis_tready_reg && s_axis_tvalid) begin
                s_axis_tdata_shift_reg <= {s_axis_tdata_shift_reg[S_DATA_WIDTH-1:0], s_axis_tdata};
                s_axis_tkeep_shift_reg <= {s_axis_tkeep_shift_reg[S_KEEP_WIDTH-1:0], s_axis_tkeep};
                s_axis_tlast_shift_reg <= {s_axis_tlast_shift_reg[0], s_axis_tlast};
                s_axis_data_count <= s_axis_data_count + 1;
                s_axis_tdata_valid <= 1;
                if (s_axis_tlast) begin
                    s_axis_tid_reg <= s_axis_tid;
                    s_axis_tdest_reg <= s_axis_tdest;
                    s_axis_tuser_reg <= s_axis_tuser;
                end
            end
        end
    end

    // Output data generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_data_count <= 0;
            m_axis_tdata_ready <= 0;
            packet_complete <= 0;
        end else begin
            if (m_axis_tdata_ready && m_axis_tvalid_reg) begin
                m_axis_tdata_reg <= m_axis_tdata_reg >> M_DATA_WIDTH;
                m_axis_tkeep_reg <= m_axis_tkeep_reg >> M_KEEP_WIDTH;
                m_axis_data_count <= m_axis_data_count + 1;
                if (m_axis_data_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                    m_axis_tlast_reg <= s_axis_tlast_shift_reg[1];
                    m_axis_tid_reg <= s_axis_tid_reg;
                    m_axis_tdest_reg <= s_axis_tdest_reg;
                    m_axis_tuser_reg <= s_axis_tuser_reg;
                    packet_complete <= 1;
                end
            end
            if (s_axis_tdata_valid && (m_axis_data_count == 0 || packet_complete)) begin
                m_axis_tdata_reg <= s_axis_tdata_shift_reg[S_DATA_WIDTH*2-1:S_DATA_WIDTH];
                m_axis_tkeep_reg <= s_axis_tkeep_shift_reg[S_KEEP_WIDTH*2-1:S_KEEP_WIDTH];
                m_axis_tvalid_reg <= 1;
                m_axis_data_count <= 0;
                packet_complete <= 0;
                if (s_axis_data_count == (S_DATA_WIDTH / M_DATA_WIDTH)) begin
                    s_axis_tdata_valid <= 0;
                end
            end
            m_axis_tdata_ready <= m_axis_tready;
        end
    end

    // Handshake signals
    assign s_axis_tready = s_axis_tready_reg && !s_axis_tdata_valid;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata = m_axis_tdata_reg[M_DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_axis_tkeep_reg[M_KEEP_WIDTH-1:0];
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

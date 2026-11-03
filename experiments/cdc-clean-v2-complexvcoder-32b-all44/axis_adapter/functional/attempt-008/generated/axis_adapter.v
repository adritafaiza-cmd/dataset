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

    reg [S_DATA_WIDTH-1:0]          shift_reg_data;
    reg [S_KEEP_WIDTH-1:0]          shift_reg_keep;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [2:0]                       bit_counter;
    reg [2:0]                       byte_counter;
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
    reg                             s_axis_tvalid_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg                             data_available;
    reg                             data_accepted;
    reg                             packet_start;
    reg                             packet_end;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg_data <= 0;
            shift_reg_keep <= 0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            bit_counter <= 0;
            byte_counter <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            data_available <= 0;
            data_accepted <= 0;
            packet_start <= 0;
            packet_end <= 0;
        end else begin
            // Register input signals
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                data_available <= 1;
                packet_start <= s_axis_tvalid && !s_axis_tready;
            end else if (data_accepted) begin
                data_available <= 0;
            end

            // Shift data and keep signals
            if (data_available && !data_accepted) begin
                shift_reg_data <= {shift_reg_data[S_DATA_WIDTH-2:0], s_axis_tdata_reg};
                shift_reg_keep <= {shift_reg_keep[S_KEEP_WIDTH-2:0], s_axis_tkeep_reg};
                data_accepted <= 1;
            end else if (m_axis_tvalid_reg && m_axis_tready) begin
                if (bit_counter < S_DATA_WIDTH - 1) begin
                    shift_reg_data <= {shift_reg_data[S_DATA_WIDTH-2:0], shift_reg_data[S_DATA_WIDTH-1]};
                    shift_reg_keep <= {shift_reg_keep[S_KEEP_WIDTH-2:0], shift_reg_keep[S_KEEP_WIDTH-1]};
                    bit_counter <= bit_counter + 1;
                end else begin
                    bit_counter <= 0;
                    if (byte_counter < S_KEEP_WIDTH - 1) begin
                        byte_counter <= byte_counter + 1;
                    end else begin
                        data_accepted <= 0;
                        byte_counter <= 0;
                    end
                end
            end

            // Generate output signals
            if (data_accepted) begin
                m_axis_tdata_reg <= shift_reg_data[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= shift_reg_keep[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= s_axis_tlast_reg && (byte_counter == S_KEEP_WIDTH - 1) && (bit_counter == S_DATA_WIDTH - 1);
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;
            end else if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 0;
            end
        end
    end

    assign s_axis_tready = !data_available;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

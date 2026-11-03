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
    reg                               s_axis_tvalid_reg;
    reg                               s_axis_tlast_reg;
    reg  [ID_WIDTH-1:0]             s_axis_tid_reg;
    reg  [DEST_WIDTH-1:0]           s_axis_tdest_reg;
    reg  [USER_WIDTH-1:0]           s_axis_tuser_reg;
    reg  [M_DATA_WIDTH-1:0]         m_axis_tdata_reg;
    reg  [M_KEEP_WIDTH-1:0]         m_axis_tkeep_reg;
    reg                               m_axis_tvalid_reg;
    reg                               m_axis_tlast_reg;
    reg  [ID_WIDTH-1:0]             m_axis_tid_reg;
    reg  [DEST_WIDTH-1:0]           m_axis_tdest_reg;
    reg  [USER_WIDTH-1:0]           m_axis_tuser_reg;
    reg  [S_DATA_WIDTH-1:0]         data_buffer [0:S_DATA_WIDTH/M_DATA_WIDTH-1];
    reg  [S_KEEP_WIDTH-1:0]         keep_buffer [0:S_DATA_WIDTH/M_DATA_WIDTH-1];
    reg  [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] buffer_pointer;
    reg                               last_received;
    reg                               last_sent;
    reg                               valid_data;
    reg                               ready_to_send;

    // Output ready signal
    assign s_axis_tready = valid_data ? ~ready_to_send : m_axis_tready;

    // Output data and sideband fields
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all internal signals to zero on reset
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
            buffer_pointer <= 0;
            last_received <= 0;
            last_sent <= 0;
            valid_data <= 0;
            ready_to_send <= 0;
        end else begin
            // Register input data and sideband fields
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                last_received <= s_axis_tlast;
            end

            // Buffer data and keep signals
            if (s_axis_tvalid && s_axis_tready) begin
                data_buffer[buffer_pointer] <= s_axis_tdata;
                keep_buffer[buffer_pointer] <= s_axis_tkeep;
                if (buffer_pointer == S_DATA_WIDTH/M_DATA_WIDTH - 1) begin
                    buffer_pointer <= 0;
                end else begin
                    buffer_pointer <= buffer_pointer + 1;
                end
            end

            // Transfer data to output
            if (m_axis_tready && valid_data) begin
                m_axis_tdata_reg <= data_buffer[buffer_pointer];
                m_axis_tkeep_reg <= keep_buffer[buffer_pointer];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= last_sent;
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;
                if (buffer_pointer == S_DATA_WIDTH/M_DATA_WIDTH - 1) begin
                    buffer_pointer <= 0;
                end else begin
                    buffer_pointer <= buffer_pointer + 1;
                end
                if (last_sent) begin
                    last_sent <= 0;
                end
                if (buffer_pointer == 0 && last_received) begin
                    last_sent <= 1;
                    last_received <= 0;
                end
                if (buffer_pointer == S_DATA_WIDTH/M_DATA_WIDTH - 1) begin
                    valid_data <= 0;
                end
            end

            // Update ready_to_send and valid_data signals
            if (m_axis_tready && valid_data) begin
                ready_to_send <= 0;
                if (buffer_pointer == S_DATA_WIDTH/M_DATA_WIDTH - 1) begin
                    valid_data <= 0;
                end
            end else if (s_axis_tvalid && s_axis_tready) begin
                valid_data <= 1;
                ready_to_send <= 1;
            end
        end
    end

endmodule

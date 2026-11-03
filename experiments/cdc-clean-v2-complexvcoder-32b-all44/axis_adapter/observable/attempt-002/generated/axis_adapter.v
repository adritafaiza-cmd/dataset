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

    // Internal registers
    reg [S_DATA_WIDTH-1:0]          s_axis_data_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_keep_reg;
    reg                             s_axis_tvalid_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_data_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_keep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0]          data_buffer [0:(M_DATA_WIDTH/S_DATA_WIDTH)-1];
    reg [S_KEEP_WIDTH-1:0]          keep_buffer [0:(M_KEEP_WIDTH/S_KEEP_WIDTH)-1];
    reg [$clog2(M_DATA_WIDTH/S_DATA_WIDTH)-1:0] buffer_pointer;
    reg                             data_valid;
    reg                             data_stalled;

    // Ready signal for input
    assign s_axis_tready = ~data_valid;

    // Output assignments
    assign m_axis_tdata = m_axis_data_reg;
    assign m_axis_tkeep = m_axis_keep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Clear all registers and buffers
            s_axis_data_reg <= 0;
            s_axis_keep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            m_axis_data_reg <= 0;
            m_axis_keep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            data_buffer <= '{default: 0};
            keep_buffer <= '{default: 0};
            buffer_pointer <= 0;
            data_valid <= 0;
            data_stalled <= 0;
        end else begin
            // Read input data and sideband signals
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_data_reg <= s_axis_tdata;
                s_axis_keep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= 1;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end

            // Output data and sideband signals
            if (m_axis_tready && data_valid) begin
                m_axis_data_reg <= data_buffer[buffer_pointer];
                m_axis_keep_reg <= keep_buffer[buffer_pointer];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= (buffer_pointer == (M_DATA_WIDTH/S_DATA_WIDTH - 1)) && s_axis_tlast_reg;
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;

                // Move to the next buffer position
                buffer_pointer <= buffer_pointer + 1;

                // Check if the current packet is complete
                if (buffer_pointer == (M_DATA_WIDTH/S_DATA_WIDTH - 1)) begin
                    buffer_pointer <= 0;
                    data_valid <= 0;
                end

                // Clear stalled flag if data was output
                if (data_stalled) begin
                    data_stalled <= 0;
                end
            end else if (data_valid && !m_axis_tready) begin
                // Stall the data if output is not ready
                data_stalled <= 1;
            end

            // Buffer new data if there is space and input is valid
            if (!data_valid && s_axis_tvalid_reg) begin
                data_buffer[0] <= s_axis_data_reg;
                keep_buffer[0] <= s_axis_keep_reg;
                buffer_pointer <= 0;
                data_valid <= 1;
            end
        end
    end

endmodule

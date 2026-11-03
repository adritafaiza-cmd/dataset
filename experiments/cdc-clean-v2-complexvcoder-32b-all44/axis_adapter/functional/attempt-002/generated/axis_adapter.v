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
    reg                             s_axis_tready_reg;
    reg                             m_axis_tvalid_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH+1)-1:0] buffer_count;
    reg                             buffer_valid;
    reg                             buffer_last;
    reg [ID_WIDTH-1:0]              buffer_id;
    reg [DEST_WIDTH-1:0]            buffer_dest;
    reg [USER_WIDTH-1:0]            buffer_user;

    // Assign outputs
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tkeep  = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast  = m_axis_tlast_reg;
    assign m_axis_tid    = m_axis_tid_reg;
    assign m_axis_tdest  = m_axis_tdest_reg;
    assign m_axis_tuser  = m_axis_tuser_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg  <= 1'b0;
            buffer_valid      <= 1'b0;
            buffer_count      <= {$clog2(S_DATA_WIDTH/M_DATA_WIDTH+1){1'b0}};
        end else begin
            // Handle input data
            if (s_axis_tvalid && s_axis_tready_reg) begin
                if (buffer_count == 0) begin
                    buffer_id   <= s_axis_tid;
                    buffer_dest <= s_axis_tdest;
                    buffer_user <= s_axis_tuser;
                end
                if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                    m_axis_tdata_reg <= s_axis_tdata;
                    m_axis_tkeep_reg <= s_axis_tkeep;
                    m_axis_tlast_reg <= s_axis_tlast;
                    m_axis_tvalid_reg <= 1'b1;
                end else begin
                    if (buffer_count == 0) begin
                        data_buffer  <= s_axis_tdata;
                        keep_buffer  <= s_axis_tkeep;
                        buffer_last  <= s_axis_tlast;
                        buffer_valid <= 1'b1;
                        buffer_count <= S_DATA_WIDTH/M_DATA_WIDTH;
                    end else begin
                        data_buffer  <= {data_buffer[S_DATA_WIDTH-M_DATA_WIDTH-1:0], s_axis_tdata};
                        keep_buffer  <= {keep_buffer[S_KEEP_WIDTH-1:0], s_axis_tkeep};
                        buffer_last  <= s_axis_tlast;
                        buffer_valid <= 1'b1;
                        buffer_count <= buffer_count - 1;
                    end
                end
            end

            // Handle output data
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
                if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                    // No buffering needed
                end else begin
                    if (buffer_count == 0) begin
                        buffer_valid <= 1'b0;
                    end else begin
                        m_axis_tdata_reg <= data_buffer[M_DATA_WIDTH-1:0];
                        m_axis_tkeep_reg <= keep_buffer[M_KEEP_WIDTH-1:0];
                        m_axis_tlast_reg <= buffer_last;
                        data_buffer      <= data_buffer[S_DATA_WIDTH-1:M_DATA_WIDTH];
                        keep_buffer      <= keep_buffer[S_KEEP_WIDTH-1:M_KEEP_WIDTH];
                        buffer_count     <= buffer_count - 1;
                    end
                end
            end

            // Update sideband signals
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tid_reg   <= buffer_id;
                m_axis_tdest_reg <= buffer_dest;
                m_axis_tuser_reg <= buffer_user;
            end

            // Update s_axis_tready
            if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                s_axis_tready_reg <= !m_axis_tvalid_reg || m_axis_tready;
            end else begin
                s_axis_tready_reg <= (buffer_count == 0) && (!m_axis_tvalid_reg || m_axis_tready);
            end
        end
    end
endmodule

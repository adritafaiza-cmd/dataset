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

    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg [$clog2(S_KEEP_WIDTH):0]    data_ptr;
    reg                             packet_start;
    reg                             packet_end;

    // FIFO for data buffering
    reg [S_DATA_WIDTH-1:0]          fifo_data [0:(S_DATA_WIDTH/M_DATA_WIDTH)-1];
    reg [S_KEEP_WIDTH-1:0]          fifo_keep [0:(S_DATA_WIDTH/M_DATA_WIDTH)-1];
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH):0] fifo_wr_ptr;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH):0] fifo_rd_ptr;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH):0] fifo_count;
    reg [S_KEEP_WIDTH-1:0]          fifo_keep_mask;

    // Control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready <= 0;
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
            data_buffer <= 0;
            keep_buffer <= 0;
            data_ptr <= 0;
            packet_start <= 0;
            packet_end <= 0;
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count <= 0;
            fifo_keep_mask <= 0;
        end else begin
            // Register input signals
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;

            // FIFO write logic
            if (s_axis_tvalid_reg && s_axis_tready) begin
                fifo_data[fifo_wr_ptr] <= s_axis_tdata_reg;
                fifo_keep[fifo_wr_ptr] <= s_axis_tkeep_reg;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count + 1;
            end

            // FIFO read logic
            if (m_axis_tvalid_reg && m_axis_tready) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_count <= fifo_count - 1;
            end

            // Data packing logic
            if (s_axis_tvalid_reg && s_axis_tready) begin
                if (data_ptr == 0) begin
                    data_buffer <= s_axis_tdata_reg;
                    keep_buffer <= s_axis_tkeep_reg;
                    packet_start <= 1;
                end else begin
                    data_buffer <= {data_buffer, s_axis_tdata_reg};
                    keep_buffer <= {keep_buffer, s_axis_tkeep_reg};
                end
                data_ptr <= data_ptr + 1;
                if (data_ptr == (S_DATA_WIDTH/M_DATA_WIDTH) - 1) begin
                    data_ptr <= 0;
                    packet_end <= 1;
                end
            end

            // Output data generation
            if (fifo_count > 0) begin
                m_axis_tdata_reg <= fifo_data[fifo_rd_ptr];
                m_axis_tkeep_reg <= fifo_keep[fifo_rd_ptr];
                m_axis_tvalid_reg <= 1;
                if (packet_end) begin
                    m_axis_tlast_reg <= s_axis_tlast_reg;
                    m_axis_tid_reg <= s_axis_tid_reg;
                    m_axis_tdest_reg <= s_axis_tdest_reg;
                    m_axis_tuser_reg <= s_axis_tuser_reg;
                    packet_end <= 0;
                end else begin
                    m_axis_tlast_reg <= 0;
                    m_axis_tid_reg <= 0;
                    m_axis_tdest_reg <= 0;
                    m_axis_tuser_reg <= 0;
                end
            end else begin
                m_axis_tvalid_reg <= 0;
                m_axis_tlast_reg <= 0;
            end

            // Handshake control
            s_axis_tready <= (fifo_count < (S_DATA_WIDTH/M_DATA_WIDTH));
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

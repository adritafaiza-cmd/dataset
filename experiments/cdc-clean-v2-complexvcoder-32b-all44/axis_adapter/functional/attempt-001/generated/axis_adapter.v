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

    reg [S_DATA_WIDTH-1:0]  data_buffer;
    reg [S_KEEP_WIDTH-1:0]  keep_buffer;
    reg                     last_buffer;
    reg [ID_WIDTH-1:0]      id_buffer;
    reg [DEST_WIDTH-1:0]    dest_buffer;
    reg [USER_WIDTH-1:0]    user_buffer;
    reg                     buffer_full;
    reg                     buffer_empty;
    reg                     packing;
    reg                     unpacking;
    reg [7:0]               buffer_count;

    reg [M_DATA_WIDTH-1:0]  m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]  m_axis_tkeep_reg;
    reg                     m_axis_tvalid_reg;
    reg                     m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]      m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]    m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]    m_axis_tuser_reg;

    wire [S_DATA_WIDTH-1:0] data_shifted;
    wire [S_KEEP_WIDTH-1:0] keep_shifted;

    assign s_axis_tready = ~buffer_full & m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_full <= 0;
            buffer_empty <= 1;
            buffer_count <= 0;
            packing <= 0;
            unpacking <= 0;
            data_buffer <= 0;
            keep_buffer <= 0;
            last_buffer <= 0;
            id_buffer <= 0;
            dest_buffer <= 0;
            user_buffer <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (buffer_empty) begin
                    data_buffer <= s_axis_tdata;
                    keep_buffer <= s_axis_tkeep;
                    last_buffer <= s_axis_tlast;
                    id_buffer <= s_axis_tid;
                    dest_buffer <= s_axis_tdest;
                    user_buffer <= s_axis_tuser;
                    buffer_empty <= 0;
                    buffer_count <= S_DATA_WIDTH;
                    if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                        buffer_full <= 1;
                    end
                end else begin
                    buffer_full <= 1;
                end
            end

            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 0;
                if (buffer_count == M_DATA_WIDTH) begin
                    if (last_buffer) begin
                        last_buffer <= 0;
                        buffer_empty <= 1;
                    end else begin
                        data_buffer <= data_shifted;
                        keep_buffer <= keep_shifted;
                        buffer_count <= buffer_count - M_DATA_WIDTH;
                    end
                end else begin
                    buffer_empty <= 1;
                end
            end

            if (s_axis_tvalid && s_axis_tready && buffer_empty) begin
                m_axis_tvalid_reg <= 1;
                m_axis_tdata_reg <= s_axis_tdata;
                m_axis_tkeep_reg <= s_axis_tkeep;
                m_axis_tlast_reg <= s_axis_tlast;
                m_axis_tid_reg <= s_axis_tid;
                m_axis_tdest_reg <= s_axis_tdest;
                m_axis_tuser_reg <= s_axis_tuser;
            end else if (buffer_count == M_DATA_WIDTH && m_axis_tready) begin
                m_axis_tvalid_reg <= 1;
                m_axis_tdata_reg <= data_buffer;
                m_axis_tkeep_reg <= keep_buffer;
                m_axis_tlast_reg <= last_buffer;
                m_axis_tid_reg <= id_buffer;
                m_axis_tdest_reg <= dest_buffer;
                m_axis_tuser_reg <= user_buffer;
            end
        end
    end

    assign data_shifted = {data_buffer, s_axis_tdata};
    assign keep_shifted = {keep_buffer, s_axis_tkeep};

    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

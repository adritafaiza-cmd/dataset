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
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
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

    // Buffer control signals
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] write_ptr;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] read_ptr;
    reg [S_DATA_WIDTH-1:0]          buffer [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg [S_KEEP_WIDTH-1:0]          buffer_keep [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg                             buffer_last [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg [ID_WIDTH-1:0]              buffer_tid [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg [DEST_WIDTH-1:0]            buffer_tdest [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg [USER_WIDTH-1:0]            buffer_tuser [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg                             buffer_full;
    reg                             buffer_empty;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH+1)-1:0] buffer_count;

    // Buffer control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;
            buffer_full <= 0;
            buffer_empty <= 1;
            buffer_count <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
        end else begin
            // Write to buffer
            if (s_axis_tvalid && s_axis_tready && !buffer_full) begin
                buffer[write_ptr] <= s_axis_tdata_reg;
                buffer_keep[write_ptr] <= s_axis_tkeep_reg;
                buffer_last[write_ptr] <= s_axis_tlast_reg;
                buffer_tid[write_ptr] <= s_axis_tid_reg;
                buffer_tdest[write_ptr] <= s_axis_tdest_reg;
                buffer_tuser[write_ptr] <= s_axis_tuser_reg;
                write_ptr <= write_ptr + 1;
                if (write_ptr == S_DATA_WIDTH/M_DATA_WIDTH - 1)
                    write_ptr <= 0;
                buffer_count <= buffer_count + 1;
                if (buffer_count == S_DATA_WIDTH/M_DATA_WIDTH - 1)
                    buffer_full <= 1;
                buffer_empty <= 0;
            end

            // Read from buffer
            if (m_axis_tready && m_axis_tvalid_reg && !buffer_empty) begin
                read_ptr <= read_ptr + 1;
                if (read_ptr == S_DATA_WIDTH/M_DATA_WIDTH - 1)
                    read_ptr <= 0;
                buffer_count <= buffer_count - 1;
                if (buffer_count == 0)
                    buffer_empty <= 1;
                buffer_full <= 0;
            end

            // Update m_axis_tvalid
            m_axis_tvalid_reg <= !buffer_empty;

            // Update m_axis_tlast
            m_axis_tlast_reg <= buffer_last[read_ptr];

            // Update m_axis_tdata, m_axis_tkeep, m_axis_tid, m_axis_tdest, m_axis_tuser
            m_axis_tdata_reg <= buffer[read_ptr];
            m_axis_tkeep_reg <= buffer_keep[read_ptr];
            m_axis_tid_reg <= buffer_tid[read_ptr];
            m_axis_tdest_reg <= buffer_tdest[read_ptr];
            m_axis_tuser_reg <= buffer_tuser[read_ptr];
        end
    end

    // Sample input data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end
    end

    // Generate s_axis_tready
    assign s_axis_tready = !buffer_full;

    // Assign output signals
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

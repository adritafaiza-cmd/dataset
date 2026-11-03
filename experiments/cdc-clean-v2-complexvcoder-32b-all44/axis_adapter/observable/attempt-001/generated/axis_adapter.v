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

    // FIFO depth is 256 entries
    localparam FIFO_DEPTH = 256;
    localparam FIFO_ADDR_WIDTH = 8;

    // FIFO signals
    reg [S_DATA_WIDTH-1:0] s_axis_data_fifo [FIFO_DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] s_axis_keep_fifo [FIFO_DEPTH-1:0];
    reg s_axis_tvalid_fifo [FIFO_DEPTH-1:0];
    reg s_axis_tlast_fifo [FIFO_DEPTH-1:0];
    reg [ID_WIDTH-1:0] s_axis_tid_fifo [FIFO_DEPTH-1:0];
    reg [DEST_WIDTH-1:0] s_axis_tdest_fifo [FIFO_DEPTH-1:0];
    reg [USER_WIDTH-1:0] s_axis_tuser_fifo [FIFO_DEPTH-1:0];
    reg [FIFO_ADDR_WIDTH-1:0] fifo_write_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] fifo_read_ptr;
    reg fifo_full;
    reg fifo_empty;

    // Data buffer signals
    reg [M_DATA_WIDTH-1:0] m_axis_data_buffer [FIFO_DEPTH-1:0];
    reg [M_KEEP_WIDTH-1:0] m_axis_keep_buffer [FIFO_DEPTH-1:0];
    reg m_axis_tvalid_buffer [FIFO_DEPTH-1:0];
    reg m_axis_tlast_buffer [FIFO_DEPTH-1:0];
    reg [ID_WIDTH-1:0] m_axis_tid_buffer [FIFO_DEPTH-1:0];
    reg [DEST_WIDTH-1:0] m_axis_tdest_buffer [FIFO_DEPTH-1:0];
    reg [USER_WIDTH-1:0] m_axis_tuser_buffer [FIFO_DEPTH-1:0];
    reg [FIFO_ADDR_WIDTH-1:0] data_buffer_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] data_buffer_count;
    reg data_buffer_full;
    reg data_buffer_empty;

    // FIFO control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_write_ptr <= 0;
            fifo_read_ptr <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            if (s_axis_tvalid && !fifo_full && s_axis_tready) begin
                s_axis_data_fifo[fifo_write_ptr] <= s_axis_tdata;
                s_axis_keep_fifo[fifo_write_ptr] <= s_axis_tkeep;
                s_axis_tvalid_fifo[fifo_write_ptr] <= 1;
                s_axis_tlast_fifo[fifo_write_ptr] <= s_axis_tlast;
                s_axis_tid_fifo[fifo_write_ptr] <= s_axis_tid;
                s_axis_tdest_fifo[fifo_write_ptr] <= s_axis_tdest;
                s_axis_tuser_fifo[fifo_write_ptr] <= s_axis_tuser;
                fifo_write_ptr <= fifo_write_ptr + 1;
                fifo_empty <= 0;
                if (fifo_write_ptr == fifo_read_ptr - 1)
                    fifo_full <= 1;
            end else if (m_axis_tready && !fifo_empty && m_axis_tvalid) begin
                fifo_read_ptr <= fifo_read_ptr + 1;
                fifo_full <= 0;
                if (fifo_read_ptr == fifo_write_ptr)
                    fifo_empty <= 1;
            end
        end
    end

    // Data buffer control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer_ptr <= 0;
            data_buffer_count <= 0;
            data_buffer_full <= 0;
            data_buffer_empty <= 1;
        end else begin
            if (!fifo_empty && !data_buffer_full && m_axis_tready) begin
                m_axis_data_buffer[data_buffer_ptr] <= s_axis_data_fifo[fifo_read_ptr];
                m_axis_keep_buffer[data_buffer_ptr] <= s_axis_keep_fifo[fifo_read_ptr];
                m_axis_tvalid_buffer[data_buffer_ptr] <= 1;
                m_axis_tlast_buffer[data_buffer_ptr] <= s_axis_tlast_fifo[fifo_read_ptr];
                m_axis_tid_buffer[data_buffer_ptr] <= s_axis_tid_fifo[fifo_read_ptr];
                m_axis_tdest_buffer[data_buffer_ptr] <= s_axis_tdest_fifo[fifo_read_ptr];
                m_axis_tuser_buffer[data_buffer_ptr] <= s_axis_tuser_fifo[fifo_read_ptr];
                data_buffer_ptr <= data_buffer_ptr + 1;
                data_buffer_empty <= 0;
                if (data_buffer_ptr == data_buffer_count - 1)
                    data_buffer_full <= 1;
                data_buffer_count <= data_buffer_count + 1;
            end else if (m_axis_tready && !data_buffer_empty) begin
                data_buffer_ptr <= data_buffer_ptr + 1;
                data_buffer_full <= 0;
                if (data_buffer_ptr == data_buffer_count)
                    data_buffer_empty <= 1;
            end
        end
    end

    // Output signals
    assign s_axis_tready = !fifo_full;
    assign m_axis_tdata = m_axis_data_buffer[data_buffer_ptr];
    assign m_axis_tkeep = m_axis_keep_buffer[data_buffer_ptr];
    assign m_axis_tvalid = !data_buffer_empty;
    assign m_axis_tlast = m_axis_tlast_buffer[data_buffer_ptr];
    assign m_axis_tid = m_axis_tid_buffer[data_buffer_ptr];
    assign m_axis_tdest = m_axis_tdest_buffer[data_buffer_ptr];
    assign m_axis_tuser = m_axis_tuser_buffer[data_buffer_ptr];

endmodule

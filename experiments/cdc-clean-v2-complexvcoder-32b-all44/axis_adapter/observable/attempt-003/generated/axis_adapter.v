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
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_shift_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_shift_reg;
    reg                             s_axis_tvalid_shift_reg;
    reg                             s_axis_tlast_shift_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_shift_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_shift_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_shift_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [7:0]                       shift_count;
    reg [(S_DATA_WIDTH * (M_DATA_WIDTH / S_DATA_WIDTH))-1:0] data_buffer;
    reg [(S_KEEP_WIDTH * (M_DATA_WIDTH / S_DATA_WIDTH))-1:0] keep_buffer;
    reg [7:0]                       buffer_ptr;
    reg                             buffer_full;
    reg                             buffer_empty;

    // Calculate the number of input words needed to fill the output word
    localparam NUM_INPUT_WORDS = M_DATA_WIDTH / S_DATA_WIDTH;

    // Buffer management
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_ptr <= 0;
            buffer_full <= 0;
            buffer_empty <= 1;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                buffer_ptr <= buffer_ptr + 1;
                if (buffer_ptr == NUM_INPUT_WORDS - 1) begin
                    buffer_full <= 1;
                end
                buffer_empty <= 0;
            end else if (m_axis_tvalid && m_axis_tready) begin
                buffer_ptr <= buffer_ptr - 1;
                if (buffer_ptr == 0) begin
                    buffer_empty <= 1;
                end
                buffer_full <= 0;
            end
        end
    end

    // Input data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_shift_reg <= 0;
            s_axis_tkeep_shift_reg <= 0;
            s_axis_tvalid_shift_reg <= 0;
            s_axis_tlast_shift_reg <= 0;
            s_axis_tid_shift_reg <= 0;
            s_axis_tdest_shift_reg <= 0;
            s_axis_tuser_shift_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_shift_reg <= s_axis_tdata;
            s_axis_tkeep_shift_reg <= s_axis_tkeep;
            s_axis_tvalid_shift_reg <= s_axis_tvalid;
            s_axis_tlast_shift_reg <= s_axis_tlast;
            s_axis_tid_shift_reg <= s_axis_tid;
            s_axis_tdest_shift_reg <= s_axis_tdest;
            s_axis_tuser_shift_reg <= s_axis_tuser;
        end
    end

    // Data and keep buffer handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer <= 0;
            keep_buffer <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            data_buffer[buffer_ptr * S_DATA_WIDTH +: S_DATA_WIDTH] <= s_axis_tdata;
            keep_buffer[buffer_ptr * S_KEEP_WIDTH +: S_KEEP_WIDTH] <= s_axis_tkeep;
        end
    end

    // Output data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else if (buffer_full && m_axis_tready) begin
            m_axis_tdata_reg <= data_buffer;
            m_axis_tkeep_reg <= keep_buffer;
            m_axis_tvalid_reg <= 1;
            m_axis_tlast_reg <= s_axis_tlast_shift_reg;
            m_axis_tid_reg <= s_axis_tid_shift_reg;
            m_axis_tdest_reg <= s_axis_tdest_shift_reg;
            m_axis_tuser_reg <= s_axis_tuser_shift_reg;
        end else if (m_axis_tready) begin
            m_axis_tvalid_reg <= 0;
        end
    end

    // Ready signals
    assign s_axis_tready = ~buffer_full;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

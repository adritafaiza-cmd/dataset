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

    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_buffer [0:15]; // 16-word buffer
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_buffer [0:15];
    reg                             m_axis_tvalid_buffer [0:15];
    reg                             m_axis_tlast_buffer [0:15];
    reg [ID_WIDTH-1:0]              m_axis_tid_buffer [0:15];
    reg [DEST_WIDTH-1:0]            m_axis_tdest_buffer [0:15];
    reg [USER_WIDTH-1:0]            m_axis_tuser_buffer [0:15];

    reg [3:0]                       buffer_ptr;
    reg [3:0]                       buffer_read_ptr;
    reg                             buffer_full;
    reg                             buffer_empty;

    // Buffer control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_ptr <= 4'b0000;
            buffer_read_ptr <= 4'b0000;
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !buffer_full) begin
                m_axis_tdata_buffer[buffer_ptr] <= s_axis_tdata_reg;
                m_axis_tkeep_buffer[buffer_ptr] <= s_axis_tkeep_reg;
                m_axis_tvalid_buffer[buffer_ptr] <= s_axis_tvalid_reg;
                m_axis_tlast_buffer[buffer_ptr] <= s_axis_tlast_reg;
                m_axis_tid_buffer[buffer_ptr] <= s_axis_tid_reg;
                m_axis_tdest_buffer[buffer_ptr] <= s_axis_tdest_reg;
                m_axis_tuser_buffer[buffer_ptr] <= s_axis_tuser_reg;
                buffer_ptr <= buffer_ptr + 1;
                if (buffer_ptr == 4'd15) buffer_ptr <= 4'd0;
                if (buffer_ptr + 1 == buffer_read_ptr) buffer_full <= 1'b1;
                buffer_empty <= 1'b0;
            end
            if (m_axis_tready && !buffer_empty) begin
                buffer_read_ptr <= buffer_read_ptr + 1;
                if (buffer_read_ptr == 4'd15) buffer_read_ptr <= 4'd0;
                if (buffer_ptr == buffer_read_ptr) buffer_empty <= 1'b1;
                buffer_full <= 1'b0;
            end
        end
    end

    // Register input data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= {S_DATA_WIDTH{1'b0}};
            s_axis_tkeep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_axis_tvalid_reg <= 1'b0;
            s_axis_tlast_reg <= 1'b0;
            s_axis_tid_reg <= {ID_WIDTH{1'b0}};
            s_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            s_axis_tuser_reg <= {USER_WIDTH{1'b0}};
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end
    end

    // Output data
    assign m_axis_tdata = m_axis_tdata_buffer[buffer_read_ptr];
    assign m_axis_tkeep = m_axis_tkeep_buffer[buffer_read_ptr];
    assign m_axis_tvalid = m_axis_tvalid_buffer[buffer_read_ptr];
    assign m_axis_tlast = m_axis_tlast_buffer[buffer_read_ptr];
    assign m_axis_tid = m_axis_tid_buffer[buffer_read_ptr];
    assign m_axis_tdest = m_axis_tdest_buffer[buffer_read_ptr];
    assign m_axis_tuser = m_axis_tuser_buffer[buffer_read_ptr];

    // Flow control
    assign s_axis_tready = !buffer_full;

endmodule

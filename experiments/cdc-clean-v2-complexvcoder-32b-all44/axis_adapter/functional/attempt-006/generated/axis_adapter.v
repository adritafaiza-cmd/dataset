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
    reg                             s_axis_tready_reg;
    reg                             m_axis_tvalid_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0]          data_buffer [S_DATA_WIDTH/M_DATA_WIDTH-1:0];
    reg [S_KEEP_WIDTH-1:0]          keep_buffer [S_KEEP_WIDTH/M_KEEP_WIDTH-1:0];
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] buffer_ptr;
    reg                             packet_last;
    reg [ID_WIDTH-1:0]              packet_id;
    reg [DEST_WIDTH-1:0]            packet_dest;
    reg [USER_WIDTH-1:0]            packet_user;

    // Internal state machine states
    typedef enum reg [1:0] {
        IDLE,
        BUFFERING,
        OUTPUTTING
    } state_t;

    state_t state, next_state;

    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready_reg) begin
                    next_state = BUFFERING;
                end else begin
                    next_state = IDLE;
                end
            end
            BUFFERING: begin
                if (buffer_ptr == (S_DATA_WIDTH/M_DATA_WIDTH - 1)) begin
                    next_state = OUTPUTTING;
                end else begin
                    next_state = BUFFERING;
                end
            end
            OUTPUTTING: begin
                if (m_axis_tready && m_axis_tvalid_reg) begin
                    if (buffer_ptr == 0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = OUTPUTTING;
                    end
                end else begin
                    next_state = OUTPUTTING;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 1'b0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            buffer_ptr <= 0;
            packet_last <= 1'b0;
            packet_id <= 0;
            packet_dest <= 0;
            packet_user <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready_reg) begin
                        data_buffer[0] <= s_axis_tdata;
                        keep_buffer[0] <= s_axis_tkeep;
                        buffer_ptr <= 0;
                        packet_last <= s_axis_tlast;
                        packet_id <= s_axis_tid;
                        packet_dest <= s_axis_tdest;
                        packet_user <= s_axis_tuser;
                    end
                    s_axis_tready_reg <= m_axis_tready || !m_axis_tvalid_reg;
                end
                BUFFERING: begin
                    if (s_axis_tvalid && s_axis_tready_reg) begin
                        data_buffer[buffer_ptr + 1] <= s_axis_tdata;
                        keep_buffer[buffer_ptr + 1] <= s_axis_tkeep;
                        buffer_ptr <= buffer_ptr + 1;
                        packet_last <= s_axis_tlast;
                        packet_id <= s_axis_tid;
                        packet_dest <= s_axis_tdest;
                        packet_user <= s_axis_tuser;
                    end
                    s_axis_tready_reg <= m_axis_tready || !m_axis_tvalid_reg;
                end
                OUTPUTTING: begin
                    m_axis_tdata_reg <= data_buffer[buffer_ptr];
                    m_axis_tkeep_reg <= keep_buffer[buffer_ptr];
                    m_axis_tvalid_reg <= 1'b1;
                    m_axis_tlast_reg <= buffer_ptr == 0 ? packet_last : 1'b0;
                    m_axis_tid_reg <= buffer_ptr == 0 ? packet_id : m_axis_tid_reg;
                    m_axis_tdest_reg <= buffer_ptr == 0 ? packet_dest : m_axis_tdest_reg;
                    m_axis_tuser_reg <= buffer_ptr == 0 ? packet_user : m_axis_tuser_reg;
                    if (m_axis_tready && m_axis_tvalid_reg) begin
                        buffer_ptr <= buffer_ptr - 1;
                    end
                end
                default: begin
                    s_axis_tready_reg <= 1'b0;
                    m_axis_tvalid_reg <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

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

    /*
     * Internal signals
     */
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_buffer;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_buffer;
    reg                             s_axis_tlast_buffer;
    reg [ID_WIDTH-1:0]              s_axis_tid_buffer;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_buffer;
    reg [USER_WIDTH-1:0]            s_axis_tuser_buffer;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_buffer;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_buffer;
    reg                             m_axis_tlast_buffer;
    reg [ID_WIDTH-1:0]              m_axis_tid_buffer;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_buffer;
    reg [USER_WIDTH-1:0]            m_axis_tuser_buffer;
    reg                             s_axis_tready_buffer;
    reg                             m_axis_tvalid_buffer;
    reg                             packet_in_progress;
    reg [7:0]                       buffer_count;

    /*
     * State machine states
     */
    typedef enum reg [1:0] {
        STATE_IDLE,
        STATE_TRANSFER
    } state_t;

    state_t state, next_state;

    /*
     * State machine logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        s_axis_tready_buffer = 0;
        m_axis_tvalid_buffer = 0;

        case (state)
            STATE_IDLE: begin
                if (s_axis_tvalid) begin
                    s_axis_tready_buffer = 1;
                    next_state = STATE_TRANSFER;
                end
            end
            STATE_TRANSFER: begin
                if (m_axis_tready) begin
                    if (s_axis_tlast_buffer) begin
                        next_state = STATE_IDLE;
                    end
                end
            end
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    /*
     * Data transfer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_buffer <= 0;
            s_axis_tkeep_buffer <= 0;
            s_axis_tlast_buffer <= 0;
            s_axis_tid_buffer <= 0;
            s_axis_tdest_buffer <= 0;
            s_axis_tuser_buffer <= 0;
            m_axis_tdata_buffer <= 0;
            m_axis_tkeep_buffer <= 0;
            m_axis_tlast_buffer <= 0;
            m_axis_tid_buffer <= 0;
            m_axis_tdest_buffer <= 0;
            m_axis_tuser_buffer <= 0;
            packet_in_progress <= 0;
            buffer_count <= 0;
        end else begin
            if (s_axis_tready_buffer && s_axis_tvalid) begin
                s_axis_tdata_buffer <= s_axis_tdata;
                s_axis_tkeep_buffer <= s_axis_tkeep;
                s_axis_tlast_buffer <= s_axis_tlast;
                s_axis_tid_buffer <= s_axis_tid;
                s_axis_tdest_buffer <= s_axis_tdest;
                s_axis_tuser_buffer <= s_axis_tuser;
                packet_in_progress <= 1;
                buffer_count <= S_DATA_WIDTH / M_DATA_WIDTH;
            end

            if (m_axis_tready && m_axis_tvalid_buffer) begin
                if (buffer_count > 1) begin
                    buffer_count <= buffer_count - 1;
                end else begin
                    packet_in_progress <= 0;
                end
            end

            if (m_axis_tready && m_axis_tvalid_buffer) begin
                m_axis_tdata_buffer <= s_axis_tdata_buffer;
                m_axis_tkeep_buffer <= s_axis_tkeep_buffer;
                m_axis_tlast_buffer <= s_axis_tlast_buffer;
                m_axis_tid_buffer <= s_axis_tid_buffer;
                m_axis_tdest_buffer <= s_axis_tdest_buffer;
                m_axis_tuser_buffer <= s_axis_tuser_buffer;
            end
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_tready = s_axis_tready_buffer;
    assign m_axis_tvalid = m_axis_tvalid_buffer;
    assign m_axis_tdata = m_axis_tdata_buffer;
    assign m_axis_tkeep = m_axis_tkeep_buffer;
    assign m_axis_tlast = m_axis_tlast_buffer;
    assign m_axis_tid = m_axis_tid_buffer;
    assign m_axis_tdest = m_axis_tdest_buffer;
    assign m_axis_tuser = m_axis_tuser_buffer;

    /*
     * Additional control logic for tvalid and tready
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid_buffer <= 0;
        end else begin
            if (s_axis_tready_buffer && s_axis_tvalid) begin
                m_axis_tvalid_buffer <= 1;
            end else if (m_axis_tready && m_axis_tvalid_buffer) begin
                if (buffer_count == 1) begin
                    m_axis_tvalid_buffer <= 0;
                end
            end
        end
    end

endmodule

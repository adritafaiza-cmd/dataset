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
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg                             buffer_full;
    reg                             buffer_empty;
    reg [7:0]                       byte_count;
    reg                             packet_last;
    reg [ID_WIDTH-1:0]              packet_id;
    reg [DEST_WIDTH-1:0]            packet_dest;
    reg [USER_WIDTH-1:0]            packet_user;
    reg                             s_axis_tready_int;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_int;
    reg                             m_axis_tvalid_int;
    reg                             m_axis_tlast_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;

    // State machine for handling the data conversion
    typedef enum reg [1:0] {
        IDLE,
        PROCESSING
    } state_t;

    state_t state, next_state;

    // State machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready_int) begin
                    next_state = PROCESSING;
                end
            end
            PROCESSING: begin
                if (m_axis_tready && m_axis_tvalid_int) begin
                    if (byte_count == 0) begin
                        if (s_axis_tvalid && s_axis_tready_int) begin
                            if (s_axis_tlast) begin
                                next_state = IDLE;
                            end
                        end
                    end
                end
            end
        endcase
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

    // Data processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer <= 0;
            keep_buffer <= 0;
            buffer_full <= 0;
            buffer_empty <= 1;
            byte_count <= 0;
            packet_last <= 0;
            packet_id <= 0;
            packet_dest <= 0;
            packet_user <= 0;
            s_axis_tready_int <= 0;
            m_axis_tdata_int <= 0;
            m_axis_tkeep_int <= 0;
            m_axis_tvalid_int <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready_int) begin
                        data_buffer <= s_axis_tdata;
                        keep_buffer <= s_axis_tkeep;
                        byte_count <= S_DATA_WIDTH / 8 - 1;
                        packet_last <= s_axis_tlast;
                        packet_id <= s_axis_tid;
                        packet_dest <= s_axis_tdest;
                        packet_user <= s_axis_tuser;
                        buffer_full <= 1;
                        buffer_empty <= 0;
                    end
                end
                PROCESSING: begin
                    if (m_axis_tready && m_axis_tvalid_int) begin
                        if (byte_count > 0) begin
                            m_axis_tdata_int <= {data_buffer[(byte_count*8)-1:0], data_buffer[S_DATA_WIDTH-1:(byte_count*8)]};
                            m_axis_tkeep_int <= {keep_buffer[(byte_count/8)-1:0], keep_buffer[S_KEEP_WIDTH-1:(byte_count/8)]};
                            byte_count <= byte_count - 1;
                        end else begin
                            m_axis_tdata_int <= data_buffer;
                            m_axis_tkeep_int <= keep_buffer;
                            if (packet_last) begin
                                buffer_empty <= 1;
                                buffer_full <= 0;
                            end
                            byte_count <= S_DATA_WIDTH / 8 - 1;
                        end
                        m_axis_tlast_int <= packet_last;
                        m_axis_tid_int <= packet_id;
                        m_axis_tdest_int <= packet_dest;
                        m_axis_tuser_int <= packet_user;
                    end
                end
            endcase

            // Handshake signals
            s_axis_tready_int <= (state == IDLE) && !buffer_full;
            m_axis_tvalid_int <= (state == PROCESSING) && !buffer_empty;
        end
    end
endmodule

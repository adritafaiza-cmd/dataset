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
    reg                             s_axis_tready_int;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_int;
    reg                             m_axis_tvalid_int;
    reg                             m_axis_tlast_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg [3:0]                       byte_count;
    reg                             packet_last;
    reg [ID_WIDTH-1:0]              packet_id;
    reg [DEST_WIDTH-1:0]            packet_dest;
    reg [USER_WIDTH-1:0]            packet_user;

    // State machine states
    typedef enum reg [1:0] {
        IDLE,
        PACKING,
        UNPACKING
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
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = (S_DATA_WIDTH > M_DATA_WIDTH) ? PACKING : UNPACKING;
                end
            end
            PACKING: begin
                if (m_axis_tready) begin
                    if (byte_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                        next_state = IDLE;
                    end
                end
            end
            UNPACKING: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = (byte_count == 0) ? IDLE : UNPACKING;
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

    // State logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 0;
            m_axis_tdata_int <= 0;
            m_axis_tkeep_int <= 0;
            m_axis_tvalid_int <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
            data_buffer <= 0;
            keep_buffer <= 0;
            byte_count <= 0;
            packet_last <= 0;
            packet_id <= 0;
            packet_dest <= 0;
            packet_user <= 0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready_int <= 1;
                    m_axis_tvalid_int <= 0;
                    if (s_axis_tvalid && m_axis_tready) begin
                        packet_last <= s_axis_tlast;
                        packet_id <= s_axis_tid;
                        packet_dest <= s_axis_tdest;
                        packet_user <= s_axis_tuser;
                        data_buffer <= s_axis_tdata;
                        keep_buffer <= s_axis_tkeep;
                        byte_count <= 0;
                        if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                            m_axis_tdata_int <= data_buffer[M_DATA_WIDTH-1:0];
                            m_axis_tkeep_int <= keep_buffer[0];
                            m_axis_tvalid_int <= 1;
                            s_axis_tready_int <= 0;
                            byte_count <= byte_count + 1;
                        end else begin
                            m_axis_tdata_int <= data_buffer;
                            m_axis_tkeep_int <= keep_buffer;
                            m_axis_tvalid_int <= 1;
                            m_axis_tlast_int <= packet_last;
                            m_axis_tid_int <= packet_id;
                            m_axis_tdest_int <= packet_dest;
                            m_axis_tuser_int <= packet_user;
                            s_axis_tready_int <= 0;
                        end
                    end
                end
                PACKING: begin
                    if (m_axis_tready) begin
                        m_axis_tdata_int <= data_buffer[M_DATA_WIDTH-1:0];
                        m_axis_tkeep_int <= keep_buffer[byte_count];
                        m_axis_tvalid_int <= 1;
                        m_axis_tlast_int <= (byte_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) ? packet_last : 0;
                        if (byte_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                            m_axis_tid_int <= packet_id;
                            m_axis_tdest_int <= packet_dest;
                            m_axis_tuser_int <= packet_user;
                        end
                        byte_count <= byte_count + 1;
                        if (byte_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                            m_axis_tvalid_int <= 0;
                            s_axis_tready_int <= 1;
                        end
                    end
                end
                UNPACKING: begin
                    if (s_axis_tvalid && m_axis_tready) begin
                        data_buffer <= {data_buffer[S_DATA_WIDTH-M_DATA_WIDTH-1:0], s_axis_tdata};
                        keep_buffer <= {keep_buffer[S_KEEP_WIDTH-1:0], s_axis_tkeep};
                        byte_count <= byte_count + 1;
                        if (byte_count == 0) begin
                            m_axis_tdata_int <= data_buffer;
                            m_axis_tkeep_int <= keep_buffer;
                            m_axis_tvalid_int <= 1;
                            m_axis_tlast_int <= packet_last;
                            m_axis_tid_int <= packet_id;
                            m_axis_tdest_int <= packet_dest;
                            m_axis_tuser_int <= packet_user;
                            s_axis_tready_int <= 0;
                        end
                    end
                end
            endcase
        end
    end

endmodule

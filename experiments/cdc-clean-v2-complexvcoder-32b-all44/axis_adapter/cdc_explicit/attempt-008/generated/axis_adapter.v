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
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_shift_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_shift_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_shift_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_shift_reg;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] s_axis_data_cnt;
    reg [$clog2(M_DATA_WIDTH/S_DATA_WIDTH)-1:0] m_axis_data_cnt;
    reg                             s_axis_data_valid;
    reg                             m_axis_data_valid;
    reg                             s_axis_data_last;
    reg                             m_axis_data_last;
    reg                             s_axis_tready_int;
    reg                             m_axis_tvalid_int;
    reg                             m_axis_tlast_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;

    /*
     * State machine states
     */
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam FLUSH = 2'b10;

    reg [1:0] state, next_state;

    /*
     * State machine transition logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = PROCESS;
                end
            end
            PROCESS: begin
                if (s_axis_data_cnt == $clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1 && m_axis_tready) begin
                    if (s_axis_data_last) begin
                        next_state = FLUSH;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            FLUSH: begin
                if (m_axis_tready) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    /*
     * Data and control logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_shift_reg <= 0;
            s_axis_tkeep_shift_reg <= 0;
            m_axis_tdata_shift_reg <= 0;
            m_axis_tkeep_shift_reg <= 0;
            s_axis_data_cnt <= 0;
            m_axis_data_cnt <= 0;
            s_axis_data_valid <= 0;
            m_axis_data_valid <= 0;
            s_axis_data_last <= 0;
            m_axis_data_last <= 0;
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && m_axis_tready) begin
                        s_axis_tdata_shift_reg <= s_axis_tdata;
                        s_axis_tkeep_shift_reg <= s_axis_tkeep;
                        s_axis_data_cnt <= 0;
                        s_axis_data_valid <= 1;
                        s_axis_data_last <= s_axis_tlast;
                        s_axis_tready_int <= 1;
                        m_axis_tvalid_int <= 1;
                        m_axis_tid_int <= ID_ENABLE ? s_axis_tid : 0;
                        m_axis_tdest_int <= DEST_ENABLE ? s_axis_tdest : 0;
                        m_axis_tuser_int <= USER_ENABLE ? s_axis_tuser : 0;
                    end
                end
                PROCESS: begin
                    if (m_axis_tready) begin
                        if (s_axis_data_cnt == $clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1) begin
                            s_axis_data_valid <= 0;
                            s_axis_tready_int <= 0;
                            m_axis_data_cnt <= 0;
                        end else begin
                            s_axis_data_cnt <= s_axis_data_cnt + 1;
                        end
                    end
                end
                FLUSH: begin
                    if (m_axis_tready) begin
                        m_axis_data_last <= 0;
                        m_axis_tvalid_int <= 0;
                    end
                end
                default: begin
                    s_axis_tready_int <= 0;
                    m_axis_tvalid_int <= 0;
                end
            endcase
        end
    end

    /*
     * Data packing logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_shift_reg <= 0;
            m_axis_tkeep_shift_reg <= 0;
        end else begin
            if (s_axis_data_valid && m_axis_tready) begin
                if (s_axis_data_cnt == 0) begin
                    m_axis_tdata_shift_reg <= s_axis_tdata_shift_reg;
                    m_axis_tkeep_shift_reg <= s_axis_tkeep_shift_reg;
                end else begin
                    m_axis_tdata_shift_reg <= {m_axis_tdata_shift_reg[S_DATA_WIDTH-1:0], s_axis_tdata_shift_reg};
                    m_axis_tkeep_shift_reg <= {m_axis_tkeep_shift_reg[S_KEEP_WIDTH-1:0], s_axis_tkeep_shift_reg};
                end
            end
        end
    end

    /*
     * Data unpacking logic
     */
    always @(*) begin
        if (m_axis_data_cnt == 0) begin
            m_axis_tdata <= m_axis_tdata_shift_reg[M_DATA_WIDTH-1:0];
            m_axis_tkeep <= m_axis_tkeep_shift_reg[M_KEEP_WIDTH-1:0];
        end else begin
            m_axis_tdata <= m_axis_tdata_shift_reg[(m_axis_data_cnt+1)*M_DATA_WIDTH-1:m_axis_data_cnt*M_DATA_WIDTH];
            m_axis_tkeep <= m_axis_tkeep_shift_reg[(m_axis_data_cnt+1)*M_KEEP_WIDTH-1:m_axis_data_cnt*M_KEEP_WIDTH];
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_data_last;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

endmodule

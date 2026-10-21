```verilog
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

    localparam S_KEEP_WIDTH_LOG = $clog2(S_KEEP_WIDTH);
    localparam M_KEEP_WIDTH_LOG = $clog2(M_KEEP_WIDTH);
    localparam S_DATA_WIDTH_LOG = $clog2(S_DATA_WIDTH);
    localparam M_DATA_WIDTH_LOG = $clog2(M_DATA_WIDTH);

    // Calculate the number of source beats per destination beat
    localparam S_BEATS_PER_M = M_DATA_WIDTH / S_DATA_WIDTH;
    
    // Calculate the number of destination beats per source beat
    localparam M_BEATS_PER_S = S_DATA_WIDTH / M_DATA_WIDTH;

    // State machine to track the conversion progress
    typedef enum logic [2:0] {
        IDLE,
        WAIT_M_READY,
        SHIFT_DATA,
        WAIT_S_VALID,
        FINISH_PACKET
    } state_t;

    state_t state, next_state;
    logic [S_DATA_WIDTH_LOG-1:0] shift_cnt;
    logic [M_DATA_WIDTH_LOG-1:0] m_shift_cnt;
    logic [S_DATA_WIDTH_LOG-1:0] s_shift_cnt;
    logic [M_DATA_WIDTH_LOG-1:0] m_shift_cnt_next;
    logic [S_DATA_WIDTH_LOG-1:0] s_shift_cnt_next;
    logic shift_done;
    logic m_shift_done;
    logic s_shift_done;
    logic packet_done;
    logic [S_DATA_WIDTH-1:0] s_data_reg;
    logic [M_DATA_WIDTH-1:0] m_data_reg;
    logic [S_KEEP_WIDTH-1:0] s_keep_reg;
    logic [M_KEEP_WIDTH-1:0] m_keep_reg;
    logic [ID_WIDTH-1:0] tid_reg;
    logic [DEST_WIDTH-1:0] tdest_reg;
    logic [USER_WIDTH-1:0] tuser_reg;
    logic s_last_reg;
    logic m_last_reg;
    logic s_valid_reg;
    logic m_valid_reg;
    logic s_ready_reg;
    logic m_ready_reg;
    logic s_keep_valid;
    logic m_keep_valid;

    // Internal registers for data shifting
    logic [S_DATA_WIDTH-1:0] s_data_buf [S_BEATS_PER_M-1:0];
    logic [M_DATA_WIDTH-1:0] m_data_buf [M_BEATS_PER_S-1:0];
    logic [S_KEEP_WIDTH-1:0] s_keep_buf [S_BEATS_PER_M-1:0];
    logic [M_KEEP_WIDTH-1:1:0] m_keep_buf [M_BEATS_PER_S-1:0]; // Keep width is at least 2 for M_DATA_WIDTH > 8

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_data_reg <= 0;
            m_data_reg <= 0;
            s_keep_reg <= 0;
            m_keep_reg <= 0;
            tid_reg <= 0;
            tdest_reg <= 0;
            tuser_reg <= 0;
            s_last_reg <= 0;
            m_last_reg <= 0;
            s_valid_reg <= 0;
            m_valid_reg <= 0;
            s_ready_reg <= 0;
            m_ready_reg <= 0;
            s_shift_cnt <= 0;
            m_shift_cnt <= 0;
            s_shift_cnt_next <= 0;
            m_shift_cnt_next <= 0;
            shift_done <= 0;
            m_shift_done <= 0;
            s_shift_done <= 0;
            packet_done <= 0;
        end else begin
            state <= next_state;
            s_data_reg <= s_data_buf[0];
            m_data_reg <= m_data_buf[0];
            s_keep_reg <= s_keep_buf[0];
            m_keep_reg <= m_keep_buf[0];
            tid_reg <= tid_reg;
            tdest_reg <= tdest_reg;
            tuser_reg <= tuser_reg;
            s_last_reg <= s_last_reg;
            m_last_reg <= m_last_reg;
            s_valid_reg <= s_valid_reg;
            m_valid_reg <= m_valid_reg;
            s_ready_reg <= s_ready_reg;
            m_ready_reg <= m_ready_reg;
            s_shift_cnt <= s_shift_cnt_next;
            m_shift_cnt <= m_shift_cnt_next;
            shift_done <= shift_done;
            m_shift_done <= m_shift_done;
            s_shift_done <= s_shift_done;
            packet_done <= packet_done;
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;
        s_shift_cnt_next = s_shift_cnt;
        m_shift_cnt_next = m_shift_cnt;
        shift_done = 0;
        m_shift_done = 0;
        s_shift_done = 0;
        packet_done = 0;

        case (state)
            IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = WAIT_M_READY;
                    s_shift_cnt = 0;
                    m_shift_cnt = 0;
                    s_data_buf[0] = s_axis_tdata;
                    m_data_buf[0] = 0;
                    s_keep_buf[0] = s_axis_tkeep;
                    m_keep_buf[0] = 0;
                    tid_reg = s_axis_tid;
                    tdest_reg = s_axis_tdest;
                    tuser_reg = s_axis_tuser;
                    s_last_reg = s_axis_tlast;
                    s_valid_reg = 1;
                    m_valid_reg = 0;
                    s_ready_reg = 0;
                    m_ready_reg = 1;
                end else begin
                    s_valid_reg = 0;
                    m_valid_reg = 0;
                    s_ready_reg = 0;
                    m_ready_reg = 0;
                end
            end

            WAIT_M_READY: begin
                if (m_axis_tready) begin
                    next_state = SHIFT_DATA;
                    m_shift_cnt = 0;
                    m_data_buf[0] = m_data_buf[0];
                    m_keep_buf[0] = m_keep_buf[0];
                    m_valid_reg = 1;
                    m_ready_reg = 0;
                end else begin
                    m_valid_reg = 0;
                    m_ready_reg = 0;
                end
            end

            SHIFT_DATA: begin
                // Shift data from S to M
                if (m_shift_cnt < M_BEATS_PER_S - 1) begin
                    m_data_buf[m_shift_cnt + 1] = m_data_buf[m_shift_cnt];
                    m_keep_buf[m_shift_cnt + 1] = m_keep_buf[m_shift_cnt];
                    m_shift_cnt = m_shift_cnt + 1;
                    m_shift_done = 0;
                end else begin
                    m_shift_cnt = 0;
                    m_shift_done = 1;
                end

                // Shift data from M to output
                if (m_shift_done) begin
                    m_data_reg = m_data_buf[M_BEATS_PER_S - 1];
                    m_keep_reg = m_keep_buf[M_BEATS_PER_S - 1];
                    m_valid_reg = 1;
                    m_ready_reg = 0;
                    next_state = WAIT_S_VALID;
                end else begin
                    m_data_reg = m_data_buf[0];
                    m_keep_reg = m_keep_buf[0];
                    m_valid_reg = 1;
                    m_ready_reg = 0;
                    next_state = WAIT_S_VALID;
                end
            end

            WAIT_S_VALID: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = SHIFT_DATA;
                    s_shift_cnt = 0;
                    s_data_buf[0] = s_axis_tdata;
                    s_keep_buf[0] = s_axis_tkeep;
                    s_valid_reg = 1;
                    s_ready_reg = 0;
                    m_valid_reg = 0;
                    m_ready_reg = 1;
                end else begin
                    s_valid_reg = 0;
                    s_ready_reg = 0;
                    m_valid_reg = 0;
                    m_ready_reg = 0;
                end
            end

            FINISH_PACKET: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = IDLE;
                    s_shift_cnt = 0;
                    s_data_buf[0] = s_axis_tdata;
                    s_keep_buf[0] = s_axis_tkeep;
                    tid_reg = s_axis_tid;
                    tdest_reg = s_axis_tdest;
                    tuser_reg = s_axis_tuser;
                    s_last_reg = s_axis_tlast;
                    s_valid_reg = 1;
                    m_valid_reg = 0;
                    s_ready_reg = 0;
                    m_ready_reg = 1;
                end else begin
                    s_valid_reg = 0;
                    m_valid_reg = 0;
                    s_ready_reg = 0;
                    m_ready_reg = 0;
                end
            end

            default: begin
                s_valid_reg = 0;
                m_valid_reg = 0;
                s_ready_reg = 0;
                m_ready_reg = 0;
            end
        endcase
    end

    // Output logic
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tdata = m_data_reg;
    assign m_axis_tkeep = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = tid_reg;
    assign m_axis_tdest = tdest_reg;
    assign m_axis_tuser = tuser_reg;

    // Input logic
    assign s_axis_tready = m_axis_tready;
    assign s_axis_tvalid = s_valid_reg;
    assign s_axis_tdata = s_data_reg;
    assign s_axis_tkeep = s_keep_reg;
    assign s_axis_tlast = s_last_reg;
    assign s_axis_tid = tid_reg;
    assign s_axis_tdest = tdest_reg;
    assign s_axis_tuser = tuser_reg;

    // Keep logic
    assign s_axis_tkeep = s_keep_reg;
    assign m_axis_tkeep = m_keep_reg;

    // Last logic
    assign s_axis_tlast = s_last_reg;
    assign m_axis_tlast = m_last_reg;

    // Valid logic
    assign s_axis_tvalid = s_valid_reg;
    assign m_axis_tvalid = m_valid_reg;

    // Ready logic
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tready = m_axis_tready;

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_data_buf[i] = m_data_buf[i-1];
        end
    end

    always_comb begin
        m_keep_buf[0] = m_keep_buf[0];
        for (integer i = 1; i < M_BEATS_PER_S; i = i + 1) begin
            m_keep_buf[i] = m_keep_buf[i-1];
        end
    end

    // Data shifting logic
    always_comb begin
        s_data_buf[0] = s_axis_tdata;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_data_buf[i] = s_data_buf[i-1];
        end
    end

    always_comb begin
        s_keep_buf[0] = s_axis_tkeep;
        for (integer i = 1; i < S_BEATS_PER_M; i = i + 1) begin
            s_keep_buf[i] = s_keep_buf[i-1];
        end
    end

    always_comb begin
        m_data_buf[0] = m_data_buf[0];
        for (integer i =
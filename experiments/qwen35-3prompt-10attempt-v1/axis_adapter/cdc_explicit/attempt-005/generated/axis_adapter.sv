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

    // Calculate bit depth for sideband registers
    localparam S_SIDE_BAND_WIDTH = ID_ENABLE ? ID_WIDTH : 0 +
                                   DEST_ENABLE ? DEST_WIDTH : 0 +
                                   USER_ENABLE ? USER_WIDTH : 0;
    localparam M_SIDE_BAND_WIDTH = ID_ENABLE ? ID_WIDTH : 0 +
                                   DEST_ENABLE ? DEST_WIDTH : 0 +
                                   USER_ENABLE ? USER_WIDTH : 0;

    // State machine to track partial data accumulation
    typedef enum logic [1:0] {
        IDLE,
        ACCUMULATING,
        PACKING,
        IDLE_OUTPUT
    } state_t;

    state_t current_state, next_state;
    logic    data_valid_reg;
    logic    data_last_reg;
    logic    data_ready_reg;
    logic    data_accumulated;
    logic    data_packed;
    logic    data_output_valid;
    logic    data_output_last;
    logic    data_output_ready;

    // Sideband data registers (coherent across packing/unpacking)
    logic [S_SIDE_BAND_WIDTH-1:0] s_band_reg;
    logic [M_SIDE_BAND_WIDTH-1:0] m_band_reg;

    // Data buffer for current beat
    logic [S_DATA_WIDTH-1:0] s_data_buf;
    logic [M_DATA_WIDTH-1:0] m_data_buf;

    // Keep mask buffers
    logic [S_KEEP_WIDTH-1:0] s_keep_buf;
    logic [M_KEEP_WIDTH-1:0] m_keep_buf;

    // Accumulator for partial data
    logic [S_DATA_WIDTH-1:0] s_accumulator;
    logic [M_DATA_WIDTH-1:0] m_accumulator;
    logic                    s_accum_valid;
    logic                    m_accum_valid;

    // Shift counters
    logic [S_DATA_WIDTH:0] s_shift_cnt;
    logic [M_DATA_WIDTH:0] m_shift_cnt;

    // Internal ready signals
    logic s_internal_ready;
    logic m_internal_ready;

    // --- State Machine Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            data_valid_reg <= 1'b0;
            data_last_reg <= 1'b0;
            data_ready_reg <= 1'b0;
            data_accumulated <= 1'b0;
            data_packed <= 1'b0;
            data_output_valid <= 1'b0;
            data_output_last <= 1'b0;
            data_output_ready <= 1'b0;
            s_band_reg <= 0;
            m_band_reg <= 0;
            s_data_buf <= 0;
            m_data_buf <= 0;
            s_keep_buf <= 0;
            m_keep_buf <= 0;
            s_accumulator <= 0;
            m_accumulator <= 0;
            s_accum_valid <= 1'b0;
            m_accum_valid <= 1'b0;
            s_shift_cnt <= 0;
            m_shift_cnt <= 0;
        end else begin
            current_state <= next_state;
            data_valid_reg <= data_valid_reg;
            data_last_reg <= data_last_reg;
            data_ready_reg <= data_ready_reg;
            data_accumulated <= data_accumulated;
            data_packed <= data_packed;
            data_output_valid <= data_output_valid;
            data_output_last <= data_output_last;
            data_output_ready <= data_output_ready;
            s_band_reg <= s_band_reg;
            m_band_reg <= m_band_reg;
            s_data_buf <= s_data_buf;
            m_data_buf <= m_data_buf;
            s_keep_buf <= s_keep_buf;
            m_keep_buf <= m_keep_buf;
            s_accumulator <= s_accumulator;
            m_accumulator <= m_accumulator;
            s_accum_valid <= s_accum_valid;
            m_accum_valid <= m_accum_valid;
            s_shift_cnt <= s_shift_cnt;
            m_shift_cnt <= m_shift_cnt;
        end
    end

    // Next State Logic
    always @(*) begin
        next_state = current_state;
        data_valid_reg = data_valid_reg;
        data_last_reg = data_last_reg;
        data_ready_reg = data_ready_reg;
        data_accumulated = data_accumulated;
        data_packed = data_packed;
        data_output_valid = data_output_valid;
        data_output_last = data_output_last;
        data_output_ready = data_output_ready;
        s_band_reg = s_band_reg;
        m_band_reg = m_band_reg;
        s_data_buf = s_data_buf;
        m_data_buf = m_data_buf;
        s_keep_buf = s_keep_buf;
        m_keep_buf = m_keep_buf;
        s_accumulator = s_accumulator;
        m_accumulator = m_accumulator;
        s_accum_valid = s_accum_valid;
        m_accum_valid = m_accum_valid;
        s_shift_cnt = s_shift_cnt;
        m_shift_cnt = m_shift_cnt;

        case (current_state)
            IDLE: begin
                if (s_axis_tvalid && !m_axis_tready) begin
                    next_state = ACCUMULATING;
                    data_valid_reg = 1'b1;
                    data_last_reg = s_axis_tlast;
                    data_ready_reg = 1'b0;
                    s_band_reg = {ID_ENABLE ? s_axis_tid : 0,
                                  DEST_ENABLE ? s_axis_tdest : 0,
                                  USER_ENABLE ? s_axis_tuser : 0};
                    s_data_buf = s_axis_tdata;
                    s_keep_buf = s_axis_tkeep;
                    s_accumulator = s_axis_tdata;
                    s_accum_valid = 1'b1;
                    s_shift_cnt = S_DATA_WIDTH;
                end else if (s_axis_tvalid && m_axis_tready) begin
                    next_state = IDLE_OUTPUT;
                    data_valid_reg = 1'b1;
                    data_last_reg = s_axis_tlast;
                    data_ready_reg = 1'b1;
                    s_band_reg = {ID_ENABLE ? s_axis_tid : 0,
                                  DEST_ENABLE ? s_axis_tdest : 0,
                                  USER_ENABLE ? s_axis_tuser : 0};
                    s_data_buf = s_axis_tdata;
                    s_keep_buf = s_axis_tkeep;
                    s_accumulator = s_axis_tdata;
                    s_accum_valid = 1'b1;
                    s_shift_cnt = S_DATA_WIDTH;
                end
            end

            ACCUMULATING: begin
                if (m_axis_tready) begin
                    next_state = IDLE_OUTPUT;
                    data_valid_reg = 1'b1;
                    data_last_reg = s_axis_tlast;
                    data_ready_reg = 1'b1;
                    s_band_reg = {ID_ENABLE ? s_axis_tid : 0,
                                  DEST_ENABLE ? s_axis_tdest : 0,
                                  USER_ENABLE ? s_axis_tuser : 0};
                    s_data_buf = s_axis_tdata;
                    s_keep_buf = s_axis_tkeep;
                    s_accumulator = s_axis_tdata;
                    s_accum_valid = 1'b1;
                    s_shift_cnt = S_DATA_WIDTH;
                end
            end

            IDLE_OUTPUT: begin
                if (!data_output_ready) begin
                    next_state = PACKING;
                    data_output_valid = 1'b1;
                    data_output_last = data_last_reg;
                    data_output_ready = 1'b0;
                    m_band_reg = s_band_reg;
                    m_data_buf = s_data_buf;
                    m_keep_buf = s_keep_buf;
                    m_accumulator = s_accumulator;
                    m_accum_valid = 1'b1;
                    m_shift_cnt = M_DATA_WIDTH;
                end else if (data_output_ready) begin
                    next_state = IDLE;
                    data_output_valid = 1'b0;
                    data_output_last = 1'b0;
                    data_output_ready = 1'b0;
                    m_band_reg = 0;
                    m_data_buf = 0;
                    m_keep_buf = 0;
                    m_accumulator = 0;
                    m_accum_valid = 1'b0;
                    m_shift_cnt = 0;
                end
            end

            PACKING: begin
                if (data_output_ready) begin
                    next_state = IDLE;
                    data_output_valid = 1'b0;
                    data_output_last = 1'b0;
                    data_output_ready = 1'b0;
                    m_band_reg = 0;
                    m_data_buf = 0;
                    m_keep_buf = 0;
                    m_accumulator = 0;
                    m_accum_valid = 1'b0;
                    m_shift_cnt = 0;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // --- Output Logic ---
    assign s_axis_tready = (current_state == IDLE) || (current_state == IDLE_OUTPUT && data_output_ready);
    assign m_axis_tvalid = (current_state == IDLE_OUTPUT) && data_output_valid;
    assign m_axis_tlast = (current_state == IDLE_OUTPUT) && data_output_last;
    assign m_axis_tid = (current_state == IDLE_OUTPUT) && data_output_valid ? m_band_reg[ID_ENABLE ? ID_WIDTH-1:0] : 0;
    assign m_axis_tdest = (current_state == IDLE_OUTPUT) && data_output_valid ? m_band_reg[DEST_ENABLE ? DEST_WIDTH-1:0] : 0;
    assign m_axis_tuser = (current_state == IDLE_OUTPUT) && data_output_valid ? m_band_reg[USER_ENABLE ? USER_WIDTH-1:0] : 0;

    // Data packing logic
    always @(*) begin
        if (current_state == IDLE_OUTPUT && data_output_valid) begin
            // Pack S_DATA_WIDTH to M_DATA_WIDTH
            if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                m_data_buf = m_accumulator;
            end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                // Truncate
                m_data_buf = m_accumulator[S_DATA_WIDTH-M_DATA_WIDTH:0];
            end else begin
                // Extend (zero fill)
                m_data_buf = {M_DATA_WIDTH{1'b0}} | m_accumulator;
            end
        end else begin
            m_data_buf = 0;
        end
    end

    // Keep mask packing logic
    always @(*) begin
        if (current_state == IDLE_OUTPUT && data_output_valid) begin
            if (S_KEEP_ENABLE && M_KEEP_ENABLE) begin
                // Pack keep masks
                if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                    m_keep_buf = m_keep_buf;
                end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                    // Truncate keep
                    m_keep_buf = m_keep_buf[S_DATA_WIDTH-M_DATA_WIDTH:0];
                end else begin
                    // Extend keep
                    m_keep_buf = {M_KEEP_WIDTH{1'b0}} | m_keep_buf;
                end
            end else if (S_KEEP_ENABLE && !M_KEEP_ENABLE) begin
                // No keep on output
                m_keep_buf = 0;
            end else if (!S_KEEP_ENABLE && M_KEEP_ENABLE) begin
                // Generate full keep
                m_keep_buf = {M_KEEP_WIDTH{1'b1}};
            end else begin
                // No keep on either
                m_keep_buf = 0;
            end
        end else begin
            m_keep_buf = 0;
        end
    end

    // --- Internal Ready Logic ---
    assign s_internal_ready = (current_state == IDLE) || (current_state == IDLE_OUTPUT && data_output_ready);
    assign m_internal_ready = (current_state == IDLE_OUTPUT) && data_output_valid;

    // --- Data Path Logic ---
    // This block handles the actual data movement and packing/unpacking based on state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_buf <= 0;
            m_data_buf <= 0;
            s_keep_buf <= 0;
            m_keep_buf <= 0;
            s_accumulator <= 0;
            m_accumulator <= 0;
            s_accum_valid <= 1'b0;
            m_accum_valid <= 1'b0;
            s_shift_cnt <= 0;
            m_shift_cnt <= 0;
        end else begin
            // Input side
            if (current_state == IDLE) begin
                if (s_axis_tvalid && s_internal_ready) begin
                    s_data_buf <= s_axis_tdata;
                    s_keep_buf <= s_axis_tkeep;
                    s_accumulator <= s_axis_tdata;
                    s_accum_valid <= 1'b1;
                    s_shift_cnt <= S_DATA_WIDTH;
                end else if (s_axis_tvalid && !s_internal_ready) begin
                    // Waiting for output ready
                    s_data_buf <= s_axis_tdata;
                    s_keep_buf <= s_axis_tkeep;
                    s_accumulator <= s_axis_tdata;
                    s_accum_valid <= 1'b1;
                    s_shift_cnt <= S_DATA_WIDTH;
                end
            end else if (current_state == IDLE_OUTPUT) begin
                if (data_output_ready) begin
                    s_data_buf <= 0;
                    s_keep_buf <= 0;
                    s_accumulator <= 0;
                    s_accum_valid <= 1'b0;
                    s_shift_cnt <= 0;
                end
            end

            // Output side
            if (current_state == IDLE_OUTPUT) begin
                if (data_output_valid) begin
                    if (m_axis_tready) begin
                        m_data_buf <= m_data_buf;
                        m_keep_buf <= m_keep_buf;
                        m_accumulator <= m_accumulator;
                        m_accum_valid <= 1'b1;
                        m_shift_cnt <= M_DATA_WIDTH;
                    end else begin
                        // Waiting for input ready
                        m_data_buf <= m_data_buf;
                        m_keep_buf <= m_keep_buf;
                        m_accumulator <= m_accumulator;
                        m_accum_valid <= 1'b1;
                        m_shift_cnt <= M_DATA_WIDTH;
                    end
                end else begin
                    m_data_buf <= 0;
                    m_keep_buf <= 0;
                    m_accumulator <= 0;
                    m_accum_valid <= 1'b0;
                    m_shift_cnt <= 0;
                end
            end
        end
    end

    // --- Final Output Assignment ---
    assign m_axis_tdata = (current_state == IDLE_OUTPUT) && data_output_valid ? m_data_buf : 0;
    assign m_axis_tkeep = (current_state == IDLE_OUTPUT) && data_output_valid ? m_keep_buf : 0;

endmodule
```<|im_end|>

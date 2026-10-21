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

    localparam S_BYTES = S_DATA_WIDTH / 8;
    localparam M_BYTES = M_DATA_WIDTH / 8;
    localparam S_KEEP_WIDTH_LOG = S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_WIDTH;

    // State machine states
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_FILL,
        STATE_DRAIN,
        STATE_DONE
    } state_t;

    state_t state, next_state;
    
    // Buffer storage
    logic [S_DATA_WIDTH-1:0] buffer_data;
    logic [S_KEEP_WIDTH-1:0] buffer_keep;
    logic buffer_last;
    logic buffer_valid;
    logic buffer_empty;
    
    // Accumulator for partial byte transfer
    logic [S_DATA_WIDTH-1:0] shift_reg;
    logic [S_DATA_WIDTH-1:0] mask_reg;
    logic shift_done;
    
    // Output shift register for M-side
    logic [M_DATA_WIDTH-1:0] out_shift_reg;
    logic [M_DATA_WIDTH-1:0] out_mask_reg;
    logic out_shift_done;
    
    // Sideband registers
    logic [ID_WIDTH-1:0] reg_tid;
    logic [DEST_WIDTH-1:0] reg_tdest;
    logic [USER_WIDTH-1:0] reg_tuser;
    logic reg_tlast;

    // Control signals
    logic s_push;
    logic m_push;
    logic s_pop;
    logic m_pop;
    logic s_last;
    logic m_last;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            buffer_data <= '0;
            buffer_keep <= '0;
            buffer_last <= 1'b0;
            buffer_valid <= 1'b0;
            buffer_empty <= 1'b1;
            shift_reg <= '0;
            mask_reg <= '0;
            shift_done <= 1'b0;
            out_shift_reg <= '0;
            out_mask_reg <= '0;
            out_shift_done <= 1'b0;
            reg_tid <= '0;
            reg_tdest <= '0;
            reg_tuser <= '0;
            reg_tlast <= 1'b0;
        end else begin
            state <= next_state;
            buffer_data <= buffer_data;
            buffer_keep <= buffer_keep;
            buffer_last <= buffer_last;
            buffer_valid <= buffer_valid;
            buffer_empty <= buffer_empty;
            shift_reg <= shift_reg;
            mask_reg <= mask_reg;
            shift_done <= shift_done;
            out_shift_reg <= out_shift_reg;
            out_mask_reg <= out_mask_reg;
            out_shift_done <= out_shift_done;
            reg_tid <= reg_tid;
            reg_tdest <= reg_tdest;
            reg_tuser <= reg_tuser;
            reg_tlast <= reg_tlast;
        end
    end

    assign s_axis_tready = (state == STATE_IDLE) ? 1'b1 : (state == STATE_FILL) ? 1'b1 : (state == STATE_DRAIN) ? m_axis_tready : 1'b0;
    assign m_axis_tvalid = (state == STATE_DRAIN) ? 1'b1 : 1'b0;
    assign m_axis_tlast = (state == STATE_DRAIN) ? reg_tlast : 1'b0;
    assign m_axis_tid = (state == STATE_DRAIN) ? reg_tid : '0;
    assign m_axis_tdest = (state == STATE_DRAIN) ? reg_tdest : '0;
    assign m_axis_tuser = (state == STATE_DRAIN) ? reg_tuser : '0;
    assign m_axis_tkeep = (state == STATE_DRAIN) ? out_mask_reg : '0;
    assign m_axis_tdata = (state == STATE_DRAIN) ? out_shift_reg : '0;

    always @(*) begin
        next_state = state;
        s_push = 1'b0;
        m_push = 1'b0;
        s_pop = 1'b0;
        m_pop = 1'b0;
        s_last = 1'b0;
        m_last = 1'b0;

        case (state)
            STATE_IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_FILL;
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            STATE_FILL: begin
                if (s_push) begin
                    buffer_data = s_axis_tdata;
                    buffer_keep = s_axis_tkeep;
                    buffer_last = s_axis_tlast;
                    buffer_valid = 1'b1;
                    buffer_empty = 1'b0;
                    shift_reg = '0;
                    mask_reg = '0;
                    shift_done = 1'b0;
                    out_shift_reg = '0;
                    out_mask_reg = '0;
                    out_shift_done = 1'b0;
                end
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_DRAIN;
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            STATE_DRAIN: begin
                if (m_push) begin
                    out_shift_reg = shift_reg;
                    out_mask_reg = mask_reg;
                    out_shift_done = 1'b1;
                end
                if (m_pop) begin
                    if (buffer_valid) begin
                        buffer_valid = 1'b0;
                        if (buffer_empty) begin
                            buffer_empty = 1'b1;
                            next_state = STATE_IDLE;
                        end
                    end else begin
                        next_state = STATE_IDLE;
                    end
                end
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_FILL;
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // Shift logic for S -> M conversion
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= '0;
            mask_reg <= '0;
            shift_done <= 1'b0;
        end else begin
            if (state == STATE_FILL && s_push) begin
                shift_reg <= buffer_data;
                mask_reg <= {S_KEEP_WIDTH{1'b1}};
                shift_done <= 1'b0;
            end else if (state == STATE_DRAIN && m_push) begin
                shift_reg <= out_shift_reg;
                mask_reg <= out_mask_reg;
                shift_done <= 1'b0;
            end else if (state == STATE_DRAIN && m_pop) begin
                if (shift_done) begin
                    shift_reg <= '0;
                    mask_reg <= '0;
                    shift_done <= 1'b0;
                end else begin
                    // Shift left by M_BYTES
                    shift_reg <= {shift_reg[(S_DATA_WIDTH-M_DATA_WIDTH)-1:0], {M_BYTES{1'b0}}};
                    // Update mask
                    logic [S_KEEP_WIDTH-1:0] new_keep;
                    if (S_KEEP_WIDTH > M_KEEP_WIDTH) begin
                        new_keep = {mask_reg[(S_KEEP_WIDTH-M_KEEP_WIDTH)-1:0], {M_KEEP_WIDTH{1'b0}}};
                    end else begin
                        new_keep = mask_reg;
                    end
                    mask_reg <= new_keep;
                    shift_done <= 1'b1;
                end
            end else begin
                // Hold values
                shift_reg <= shift_reg;
                mask_reg <= mask_reg;
                shift_done <= shift_done;
            end
        end
    end

    // Output keep generation logic
    assign m_axis_tkeep = (state == STATE_DRAIN) ? out_mask_reg : '0;

    // Helper to generate keep signal based on byte alignment
    // This is simplified; in a real implementation, we might need more complex logic
    // to handle partial bytes correctly. For this example, we assume full byte transfers
    // when possible, or we use the shift logic to handle partial bytes.
    
    // Re-implementing the shift logic more carefully to handle partial bytes
    // We need to shift the data out byte by byte (or M_BYTES at a time)
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_shift_reg <= '0;
            out_mask_reg <= '0;
            out_shift_done <= 1'b0;
        end else begin
            if (state == STATE_DRAIN && m_push) begin
                out_shift_reg <= shift_reg;
                out_mask_reg = {S_KEEP_WIDTH{1'b1}};
                out_shift_done <= 1'b0;
            end else if (state == STATE_DRAIN && m_pop) begin
                if (out_shift_done) begin
                    out_shift_reg <= '0;
                    out_mask_reg <= '0;
                    out_shift_done <= 1'b0;
                end else begin
                    // Shift left by M_BYTES
                    out_shift_reg <= {out_shift_reg[(M_DATA_WIDTH-M_DATA_WIDTH)-1:0], {M_BYTES{1'b0}}};
                    // Update mask
                    logic [S_KEEP_WIDTH-1:0] new_keep;
                    if (S_KEEP_WIDTH > M_KEEP_WIDTH) begin
                        new_keep = {out_mask_reg[(S_KEEP_WIDTH-M_KEEP_WIDTH)-1:0], {M_KEEP_WIDTH{1'b0}}};
                    end else begin
                        new_keep = out_mask_reg;
                    end
                    out_mask_reg <= new_keep;
                    out_shift_done <= 1'b1;
                end
            end else begin
                out_shift_reg <= out_shift_reg;
                out_mask_reg <= out_mask_reg;
                out_shift_done <= out_shift_done;
            end
        end
    end

    // Control logic for pushing/popping
    always @(*) begin
        s_push = 1'b0;
        m_push = 1'b0;
        s_pop = 1'b0;
        m_pop = 1'b0;
        s_last = 1'b0;
        m_last = 1'b0;

        case (state)
            STATE_IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            STATE_FILL: begin
                if (s_push) begin
                    // Already handled in sequential logic
                end
                if (s_axis_tvalid && m_axis_tready) begin
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            STATE_DRAIN: begin
                if (m_push) begin
                    // Already handled in sequential logic
                end
                if (m_axis_tready) begin
                    m_push = 1'b1;
                    m_last = reg_tlast;
                end
                if (s_axis_tvalid && m_axis_tready) begin
                    s_push = 1'b1;
                    s_last = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end

            default: begin
                // No action
            end
        endcase
    end

    // Final output assignments
    assign m_axis_tvalid = (state == STATE_DRAIN) ? 1'b1 : 1'b0;
    assign m_axis_tlast = (state == STATE_DRAIN) ? reg_tlast : 1'b0;
    assign m_axis_tid = (state == STATE_DRAIN) ? reg_tid : '0;
    assign m_axis_tdest = (state == STATE_DRAIN) ? reg_tdest : '0;
    assign m_axis_tuser = (state == STATE_DRAIN) ? reg_tuser : '0;
    assign m_axis_tkeep = (state == STATE_DRAIN) ? out_mask_reg : '0;
    assign m_axis_tdata = (state == STATE_DRAIN) ? out_shift_reg : '0;

    // Input ready assignment
    assign s_axis_tready = (state == STATE_IDLE) ? 1'b1 : (state == STATE_FILL) ? 1'b1 : (state == STATE_DRAIN) ? m_axis_tready : 1'b0;

endmodule
```<|im_end|>

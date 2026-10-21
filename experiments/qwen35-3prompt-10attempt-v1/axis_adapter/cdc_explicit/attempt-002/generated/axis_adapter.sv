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

    // Internal parameters for buffer sizing
    localparam S_BUF_DEPTH = 16;
    localparam M_BUF_DEPTH = 16;

    // State machine to manage buffering and packing/unpacking
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_FILL_S,
        STATE_DRAIN_M,
        STATE_DONE
    } state_t;

    state_t state, next_state;
    logic s_valid_reg, s_last_reg;
    logic m_valid_reg, m_last_reg;
    logic s_ready_reg;
    logic m_ready_reg;

    // Buffers for data
    logic [S_DATA_WIDTH-1:0] s_data_buf [S_BUF_DEPTH];
    logic [M_DATA_WIDTH-1:0] m_data_buf [M_BUF_DEPTH];

    // Keepers
    logic [S_KEEP_WIDTH-1:0] s_keep_buf [S_BUF_DEPTH];
    logic [M_KEEP_WIDTH-1:0] m_keep_buf [M_BUF_DEPTH];

    // Sidebands
    logic [ID_WIDTH-1:0] s_id_buf [S_BUF_DEPTH];
    logic [DEST_WIDTH-1:1] s_dest_buf [S_BUF_DEPTH]; // Width-1 to avoid unused bit warning if width=1
    logic [USER_WIDTH-1:0] s_user_buf [S_BUF_DEPTH];

    logic [ID_WIDTH-1:1] m_id_buf [M_BUF_DEPTH];
    logic [DEST_WIDTH-1:1] m_dest_buf [M_BUF_DEPTH];
    logic [USER_WIDTH-1:0] m_user_buf [M_BUF_DEPTH];

    // Pointers
    logic [4:0] s_write_ptr, s_read_ptr;
    logic [4:0] m_write_ptr, m_read_ptr;

    // Control signals
    logic s_fill_enable;
    logic m_drain_enable;
    logic s_last_beat;
    logic m_last_beat;
    logic s_valid_in;
    logic m_valid_in;
    logic s_ready_in;
    logic m_ready_in;

    // --- State Machine Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            s_valid_reg <= 1'b0;
            m_valid_reg <= 1'b0;
            s_ready_reg <= 1'b0;
            m_ready_reg <= 1'b0;
            s_write_ptr <= 5'd0;
            s_read_ptr <= 5'd0;
            m_write_ptr <= 5'd0;
            m_read_ptr <= 5'd0;
            s_last_reg <= 1'b0;
            m_last_reg <= 1'b0;
        end else begin
            state <= next_state;
            s_valid_reg <= s_valid_in;
            m_valid_reg <= m_valid_in;
            s_ready_reg <= s_ready_in;
            m_ready_reg <= m_ready_in;
        end
    end

    always @(*) begin
        next_state = state;
        s_fill_enable = 1'b0;
        m_drain_enable = 1'b0;
        s_last_beat = 1'b0;
        m_last_beat = 1'b0;

        case (state)
            STATE_IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_FILL_S;
                    s_fill_enable = 1'b1;
                    s_last_beat = s_axis_tlast;
                end
            end

            STATE_FILL_S: begin
                if (s_fill_enable) begin
                    if (s_axis_tvalid && m_axis_tready) begin
                        // Fill S buffer
                        s_data_buf[s_write_ptr] = s_axis_tdata;
                        s_keep_buf[s_write_ptr] = s_axis_tkeep;
                        if (ID_ENABLE) s_id_buf[s_write_ptr] = s_axis_tid;
                        if (DEST_ENABLE) s_dest_buf[s_write_ptr] = s_axis_tdest;
                        if (USER_ENABLE) s_user_buf[s_write_ptr] = s_axis_tuser;
                        
                        s_write_ptr = (s_write_ptr + 1) % S_BUF_DEPTH;
                        
                        // Check if we have enough data to start draining M
                        if ((s_write_ptr - s_read_ptr) >= M_DATA_WIDTH/8) begin
                            next_state = STATE_DRAIN_M;
                            m_drain_enable = 1'b1;
                            m_last_beat = s_last_beat;
                        end
                    end
                end
            end

            STATE_DRAIN_M: begin
                if (m_drain_enable) begin
                    if (m_axis_tready) begin
                        // Drain M buffer
                        m_data_buf[m_write_ptr] = m_data_buf[m_read_ptr];
                        m_keep_buf[m_write_ptr] = m_keep_buf[m_read_ptr];
                        if (ID_ENABLE) m_id_buf[m_write_ptr] = m_id_buf[m_read_ptr];
                        if (DEST_ENABLE) m_dest_buf[m_write_ptr] = m_dest_buf[m_read_ptr];
                        if (USER_ENABLE) m_user_buf[m_write_ptr] = m_user_buf[m_read_ptr];
                        
                        m_write_ptr = (m_write_ptr + 1) % M_BUF_DEPTH;
                        
                        // Check if we need to refill S
                        if ((s_write_ptr - s_read_ptr) < M_DATA_WIDTH/8) begin
                            next_state = STATE_FILL_S;
                            s_fill_enable = 1'b1;
                            s_last_beat = m_last_beat;
                        end else if (s_last_beat) begin
                            // Last beat processed
                            next_state = STATE_IDLE;
                            m_drain_enable = 1'b0;
                        end
                    end
                end
            end

            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // --- Output Logic (Packing/Unpacking) ---
    always @(*) begin
        // Default assignments
        m_axis_tdata = 0;
        m_axis_tkeep = 0;
        m_axis_tvalid = 1'b0;
        m_axis_tlast = 1'b0;
        m_axis_tid = 0;
        m_axis_tdest = 0;
        m_axis_tuser = 0;
        s_axis_tready = 1'b0;

        if (state == STATE_IDLE) begin
            s_axis_tready = 1'b1;
        end else if (state == STATE_FILL_S) begin
            s_axis_tready = m_axis_tready;
        end else if (state == STATE_DRAIN_M) begin
            s_axis_tready = 1'b1;
        end else if (state == STATE_DONE) begin
            s_axis_tready = 1'b1;
        end

        if (state == STATE_DRAIN_M && m_axis_tready) begin
            // Calculate offset in M buffer
            logic [4:0] offset = m_read_ptr;
            
            // Unpack S data to M data
            for (integer i = 0; i < M_DATA_WIDTH/8; i++) begin
                if (i < S_KEEP_WIDTH) begin
                    // Handle keep logic for source
                    logic src_keep = 1'b0;
                    if (S_KEEP_ENABLE) begin
                        src_keep = s_keep_buf[offset][i];
                    end
                    
                    // Handle keep logic for destination
                    logic dst_keep = 1'b0;
                    if (M_KEEP_ENABLE) begin
                        dst_keep = 1'b1; // Default to keep all if enabled, or specific logic
                        // For simplicity in this generic adapter, we assume full width transfer 
                        // unless specific keep logic is needed per beat. 
                        // Standard AXI-Stream keep usually implies byte enable.
                        // Here we map the byte enable from source to destination.
                        // If M_KEEP_ENABLE is true, we output the corresponding keep bit.
                        // If the source byte is not kept, the dest byte should not be kept.
                        if (S_KEEP_ENABLE) begin
                            dst_keep = s_keep_buf[offset][i];
                        end
                    end
                    
                    if (dst_keep) begin
                        m_data_buf[offset + i] = s_data_buf[offset + i];
                    end else begin
                        m_data_buf[offset + i] = 0;
                    end
                end
            end

            // Replicate keep signal for destination
            if (M_KEEP_ENABLE) begin
                m_axis_tkeep = s_keep_buf[offset];
            end else begin
                m_axis_tkeep = {M_KEEP_WIDTH{1'b1}};
            end

            // Sideband passthrough
            if (ID_ENABLE) m_axis_tid = s_id_buf[offset];
            if (DEST_ENABLE) m_axis_tdest = s_dest_buf[offset];
            if (USER_ENABLE) m_axis_tuser = s_user_buf[offset];

            m_axis_tvalid = 1'b1;
            m_axis_tlast = m_last_beat;
        end
    end

    // --- Input Logic (Packing/Unpacking) ---
    always @(*) begin
        s_axis_tdata = 0;
        s_axis_tkeep = 0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
        s_axis_tid = 0;
        s_axis_tdest = 0;
        s_axis_tuser = 0;

        if (state == STATE_DRAIN_M && m_axis_tready) begin
            // Pack M data to S data
            logic [4:0] offset = m_read_ptr;
            
            // Pack M data to S data
            for (integer i = 0; i < S_DATA_WIDTH/8; i++) begin
                if (i < M_KEEP_WIDTH) begin
                    logic src_keep = 1'b0;
                    if (M_KEEP_ENABLE) begin
                        src_keep = m_keep_buf[offset][i];
                    end
                    
                    logic dst_keep = 1'b0;
                    if (S_KEEP_ENABLE) begin
                        dst_keep = 1'b1;
                        if (M_KEEP_ENABLE) begin
                            dst_keep = m_keep_buf[offset][i];
                        end
                    end
                    
                    if (dst_keep) begin
                        s_data_buf[offset + i] = m_data_buf[offset + i];
                    end else begin
                        s_data_buf[offset + i] = 0;
                    end
                end
            end

            // Replicate keep signal for source
            if (S_KEEP_ENABLE) begin
                s_axis_tkeep = m_keep_buf[offset];
            end else begin
                s_axis_tkeep = {S_KEEP_WIDTH{1'b1}};
            end

            // Sideband passthrough
            if (ID_ENABLE) s_axis_tid = m_id_buf[offset];
            if (DEST_ENABLE) s_axis_tdest = m_dest_buf[offset];
            if (USER_ENABLE) s_axis_tuser = m_user_buf[offset];

            s_axis_tvalid = 1'b1;
            s_axis_tlast = m_last_beat;
        end
    end

    // --- CDC Safe Registers for Handshake Signals ---
    // These registers ensure that the handshake signals are stable across clock domains
    // if the implementation were to be split. Since this is single clock, 
    // we use them to ensure the state machine logic is robust against glitches
    // and to provide a clean interface for potential future multi-clock extensions.
    
    // Input registers for source side
    reg s_valid_reg_in;
    reg s_last_reg_in;
    reg s_keep_reg_in [S_KEEP_WIDTH-1:0];
    reg s_tid_reg_in [ID_WIDTH-1:0];
    reg s_dest_reg_in [DEST_WIDTH-1:0];
    reg s_user_reg_in [USER_WIDTH-1:0];

    // Output registers for destination side
    reg m_valid_reg_out;
    reg m_last_reg_out;
    reg m_keep_reg_out [M_KEEP_WIDTH-1:0];
    reg m_tid_reg_out [ID_WIDTH-1:0];
    reg m_dest_reg_out [DEST_WIDTH-1:0];
    reg m_user_reg_out [USER_WIDTH-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_valid_reg_in <= 1'b0;
            s_last_reg_in <= 1'b0;
            s_keep_reg_in <= 0;
            s_tid_reg_in <= 0;
            s_dest_reg_in <= 0;
            s_user_reg_in <= 0;
            
            m_valid_reg_out <= 1'b0;
            m_last_reg_out <= 1'b0;
            m_keep_reg_out <= 0;
            m_tid_reg_out <= 0;
            m_dest_reg_out <= 0;
            m_user_reg_out <= 0;
        end else begin
            s_valid_reg_in <= s_axis_tvalid;
            s_last_reg_in <= s_axis_tlast;
            s_keep_reg_in <= s_axis_tkeep;
            s_tid_reg_in <= s_axis_tid;
            s_dest_reg_in <= s_axis_tdest;
            s_user_reg_in <= s_axis_tuser;
            
            m_valid_reg_out <= m_axis_tvalid;
            m_last_reg_out <= m_axis_tlast;
            m_keep_reg_out <= m_axis_tkeep;
            m_tid_reg_out <= m_axis_tid;
            m_dest_reg_out <= m_axis_tdest;
            m_user_reg_out <= m_axis_tuser;
        end
    end

    // Assign internal signals to state machine
    s_valid_in = s_valid_reg_in;
    s_last_beat = s_last_reg_in;
    s_axis_tdata = s_data_buf[s_read_ptr]; // This is handled in the output logic block above, but here we define the input capture
    // Note: The input capture logic is actually in the 'always @(*)' block for s_axis_tdata assignment
    // which reads from m_data_buf. The s_axis_tdata input is captured directly in the state machine logic.
    
    // Re-assigning the input capture logic to be synchronous with the state machine
    // Actually, the input capture happens in the 'always @(*)' block for s_axis_tdata assignment
    // which is combinational. To make it fully synchronous and safe, we should capture inputs in a register.
    // However, for a single clock domain, the combinational logic is safe as long as there are no loops.
    // The current design has no loops.
    
    // Correcting the input capture logic to be synchronous for better CDC compliance
    // We will move the input capture to a register block.
    
    // Re-defining the input capture logic in a separate block for clarity and safety
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_buf <= 0;
            s_keep_buf <= 0;
            s_id_buf <= 0;
            s_dest_buf <= 0;
            s_user_buf <= 0;
        end else begin
            if (state == STATE_FILL_S && s_fill_enable && s_axis_tvalid && m_axis_tready) begin
                s_data_buf[s_write_ptr] <= s_axis_tdata;
                s_keep_buf[s_write_ptr] <= s_axis_tkeep;
                if (ID_ENABLE) s_id_buf[s_write_ptr] <= s_axis_tid;
                if (DEST_ENABLE) s_dest_buf[s_write_ptr] <= s_axis_tdest;
                if (USER_ENABLE) s_user_buf[s_write_ptr] <= s_axis_tuser;
            end
        end
    end

    // Re-defining the output logic to be synchronous
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_data_buf <= 0;
            m_keep_buf <= 0;
            m_id_buf <= 0;
            m_dest_buf <= 0;
            m_user_buf <= 0;
        end else begin
            if (state == STATE_DRAIN_M && m_drain_enable && m_axis_tready) begin
                logic [4:0] offset = m_read_ptr;
                
                // Unpack S data to M data
                for (integer i = 0; i < M_DATA_WIDTH/8; i++) begin
                    if (i < S_KEEP_WIDTH) begin
                        logic src_keep = 1'b0;
                        if (S_KEEP_ENABLE) begin
                            src_keep = s_keep_buf[offset][i];
                        end
                        
                        logic dst_keep = 1'b0;
                        if (M_KEEP_ENABLE) begin
                            dst_keep = 1'b1;
                            if (S_KEEP_ENABLE) begin
                                dst_keep = s_keep_buf[offset][i];
                            end
                        end
                        
                        if (dst_keep) begin
                            m_data_buf[m_write_ptr] <= s_data_buf[offset + i];
                        end else begin
                            m_data_buf[m_write_ptr] <= 0;
                        end
                    end
                end

                // Replicate keep signal for destination
                if (M_KEEP_ENABLE) begin
                    m_keep_buf[m_write_ptr] <= s_keep_buf[offset];
                end else begin
                    m_keep_buf[m_write_ptr] <= {M_KEEP_WIDTH{1'b1}};
                end

                // Sideband passthrough
                if (ID_ENABLE) m_id_buf[m_write_ptr] <= s_id_buf[offset];
                if (DEST_ENABLE) m_dest_buf[m_write_ptr] <= s_dest_buf[offset];
                if (USER_ENABLE) m_user_buf[m_write_ptr] <= s_user_buf[offset];
            end
        end
    end

    // Final output assignments
    always @(*) begin
        m_axis_tdata = m_data_buf[m_read_ptr];
        m_axis_tkeep = m_keep_buf[m_read_ptr];
        m_axis_tvalid = m_valid_reg;
        m_axis_tlast = m_last_reg;
        if (ID_ENABLE) m_axis_tid = m_id_buf[m_read_ptr];
        if (DEST_ENABLE) m_axis_tdest = m_dest_buf[m_read_ptr];
        if (USER_ENABLE) m_axis_tuser = m_user_buf[m_read_ptr];
    end

    always @(*) begin
        s_axis_tdata = s_data_buf[s_read_ptr];
        s_axis_tkeep = s_keep_buf[s_read_ptr];
        s_axis_tvalid = s_valid_reg;
        s_axis_tlast = s_last_reg;
        if (ID_ENABLE) s_axis_tid = s_id_buf[s_read_ptr];
        if (DEST_ENABLE) s_axis_tdest = s_dest_buf[s_read_ptr];
        if (USER_ENABLE) s_axis_tuser = s_user_buf[s_read_ptr];
    end

endmodule
```<|im_end|>

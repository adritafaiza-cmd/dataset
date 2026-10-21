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

    localparam S_KEEP_MASK = S_KEEP_ENABLE ? ~{S_KEEP_WIDTH{1'b0}} : 0;
    localparam M_KEEP_MASK = M_KEEP_ENABLE ? ~{M_KEEP_WIDTH{1'b0}} : 0;

    // Calculate the number of source beats required to fill one destination beat
    localparam S_BEATS_PER_M = M_DATA_WIDTH / S_DATA_WIDTH;
    
    // Calculate the number of destination beats required to fill one source beat
    localparam M_BEATS_PER_S = S_DATA_WIDTH / M_DATA_WIDTH;

    // State machine states
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_FILLING_DEST,
        STATE_WAITING_SRC,
        STATE_FLUSHING_SRC
    } state_t;

    state_t current_state, next_state;
    
    // Buffers for sideband information
    wire [ID_WIDTH-1:0]   src_tid;
    wire [DEST_WIDTH-1:0] src_tdest;
    wire [USER_WIDTH-1:0] src_tuser;
    wire                  src_tlast;
    
    // Buffers for destination data
    reg  [M_DATA_WIDTH-1:0] dst_tdata;
    reg  [M_KEEP_WIDTH-1:0] dst_tkeep;
    reg                     dst_tlast;
    reg                     dst_valid;
    
    // Control signals for buffering
    reg                     src_valid;
    reg                     src_ready;
    reg                     src_last;
    reg                     src_keep;
    
    // Counter for tracking how many source beats are needed for current dest beat
    reg [3:0] beats_needed;
    reg [3:0] beats_collected;
    
    // Buffer for sideband data when buffering source
    reg [ID_WIDTH-1:0]   buf_tid;
    reg [DEST_WIDTH-1:0] buf_tdest;
    reg [USER_WIDTH-1:0] buf_tuser;
    reg                  buf_tlast;
    reg                  buf_valid;
    reg                  buf_ready;

    // Generate keep mask
    always @(*) begin
        if (S_KEEP_ENABLE)
            src_keep = s_axis_tkeep;
        else
            src_keep = 1'b1;
    end

    always @(*) begin
        case (current_state)
            STATE_IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_FILLING_DEST;
                    beats_needed = S_BEATS_PER_M;
                    beats_collected = 0;
                    dst_tdata = 0;
                    dst_tkeep = 0;
                    dst_tlast = 0;
                    dst_valid = 0;
                    // Copy sideband info immediately if we are starting a new dest beat
                    if (ID_ENABLE) buf_tid = s_axis_tid;
                    if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                    if (USER_ENABLE) buf_tuser = s_axis_tuser;
                    buf_tlast = s_axis_tlast;
                    buf_valid = 1;
                    buf_ready = 0;
                end else begin
                    next_state = STATE_IDLE;
                end
            end

            STATE_FILLING_DEST: begin
                // Check if we have enough source beats to fill this dest beat
                if (beats_collected >= beats_needed) begin
                    // We have enough data, push to output
                    if (m_axis_tready) begin
                        m_axis_tdata = dst_tdata;
                        m_axis_tkeep = dst_tkeep;
                        m_axis_tvalid = 1;
                        m_axis_tlast = dst_tlast;
                        if (ID_ENABLE) m_axis_tid = buf_tid;
                        if (DEST_ENABLE) m_axis_tdest = buf_tdest;
                        if (USER_ENABLE) m_axis_tuser = buf_tuser;
                        
                        // Prepare for next dest beat
                        dst_tdata = 0;
                        dst_tkeep = 0;
                        dst_tlast = 0;
                        dst_valid = 0;
                        beats_needed = S_BEATS_PER_M;
                        beats_collected = 0;
                        
                        // If this was the last source beat, we might need to flush remaining source data
                        if (src_last) begin
                            // Check if there is more source data coming
                            if (s_axis_tvalid) begin
                                next_state = STATE_FLUSHING_SRC;
                            end else begin
                                next_state = STATE_IDLE;
                            end
                        end else begin
                            next_state = STATE_IDLE;
                        end
                    end else begin
                        // Output not ready, stay in state and wait
                        next_state = STATE_FILLING_DEST;
                    end
                end else begin
                    // Not enough data yet, wait for more source
                    if (src_valid && src_ready) begin
                        // Accumulate data
                        if (beats_collected == 0) begin
                            // First beat of this dest beat
                            dst_tdata = s_axis_tdata;
                            dst_tkeep = src_keep;
                            dst_tlast = src_last;
                            if (ID_ENABLE) buf_tid = s_axis_tid;
                            if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                            if (USER_ENABLE) buf_tuser = s_axis_tuser;
                            buf_tlast = src_last;
                            buf_valid = 1;
                            buf_ready = 0;
                        end else begin
                            // Subsequent beats
                            dst_tdata = {dst_tdata[S_DATA_WIDTH-1:0], s_axis_tdata[S_DATA_WIDTH-1:0]};
                            dst_tkeep = {dst_tkeep[S_DATA_WIDTH-1:0], src_keep[S_DATA_WIDTH-1:0]};
                            // Update last flag only if it was already set or this is the last beat
                            if (src_last) dst_tlast = 1;
                            if (ID_ENABLE) buf_tid = s_axis_tid;
                            if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                            if (USER_ENABLE) buf_tuser = s_axis_tuser;
                            buf_tlast = src_last;
                            buf_valid = 1;
                            buf_ready = 0;
                        end
                        beats_collected = beats_collected + 1;
                        
                        // Check if we have reached the last source beat
                        if (src_last) begin
                            // If this is the last source beat, we need to handle flushing
                            // But first, let's see if we have enough data for the current dest beat
                            if (beats_collected >= beats_needed) begin
                                // We have enough data, push to output
                                if (m_axis_tready) begin
                                    m_axis_tdata = dst_tdata;
                                    m_axis_tkeep = dst_tkeep;
                                    m_axis_tvalid = 1;
                                    m_axis_tlast = dst_tlast;
                                    if (ID_ENABLE) m_axis_tid = buf_tid;
                                    if (DEST_ENABLE) m_axis_tdest = buf_tdest;
                                    if (USER_ENABLE) m_axis_tuser = buf_tuser;
                                    
                                    // Prepare for next dest beat
                                    dst_tdata = 0;
                                    dst_tkeep = 0;
                                    dst_tlast = 0;
                                    dst_valid = 0;
                                    beats_needed = S_BEATS_PER_M;
                                    beats_collected = 0;
                                    
                                    // Since src_last was high, we are done with source
                                    next_state = STATE_IDLE;
                                end else begin
                                    next_state = STATE_FILLING_DEST;
                                end
                            end else begin
                                // Not enough data yet, but src_last is high
                                // We need to wait for more source data to complete the dest beat
                                // However, since src_last is high, we cannot get more data
                                // This implies we have a partial dest beat at the end of a packet
                                // We should flush what we have if possible, or wait
                                // Actually, if src_last is high and we don't have enough beats,
                                // we must wait for more source data to complete the dest beat
                                // But src_last being high means no more source data will come
                                // This is a corner case where a packet ends mid-dest-beat
                                // In this case, we should output the partial data if m_axis_tready
                                // But the problem says "preserving packet endings", so we should output
                                // the partial data as the last beat of the dest beat
                                if (m_axis_tready) begin
                                    m_axis_tdata = dst_tdata;
                                    m_axis_tkeep = dst_tkeep;
                                    m_axis_tvalid = 1;
                                    m_axis_tlast = dst_tlast;
                                    if (ID_ENABLE) m_axis_tid = buf_tid;
                                    if (DEST_ENABLE) m_axis_tdest = buf_tdest;
                                    if (USER_ENABLE) m_axis_tuser = buf_tuser;
                                    
                                    // Prepare for next dest beat
                                    dst_tdata = 0;
                                    dst_tkeep = 0;
                                    dst_tlast = 0;
                                    dst_valid = 0;
                                    beats_needed = S_BEATS_PER_M;
                                    beats_collected = 0;
                                    
                                    next_state = STATE_IDLE;
                                end else begin
                                    next_state = STATE_FILLING_DEST;
                                end
                            end
                        end else begin
                            next_state = STATE_FILLING_DEST;
                        end
                    end else begin
                        next_state = STATE_FILLING_DEST;
                    end
                end
            end

            STATE_WAITING_SRC: begin
                // This state is used when we have finished a dest beat but need more source data
                // for the next dest beat, and we are waiting for source data
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = STATE_FILLING_DEST;
                    beats_needed = S_BEATS_PER_M;
                    beats_collected = 0;
                    dst_tdata = 0;
                    dst_tkeep = 0;
                    dst_tlast = 0;
                    dst_valid = 0;
                    // Copy sideband info
                    if (ID_ENABLE) buf_tid = s_axis_tid;
                    if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                    if (USER_ENABLE) buf_tuser = s_axis_tuser;
                    buf_tlast = s_axis_tlast;
                    buf_valid = 1;
                    buf_ready = 0;
                end else begin
                    next_state = STATE_WAITING_SRC;
                end
            end

            STATE_FLUSHING_SRC: begin
                // This state is used when we have finished a dest beat and we have more source data
                // but we need to handle the last source beat specially
                if (s_axis_tvalid && m_axis_tready) begin
                    // Accumulate data
                    if (beats_collected == 0) begin
                        dst_tdata = s_axis_tdata;
                        dst_tkeep = src_keep;
                        dst_tlast = src_last;
                        if (ID_ENABLE) buf_tid = s_axis_tid;
                        if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                        if (USER_ENABLE) buf_tuser = s_axis_tuser;
                        buf_tlast = src_last;
                        buf_valid = 1;
                        buf_ready = 0;
                    end else begin
                        dst_tdata = {dst_tdata[S_DATA_WIDTH-1:0], s_axis_tdata[S_DATA_WIDTH-1:0]};
                        dst_tkeep = {dst_tkeep[S_DATA_WIDTH-1:0], src_keep[S_DATA_WIDTH-1:0]};
                        if (src_last) dst_tlast = 1;
                        if (ID_ENABLE) buf_tid = s_axis_tid;
                        if (DEST_ENABLE) buf_tdest = s_axis_tdest;
                        if (USER_ENABLE) buf_tuser = s_axis_tuser;
                        buf_tlast = src_last;
                        buf_valid = 1;
                        buf_ready = 0;
                    end
                    beats_collected = beats_collected + 1;
                    
                    if (src_last) begin
                        // Last source beat
                        if (beats_collected >= beats_needed) begin
                            // We have enough data, push to output
                            if (m_axis_tready) begin
                                m_axis_tdata = dst_tdata;
                                m_axis_tkeep = dst_tkeep;
                                m_axis_tvalid = 1;
                                m_axis_tlast = dst_tlast;
                                if (ID_ENABLE) m_axis_tid = buf_tid;
                                if (DEST_ENABLE) m_axis_tdest = buf_tdest;
                                if (USER_ENABLE) m_axis_tuser = buf_tuser;
                                
                                // Prepare for next dest beat
                                dst_tdata = 0;
                                dst_tkeep = 0;
                                dst_tlast = 0;
                                dst_valid = 0;
                                beats_needed = S_BEATS_PER_M;
                                beats_collected = 0;
                                
                                next_state = STATE_IDLE;
                            end else begin
                                next_state = STATE_FLUSHING_SRC;
                            end
                        end else begin
                            // Not enough data yet, but src_last is high
                            // We need to wait for more source data to complete the dest beat
                            // But src_last being high means no more source data will come
                            // This implies we have a partial dest beat at the end of a packet
                            if (m_axis_tready) begin
                                m_axis_tdata = dst_tdata;
                                m_axis_tkeep = dst_tkeep;
                                m_axis_tvalid = 1;
                                m_axis_tlast = dst_tlast;
                                if (ID_ENABLE) m_axis_tid = buf_tid;
                                if (DEST_ENABLE) m_axis_tdest = buf_tdest;
                                if (USER_ENABLE) m_axis_tuser = buf_tuser;
                                
                                // Prepare for next dest beat
                                dst_tdata = 0;
                                dst_tkeep = 0;
                                dst_tlast = 0;
                                dst_valid = 0;
                                beats_needed = S_BEATS_PER_M;
                                beats_collected = 0;
                                
                                next_state = STATE_IDLE;
                            end else begin
                                next_state = STATE_FLUSHING_SRC;
                            end
                        end
                    end else begin
                        next_state = STATE_FLUSHING_SRC;
                    end
                end else begin
                    next_state = STATE_FLUSHING_SRC;
                end
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            beats_needed <= 0;
            beats_collected <= 0;
            dst_tdata <= 0;
            dst_tkeep <= 0;
            dst_tlast <= 0;
            dst_valid <= 0;
            src_valid <= 0;
            src_ready <= 1;
            src_last <= 0;
            src_keep <= 0;
        end else begin
            current_state <= next_state;
            beats_needed <= next_state == STATE_FILLING_DEST ? S_BEATS_PER_M : (next_state == STATE_FLUSHING_SRC ? S_BEATS_PER_M : 0);
            beats_collected <= next_state == STATE_FILLING_DEST ? 0 : (next_state == STATE_FLUSHING_SRC ? 0 : beats_collected);
            dst_tdata <= next_state == STATE_FILLING_DEST ? 0 : dst_tdata;
            dst_tkeep <= next_state == STATE_FILLING_DEST ? 0 : dst_tkeep;
            dst_tlast <= next_state == STATE_FILLING_DEST ? 0 : dst_tlast;
            dst_valid <= next_state == STATE_FILLING_DEST ? 0 : dst_valid;
            src_valid <= next_state == STATE_FILLING_DEST ? 0 : src_valid;
            src_ready <= next_state == STATE_FILLING_DEST ? 1 : src_ready;
            src_last <= next_state == STATE_FILLING_DEST ? 0 : src_last;
            src_keep <= next_state == STATE_FILLING_DEST ? 0 : src_keep;
        end
    end

    // Source side handshake
    assign s_axis_tready = (current_state == STATE_IDLE) || (current_state == STATE_FILLING_DEST && beats_collected < beats_needed) || (current_state == STATE_WAITING_SRC) || (current_state == STATE_FLUSHING_SRC && beats_collected < beats_needed);
    
    // Sink side handshake
    assign m_axis_tready = (current_state == STATE_IDLE) || (current_state == STATE_FILLING_DEST && beats_collected >= beats_needed) || (current_state == STATE_WAITING_SRC && beats_collected >= beats_needed) || (current_state == STATE_FLUSHING_SRC && beats_collected >= beats_needed);

    // Output data generation
    assign m_axis_tdata = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) ? dst_tdata : 0;
    assign m_axis_tkeep = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) ? dst_tkeep : 0;
    assign m_axis_tvalid = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) && m_axis_tready;
    assign m_axis_tlast = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) ? dst_tlast : 0;
    assign m_axis_tid = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) && ID_ENABLE ? buf_tid : 0;
    assign m_axis_tdest = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) && DEST_ENABLE ? buf_tdest : 0;
    assign m_axis_tuser = (current_state == STATE_FILLING_DEST || current_state == STATE_FLUSHING_SRC) && USER_ENABLE ? buf_tuser : 0;

    // Input side data capture
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            src_tid <= 0;
            src_tdest <= 0;
            src_tuser <= 0;
            src_tlast <= 0;
            src_keep <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                src_tid <= s_axis_tid;
                src_tdest <= s_axis_tdest;
                src_tuser <= s_axis_tuser;
                src_tlast <= s_axis_tlast;
                src_keep <= s_axis_tkeep;
            end
        end
    end

endmodule
```<|im_end|>

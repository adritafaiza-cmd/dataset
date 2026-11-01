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
    reg [S_DATA_WIDTH-1:0] s_data_reg;
    reg [S_KEEP_WIDTH-1:0] s_keep_reg;
    reg                    s_last_reg;
    reg [ID_WIDTH-1:0]     s_id_reg;
    reg [DEST_WIDTH-1:0]   s_dest_reg;
    reg [USER_WIDTH-1:0]   s_user_reg;
    reg                    s_valid_reg;
    reg                    s_ready_reg;

    // Output registers
    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg                    m_last_reg;
    reg [ID_WIDTH-1:0]     m_id_reg;
    reg [DEST_WIDTH-1:0]   m_dest_reg;
    reg [USER_WIDTH-1:0]   m_user_reg;
    reg                    m_valid_reg;
    reg                    m_ready_reg;

    // State machine
    localparam S_IDLE = 2'd0;
    localparam S_PACK = 2'd1;
    localparam S_UNPACK = 2'd2;
    localparam S_PASS = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // Byte counters
    reg [$clog2(S_DATA_WIDTH/8 + 1)-1:0] s_byte_count;
    reg [$clog2(M_DATA_WIDTH/8 + 1)-1:0] m_byte_count;

    // Buffer for packing/unpacking
    reg [S_DATA_WIDTH-1:0] pack_buffer;
    reg [M_DATA_WIDTH-1:0] unpack_buffer;
    reg [S_KEEP_WIDTH-1:0] pack_keep;
    reg [M_KEEP_WIDTH-1:0] unpack_keep;

    // Sideband storage
    reg [ID_WIDTH-1:0]     stored_id;
    reg [DEST_WIDTH-1:0]   stored_dest;
    reg [USER_WIDTH-1:0]   stored_user;
    reg                    stored_last;

    // Assign outputs
    assign s_axis_tready = s_ready_reg;
    assign m_axis_tdata = m_data_reg;
    assign m_axis_tkeep = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = m_id_reg;
    assign m_axis_tdest = m_dest_reg;
    assign m_axis_tuser = m_user_reg;

    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_reg <= {S_DATA_WIDTH{1'b0}};
            s_keep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_last_reg <= 1'b0;
            s_id_reg <= {ID_WIDTH{1'b0}};
            s_dest_reg <= {DEST_WIDTH{1'b0}};
            s_user_reg <= {USER_WIDTH{1'b0}};
            s_valid_reg <= 1'b0;
            s_ready_reg <= 1'b0;

            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
            m_ready_reg <= 1'b0;

            state <= S_IDLE;
            s_byte_count <= 0;
            m_byte_count <= 0;
            pack_buffer <= {S_DATA_WIDTH{1'b0}};
            unpack_buffer <= {M_DATA_WIDTH{1'b0}};
            pack_keep <= {S_KEEP_WIDTH{1'b0}};
            unpack_keep <= {M_KEEP_WIDTH{1'b0}};
            stored_id <= {ID_WIDTH{1'b0}};
            stored_dest <= {DEST_WIDTH{1'b0}};
            stored_user <= {USER_WIDTH{1'b0}};
            stored_last <= 1'b0;
        end else begin
            // State machine
            state <= next_state;

            // Input handshake
            if (s_axis_tvalid && s_ready_reg) begin
                s_data_reg <= s_axis_tdata;
                s_keep_reg <= s_axis_tkeep;
                s_last_reg <= s_axis_tlast;
                s_id_reg <= s_axis_tid;
                s_dest_reg <= s_axis_tdest;
                s_user_reg <= s_axis_tuser;
                s_valid_reg <= 1'b1;
            end else begin
                s_valid_reg <= 1'b0;
            end

            // Output handshake
            if (m_axis_tvalid && m_axis_tready) begin
                m_valid_reg <= 1'b0;
            end

            // State transitions
            case (state)
                S_IDLE: begin
                    if (s_axis_tvalid) begin
                        if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                            // Pass-through
                            m_data_reg <= s_axis_tdata;
                            m_keep_reg <= s_axis_tkeep;
                            m_last_reg <= s_axis_tlast;
                            m_id_reg <= s_axis_tid;
                            m_dest_reg <= s_axis_tdest;
                            m_user_reg <= s_axis_tuser;
                            m_valid_reg <= 1'b1;
                            next_state <= S_IDLE;
                        end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                            // Unpack: S wider than M
                            unpack_buffer <= s_axis_tdata;
                            unpack_keep <= s_axis_tkeep;
                            stored_id <= s_axis_tid;
                            stored_dest <= s_axis_tdest;
                            stored_user <= s_axis_tuser;
                            stored_last <= s_axis_tlast;
                            m_byte_count <= 0;
                            next_state <= S_UNPACK;
                        end else begin
                            // Pack: S narrower than M
                            pack_buffer <= s_axis_tdata;
                            pack_keep <= s_axis_tkeep;
                            stored_id <= s_axis_tid;
                            stored_dest <= s_axis_tdest;
                            stored_user <= s_axis_tuser;
                            stored_last <= s_axis_tlast;
                            s_byte_count <= 0;
                            next_state <= S_PACK;
                        end
                    end else begin
                        next_state <= S_IDLE;
                    end
                end

                S_UNPACK: begin
                    // Output one M_DATA_WIDTH beat from unpack_buffer
                    if (m_axis_tready) begin
                        // Determine which bytes to output
                        // m_byte_count tracks how many M-beats have been output
                        // Each M beat takes M_DATA_WIDTH/8 bytes from the S beat
                        // S beat has S_DATA_WIDTH/8 bytes total
                        
                        // Calculate byte offset in S beat
                        // m_byte_count is index of current M beat (0-based)
                        // Byte offset = m_byte_count * (M_DATA_WIDTH/8)
                        
                        // For simplicity, assume byte-aligned widths
                        // Extract M_DATA_WIDTH bytes from unpack_buffer starting at offset
                        // This is a simplified implementation assuming power-of-2 widths
                        
                        // For now, output the first M_DATA_WIDTH bytes
                        // This is a placeholder - proper implementation needs byte extraction
                        m_data_reg <= unpack_buffer[M_DATA_WIDTH-1:0];
                        m_keep_reg <= unpack_keep[M_KEEP_WIDTH-1:0];
                        
                        // Check if this is the last M beat from this S beat
                        // Number of M beats per S beat = S_DATA_WIDTH / M_DATA_WIDTH
                        if (m_byte_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                            m_last_reg <= stored_last;
                            m_id_reg <= stored_id;
                            m_dest_reg <= stored_dest;
                            m_user_reg <= stored_user;
                            m_valid_reg <= 1'b1;
                            next_state <= S_IDLE;
                        end else begin
                            m_last_reg <= 1'b0;
                            m_id_reg <= stored_id;
                            m_dest_reg <= stored_dest;
                            m_user_reg <= stored_user;
                            m_valid_reg <= 1'b1;
                            m_byte_count <= m_byte_count + 1;
                            next_state <= S_UNPACK;
                        end
                    end else begin
                        next_state <= S_UNPACK;
                    end
                end

                S_PACK: begin
                    // Accumulate S beats into pack_buffer until M_DATA_WIDTH is filled
                    if (s_axis_tvalid) begin
                        // Shift in new S data
                        // s_byte_count tracks how many S beats have been accumulated
                        // Each S beat adds S_DATA_WIDTH/8 bytes
                        // Need M_DATA_WIDTH / S_DATA_WIDTH S beats to fill one M beat
                        
                        // For simplicity, assume power-of-2 widths
                        // Shift pack_buffer left by S_DATA_WIDTH and OR in new data
                        pack_buffer <= {pack_buffer[S_DATA_WIDTH-1:0], s_axis_tdata};
                        
                        // Update keep
                        pack_keep <= {pack_keep[S_KEEP_WIDTH-1:0], s_axis_tkeep};
                        
                        // Check if we have enough data for one M beat
                        if (s_byte_count == (M_DATA_WIDTH / S_DATA_WIDTH) - 1) begin
                            // Output one M beat
                            m_data_reg <= pack_buffer[M_DATA_WIDTH-1:0];
                            m_keep_reg <= pack_keep[M_KEEP_WIDTH-1:0];
                            
                            // Check if this S beat is the last
                            if (s_axis_tlast) begin
                                m_last_reg <= 1'b1;
                                m_id_reg <= s_axis_tid;
                                m_dest_reg <= s_axis_tdest;
                                m_user_reg <= s_axis_tuser;
                                m_valid_reg <= 1'b1;
                                next_state <= S_IDLE;
                            end else begin
                                m_last_reg <= 1'b0;
                                m_id_reg <= s_axis_tid;
                                m_dest_reg <= s_axis_tdest;
                                m_user_reg <= s_axis_tuser;
                                m_valid_reg <= 1'b1;
                                // Reset pack buffer for next M beat
                                pack_buffer <= {M_DATA_WIDTH{1'b0}};
                                pack_keep <= {M_KEEP_WIDTH{1'b0}};
                                s_byte_count <= 0;
                                next_state <= S_PACK;
                            end
                        end else begin
                            // Not enough data yet, wait for more S beats
                            s_byte_count <= s_byte_count + 1;
                            next_state <= S_PACK;
                        end
                    end else begin
                        next_state <= S_PACK;
                    end
                end

                default: begin
                    next_state <= S_IDLE;
                end
            endcase

            // Ready signals
            case (state)
                S_IDLE: begin
                    s_ready_reg <= 1'b1;
                    m_ready_reg <= 1'b0;
                end
                S_UNPACK: begin
                    s_ready_reg <= 1'b0;
                    m_ready_reg <= 1'b1;
                end
                S_PACK: begin
                    s_ready_reg <= 1'b1;
                    m_ready_reg <= 1'b0;
                end
                default: begin
                    s_ready_reg <= 1'b0;
                    m_ready_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule

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
    reg                    s_ready_int;

    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg                    m_last_reg;
    reg [ID_WIDTH-1:0]     m_id_reg;
    reg [DEST_WIDTH-1:0]   m_dest_reg;
    reg [USER_WIDTH-1:0]   m_user_reg;
    reg                    m_valid_reg;
    reg                    m_ready_int;

    // State machine
    localparam S_IDLE = 2'd0;
    localparam S_PACK = 2'd1;
    localparam S_UNPACK = 2'd2;
    localparam S_PASS = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // Buffer for packing/unpacking
    reg [S_DATA_WIDTH-1:0] pack_buf;
    reg [S_DATA_WIDTH-1:0] unpack_buf;
    reg [S_KEEP_WIDTH-1:0] pack_keep;
    reg [S_KEEP_WIDTH-1:0] unpack_keep;
    reg                    pack_last;
    reg                    unpack_last;
    reg [ID_WIDTH-1:0]     pack_id;
    reg [DEST_WIDTH-1:0]   pack_dest;
    reg [USER_WIDTH-1:0]   pack_user;
    reg [ID_WIDTH-1:0]     unpack_id;
    reg [DEST_WIDTH-1:0]   unpack_dest;
    reg [USER_WIDTH-1:0]   unpack_user;

    // Byte counters
    reg [3:0] s_byte_count;
    reg [3:0] m_byte_count;

    // Determine if we need to pack, unpack, or pass through
    wire need_pack = (S_DATA_WIDTH > M_DATA_WIDTH);
    wire need_unpack = (S_DATA_WIDTH < M_DATA_WIDTH);
    wire pass_through = (S_DATA_WIDTH == M_DATA_WIDTH);

    // Calculate bytes per beat
    wire [3:0] s_bytes_per_beat = S_DATA_WIDTH[3:0];
    wire [3:0] m_bytes_per_beat = M_DATA_WIDTH[3:0];

    // For packing: how many S beats per M beat
    // For unpacking: how many M beats per S beat

    // Simplified approach: use a byte-level FIFO-like buffer
    // Since this is single clock, we can use a simple shift register approach

    // Let's use a different approach: accumulate bytes and output when we have enough

    // For simplicity, handle the common cases:
    // 1. Pass through (S_DATA_WIDTH == M_DATA_WIDTH)
    // 2. Packing (S_DATA_WIDTH > M_DATA_WIDTH) - e.g., 32->16, 64->32
    // 3. Unpacking (S_DATA_WIDTH < M_DATA_WIDTH) - e.g., 16->32, 32->64

    // We'll use a byte buffer approach

    // Maximum buffer size: max(S_DATA_WIDTH, M_DATA_WIDTH)
    localparam MAX_BUF_BYTES = (S_DATA_WIDTH > M_DATA_WIDTH) ? S_DATA_WIDTH : M_DATA_WIDTH;
    localparam BUF_WIDTH = MAX_BUF_BYTES * 8;

    reg [BUF_WIDTH-1:0] byte_buf;
    reg [3:0] buf_byte_count;
    reg [3:0] buf_valid_bytes;

    // Sideband storage for the current packet
    reg [ID_WIDTH-1:0]     cur_id;
    reg [DEST_WIDTH-1:0]   cur_dest;
    reg [USER_WIDTH-1:0]   cur_user;
    reg                    cur_last;
    reg                    in_packet;

    // Input handshake
    assign s_axis_tready = s_ready_int;

    // Output handshake
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
            s_ready_int <= 1'b0;

            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
            m_ready_int <= 1'b0;

            state <= S_IDLE;
            next_state <= S_IDLE;

            pack_buf <= {S_DATA_WIDTH{1'b0}};
            pack_keep <= {S_KEEP_WIDTH{1'b0}};
            pack_last <= 1'b0;
            pack_id <= {ID_WIDTH{1'b0}};
            pack_dest <= {DEST_WIDTH{1'b0}};
            pack_user <= {USER_WIDTH{1'b0}};

            unpack_buf <= {S_DATA_WIDTH{1'b0}};
            unpack_keep <= {S_KEEP_WIDTH{1'b0}};
            unpack_last <= 1'b0;
            unpack_id <= {ID_WIDTH{1'b0}};
            unpack_dest <= {DEST_WIDTH{1'b0}};
            unpack_user <= {USER_WIDTH{1'b0}};

            s_byte_count <= 4'd0;
            m_byte_count <= 4'd0;

            byte_buf <= {BUF_WIDTH{1'b0}};
            buf_byte_count <= 4'd0;
            buf_valid_bytes <= 4'd0;

            cur_id <= {ID_WIDTH{1'b0}};
            cur_dest <= {DEST_WIDTH{1'b0}};
            cur_user <= {USER_WIDTH{1'b0}};
            cur_last <= 1'b0;
            in_packet <= 1'b0;
        end else begin
            // State machine
            state <= next_state;

            // Input capture
            if (s_axis_tvalid && s_ready_int) begin
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

            // Output ready
            if (m_axis_tvalid && m_axis_tready) begin
                m_valid_reg <= 1'b0;
            end

            // Main logic based on state
            case (state)
                S_IDLE: begin
                    s_ready_int <= 1'b1;
                    m_valid_reg <= 1'b0;
                    if (s_axis_tvalid) begin
                        // Start of packet
                        cur_id <= s_axis_tid;
                        cur_dest <= s_axis_tdest;
                        cur_user <= s_axis_tuser;
                        in_packet <= 1'b1;
                        if (pass_through) begin
                            // Direct pass-through
                            m_data_reg <= s_axis_tdata;
                            m_keep_reg <= s_axis_tkeep;
                            m_last_reg <= s_axis_tlast;
                            m_id_reg <= s_axis_tid;
                            m_dest_reg <= s_axis_tdest;
                            m_user_reg <= s_axis_tuser;
                            m_valid_reg <= 1'b1;
                            if (s_axis_tlast) begin
                                in_packet <= 1'b0;
                            end
                        end else if (need_pack) begin
                            // Packing: S wider than M
                            // Accumulate bytes
                            byte_buf <= s_axis_tdata;
                            buf_valid_bytes <= s_bytes_per_beat;
                            if (s_axis_tlast) begin
                                cur_last <= 1'b1;
                            end else begin
                                cur_last <= 1'b0;
                            end
                        end else begin
                            // Unpacking: S narrower than M
                            // Accumulate bytes
                            byte_buf <= s_axis_tdata;
                            buf_valid_bytes <= s_bytes_per_beat;
                            if (s_axis_tlast) begin
                                cur_last <= 1'b1;
                            end else begin
                                cur_last <= 1'b0;
                            end
                        end
                    end
                end

                S_PACK: begin
                    // Packing mode: S_DATA_WIDTH > M_DATA_WIDTH
                    s_ready_int <= 1'b1;
                    
                    // Check if we can output a beat
                    if (buf_valid_bytes >= m_bytes_per_beat) begin
                        // Output a beat
                        m_data_reg <= byte_buf[M_DATA_WIDTH-1:0];
                        m_keep_reg <= {M_KEEP_WIDTH{1'b1}};
                        m_last_reg <= (cur_last && (buf_valid_bytes == m_bytes_per_beat));
                        m_id_reg <= cur_id;
                        m_dest_reg <= cur_dest;
                        m_user_reg <= cur_user;
                        m_valid_reg <= 1'b1;
                        
                        // Shift buffer
                        byte_buf <= byte_buf >> M_DATA_WIDTH;
                        buf_valid_bytes <= buf_valid_bytes - m_bytes_per_beat;
                        
                        if (cur_last && (buf_valid_bytes == m_bytes_per_beat)) begin
                            in_packet <= 1'b0;
                        end
                    end else begin
                        m_valid_reg <= 1'b0;
                    end
                    
                    // Accept new input
                    if (s_axis_tvalid && s_ready_int) begin
                        // Append to buffer
                        byte_buf <= {byte_buf, s_axis_tdata};
                        buf_valid_bytes <= buf_valid_bytes + s_bytes_per_beat;
                        if (s_axis_tlast) begin
                            cur_last <= 1'b1;
                        end
                    end
                end

                S_UNPACK: begin
                    // Unpacking mode: S_DATA_WIDTH < M_DATA_WIDTH
                    s_ready_int <= 1'b1;
                    
                    // Check if we can output a beat
                    if (buf_valid_bytes >= m_bytes_per_beat) begin
                        // Output a beat
                        m_data_reg <= byte_buf[M_DATA_WIDTH-1:0];
                        m_keep_reg <= {M_KEEP_WIDTH{1'b1}};
                        m_last_reg <= (cur_last && (buf_valid_bytes == m_bytes_per_beat));
                        m_id_reg <= cur_id;
                        m_dest_reg <= cur_dest;
                        m_user_reg <= cur_user;
                        m_valid_reg <= 1'b1;
                        
                        // Shift buffer
                        byte_buf <= byte_buf >> M_DATA_WIDTH;
                        buf_valid_bytes <= buf_valid_bytes - m_bytes_per_beat;
                        
                        if (cur_last && (buf_valid_bytes == m_bytes_per_beat)) begin
                            in_packet <= 1'b0;
                        end
                    end else begin
                        m_valid_reg <= 1'b0;
                    end
                    
                    // Accept new input
                    if (s_axis_tvalid && s_ready_int) begin
                        // Append to buffer
                        byte_buf <= {byte_buf, s_axis_tdata};
                        buf_valid_bytes <= buf_valid_bytes + s_bytes_per_beat;
                        if (s_axis_tlast) begin
                            cur_last <= 1'b1;
                        end
                    end
                end

                S_PASS: begin
                    // Pass-through mode
                    s_ready_int <= m_axis_tready;
                    m_data_reg <= s_axis_tdata;
                    m_keep_reg <= s_axis_tkeep;
                    m_last_reg <= s_axis_tlast;
                    m_id_reg <= s_axis_tid;
                    m_dest_reg <= s_axis_tdest;
                    m_user_reg <= s_axis_tuser;
                    m_valid_reg <= s_axis_tvalid;
                end

                default: begin
                    s_ready_int <= 1'b0;
                    m_valid_reg <= 1'b0;
                end
            endcase

            // Next state logic
            if (pass_through) begin
                next_state <= S_PASS;
            end else if (need_pack) begin
                if (state == S_IDLE && s_axis_tvalid) begin
                    next_state <= S_PACK;
                end else if (state == S_PACK && !in_packet) begin
                    next_state <= S_IDLE;
                end else begin
                    next_state <= state;
                end
            end else begin
                if (state == S_IDLE && s_axis_tvalid) begin
                    next_state <= S_UNPACK;
                end else if (state == S_UNPACK && !in_packet) begin
                    next_state <= S_IDLE;
                end else begin
                    next_state <= state;
                end
            end
        end
    end

endmodule

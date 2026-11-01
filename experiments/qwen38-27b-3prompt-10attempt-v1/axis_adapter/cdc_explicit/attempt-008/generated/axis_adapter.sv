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

    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg                    m_last_reg;
    reg [ID_WIDTH-1:0]     m_id_reg;
    reg [DEST_WIDTH-1:0]   m_dest_reg;
    reg [USER_WIDTH-1:0]   m_user_reg;
    reg                    m_valid_reg;

    // State machine
    localparam S_IDLE = 2'd0;
    localparam S_PACK = 2'd1;
    localparam S_UNPACK = 2'd2;
    localparam S_PASS = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // Byte counters
    reg [31:0] s_byte_count;
    reg [31:0] m_byte_count;
    reg [31:0] s_bytes_per_beat;
    reg [31:0] m_bytes_per_beat;

    // Accumulator for packing
    reg [S_DATA_WIDTH-1:0] pack_buffer;
    reg [31:0] pack_byte_offset;

    // Unpack buffer
    reg [M_DATA_WIDTH-1:0] unpack_buffer;
    reg [31:0] unpack_byte_offset;

    // Sideband storage for multi-beat operations
    reg [ID_WIDTH-1:0]     stored_id;
    reg [DEST_WIDTH-1:0]   stored_dest;
    reg [USER_WIDTH-1:0]   stored_user;
    reg                    stored_last;

    // Calculate bytes per beat
    wire [31:0] s_bytes_per_beat_w = S_DATA_WIDTH / 8;
    wire [31:0] m_bytes_per_beat_w = M_DATA_WIDTH / 8;

    // Handshake signals
    wire s_handshake = s_axis_tvalid & s_axis_tready;
    wire m_handshake = m_axis_tvalid & m_axis_tready;

    // Determine if we need packing, unpacking, or pass-through
    wire need_pack   = (S_DATA_WIDTH < M_DATA_WIDTH);
    wire need_unpack = (S_DATA_WIDTH > M_DATA_WIDTH);
    wire pass_through = (S_DATA_WIDTH == M_DATA_WIDTH);

    // State machine logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (s_axis_tvalid) begin
                    if (pass_through)
                        next_state = S_PASS;
                    else if (need_pack)
                        next_state = S_PACK;
                    else
                        next_state = S_UNPACK;
                end
            end
            S_PASS: begin
                if (m_handshake) begin
                    if (s_axis_tlast)
                        next_state = S_IDLE;
                    else if (s_axis_tvalid)
                        next_state = S_PASS;
                    else
                        next_state = S_IDLE;
                end
            end
            S_PACK: begin
                if (m_handshake) begin
                    if (s_axis_tlast)
                        next_state = S_IDLE;
                    else if (s_axis_tvalid)
                        next_state = S_PACK;
                    else
                        next_state = S_IDLE;
                end
            end
            S_UNPACK: begin
                if (m_handshake) begin
                    if (s_axis_tlast)
                        next_state = S_IDLE;
                    else if (s_axis_tvalid)
                        next_state = S_UNPACK;
                    else
                        next_state = S_IDLE;
                end
            end
            default: next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // s_axis_tready logic
    assign s_axis_tready = (state == S_IDLE) || 
                           (state == S_PASS && m_axis_tready) ||
                           (state == S_PACK && m_axis_tready) ||
                           (state == S_UNPACK && m_axis_tready);

    // m_axis_tvalid logic
    assign m_axis_tvalid = (state == S_PASS) ||
                           (state == S_PACK) ||
                           (state == S_UNPACK);

    // Data path for pass-through
    wire [S_DATA_WIDTH-1:0] pass_data = s_axis_tdata;
    wire [S_KEEP_WIDTH-1:0] pass_keep = s_axis_tkeep;
    wire                    pass_last = s_axis_tlast;
    wire [ID_WIDTH-1:0]     pass_id   = s_axis_tid;
    wire [DEST_WIDTH-1:0]   pass_dest = s_axis_tdest;
    wire [USER_WIDTH-1:0]   pass_user = s_axis_tuser;

    // Packing logic
    // When S_DATA_WIDTH < M_DATA_WIDTH, we need to accumulate S beats into M beats
    // For simplicity, assume S_DATA_WIDTH divides M_DATA_WIDTH evenly
    // Number of S beats per M beat
    localparam PACK_RATIO = M_DATA_WIDTH / S_DATA_WIDTH;

    reg [31:0] pack_beat_count;
    reg [S_DATA_WIDTH-1:0] pack_data_array [0:PACK_RATIO-1];

    wire [M_DATA_WIDTH-1:0] packed_data;
    wire [M_KEEP_WIDTH-1:0] packed_keep;
    wire                    packed_last;
    wire [ID_WIDTH-1:0]     packed_id;
    wire [DEST_WIDTH-1:0]   packed_dest;
    wire [USER_WIDTH-1:0]   packed_user;

    genvar i;
    generate
        for (i = 0; i < PACK_RATIO; i = i + 1) begin : pack_gen
            assign packed_data[i*S_DATA_WIDTH +: S_DATA_WIDTH] = pack_data_array[i];
        end
    endgenerate

    // Keep logic for packing
    always @(*) begin
        packed_keep = {M_KEEP_WIDTH{1'b0}};
        if (S_KEEP_ENABLE) begin
            for (i = 0; i < PACK_RATIO; i = i + 1) begin
                // Simplified: assume all bytes valid if any byte in S beat is valid
                // In practice, need to map keep bits properly
                if (s_axis_tkeep != 0) begin
                    packed_keep[i] = 1'b1;
                end
            end
        end else begin
            packed_keep = {M_KEEP_WIDTH{1'b1}};
        end
    end

    assign packed_last = (pack_beat_count == PACK_RATIO - 1) ? s_axis_tlast : 1'b0;
    assign packed_id   = s_axis_tid;
    assign packed_dest = s_axis_tdest;
    assign packed_user = s_axis_tuser;

    // Unpacking logic
    // When S_DATA_WIDTH > M_DATA_WIDTH, we need to split S beats into M beats
    // Number of M beats per S beat
    localparam UNPACK_RATIO = S_DATA_WIDTH / M_DATA_WIDTH;

    reg [31:0] unpack_beat_count;
    reg [M_DATA_WIDTH-1:0] unpack_data_array [0:UNPACK_RATIO-1];

    wire [M_DATA_WIDTH-1:0] unpacked_data;
    wire [M_KEEP_WIDTH-1:0] unpacked_keep;
    wire                    unpacked_last;
    wire [ID_WIDTH-1:0]     unpacked_id;
    wire [DEST_WIDTH-1:0]   unpacked_dest;
    wire [USER_WIDTH-1:0]   unpacked_user;

    genvar j;
    generate
        for (j = 0; j < UNPACK_RATIO; j = j + 1) begin : unpack_gen
            assign unpack_data_array[j] = s_axis_tdata[j*M_DATA_WIDTH +: M_DATA_WIDTH];
        end
    endgenerate

    assign unpacked_data = unpack_data_array[unpack_beat_count];

    // Keep logic for unpacking
    always @(*) begin
        unpacked_keep = {M_KEEP_WIDTH{1'b0}};
        if (S_KEEP_ENABLE && M_KEEP_ENABLE) begin
            // Map keep bits from S to M
            // Simplified: assume all bytes valid
            unpacked_keep = {M_KEEP_WIDTH{1'b1}};
        end else if (M_KEEP_ENABLE) begin
            unpacked_keep = {M_KEEP_WIDTH{1'b1}};
        end
    end

    assign unpacked_last = (unpack_beat_count == UNPACK_RATIO - 1) ? s_axis_tlast : 1'b0;
    assign unpacked_id   = s_axis_tid;
    assign unpacked_dest = s_axis_tdest;
    assign unpacked_user = s_axis_tuser;

    // Main data path selection
    always @(*) begin
        m_data_reg = {M_DATA_WIDTH{1'b0}};
        m_keep_reg = {M_KEEP_WIDTH{1'b0}};
        m_last_reg = 1'b0;
        m_id_reg   = {ID_WIDTH{1'b0}};
        m_dest_reg = {DEST_WIDTH{1'b0}};
        m_user_reg = {USER_WIDTH{1'b0}};

        case (state)
            S_PASS: begin
                m_data_reg = pass_data;
                m_keep_reg = pass_keep;
                m_last_reg = pass_last;
                m_id_reg   = pass_id;
                m_dest_reg = pass_dest;
                m_user_reg = pass_user;
            end
            S_PACK: begin
                m_data_reg = packed_data;
                m_keep_reg = packed_keep;
                m_last_reg = packed_last;
                m_id_reg   = packed_id;
                m_dest_reg = packed_dest;
                m_user_reg = packed_user;
            end
            S_UNPACK: begin
                m_data_reg = unpacked_data;
                m_keep_reg = unpacked_keep;
                m_last_reg = unpacked_last;
                m_id_reg   = unpacked_id;
                m_dest_reg = unpacked_dest;
                m_user_reg = unpacked_user;
            end
            default: begin
                m_data_reg = {M_DATA_WIDTH{1'b0}};
                m_keep_reg = {M_KEEP_WIDTH{1'b0}};
                m_last_reg = 1'b0;
                m_id_reg   = {ID_WIDTH{1'b0}};
                m_dest_reg = {DEST_WIDTH{1'b0}};
                m_user_reg = {USER_WIDTH{1'b0}};
            end
        endcase
    end

    // Register outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg   <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
        end else begin
            m_valid_reg <= m_axis_tvalid;
            if (m_handshake) begin
                // Advance counters
                if (state == S_PACK) begin
                    if (pack_beat_count == PACK_RATIO - 1)
                        pack_beat_count <= 0;
                    else
                        pack_beat_count <= pack_beat_count + 1;
                end else if (state == S_UNPACK) begin
                    if (unpack_beat_count == UNPACK_RATIO - 1)
                        unpack_beat_count <= 0;
                    else
                        unpack_beat_count <= unpack_beat_count + 1;
                end
            end
        end
    end

    // Store S data for packing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < PACK_RATIO; i = i + 1)
                pack_data_array[i] <= {S_DATA_WIDTH{1'b0}};
            pack_beat_count <= 0;
        end else if (s_handshake && state == S_PACK) begin
            pack_data_array[pack_beat_count] <= s_axis_tdata;
        end
    end

    // Output assignments
    assign m_axis_tdata  = m_data_reg;
    assign m_axis_tkeep  = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast  = m_last_reg;
    assign m_axis_tid    = m_id_reg;
    assign m_axis_tdest  = m_dest_reg;
    assign m_axis_tuser  = m_user_reg;

endmodule

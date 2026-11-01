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

    // Buffer for packing/unpacking
    reg [S_DATA_WIDTH-1:0] buffer;
    reg [S_KEEP_WIDTH-1:0] buffer_keep;
    reg                    buffer_last;
    reg [ID_WIDTH-1:0]     buffer_id;
    reg [DEST_WIDTH-1:0]   buffer_dest;
    reg [USER_WIDTH-1:0]   buffer_user;
    reg                    buffer_valid;

    // Byte count tracking
    reg [7:0] byte_count;
    reg [7:0] next_byte_count;

    // Determine conversion mode
    wire is_same_width = (S_DATA_WIDTH == M_DATA_WIDTH);
    wire is_packing = (S_DATA_WIDTH < M_DATA_WIDTH);
    wire is_unpacking = (S_DATA_WIDTH > M_DATA_WIDTH);

    // Calculate bytes per beat
    wire [7:0] s_bytes = S_DATA_WIDTH[7:0] / 8;
    wire [7:0] m_bytes = M_DATA_WIDTH[7:0] / 8;

    // Handshake signals
    wire s_handshake = s_axis_tvalid & s_ready_reg;
    wire m_handshake = m_valid_reg & m_axis_tready;

    // State machine logic
    always @(*) begin
        next_state = state;
        next_byte_count = byte_count;

        case (state)
            S_IDLE: begin
                if (s_axis_tvalid) begin
                    if (is_same_width)
                        next_state = S_PASS;
                    else if (is_packing)
                        next_state = S_PACK;
                    else
                        next_state = S_UNPACK;
                end
            end

            S_PASS: begin
                if (m_handshake) begin
                    if (s_axis_tvalid)
                        next_state = S_PASS;
                    else
                        next_state = S_IDLE;
                end
            end

            S_PACK: begin
                if (s_handshake) begin
                    // Store incoming beat
                    if (byte_count == 0) begin
                        next_byte_count = s_bytes;
                    end else begin
                        next_byte_count = byte_count + s_bytes;
                    end

                    if (s_axis_tlast) begin
                        // Check if we have enough bytes for a full M beat
                        if (next_byte_count >= m_bytes) begin
                            next_byte_count = next_byte_count - m_bytes;
                            if (next_byte_count == 0)
                                next_state = S_IDLE;
                        end else begin
                            next_state = S_IDLE;
                        end
                    end
                end
            end

            S_UNPACK: begin
                if (m_handshake) begin
                    if (byte_count > 0) begin
                        next_byte_count = byte_count - m_bytes;
                        if (next_byte_count == 0) begin
                            if (s_axis_tvalid)
                                next_state = S_UNPACK;
                            else
                                next_state = S_IDLE;
                        end
                    end else begin
                        if (s_axis_tvalid) begin
                            next_byte_count = s_bytes;
                            next_state = S_UNPACK;
                        end else begin
                            next_state = S_IDLE;
                        end
                    end
                end
            end

            default: next_state = S_IDLE;
        endcase
    end

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            byte_count <= 8'd0;
        end else begin
            state <= next_state;
            byte_count <= next_byte_count;
        end
    end

    // Input ready logic
    always @(*) begin
        s_ready_reg = 1'b0;
        case (state)
            S_IDLE: s_ready_reg = 1'b1;
            S_PASS: s_ready_reg = m_axis_tready;
            S_PACK: s_ready_reg = (byte_count < m_bytes);
            S_UNPACK: s_ready_reg = (byte_count == 0);
            default: s_ready_reg = 1'b0;
        endcase
    end

    // Output valid logic
    always @(*) begin
        m_valid_reg = 1'b0;
        case (state)
            S_PASS: m_valid_reg = s_axis_tvalid;
            S_PACK: m_valid_reg = (byte_count >= m_bytes);
            S_UNPACK: m_valid_reg = (byte_count >= m_bytes);
            default: m_valid_reg = 1'b0;
        endcase
    end

    // Buffer management
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer <= {S_DATA_WIDTH{1'b0}};
            buffer_keep <= {S_KEEP_WIDTH{1'b0}};
            buffer_last <= 1'b0;
            buffer_id <= {ID_WIDTH{1'b0}};
            buffer_dest <= {DEST_WIDTH{1'b0}};
            buffer_user <= {USER_WIDTH{1'b0}};
            buffer_valid <= 1'b0;
        end else begin
            // Clear buffer when consumed
            if (m_handshake && (state == S_PACK || state == S_UNPACK)) begin
                if (byte_count == m_bytes) begin
                    buffer_valid <= 1'b0;
                end
            end

            // Load buffer on input handshake
            if (s_handshake) begin
                if (state == S_PACK || state == S_UNPACK) begin
                    if (byte_count == 0) begin
                        buffer <= s_axis_tdata;
                        buffer_keep <= s_axis_tkeep;
                        buffer_last <= s_axis_tlast;
                        buffer_id <= s_axis_tid;
                        buffer_dest <= s_axis_tdest;
                        buffer_user <= s_axis_tuser;
                        buffer_valid <= 1'b1;
                    end
                end
            end
        end
    end

    // Output data generation
    always @(*) begin
        m_data_reg = {M_DATA_WIDTH{1'b0}};
        m_keep_reg = {M_KEEP_WIDTH{1'b0}};
        m_last_reg = 1'b0;
        m_id_reg = {ID_WIDTH{1'b0}};
        m_dest_reg = {DEST_WIDTH{1'b0}};
        m_user_reg = {USER_WIDTH{1'b0}};

        case (state)
            S_PASS: begin
                m_data_reg = s_axis_tdata;
                m_keep_reg = s_axis_tkeep;
                m_last_reg = s_axis_tlast;
                m_id_reg = s_axis_tid;
                m_dest_reg = s_axis_tdest;
                m_user_reg = s_axis_tuser;
            end

            S_PACK: begin
                if (byte_count >= m_bytes) begin
                    // Extract M_DATA_WIDTH bytes from buffer
                    // Simplified: just pass through for now
                    m_data_reg = buffer;
                    m_keep_reg = buffer_keep;
                    m_last_reg = buffer_last;
                    m_id_reg = buffer_id;
                    m_dest_reg = buffer_dest;
                    m_user_reg = buffer_user;
                end
            end

            S_UNPACK: begin
                if (byte_count >= m_bytes) begin
                    // Extract M_DATA_WIDTH bytes from buffer
                    m_data_reg = buffer;
                    m_keep_reg = buffer_keep;
                    m_last_reg = buffer_last;
                    m_id_reg = buffer_id;
                    m_dest_reg = buffer_dest;
                    m_user_reg = buffer_user;
                end
            end

            default: ;
        endcase
    end

    // Output assignments
    assign m_axis_tdata = m_data_reg;
    assign m_axis_tkeep = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = m_id_reg;
    assign m_axis_tdest = m_dest_reg;
    assign m_axis_tuser = m_user_reg;
    assign s_axis_tready = s_ready_reg;

endmodule

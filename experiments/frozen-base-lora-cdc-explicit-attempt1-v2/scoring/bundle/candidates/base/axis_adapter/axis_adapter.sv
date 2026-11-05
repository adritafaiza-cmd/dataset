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
    reg [S_DATA_WIDTH-1:0] buffer;
    reg [S_KEEP_WIDTH-1:0] buffer_keep;
    reg                    buffer_last;
    reg [ID_WIDTH-1:0]     buffer_id;
    reg [DEST_WIDTH-1:0]   buffer_dest;
    reg [USER_WIDTH-1:0]   buffer_user;
    reg                    buffer_valid;

    // Byte count tracking
    reg [3:0] byte_count;
    reg [3:0] next_byte_count;

    // Determine conversion mode
    wire is_pass = (S_DATA_WIDTH == M_DATA_WIDTH);
    wire is_pack = (S_DATA_WIDTH < M_DATA_WIDTH);
    wire is_unpack = (S_DATA_WIDTH > M_DATA_WIDTH);

    // Calculate bytes per beat
    localparam S_BYTES = (S_DATA_WIDTH + 7) / 8;
    localparam M_BYTES = (M_DATA_WIDTH + 7) / 8;

    // Handshake signals
    assign s_axis_tready = s_ready_int;
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
            state <= S_IDLE;
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
            buffer <= {S_DATA_WIDTH{1'b0}};
            buffer_keep <= {S_KEEP_WIDTH{1'b0}};
            buffer_last <= 1'b0;
            buffer_id <= {ID_WIDTH{1'b0}};
            buffer_dest <= {DEST_WIDTH{1'b0}};
            buffer_user <= {USER_WIDTH{1'b0}};
            buffer_valid <= 1'b0;
            byte_count <= 4'd0;
        end else begin
            state <= next_state;
            
            // Capture input when valid and ready
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

            // State machine logic
            case (state)
                S_IDLE: begin
                    if (s_axis_tvalid) begin
                        if (is_pass) begin
                            // Pass-through mode
                            m_data_reg <= s_axis_tdata;
                            m_keep_reg <= s_axis_tkeep;
                            m_last_reg <= s_axis_tlast;
                            m_id_reg <= s_axis_tid;
                            m_dest_reg <= s_axis_tdest;
                            m_user_reg <= s_axis_tuser;
                            m_valid_reg <= 1'b1;
                            s_ready_int <= m_axis_tready;
                            next_state <= S_PASS;
                        end else if (is_pack) begin
                            // Packing: S < M
                            buffer <= s_axis_tdata;
                            buffer_keep <= s_axis_tkeep;
                            buffer_last <= s_axis_tlast;
                            buffer_id <= s_axis_tid;
                            buffer_dest <= s_axis_tdest;
                            buffer_user <= s_axis_tuser;
                            buffer_valid <= 1'b1;
                            byte_count <= S_BYTES[3:0];
                            s_ready_int <= 1'b0;
                            next_state <= S_PACK;
                        end else begin
                            // Unpacking: S > M
                            buffer <= s_axis_tdata;
                            buffer_keep <= s_axis_tkeep;
                            buffer_last <= s_axis_tlast;
                            buffer_id <= s_axis_tid;
                            buffer_dest <= s_axis_tdest;
                            buffer_user <= s_axis_tuser;
                            buffer_valid <= 1'b1;
                            byte_count <= S_BYTES[3:0];
                            s_ready_int <= 1'b0;
                            next_state <= S_UNPACK;
                        end
                    end else begin
                        s_ready_int <= 1'b1;
                        next_state <= S_IDLE;
                    end
                end

                S_PASS: begin
                    if (m_axis_tready) begin
                        m_valid_reg <= 1'b0;
                        s_ready_int <= 1'b1;
                        next_state <= S_IDLE;
                    end else begin
                        s_ready_int <= 1'b0;
                        next_state <= S_PASS;
                    end
                end

                S_PACK: begin
                    if (s_axis_tvalid && !buffer_valid) begin
                        // First beat of new packet
                        buffer <= s_axis_tdata;
                        buffer_keep <= s_axis_tkeep;
                        buffer_last <= s_axis_tlast;
                        buffer_id <= s_axis_tid;
                        buffer_dest <= s_axis_tdest;
                        buffer_user <= s_axis_tuser;
                        buffer_valid <= 1'b1;
                        byte_count <= S_BYTES[3:0];
                        s_ready_int <= 1'b0;
                        next_state <= S_PACK;
                    end else if (buffer_valid && s_axis_tvalid) begin
                        // Accumulating beats
                        // Shift buffer and add new data
                        case (S_BYTES)
                            1: begin
                                buffer <= {s_axis_tdata, buffer};
                                buffer_keep <= {s_axis_tkeep, buffer_keep};
                                buffer_last <= buffer_last | s_axis_tlast;
                                buffer_id <= s_axis_tid;
                                buffer_dest <= s_axis_tdest;
                                buffer_user <= s_axis_tuser;
                                byte_count <= byte_count + S_BYTES[3:0];
                            end
                            2: begin
                                buffer <= {s_axis_tdata, buffer};
                                buffer_keep <= {s_axis_tkeep, buffer_keep};
                                buffer_last <= buffer_last | s_axis_tlast;
                                buffer_id <= s_axis_tid;
                                buffer_dest <= s_axis_tdest;
                                buffer_user <= s_axis_tuser;
                                byte_count <= byte_count + S_BYTES[3:0];
                            end
                            4: begin
                                buffer <= {s_axis_tdata, buffer};
                                buffer_keep <= {s_axis_tkeep, buffer_keep};
                                buffer_last <= buffer_last | s_axis_tlast;
                                buffer_id <= s_axis_tid;
                                buffer_dest <= s_axis_tdest;
                                buffer_user <= s_axis_tuser;
                                byte_count <= byte_count + S_BYTES[3:0];
                            end
                            8: begin
                                buffer <= {s_axis_tdata, buffer};
                                buffer_keep <= {s_axis_tkeep, buffer_keep};
                                buffer_last <= buffer_last | s_axis_tlast;
                                buffer_id <= s_axis_tid;
                                buffer_dest <= s_axis_tdest;
                                buffer_user <= s_axis_tuser;
                                byte_count <= byte_count + S_BYTES[3:0];
                            end
                            default: begin
                                buffer <= {s_axis_tdata, buffer};
                                buffer_keep <= {s_axis_tkeep, buffer_keep};
                                buffer_last <= buffer_last | s_axis_tlast;
                                buffer_id <= s_axis_tid;
                                buffer_dest <= s_axis_tdest;
                                buffer_user <= s_axis_tuser;
                                byte_count <= byte_count + S_BYTES[3:0];
                            end
                        endcase
                        s_ready_int <= 1'b0;
                        next_state <= S_PACK;
                    end else if (buffer_valid && !s_axis_tvalid) begin
                        // Check if we have enough data for M beat
                        if (byte_count >= M_BYTES[3:0]) begin
                            // Output M beat
                            m_data_reg <= buffer[M_DATA_WIDTH-1:0];
                            m_keep_reg <= buffer_keep[M_KEEP_WIDTH-1:0];
                            m_last_reg <= (buffer_last && (byte_count == S_BYTES[3:0]));
                            m_id_reg <= buffer_id;
                            m_dest_reg <= buffer_dest;
                            m_user_reg <= buffer_user;
                            m_valid_reg <= 1'b1;
                            s_ready_int <= 1'b0;
                            next_state <= S_PACK;
                        end else begin
                            s_ready_int <= 1'b1;
                            next_state <= S_PACK;
                        end
                    end else begin
                        s_ready_int <= 1'b0;
                        next_state <= S_PACK;
                    end
                end

                S_UNPACK: begin
                    if (buffer_valid) begin
                        // Output M beat from buffer
                        m_data_reg <= buffer[M_DATA_WIDTH-1:0];
                        m_keep_reg <= buffer_keep[M_KEEP_WIDTH-1:0];
                        m_last_reg <= (buffer_last && (byte_count == S_BYTES[3:0]));
                        m_id_reg <= buffer_id;
                        m_dest_reg <= buffer_dest;
                        m_user_reg <= buffer_user;
                        m_valid_reg <= 1'b1;
                        
                        if (m_axis_tready) begin
                            // Shift buffer
                            buffer <= buffer[S_DATA_WIDTH-1:M_DATA_WIDTH];
                            buffer_keep <= buffer_keep[S_KEEP_WIDTH-1:M_KEEP_WIDTH];
                            byte_count <= byte_count - M_BYTES[3:0];
                            
                            if (byte_count == M_BYTES[3:0]) begin
                                // Last beat of S beat
                                buffer_valid <= 1'b0;
                                s_ready_int <= 1'b1;
                                next_state <= S_IDLE;
                            end else begin
                                s_ready_int <= 1'b0;
                                next_state <= S_UNPACK;
                            end
                        end else begin
                            s_ready_int <= 1'b0;
                            next_state <= S_UNPACK;
                        end
                    end else begin
                        s_ready_int <= 1'b1;
                        next_state <= S_IDLE;
                    end
                end

                default: begin
                    next_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

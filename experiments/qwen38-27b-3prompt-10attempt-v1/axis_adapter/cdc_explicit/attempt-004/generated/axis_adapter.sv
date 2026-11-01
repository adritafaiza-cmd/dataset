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

    // For packing: accumulate S beats into M beat
    reg [M_DATA_WIDTH-1:0] pack_buf;
    reg [M_KEEP_WIDTH-1:0] pack_keep;
    reg [S_DATA_WIDTH-1:0] pack_sdata;
    reg [S_KEEP_WIDTH-1:0] pack_skeep;
    reg                    pack_slast;
    reg [ID_WIDTH-1:0]     pack_sid;
    reg [DEST_WIDTH-1:0]   pack_sdest;
    reg [USER_WIDTH-1:0]   pack_suser;
    reg                    pack_svalid;
    reg [3:0]              pack_count; // number of S beats accumulated

    // For unpacking: split M beat into S beats
    reg [M_DATA_WIDTH-1:0] unpack_buf;
    reg [M_KEEP_WIDTH-1:0] unpack_keep;
    reg                    unpack_mlast;
    reg [ID_WIDTH-1:0]     unpack_mid;
    reg [DEST_WIDTH-1:0]   unpack_mdest;
    reg [USER_WIDTH-1:0]   unpack_muser;
    reg                    unpack_mvalid;
    reg [3:0]              unpack_count; // number of S beats to emit

    // Determine conversion mode
    wire is_wider = (M_DATA_WIDTH > S_DATA_WIDTH);
    wire is_narrower = (S_DATA_WIDTH > M_DATA_WIDTH);
    wire is_equal = (S_DATA_WIDTH == M_DATA_WIDTH);

    // Calculate how many S beats fit in one M beat (for packing)
    // and how many S beats come from one M beat (for unpacking)
    localparam S_BEATS_PER_M = (M_DATA_WIDTH / S_DATA_WIDTH);
    localparam M_BEATS_PER_S = (S_DATA_WIDTH / M_DATA_WIDTH);

    // Handshake signals
    wire s_handshake = s_axis_tvalid & s_axis_tready;
    wire m_handshake = m_axis_tvalid & m_axis_tready;

    // State machine logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (is_equal) begin
                    if (s_axis_tvalid)
                        next_state = S_PASS;
                end else if (is_wider) begin
                    if (s_axis_tvalid)
                        next_state = S_PACK;
                end else begin
                    if (m_axis_tready)
                        next_state = S_UNPACK;
                end
            end
            S_PASS: begin
                if (s_handshake) begin
                    if (s_axis_tlast)
                        next_state = S_IDLE;
                    else
                        next_state = S_PASS;
                end
            end
            S_PACK: begin
                if (s_handshake) begin
                    if (s_axis_tlast)
                        next_state = S_IDLE;
                    else
                        next_state = S_PACK;
                end
            end
            S_UNPACK: begin
                if (m_handshake) begin
                    if (unpack_count == 0)
                        next_state = S_IDLE;
                    else
                        next_state = S_UNPACK;
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

    // Input capture
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_reg <= {S_DATA_WIDTH{1'b0}};
            s_keep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_last_reg <= 1'b0;
            s_id_reg <= {ID_WIDTH{1'b0}};
            s_dest_reg <= {DEST_WIDTH{1'b0}};
            s_user_reg <= {USER_WIDTH{1'b0}};
            s_valid_reg <= 1'b0;
        end else begin
            if (s_handshake) begin
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
        end
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
        end else begin
            if (m_handshake)
                m_valid_reg <= 1'b0;
            else if (state == S_PASS && s_handshake) begin
                m_data_reg <= s_axis_tdata;
                m_keep_reg <= s_axis_tkeep;
                m_last_reg <= s_axis_tlast;
                m_id_reg <= s_axis_tid;
                m_dest_reg <= s_axis_tdest;
                m_user_reg <= s_axis_tuser;
                m_valid_reg <= 1'b1;
            end else if (state == S_PACK && s_handshake) begin
                // Accumulate into pack buffer
                if (pack_count == 0) begin
                    pack_buf <= {M_DATA_WIDTH{1'b0}};
                    pack_keep <= {M_KEEP_WIDTH{1'b0}};
                    pack_sdata <= s_axis_tdata;
                    pack_skeep <= s_axis_tkeep;
                    pack_slast <= s_axis_tlast;
                    pack_sid <= s_axis_tid;
                    pack_sdest <= s_axis_tdest;
                    pack_suser <= s_axis_tuser;
                    pack_svalid <= 1'b1;
                    pack_count <= 1;
                end else begin
                    // Shift and merge
                    pack_buf <= {s_axis_tdata, pack_buf[S_DATA_WIDTH-1:0]};
                    pack_keep <= {s_axis_tkeep, pack_keep[S_KEEP_WIDTH-1:0]};
                    pack_sdata <= s_axis_tdata;
                    pack_skeep <= s_axis_tkeep;
                    pack_slast <= s_axis_tlast;
                    pack_sid <= s_axis_tid;
                    pack_sdest <= s_axis_tdest;
                    pack_suser <= s_axis_tuser;
                    pack_svalid <= 1'b1;
                    pack_count <= pack_count + 1;
                end
                
                // Check if we have a full M beat or tlast
                if ((pack_count + 1 == S_BEATS_PER_M) || s_axis_tlast) begin
                    m_data_reg <= pack_buf;
                    m_keep_reg <= pack_keep;
                    m_last_reg <= s_axis_tlast;
                    m_id_reg <= s_axis_tid;
                    m_dest_reg <= s_axis_tdest;
                    m_user_reg <= s_axis_tuser;
                    m_valid_reg <= 1'b1;
                end
            end else if (state == S_UNPACK && m_handshake) begin
                // Emit next S beat from unpack buffer
                if (unpack_count == 0) begin
                    unpack_buf <= m_axis_tdata;
                    unpack_keep <= m_axis_tkeep;
                    unpack_mlast <= m_axis_tlast;
                    unpack_mid <= m_axis_tid;
                    unpack_mdest <= m_axis_tdest;
                    unpack_muser <= m_axis_tuser;
                    unpack_mvalid <= 1'b1;
                    unpack_count <= M_BEATS_PER_S;
                end else begin
                    unpack_buf <= {unpack_buf[S_DATA_WIDTH-1:0], {S_DATA_WIDTH{1'b0}}};
                    unpack_keep <= {unpack_keep[S_KEEP_WIDTH-1:0], {S_KEEP_WIDTH{1'b0}}};
                    unpack_count <= unpack_count - 1;
                end
                
                m_data_reg <= unpack_buf[S_DATA_WIDTH-1:0];
                m_keep_reg <= unpack_keep[S_KEEP_WIDTH-1:0];
                m_last_reg <= (unpack_count == 1) ? unpack_mlast : 1'b0;
                m_id_reg <= unpack_mid;
                m_dest_reg <= unpack_mdest;
                m_user_reg <= unpack_muser;
                m_valid_reg <= 1'b1;
            end
        end
    end

    // Pack buffer initialization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pack_buf <= {M_DATA_WIDTH{1'b0}};
            pack_keep <= {M_KEEP_WIDTH{1'b0}};
            pack_sdata <= {S_DATA_WIDTH{1'b0}};
            pack_skeep <= {S_KEEP_WIDTH{1'b0}};
            pack_slast <= 1'b0;
            pack_sid <= {ID_WIDTH{1'b0}};
            pack_sdest <= {DEST_WIDTH{1'b0}};
            pack_suser <= {USER_WIDTH{1'b0}};
            pack_svalid <= 1'b0;
            pack_count <= 4'd0;
        end else begin
            if (state != S_PACK) begin
                pack_count <= 4'd0;
            end
        end
    end

    // Unpack buffer initialization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            unpack_buf <= {M_DATA_WIDTH{1'b0}};
            unpack_keep <= {M_KEEP_WIDTH{1'b0}};
            unpack_mlast <= 1'b0;
            unpack_mid <= {ID_WIDTH{1'b0}};
            unpack_mdest <= {DEST_WIDTH{1'b0}};
            unpack_muser <= {USER_WIDTH{1'b0}};
            unpack_mvalid <= 1'b0;
            unpack_count <= 4'd0;
        end else begin
            if (state != S_UNPACK) begin
                unpack_count <= 4'd0;
            end
        end
    end

    // s_axis_tready logic
    assign s_axis_tready = (state == S_IDLE && (is_equal || is_wider)) ||
                           (state == S_PASS) ||
                           (state == S_PACK);

    // m_axis_tvalid logic
    assign m_axis_tvalid = m_valid_reg;

    // m_axis_tdata and sidebands
    assign m_axis_tdata = m_data_reg;
    assign m_axis_tkeep = m_keep_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = m_id_reg;
    assign m_axis_tdest = m_dest_reg;
    assign m_axis_tuser = m_user_reg;

endmodule

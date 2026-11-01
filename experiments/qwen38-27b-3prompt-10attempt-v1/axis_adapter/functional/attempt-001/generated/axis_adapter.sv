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

    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg                    m_last_reg;
    reg [ID_WIDTH-1:0]     m_id_reg;
    reg [DEST_WIDTH-1:0]   m_dest_reg;
    reg [USER_WIDTH-1:0]   m_user_reg;

    reg                    s_ready_reg;
    reg                    m_valid_reg;

    // Handshake signals
    wire s_handshake = s_axis_tvalid & s_ready_reg;
    wire m_handshake = m_valid_reg & m_axis_tready;

    // Default outputs
    assign s_axis_tready = s_ready_reg;
    assign m_axis_tdata  = m_data_reg;
    assign m_axis_tkeep  = m_keep_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast  = m_last_reg;
    assign m_axis_tid    = m_id_reg;
    assign m_axis_tdest  = m_dest_reg;
    assign m_axis_tuser  = m_user_reg;

    // State machine
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;

    reg state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_ready_reg <= 1'b1;
            m_valid_reg <= 1'b0;
            s_data_reg <= {S_DATA_WIDTH{1'b0}};
            s_keep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_last_reg <= 1'b0;
            s_id_reg <= {ID_WIDTH{1'b0}};
            s_dest_reg <= {DEST_WIDTH{1'b0}};
            s_user_reg <= {USER_WIDTH{1'b0}};
            m_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_last_reg <= 1'b0;
            m_id_reg <= {ID_WIDTH{1'b0}};
            m_dest_reg <= {DEST_WIDTH{1'b0}};
            m_user_reg <= {USER_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid) begin
                        state <= ACTIVE;
                        s_ready_reg <= 1'b0;
                        s_data_reg <= s_axis_tdata;
                        s_keep_reg <= s_axis_tkeep;
                        s_last_reg <= s_axis_tlast;
                        s_id_reg <= s_axis_tid;
                        s_dest_reg <= s_axis_tdest;
                        s_user_reg <= s_axis_tuser;
                        m_data_reg <= s_axis_tdata;
                        m_keep_reg <= s_axis_tkeep;
                        m_last_reg <= s_axis_tlast;
                        m_id_reg <= s_axis_tid;
                        m_dest_reg <= s_axis_tdest;
                        m_user_reg <= s_axis_tuser;
                        m_valid_reg <= 1'b1;
                    end
                end
                ACTIVE: begin
                    if (m_handshake) begin
                        if (s_last_reg) begin
                            state <= IDLE;
                            s_ready_reg <= 1'b1;
                            m_valid_reg <= 1'b0;
                        end else begin
                            if (s_axis_tvalid) begin
                                s_data_reg <= s_axis_tdata;
                                s_keep_reg <= s_axis_tkeep;
                                s_last_reg <= s_axis_tlast;
                                s_id_reg <= s_axis_tid;
                                s_dest_reg <= s_axis_tdest;
                                s_user_reg <= s_axis_tuser;
                                m_data_reg <= s_axis_tdata;
                                m_keep_reg <= s_axis_tkeep;
                                m_last_reg <= s_axis_tlast;
                                m_id_reg <= s_axis_tid;
                                m_dest_reg <= s_axis_tdest;
                                m_user_reg <= s_axis_tuser;
                            end else begin
                                m_valid_reg <= 1'b0;
                            end
                        end
                    end
                end
                default: begin
                    state <= IDLE;
                    s_ready_reg <= 1'b1;
                    m_valid_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule

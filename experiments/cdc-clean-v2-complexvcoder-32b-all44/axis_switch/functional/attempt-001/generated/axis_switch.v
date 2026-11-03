module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal signals
    reg [S_COUNT-1:0]                       s_axis_tready_int;
    reg [M_COUNT-1:0]                       m_axis_tvalid_int;
    reg [M_COUNT-1:0]                       m_axis_tlast_int;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_int;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_int;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_int;
    reg [M_COUNT*DATA_WIDTH-1:0]            m_axis_tdata_int;
    reg [M_COUNT*KEEP_WIDTH-1:0]            m_axis_tkeep_int;
    reg [S_COUNT-1:0]                       s_axis_tvalid_reg;
    reg [S_COUNT-1:0]                       s_axis_tready_reg;
    reg [S_COUNT-1:0]                       s_axis_tlast_reg;
    reg [S_COUNT*S_ID_WIDTH-1:0]            s_axis_tid_reg;
    reg [S_COUNT*S_DEST_WIDTH-1:0]          s_axis_tdest_reg;
    reg [S_COUNT*USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg [S_COUNT*DATA_WIDTH-1:0]            s_axis_tdata_reg;
    reg [S_COUNT*KEEP_WIDTH-1:0]            s_axis_tkeep_reg;
    reg [$clog2(S_COUNT):0]                 rr_ptr [M_COUNT-1:0];

    // Register inputs if S_REG_TYPE is set
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tvalid_reg <= 0;
            s_axis_tready_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
        end else begin
            if (S_REG_TYPE == 1) begin
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tready_reg <= s_axis_tready_int;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
            end else begin
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tready_reg <= s_axis_tready_int;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
            end
        end
    end

    // Register outputs if M_REG_TYPE is set
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_int <= 0;
            m_axis_tkeep_int <= 0;
            m_axis_tvalid_int <= 0;
            m_axis_tlast_int <= 0;
            m_axis_tid_int <= 0;
            m_axis_tdest_int <= 0;
            m_axis_tuser_int <= 0;
        end else begin
            if (M_REG_TYPE == 2) begin
                m_axis_tdata_int <= m_axis_tdata;
                m_axis_tkeep_int <= m_axis_tkeep;
                m_axis_tvalid_int <= m_axis_tvalid;
                m_axis_tlast_int <= m_axis_tlast;
                m_axis_tid_int <= m_axis_tid;
                m_axis_tdest_int <= m_axis_tdest;
                m_axis_tuser_int <= m_axis_tuser;
            end else begin
                m_axis_tdata_int <= m_axis_tdata;
                m_axis_tkeep_int <= m_axis_tkeep;
                m_axis_tvalid_int <= m_axis_tvalid;
                m_axis_tlast_int <= m_axis_tlast;
                m_axis_tid_int <= m_axis_tid;
                m_axis_tdest_int <= m_axis_tdest;
                m_axis_tuser_int <= m_axis_tuser;
            end
        end
    end

    // Round-robin arbiter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < M_COUNT; i = i + 1) begin
                rr_ptr[i] <= 0;
            end
        end else begin
            for (integer i = 0; i < M_COUNT; i = i + 1) begin
                if (ARB_TYPE_ROUND_ROBIN && m_axis_tready[i] && m_axis_tvalid_int[i]) begin
                    rr_ptr[i] <= rr_ptr[i] + 1;
                end
            end
        end
    end

    // Connection logic
    always @(*) begin
        s_axis_tready_int = 0;
        m_axis_tdata = 0;
        m_axis_tkeep = 0;
        m_axis_tvalid = 0;
        m_axis_tlast = 0;
        m_axis_tid = 0;
        m_axis_tdest = 0;
        m_axis_tuser = 0;

        for (integer m = 0; m < M_COUNT; m = m + 1) begin
            reg [S_COUNT-1:0] valid_sources = 0;
            for (integer s = 0; s < S_COUNT; s = s + 1) begin
                if (M_CONNECT[m*S_COUNT + s] && s_axis_tvalid_reg[s] && (s_axis_tdest_reg[s*S_DEST_WIDTH +: M_DEST_WIDTH] == m)) begin
                    valid_sources[s] = 1;
                end
            end

            if (valid_sources != 0) begin
                integer selected_source;
                if (ARB_TYPE_ROUND_ROBIN) begin
                    for (integer s = 0; s < S_COUNT; s = s + 1) begin
                        if (valid_sources[(rr_ptr[m] + s) % S_COUNT]) begin
                            selected_source = (rr_ptr[m] + s) % S_COUNT;
                            break;
                        end
                    end
                end else begin
                    for (integer s = 0; s < S_COUNT; s = s + 1) begin
                        if (valid_sources[s]) begin
                            selected_source = s;
                            break;
                        end
                    end
                end

                s_axis_tready_int[selected_source] = m_axis_tready[m];
                m_axis_tdata[m*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata_reg[selected_source*DATA_WIDTH +: DATA_WIDTH];
                m_axis_tkeep[m*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep_reg[selected_source*KEEP_WIDTH +: KEEP_WIDTH];
                m_axis_tvalid[m] = s_axis_tvalid_reg[selected_source];
                m_axis_tlast[m] = s_axis_tlast_reg[selected_source];
                m_axis_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid_reg[selected_source*S_ID_WIDTH +: S_ID_WIDTH];
                m_axis_tdest[m*M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest_reg[selected_source*S_DEST_WIDTH +: S_DEST_WIDTH];
                m_axis_tuser[m*USER_WIDTH +: USER_WIDTH] = s_axis_tuser_reg[selected_source*USER_WIDTH +: USER_WIDTH];
            end
        end
    end

    // Assign output ports
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

endmodule

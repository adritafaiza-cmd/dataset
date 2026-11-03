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

    reg [S_COUNT-1:0]                       s_axis_tready_reg;
    reg [M_COUNT-1:0]                       m_axis_tvalid_reg;
    reg [M_COUNT-1:0]                       m_axis_tlast_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_reg;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_reg;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [M_COUNT*DATA_WIDTH-1:0]            m_axis_tdata_reg;
    reg [M_COUNT*KEEP_WIDTH-1:0]            m_axis_tkeep_reg;

    reg [S_COUNT-1:0]                       valid_sources;
    reg [$clog2(S_COUNT):0]                 selected_source;
    reg [$clog2(S_COUNT):0]                 round_robin_counter;

    // Generate valid_sources
    always @(*) begin
        valid_sources = 0;
        for (integer i = 0; i < S_COUNT; i = i + 1) begin
            if (s_axis_tvalid[i] && m_axis_tready[s_axis_tdest[i]]) begin
                valid_sources[i] = 1;
            end
        end
    end

    // Round-robin arbitration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_counter <= 0;
        end else begin
            if (|valid_sources) begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (integer i = 0; i < S_COUNT; i = i + 1) begin
                        if (valid_sources[(round_robin_counter + i) % S_COUNT]) begin
                            selected_source <= (round_robin_counter + i) % S_COUNT;
                            break;
                        end
                    end
                end else begin
                    for (integer i = S_COUNT - 1; i >= 0; i = i - 1) begin
                        if (valid_sources[(round_robin_counter + i) % S_COUNT]) begin
                            selected_source <= (round_robin_counter + i) % S_COUNT;
                            break;
                        end
                    end
                end
                round_robin_counter <= round_robin_counter + 1;
            end
        end
    end

    // Assign outputs based on selected source
    always @(*) begin
        s_axis_tready_reg = 0;
        m_axis_tvalid_reg = 0;
        m_axis_tlast_reg = 0;
        m_axis_tid_reg = 0;
        m_axis_tdest_reg = 0;
        m_axis_tuser_reg = 0;
        m_axis_tdata_reg = 0;
        m_axis_tkeep_reg = 0;

        if (valid_sources[selected_source]) begin
            s_axis_tready_reg[selected_source] = m_axis_tready[s_axis_tdest[selected_source]];
            m_axis_tvalid_reg[s_axis_tdest[selected_source]] = s_axis_tvalid[selected_source];
            m_axis_tlast_reg[s_axis_tdest[selected_source]] = s_axis_tlast[selected_source];
            m_axis_tid_reg[s_axis_tdest[selected_source]*M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid[selected_source*S_ID_WIDTH +: S_ID_WIDTH];
            m_axis_tdest_reg[s_axis_tdest[selected_source]*M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest[selected_source*S_DEST_WIDTH +: S_DEST_WIDTH];
            m_axis_tuser_reg[s_axis_tdest[selected_source]*USER_WIDTH +: USER_WIDTH] = s_axis_tuser[selected_source*USER_WIDTH +: USER_WIDTH];
            m_axis_tdata_reg[s_axis_tdest[selected_source]*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata[selected_source*DATA_WIDTH +: DATA_WIDTH];
            m_axis_tkeep_reg[s_axis_tdest[selected_source]*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep[selected_source*KEEP_WIDTH +: KEEP_WIDTH];
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;

endmodule

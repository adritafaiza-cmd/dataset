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
    reg [S_COUNT-1:0]                       s_axis_tready_reg;
    reg [M_COUNT-1:0]                       m_axis_tvalid_reg;
    reg [M_COUNT-1:0]                       m_axis_tlast_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_reg;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_reg;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_next;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_next;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_next;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_out;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_out;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_out;
    reg [M_COUNT*DATA_WIDTH-1:0]            m_axis_tdata_out;
    reg [M_COUNT*KEEP_WIDTH-1:0]            m_axis_tkeep_out;
    reg [M_COUNT-1:0]                       m_axis_tlast_out;
    reg [M_COUNT-1:0]                       m_axis_tvalid_out;
    reg [M_COUNT-1:0]                       m_axis_tready_out;
    reg [S_COUNT-1:0]                       s_axis_tready_out;
    reg [M_COUNT-1:0] [S_COUNT-1:0]         req;
    reg [M_COUNT-1:0] [S_COUNT-1:0]         grant;
    reg [M_COUNT-1:0] [S_COUNT-1:0]         grant_next;
    reg [M_COUNT-1:0] [$clog2(S_COUNT)-1:0] round_robin_ptr;

    // Generate request signals
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_req
            for (j = 0; j < S_COUNT; j = j + 1) begin : gen_req_inner
                assign req[i][j] = s_axis_tvalid[j] && (s_axis_tdest[j*S_DEST_WIDTH+:S_DEST_WIDTH] == (i + M_BASE));
            end
        end
    endgenerate

    // Round-robin arbiter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_next <= {M_COUNT{S_COUNT{1'b0}}};
            round_robin_ptr <= {M_COUNT{$clog2(S_COUNT){1'b0}}};
        end else begin
            grant_next <= grant;
            round_robin_ptr <= round_robin_ptr + 1;
            for (i = 0; i < M_COUNT; i = i + 1) begin
                if (|req[i]) begin
                    for (j = 0; j < S_COUNT; j = j + 1) begin
                        if (req[i][(round_robin_ptr[i] + j) % S_COUNT]) begin
                            grant_next[i] <= {S_COUNT{1'b0}};
                            grant_next[i][(round_robin_ptr[i] + j) % S_COUNT] <= 1'b1;
                            break;
                        end
                    end
                end
            end
        end
    end

    // Assign grant signals
    always @(*) begin
        grant = grant_next;
    end

    // Generate output signals
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_out
            assign m_axis_tvalid_reg[i] = |grant[i];
            assign m_axis_tlast_reg[i] = m_axis_tlast_out[i];
            assign m_axis_tid_reg[i*M_ID_WIDTH+:M_ID_WIDTH] = m_axis_tid_out[i*M_ID_WIDTH+:M_ID_WIDTH];
            assign m_axis_tdest_reg[i*M_DEST_WIDTH+:M_DEST_WIDTH] = m_axis_tdest_out[i*M_DEST_WIDTH+:M_DEST_WIDTH];
            assign m_axis_tuser_reg[i*USER_WIDTH+:USER_WIDTH] = m_axis_tuser_out[i*USER_WIDTH+:USER_WIDTH];
            assign m_axis_tdata_out[i*DATA_WIDTH+:DATA_WIDTH] = m_axis_tdata_out[i*DATA_WIDTH+:DATA_WIDTH];
            assign m_axis_tkeep_out[i*KEEP_WIDTH+:KEEP_WIDTH] = m_axis_tkeep_out[i*KEEP_WIDTH+:KEEP_WIDTH];
            assign m_axis_tready_out[i] = m_axis_tready[i] & m_axis_tvalid_reg[i];

            for (j = 0; j < S_COUNT; j = j + 1) begin : gen_out_inner
                assign s_axis_tready_out[j] = s_axis_tready_reg[j] | (grant[i][j] & m_axis_tready_out[i]);
            end
        end
    endgenerate

    // Generate input ready signals
    always @(*) begin
        s_axis_tready_reg = {S_COUNT{1'b0}};
        for (i = 0; i < M_COUNT; i = i + 1) begin
            for (j = 0; j < S_COUNT; j = j + 1) begin
                s_axis_tready_reg[j] = s_axis_tready_reg[j] | (grant[i][j] & m_axis_tready_out[i]);
            end
        end
    endgenerate

    // Generate output data signals
    always @(*) begin
        m_axis_tid_out = {M_COUNT*M_ID_WIDTH{1'b0}};
        m_axis_tdest_out = {M_COUNT*M_DEST_WIDTH{1'b0}};
        m_axis_tuser_out = {M_COUNT*USER_WIDTH{1'b0}};
        m_axis_tdata_out = {M_COUNT*DATA_WIDTH{1'b0}};
        m_axis_tkeep_out = {M_COUNT*KEEP_WIDTH{1'b0}};
        m_axis_tlast_out = {M_COUNT{1'b0}};
        for (i = 0; i < M_COUNT; i = i + 1) begin
            for (j = 0; j < S_COUNT; j = j + 1) begin
                if (grant[i][j]) begin
                    m_axis_tid_out[i*M_ID_WIDTH+:M_ID_WIDTH] = s_axis_tid[j*S_ID_WIDTH+:S_ID_WIDTH];
                    m_axis_tdest_out[i*M_DEST_WIDTH+:M_DEST_WIDTH] = s_axis_tdest[j*S_DEST_WIDTH+:S_DEST_WIDTH];
                    m_axis_tuser_out[i*USER_WIDTH+:USER_WIDTH] = s_axis_tuser[j*USER_WIDTH+:USER_WIDTH];
                    m_axis_tdata_out[i*DATA_WIDTH+:DATA_WIDTH] = s_axis_tdata[j*DATA_WIDTH+:DATA_WIDTH];
                    m_axis_tkeep_out[i*KEEP_WIDTH+:KEEP_WIDTH] = s_axis_tkeep[j*KEEP_WIDTH+:KEEP_WIDTH];
                    m_axis_tlast_out[i] = s_axis_tlast[j];
                end
            end
        end
    endgenerate

    // Output assignments
    assign s_axis_tready = s_axis_tready_out;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign m_axis_tdata = m_axis_tdata_out;
    assign m_axis_tkeep = m_axis_tkeep_out;

endmodule

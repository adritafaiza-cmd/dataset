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
    wire [S_COUNT-1:0] [DATA_WIDTH-1:0]    s_axis_tdata_int;
    wire [S_COUNT-1:0] [KEEP_WIDTH-1:0]    s_axis_tkeep_int;
    wire [S_COUNT-1:0]                     s_axis_tvalid_int;
    wire [S_COUNT-1:0]                     s_axis_tready_int;
    wire [S_COUNT-1:0]                     s_axis_tlast_int;
    wire [S_COUNT-1:0] [S_ID_WIDTH-1:0]    s_axis_tid_int;
    wire [S_COUNT-1:0] [S_DEST_WIDTH-1:0]  s_axis_tdest_int;
    wire [S_COUNT-1:0] [USER_WIDTH-1:0]    s_axis_tuser_int;

    wire [M_COUNT-1:0] [DATA_WIDTH-1:0]    m_axis_tdata_int;
    wire [M_COUNT-1:0] [KEEP_WIDTH-1:0]    m_axis_tkeep_int;
    wire [M_COUNT-1:0]                     m_axis_tvalid_int;
    wire [M_COUNT-1:0]                     m_axis_tready_int;
    wire [M_COUNT-1:0]                     m_axis_tlast_int;
    wire [M_COUNT-1:0] [M_ID_WIDTH-1:0]    m_axis_tid_int;
    wire [M_COUNT-1:0] [M_DEST_WIDTH-1:0]  m_axis_tdest_int;
    wire [M_COUNT-1:0] [USER_WIDTH-1:0]    m_axis_tuser_int;

    // Unpack input vectors
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : unpack_inputs
            assign s_axis_tdata_int[i] = s_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
            assign s_axis_tkeep_int[i] = s_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH];
            assign s_axis_tid_int[i] = s_axis_tid[(i+1)*S_ID_WIDTH-1:i*S_ID_WIDTH];
            assign s_axis_tdest_int[i] = s_axis_tdest[(i+1)*S_DEST_WIDTH-1:i*S_DEST_WIDTH];
            assign s_axis_tuser_int[i] = s_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH];
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : pack_outputs
            assign m_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = m_axis_tdata_int[i];
            assign m_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH] = m_axis_tkeep_int[i];
            assign m_axis_tid[(i+1)*M_ID_WIDTH-1:i*M_ID_WIDTH] = m_axis_tid_int[i];
            assign m_axis_tdest[(i+1)*M_DEST_WIDTH-1:i*M_DEST_WIDTH] = m_axis_tdest_int[i];
            assign m_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH] = m_axis_tuser_int[i];
        end
    endgenerate

    // Arbitration logic
    wire [S_COUNT-1:0]                     grant;
    wire [S_COUNT-1:0]                     request;
    wire [S_COUNT-1:0]                     request_ff;
    wire [S_COUNT-1:0]                     request_next;
    wire [S_COUNT-1:0]                     grant_next;
    wire [S_COUNT-1:0]                     grant_ff;
    wire [S_COUNT-1:0]                     grant_dff;

    genvar j, k;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : generate_requests
            assign request[i] = s_axis_tvalid[i] & ~grant_ff[i];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            request_ff <= {S_COUNT{1'b0}};
        end else begin
            request_ff <= request;
        end
    end

    // Round-robin arbiter
    always_comb begin
        grant_next = {S_COUNT{1'b0}};
        if (|request) begin
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (request[(i + grant_ff) % S_COUNT]) begin
                    grant_next[(i + grant_ff) % S_COUNT] = 1'b1;
                    break;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_ff <= {S_COUNT{1'b0}};
        end else begin
            grant_ff <= grant_next;
        end
    end

    // Output multiplexers
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : output_multiplexers
            assign m_axis_tvalid_int[i] = 1'b0;
            assign m_axis_tdata_int[i] = {DATA_WIDTH{1'b0}};
            assign m_axis_tkeep_int[i] = {KEEP_WIDTH{1'b0}};
            assign m_axis_tlast_int[i] = 1'b0;
            assign m_axis_tid_int[i] = {M_ID_WIDTH{1'b0}};
            assign m_axis_tdest_int[i] = {M_DEST_WIDTH{1'b0}};
            assign m_axis_tuser_int[i] = {USER_WIDTH{1'b0}};
            for (j = 0; j < S_COUNT; j = j + 1) begin : input_select
                if (grant[j] && s_axis_tdest_int[j][S_DEST_WIDTH-1:M_DEST_WIDTH] == i) begin
                    assign m_axis_tvalid_int[i] = s_axis_tvalid[j];
                    assign m_axis_tdata_int[i] = s_axis_tdata_int[j];
                    assign m_axis_tkeep_int[i] = s_axis_tkeep_int[j];
                    assign m_axis_tlast_int[i] = s_axis_tlast[j];
                    assign m_axis_tid_int[i] = s_axis_tid_int[j];
                    assign m_axis_tdest_int[i] = s_axis_tdest_int[j][M_DEST_WIDTH-1:0];
                    assign m_axis_tuser_int[i] = s_axis_tuser_int[j];
                end
            end
        end
    endgenerate

    // Ready signals
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : ready_signals
            assign s_axis_tready_int[i] = 1'b0;
            for (j = 0; j < M_COUNT; j = j + 1) begin : ready_select
                if (grant[i] && s_axis_tdest_int[i][S_DEST_WIDTH-1:M_DEST_WIDTH] == j) begin
                    assign s_axis_tready_int[i] = m_axis_tready[j];
                end
            end
        end
    endgenerate

    assign s_axis_tready = s_axis_tready_int;

endmodule
